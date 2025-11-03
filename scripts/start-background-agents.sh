#!/bin/bash
# Start all background agents for AUTO-ATC ChatBOT
# Usage: ./scripts/start-background-agents.sh

set -e

PROJECT_ROOT="/Users/matias/Projects/ChatBOT"
cd "$PROJECT_ROOT"

# Create reports directory
mkdir -p reports

# Activate virtual environment
source .venv/bin/activate

echo "🚀 Starting AUTO-ATC Background Agents..."
echo "========================================"

# 1. Planner Agent (runs once, then exits - scheduled via cron/GitHub Actions)
echo "📝 Starting Planner Agent..."
nohup python scripts/planner_agent.py > reports/planner-agent.log 2>&1 &
PLANNER_PID=$!
echo $PLANNER_PID > reports/planner-agent.pid
echo "   ✓ Planner Agent started (PID: $PLANNER_PID)"
echo "   Log: reports/planner-agent.log"

# 2. Monitor Docker services (continuous loop)
echo "🏥 Starting Service Health Monitor..."
nohup bash -c 'while true; do
  docker compose ps --format json > reports/health-latest.json 2>&1
  sleep 1800  # Every 30 minutes
done' > reports/health-monitor.log 2>&1 &
HEALTH_PID=$!
echo $HEALTH_PID > reports/health-monitor.pid
echo "   ✓ Health Monitor started (PID: $HEALTH_PID)"
echo "   Log: reports/health-monitor.log"

# Log startup
echo "$(date '+%Y-%m-%d %H:%M:%S') - All background agents started" >> reports/agents-runtime.log
echo ""
echo "✅ All agents running!"
echo ""
echo "📊 Monitor with:"
echo "   tail -f reports/planner-agent.log"
echo "   tail -f reports/health-monitor.log"
echo "   ps -p $(cat reports/planner-agent.pid) -p $(cat reports/health-monitor.pid)"
echo ""
echo "🛑 Stop with:"
echo "   ./scripts/stop-background-agents.sh"
