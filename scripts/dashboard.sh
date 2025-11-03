#!/bin/bash
# Comprehensive dashboard for AUTO-ATC background operations
# Usage: ./scripts/dashboard.sh

PROJECT_ROOT="/Users/matias/Projects/ChatBOT"
cd "$PROJECT_ROOT"

clear
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║          AUTO-ATC ChatBOT - Background Agents Dashboard          ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# ============ Background Agents Status ============
echo "🤖 BACKGROUND AGENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Planner Agent
if [ -f reports/planner-agent.pid ]; then
    PLANNER_PID=$(cat reports/planner-agent.pid)
    if ps -p $PLANNER_PID > /dev/null 2>&1; then
        echo "📝 Planner Agent:     ✅ RUNNING (PID: $PLANNER_PID)"
    else
        echo "📝 Planner Agent:     ⚪ COMPLETED (last run successful)"
    fi
    if [ -f reports/planner-agent.log ]; then
        LAST_RUN=$(tail -1 reports/planner-agent.log 2>/dev/null || echo "No log")
        echo "   Last output:      $LAST_RUN"
    fi
else
    echo "📝 Planner Agent:     ⚪ NOT STARTED"
fi

echo ""

# Health Monitor
if [ -f reports/health-monitor.pid ]; then
    HEALTH_PID=$(cat reports/health-monitor.pid)
    if ps -p $HEALTH_PID > /dev/null 2>&1; then
        UPTIME=$(ps -o etime= -p $HEALTH_PID | tr -d ' ')
        echo "🏥 Health Monitor:    ✅ RUNNING (PID: $HEALTH_PID, uptime: $UPTIME)"
        if [ -f reports/health-latest.json ]; then
            LAST_CHECK=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" reports/health-latest.json 2>/dev/null)
            echo "   Last check:       $LAST_CHECK"
        fi
    else
        echo "🏥 Health Monitor:    ❌ STOPPED"
    fi
else
    echo "🏥 Health Monitor:    ⚪ NOT STARTED"
fi

echo ""

# GitHub Actions Agents
echo "☁️  GitHub Actions:    Scheduled (see .github/workflows/autonomous-agents.yml)"
echo "   📝 Documentation:   Every 6 hours"
echo "   🔍 Quality Audit:   Daily at 2 AM"
echo "   🏥 Health Check:    Every 30 minutes"

echo ""
echo ""

# ============ Docker Services Status ============
echo "🐳 DOCKER SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker compose ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}" 2>/dev/null | \
while IFS= read -r line; do
    if echo "$line" | grep -q "running"; then
        echo "✅ $line"
    elif echo "$line" | grep -q "Restarting"; then
        echo "⚠️  $line"
    elif echo "$line" | grep -q "NAME"; then
        echo "$line"
    else
        echo "❌ $line"
    fi
done

echo ""
echo ""

# ============ Recent Agent Activity ============
echo "📋 RECENT AGENT ACTIVITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f reports/agents-runtime.log ]; then
    tail -10 reports/agents-runtime.log | sed 's/^/   /'
else
    echo "   No activity logged yet"
fi

echo ""
echo ""

# ============ Latest Planner Report ============
echo "📊 LATEST PLANNER REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
LATEST_REPORT=$(ls -t reports/agent-*.json 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ]; then
    echo "   Report: $LATEST_REPORT"
    python3 -c "
import json, sys
try:
    with open('$LATEST_REPORT') as f:
        data = json.load(f)
    print(f\"   Timestamp:     {data.get('timestamp', 'N/A')}\")
    print(f\"   Macro F1:      {data.get('ci', {}).get('macro_f1', 'N/A')}\")
    print(f\"   Quality Gate:  {data.get('ci', {}).get('quality_gate', 'N/A').upper()}\")
    highlights = data.get('highlights', [])
    if highlights:
        print(f\"   Highlights:    {highlights[0]}\")
    next_steps = data.get('next_steps', [])
    if next_steps:
        print(f\"   Next Steps:    {next_steps[0]}\")
except Exception as e:
    print(f\"   Error reading report: {e}\")
" 2>/dev/null || echo "   Unable to parse report"
else
    echo "   No reports found"
fi

echo ""
echo ""

# ============ Quick Actions ============
echo "⚡ QUICK ACTIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ./scripts/start-background-agents.sh  - Start all agents"
echo "   ./scripts/stop-background-agents.sh   - Stop all agents"
echo "   ./scripts/status-background-agents.sh - Check agent status"
echo "   tail -f reports/planner-agent.log     - Watch planner logs"
echo "   tail -f reports/health-monitor.log    - Watch health logs"
echo ""
