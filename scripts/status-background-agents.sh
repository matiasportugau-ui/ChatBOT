#!/bin/bash
# Check status of background agents
# Usage: ./scripts/status-background-agents.sh

PROJECT_ROOT="/Users/matias/Projects/ChatBOT"
cd "$PROJECT_ROOT"

echo "📊 AUTO-ATC Background Agents Status"
echo "====================================="
echo ""

# Check planner agent
if [ -f reports/planner-agent.pid ]; then
    PLANNER_PID=$(cat reports/planner-agent.pid)
    if ps -p $PLANNER_PID > /dev/null 2>&1; then
        echo "📝 Planner Agent: ✅ RUNNING (PID: $PLANNER_PID)"
        if [ -f reports/planner-agent.log ]; then
            echo "   Last log entry: $(tail -1 reports/planner-agent.log)"
        fi
    else
        echo "📝 Planner Agent: ❌ STOPPED (stale PID: $PLANNER_PID)"
    fi
else
    echo "📝 Planner Agent: ⚪ NOT STARTED"
fi

echo ""

# Check health monitor
if [ -f reports/health-monitor.pid ]; then
    HEALTH_PID=$(cat reports/health-monitor.pid)
    if ps -p $HEALTH_PID > /dev/null 2>&1; then
        echo "🏥 Health Monitor: ✅ RUNNING (PID: $HEALTH_PID)"
        if [ -f reports/health-latest.json ]; then
            echo "   Last check: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" reports/health-latest.json)"
        fi
    else
        echo "🏥 Health Monitor: ❌ STOPPED (stale PID: $HEALTH_PID)"
    fi
else
    echo "🏥 Health Monitor: ⚪ NOT STARTED"
fi

echo ""

# Show recent runtime log
if [ -f reports/agents-runtime.log ]; then
    echo "📋 Recent Activity:"
    tail -5 reports/agents-runtime.log | sed 's/^/   /'
fi

echo ""
