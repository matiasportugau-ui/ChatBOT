#!/usr/bin/env python3
import argparse
import json
import os
import sys
from pathlib import Path

CANDIDATE_FILES = [
    'intent_report.json',
    'DIETClassifier_report.json',
    'report.json',
]


def find_report_file(base: Path) -> Path | None:
    # Look for known filenames, recursively
    for pattern in CANDIDATE_FILES:
        for p in base.rglob(pattern):
            return p
    # fallback: any *.json inside
    for p in base.rglob('*.json'):
        return p
    return None


def load_json(path: Path) -> dict:
    with path.open('r', encoding='utf-8') as f:
        return json.load(f)


def extract_macro_f1(report: dict) -> float | None:
    # Try sklearn-like classification report structure
    # e.g. {
    #  'accuracy': 0.91,
    #  'macro avg': {'precision': 0.89, 'recall': 0.88, 'f1-score': 0.885, 'support': 100},
    #  'weighted avg': {...},
    #  'intentA': {...}
    # }
    for key in ('macro avg', 'macro_avg', 'macro'):
        node = report.get(key)
        if isinstance(node, dict):
            for f1k in ('f1-score', 'f1_score', 'f1'):
                if f1k in node and isinstance(node[f1k], (int, float)):
                    return float(node[f1k])
    # If not found, compute average from per-label entries
    f1s = []
    skip_keys = {'accuracy', 'macro avg', 'weighted avg', 'micro avg', 'macro_avg', 'weighted_avg'}
    for k, v in report.items():
        if k in skip_keys or not isinstance(v, dict):
            continue
        for f1k in ('f1-score', 'f1_score', 'f1'):
            if f1k in v and isinstance(v[f1k], (int, float)):
                f1s.append(float(v[f1k]))
                break
    if f1s:
        return sum(f1s) / len(f1s)
    return None


def write_summary(macro_f1: float, report_path: Path):
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    md = [
        '## NLU Test Summary',
        '',
        f'- Macro F1: {macro_f1:.4f}',
        f'- Report file: `{report_path}`',
        '',
    ]
    if summary:
        with open(summary, 'a', encoding='utf-8') as f:
            f.write('\n'.join(md) + '\n')
    # Also print to logs
    print('\n'.join(md))


def set_output(name: str, value: str):
    out = os.environ.get('GITHUB_OUTPUT')
    line = f"{name}={value}\n"
    if out:
        with open(out, 'a', encoding='utf-8') as f:
            f.write(line)
    print(line.strip())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--reports', type=str, default='reports', help='Reports directory')
    args = parser.parse_args()

    base = Path(args.reports)
    if not base.exists():
        print(f"Reports directory not found: {base}", file=sys.stderr)
        sys.exit(1)

    report_file = find_report_file(base)
    if not report_file:
        print('No report JSON file found in reports/', file=sys.stderr)
        sys.exit(1)

    data = load_json(report_file)
    macro_f1 = extract_macro_f1(data)
    if macro_f1 is None:
        print('Could not extract macro F1 from report JSON', file=sys.stderr)
        sys.exit(1)

    write_summary(macro_f1, report_file)
    set_output('macro_f1', f"{macro_f1:.4f}")

    threshold = float(os.environ.get('THRESHOLD', '0.85'))
    if macro_f1 < threshold:
        print(f"Quality gate failed: macro F1 {macro_f1:.4f} < {threshold}", file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
