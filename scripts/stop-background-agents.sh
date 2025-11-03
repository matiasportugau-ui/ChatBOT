#!/bin/bash
# Stop all background agents for AUTO-ATC ChatBOT
# Usage: ./scripts/stop-background-agents.sh

PROJECT_ROOT="/Users/matias/Projects/ChatBOT"
cd "$PROJECT_ROOT"

echo "🛑 Stopping AUTO-ATC Background Agents..."
echo "========================================"

# Stop planner agent
if [ -f reports/planner-agent.pid ]; then
    PLANNER_PID=$(cat reports/planner-agent.pid)
    if ps -p $PLANNER_PID > /dev/null 2>&1; then
        kill $PLANNER_PID 2>/dev/null || true
        echo "   ✓ Planner Agent stopped (PID: $PLANNER_PID)"
    else
        echo "   ℹ Planner Agent not running"
    fi
    rm reports/planner-agent.pid
else
    echo "   ℹ No planner agent PID file found"
fi

# Stop health monitor
if [ -f reports/health-monitor.pid ]; then
    HEALTH_PID=$(cat reports/health-monitor.pid)
    if ps -p $HEALTH_PID > /dev/null 2>&1; then
        kill $HEALTH_PID 2>/dev/null || true
        echo "   ✓ Health Monitor stopped (PID: $HEALTH_PID)"
    else
        echo "   ℹ Health Monitor not running"
    fi
    rm reports/health-monitor.pid
else
    echo "   ℹ No health monitor PID file found"
fi

# Log shutdown
echo "$(date '+%Y-%m-%d %H:%M:%S') - All background agents stopped" >> reports/agents-runtime.log
echo ""
echo "✅ All agents stopped"
