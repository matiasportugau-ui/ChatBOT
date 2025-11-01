#!/usr/bin/env python3
"""
Planner Agent (background) for ChatBOT repo

Responsibilities:
- Track repo activity since last run (commits, changed files)
- Read latest NLU report (if present) and include Macro F1
- Produce a structured JSON report under reports/agent-YYYYMMDD-HHMM.json
- Update reports/agent-state.json with last_seen_commit and last_summary_at
- Maintain a convenience copy at reports/latest-agent.json

This script is idempotent and safe to run in CI on a schedule.
"""
from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parents[1]
REPORTS_DIR = REPO_ROOT / "reports"
STATE_PATH = REPORTS_DIR / "agent-state.json"


def run(cmd: List[str], cwd: Optional[Path] = None) -> str:
    res = subprocess.run(cmd, cwd=str(cwd or REPO_ROOT), check=False, capture_output=True, text=True)
    if res.returncode != 0:
        return ""
    return res.stdout.strip()


def git_head() -> str:
    return run(["git", "rev-parse", "HEAD"]) or ""


def git_commits_since(sha: str) -> List[Dict[str, str]]:
    if not sha:
        log = run(["git", "log", "-n", "10", "--pretty=format:%H\t%s"])  # last 10
    else:
        log = run(["git", "log", f"{sha}..HEAD", "--pretty=format:%H\t%s"])  # since sha (exclusive)
    commits: List[Dict[str, str]] = []
    for line in log.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t", 1)
        if len(parts) == 2:
            commits.append({"sha": parts[0], "subject": parts[1]})
    return commits


def git_changed_files_since(sha: str) -> List[str]:
    if not sha:
        diff = run(["git", "diff", "--name-only", "HEAD~1..HEAD"])  # last commit
    else:
        diff = run(["git", "diff", "--name-only", f"{sha}..HEAD"])
    files = [f for f in diff.splitlines() if f]
    return files


def read_json(path: Path) -> Optional[dict]:
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    # Load state
    state = read_json(STATE_PATH) or {}
    repo_key = "ChatBOT"
    last_seen_commit = state.get("repos", {}).get(repo_key, {}).get("last_seen_commit", "")

    head = git_head()
    commits = git_commits_since(last_seen_commit)
    changed_files = git_changed_files_since(last_seen_commit)

    # Read NLU report if present
    intent_report = read_json(REPORTS_DIR / "intent_report.json")
    macro_f1 = None
    if intent_report and isinstance(intent_report, dict):
        macro_f1 = intent_report.get("accuracy") or intent_report.get("macro f1") or intent_report.get("macro_f1")
        # some Rasa reports store f1 in nested metrics
        if macro_f1 is None:
            metrics = intent_report.get("metrics") if isinstance(intent_report.get("metrics"), dict) else None
            if metrics:
                macro_f1 = metrics.get("f1_score_macro") or metrics.get("macro_f1")

    # Build highlights
    highlights: List[str] = []
    if changed_files:
        highlights.append(f"{len(changed_files)} files changed since last run")
    if macro_f1 is not None:
        try:
            highlights.append(f"Macro F1 current: {float(macro_f1):.2f}")
        except Exception:
            highlights.append(f"Macro F1 current: {macro_f1}")
    if not highlights:
        highlights.append("No significant changes detected")

    # Compose report
    now = datetime.now(timezone.utc)
    stamp = now.strftime("%Y%m%d-%H%M")
    report = {
        "report_version": "1.0",
        "timestamp": now.isoformat(),
        "since_commit": last_seen_commit or None,
        "until_commit": head or None,
        "highlights": highlights,
        "changes": {
            "commits": commits,
            "files_modified": changed_files,
        },
        "ci": {
            "macro_f1": macro_f1,
            "quality_gate": "unknown" if macro_f1 is None else ("pass" if (isinstance(macro_f1, (int, float)) and macro_f1 >= 0.85) else "check"),
        },
        "next_steps": [
            "Review E1 tasks: n8n integration, metrics, background agents",
        ],
    }

    out_path = REPORTS_DIR / f"agent-{stamp}.json"
    write_json(out_path, report)
    write_json(REPORTS_DIR / "latest-agent.json", report)

    # Update state
    new_state = state.copy()
    new_state.setdefault("repos", {}).setdefault(repo_key, {})
    new_state["repos"][repo_key]["last_seen_commit"] = head
    new_state["repos"][repo_key]["last_summary_at"] = utcnow_iso()
    if macro_f1 is not None:
        new_state["repos"][repo_key]["last_macro_f1"] = macro_f1
    write_json(STATE_PATH, new_state)

    # Print a short digest to stdout
    print("## Planner Agent Digest")
    for h in highlights[:5]:
        print(f"- {h}")
    print(f"Report: {out_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
