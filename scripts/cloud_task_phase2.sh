#!/usr/bin/env bash
# Codex Cloud Task - Phase 2: WhatsApp Integration Testing
# This script requires Docker and environment secrets (CHATWOOT_*, BOT_OUTGOING_URL)

set -euo pipefail

echo "=========================================="
echo "Codex Cloud Task: Phase 2 - WhatsApp Integration Testing"
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

# Check required environment variables
check_env_vars() {
    local missing=()
    for var in CHATWOOT_BASE_URL CHATWOOT_PLATFORM_TOKEN CHATWOOT_ACCOUNT_ID CHATWOOT_INBOX_ID BOT_OUTGOING_URL; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        printf '  - %s\n' "${missing[@]}"
        log_error "Please configure these in your Codex environment settings"
        exit 1
    fi
    log_success "All required environment variables are set"
}

# Detect docker compose CLI
detect_compose() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        echo ""
    fi
}

# Check Docker availability
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running or not accessible"
        exit 1
    fi
    log_success "Docker is available"
}

check_env_vars
check_docker

compose_cmd=$(detect_compose)
if [[ -z "$compose_cmd" ]]; then
    log_error "docker compose not found"
    exit 1
fi

# Create necessary directories
log_info "Creating required directories..."
mkdir -p chatwoot/storage n8n/data qdrant/storage postgres/data
log_success "Directories created"

# Stop any existing containers
log_info "Stopping existing containers..."
${compose_cmd} down >/dev/null 2>&1 || true

# Start PostgreSQL and Redis first
log_info "Starting PostgreSQL and Redis..."
${compose_cmd} up -d postgres redis

log_info "Waiting for PostgreSQL to be ready..."
MAX_ATTEMPTS=30
for i in $(seq 1 ${MAX_ATTEMPTS}); do
    if ${compose_cmd} exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        log_success "PostgreSQL is ready"
        break
    fi
    if [[ $i -eq ${MAX_ATTEMPTS} ]]; then
        log_error "PostgreSQL failed to start within timeout"
        exit 1
    fi
    log_info "Waiting... (${i}/${MAX_ATTEMPTS})"
    sleep 2
done

# Initialize databases
log_info "Initializing databases..."
N8N_DB_USER=${N8N_DB_USER:-n8n}
N8N_DB_PASSWORD=${N8N_DB_PASSWORD:-n8n_pass}
CHATWOOT_DB_USER=${CHATWOOT_DB_USER:-chatwoot}
CHATWOOT_DB_PASSWORD=${CHATWOOT_DB_PASSWORD:-chatwoot_pass}

${compose_cmd} exec -T postgres psql -U postgres -c "CREATE USER \"${N8N_DB_USER}\" WITH PASSWORD '${N8N_DB_PASSWORD}';" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE n8n TO \"${N8N_DB_USER}\";" 2>/dev/null || true

${compose_cmd} exec -T postgres psql -U postgres -c "CREATE USER \"${CHATWOOT_DB_USER}\" WITH PASSWORD '${CHATWOOT_DB_PASSWORD}';" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "CREATE DATABASE chatwoot_production;" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE chatwoot_production TO \"${CHATWOOT_DB_USER}\";" 2>/dev/null || true
log_success "Databases initialized"

# Start Qdrant
log_info "Starting Qdrant..."
${compose_cmd} up -d qdrant
sleep 5

log_info "Creating Qdrant collection 'products'..."
curl -s -X PUT "http://localhost:6333/collections/products" \
    -H 'Content-Type: application/json' \
    -d '{"vectors":{"size":384,"distance":"Cosine"}}' >/dev/null 2>&1 || true
log_success "Qdrant ready"

# Start Rasa, n8n, Chatwoot
log_info "Starting Rasa..."
${compose_cmd} up -d rasa

log_info "Starting n8n..."
${compose_cmd} up -d n8n

log_info "Starting Chatwoot..."
${compose_cmd} up -d chatwoot

# Wait for services to be ready
log_info "Waiting for services to be ready..."
sleep 10

# Verify services
log_info "Verifying services..."
RASA_OK=false
CHATWOOT_OK=false
N8N_OK=false

for i in {1..30}; do
    if curl -sf http://localhost:5005/status >/dev/null 2>&1; then
        RASA_OK=true
    fi
    if curl -sf http://localhost:3000/api >/dev/null 2>&1; then
        CHATWOOT_OK=true
    fi
    if curl -sf http://localhost:5678/healthz >/dev/null 2>&1; then
        N8N_OK=true
    fi
    
    if [[ "$RASA_OK" == "true" && "$CHATWOOT_OK" == "true" && "$N8N_OK" == "true" ]]; then
        break
    fi
    sleep 2
done

if [[ "$RASA_OK" == "true" ]]; then
    log_success "Rasa API is responding"
else
    log_warning "Rasa API not responding (may still be starting)"
fi

if [[ "$CHATWOOT_OK" == "true" ]]; then
    log_success "Chatwoot API is responding"
else
    log_warning "Chatwoot API not responding (may still be starting)"
fi

if [[ "$N8N_OK" == "true" ]]; then
    log_success "n8n is responding"
else
    log_warning "n8n not responding (may still be starting)"
fi

# Provision Chatwoot bot
log_info "Provisioning Chatwoot bot..."
if [[ -f provision_chatwoot.sh ]]; then
    chmod +x provision_chatwoot.sh
    ./provision_chatwoot.sh
    log_success "Chatwoot bot provisioned"
else
    log_warning "provision_chatwoot.sh not found, skipping bot provisioning"
fi

echo ""
log_success "Phase 2 completed!"
echo ""
echo "Services available:"
echo "  - Chatwoot: http://localhost:3000"
echo "  - n8n:      http://localhost:5678"
echo "  - Rasa:     http://localhost:5005"
echo "  - Qdrant:   http://localhost:6333"
echo ""
echo "Next steps:"
echo "  1. Import n8n workflows (WF_*.json files)"
echo "  2. Configure WhatsApp in Chatwoot"
echo "  3. Test WhatsApp chat integration"

