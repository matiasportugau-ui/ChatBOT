#!/usr/bin/env python3
"""Print a short digest from the latest planner agent report, if available."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
latest = ROOT / "reports" / "latest-agent.json"

if latest.exists():
    data = json.loads(latest.read_text(encoding="utf-8"))
    ts = data.get("timestamp", "-")
    print(f"Since your last session — {ts}")
    for h in (data.get("highlights") or [])[:4]:
        print(f"- {h}")
    gate = (data.get("ci") or {}).get("quality_gate")
    if gate:
        print(f"Quality gate: {gate}")
    print(f"Report: reports/latest-agent.json")
else:
    print("No planner report yet. Run: make planner")
