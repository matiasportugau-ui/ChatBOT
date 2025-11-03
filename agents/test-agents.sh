#!/usr/bin/env bash
# Test script for autonomous agents
# Usage: ./agents/test-agents.sh [agent-name]

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test documentation agent
test_documentation_agent() {
    log_info "Testing Documentation Agent..."
    
    # Create test reports directory
    mkdir -p reports docs
    
    # Generate git log summary
    log_info "Generating git log summary..."
    git log --since="24 hours ago" --pretty=format:"- [%h] %s (%an)" > reports/recent-commits.md
    
    # Check working tree
    git status --short > reports/working-tree-status.txt
    
    # Test AVANCE.md creation
    if [ ! -f docs/AVANCE.md ]; then
        log_warn "docs/AVANCE.md not found, would be created"
    else
        log_info "docs/AVANCE.md exists"
    fi
    
    # Test CHECKPOINT.md creation
    if [ ! -f CHECKPOINT.md ]; then
        log_warn "CHECKPOINT.md not found, would be created"
    else
        log_info "CHECKPOINT.md exists"
    fi
    
    log_info "✓ Documentation agent test complete"
}

# Test quality auditor
test_quality_auditor() {
    log_info "Testing Quality Auditor..."
    
    mkdir -p reports
    
    # Test ShellCheck availability
    if command -v shellcheck &> /dev/null; then
        log_info "ShellCheck found, running audit..."
        find scripts/ -name "*.sh" -type f 2>/dev/null | while read script; do
            log_info "Checking $script"
            shellcheck "$script" || log_warn "Issues found in $script"
        done
    else
        log_warn "ShellCheck not installed (brew install shellcheck)"
    fi
    
    # Test NLU balance check
    if [ -f data/nlu.yml ]; then
        log_info "Analyzing NLU intent balance..."
        python3 << 'PYTHON'
import yaml
from collections import Counter

with open('data/nlu.yml', 'r') as f:
    nlu_data = yaml.safe_load(f)

intent_counts = Counter()
for item in nlu_data.get('nlu', []):
    if 'intent' in item:
        examples = item.get('examples', '')
        count = len([line for line in examples.split('\n') if line.strip().startswith('-')])
        intent_counts[item['intent']] += count

print(f"Found {len(intent_counts)} intents:")
for intent, count in sorted(intent_counts.items()):
    status = "✓" if count >= 8 else "⚠"
    print(f"  {status} {intent}: {count} examples")

if intent_counts:
    max_count = max(intent_counts.values())
    min_count = min(intent_counts.values())
    ratio = max_count / min_count if min_count > 0 else 0
    print(f"\nImbalance ratio: {ratio:.2f} (threshold: 3.0)")
PYTHON
    else
        log_error "data/nlu.yml not found"
    fi
    
    log_info "✓ Quality auditor test complete"
}

# Test health monitor
test_health_monitor() {
    log_info "Testing Health Monitor..."
    
    mkdir -p reports
    
    # Test Docker availability
    if command -v docker &> /dev/null; then
        log_info "Docker found, checking services..."
        if docker compose ps &> /dev/null; then
            docker compose ps --format "table {{.Name}}\t{{.Status}}" | head -10
        else
            log_warn "Docker compose not running"
        fi
    else
        log_warn "Docker not available"
    fi
    
    # Create test health report
    cat > reports/health-test.json << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "test": true,
  "status": "test_run_successful"
}
EOF
    
    log_info "✓ Health monitor test complete"
}

# Main test runner
main() {
    log_info "AUTO-ATC Agent Test Suite"
    log_info "=========================="
    echo ""
    
    case "${1:-all}" in
        documentation|doc)
            test_documentation_agent
            ;;
        quality|qa)
            test_quality_auditor
            ;;
        health|monitor)
            test_health_monitor
            ;;
        all)
            test_documentation_agent
            echo ""
            test_quality_auditor
            echo ""
            test_health_monitor
            ;;
        *)
            log_error "Unknown agent: $1"
            echo "Usage: $0 [documentation|quality|health|all]"
            exit 1
            ;;
    esac
    
    echo ""
    log_info "All tests complete! Check reports/ directory for output"
    log_info "To run agents in AI Toolkit:"
    echo "  1. Open AI Toolkit in VS Code"
    echo "  2. Navigate to Agent Builder"
    echo "  3. Import agent YAML from agents/ directory"
}

main "$@"
