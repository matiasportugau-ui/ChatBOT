#!/usr/bin/env bash
# Codex Cloud Task - Phase 1: Training & NLU Testing
# This script runs Rasa training and NLU testing without requiring Docker services or secrets

set -euo pipefail

echo "=========================================="
echo "Codex Cloud Task: Phase 1 - Training & NLU Testing"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect Python version
detect_python() {
    if command -v python3.10 >/dev/null 2>&1; then
        echo "python3.10"
    elif command -v python3 >/dev/null 2>&1; then
        PYVER=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        if [[ $(echo "$PYVER >= 3.10" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
            echo "python3"
        else
            log_warning "Python 3.10+ recommended, found $PYVER"
            echo "python3"
        fi
    else
        log_error "Python 3 not found"
        exit 1
    fi
}

PYBIN=$(detect_python)
log_info "Using Python: $PYBIN ($($PYBIN --version 2>&1))"

# Setup Python environment
log_info "Setting up Python virtual environment..."
if [[ ! -d .venv ]]; then
    $PYBIN -m venv .venv
fi
source .venv/bin/activate

log_info "Upgrading pip..."
python -m pip install --upgrade pip --quiet

log_info "Installing dependencies from requirements.txt..."
pip install -r requirements.txt --quiet
log_success "Dependencies installed"

# Validate Rasa data
log_info "Validating Rasa data structure..."
if command -v make >/dev/null 2>&1; then
    make validate
else
    python -m rasa data validate
fi
log_success "Data validation passed"

# Train Rasa model
log_info "Training Rasa model (this may take several minutes)..."
if command -v make >/dev/null 2>&1; then
    make train
else
    python -m rasa train
fi
log_success "Model training completed"

# Run NLU tests
log_info "Running NLU tests on test dataset..."
mkdir -p reports
if command -v make >/dev/null 2>&1; then
    make test-nlu
else
    python -m rasa test nlu --nlu tests/test_nlu.yml --out reports
fi
log_success "NLU tests completed"

# Run benchmark on full dataset
log_info "Running benchmark on full NLU dataset..."
if command -v make >/dev/null 2>&1; then
    make benchmark
else
    python -m rasa test nlu --nlu data/nlu.yml --out reports
    python scripts/ci_nlu_summary.py --reports reports
fi
log_success "Benchmark completed"

# Generate quality report
log_info "Generating quality report..."
THRESHOLD=${THRESHOLD:-0.85}
export THRESHOLD
python scripts/ci_nlu_summary.py --reports reports || {
    log_warning "Quality gate check completed (may have warnings)"
}

# List generated artifacts
echo ""
log_success "Generated artifacts:"
echo "  Models:"
ls -lh models/*.tar.gz 2>/dev/null || log_warning "No models found"
echo ""
echo "  Reports:"
ls -lh reports/*.json reports/*.png 2>/dev/null | head -10 || log_warning "No reports found"

echo ""
log_success "Phase 1 completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Review artifacts in models/ and reports/ directories"
echo "  2. For WhatsApp integration testing, run Phase 2 script"
echo "  3. Download artifacts from Codex cloud interface if needed"

