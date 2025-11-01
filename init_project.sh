#!/usr/bin/env bash

set -Eeuo pipefail

echo "🚀 Iniciando AUTO-ATC ChatBot en modo autopilot..."
echo "=================================================="

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging helpers
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

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Comando requerido no encontrado: $1"
        return 1
    fi
}

# Detect docker compose CLI
detect_compose() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        echo "" # none
    fi
}

ensure_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker no está corriendo. Inicia Docker Desktop y reintenta."
        exit 1
    fi
}

# Python 3.10 and virtualenv setup
ensure_python_310() {
    if command -v python3.10 >/dev/null 2>&1; then
        PY310=python3.10
    else
        PY310=""
    fi

    if [[ -z "${PY310}" ]]; then
        log_warning "Python 3.10 no está instalado (requerido por Rasa 3.6)."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Sugerencia (macOS):"
            echo "  brew install python@3.10 && brew link python@3.10 --force"
            echo "  # o usa pyenv: brew install pyenv && pyenv install 3.10.14 && pyenv local 3.10.14"
        fi
        echo "También puedes editar este script para usar 'python3' si tu sistema ya apunta a 3.10.x."
        return 1
    fi

    echo "$PY310"
}

setup_python_env() {
    local PYBIN="$1"
    if [[ -z "$PYBIN" ]]; then
        log_warning "Saltando creación de entorno virtual por falta de Python 3.10."
        return 0
    fi

    if [[ ! -d .venv ]]; then
        log_info "Creando entorno virtual (.venv) con $PYBIN..."
        "$PYBIN" -m venv .venv
    fi
    # shellcheck disable=SC1091
    source .venv/bin/activate
    log_info "Instalando dependencias (requirements.txt)..."
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    log_success "Entorno Python listo"
}

compose_cmd=$(detect_compose)
if [[ -z "$compose_cmd" ]]; then
    log_error "No se detectó 'docker compose' ni 'docker-compose'. Instala Docker Desktop actualizado."
    exit 1
fi

ensure_docker_running

# Crear directorios necesarios (idempotente)
log_info "Creando directorios necesarios..."
mkdir -p chatwoot/storage n8n/data qdrant/storage postgres/data
log_success "Directorios creados/verificados"

# Verificar docker-compose.yml
if [[ ! -f "docker-compose.yml" ]]; then
    log_error "Archivo docker-compose.yml no encontrado en $(pwd)"
    exit 1
fi

# Parar contenedores previos (si existen)
${compose_cmd} down >/dev/null 2>&1 || true

# Iniciar PostgreSQL y Redis primero
log_info "Iniciando PostgreSQL y Redis..."
${compose_cmd} up -d postgres redis

log_info "Esperando a PostgreSQL..."
MAX_ATTEMPTS=30
for i in $(seq 1 ${MAX_ATTEMPTS}); do
    if ${compose_cmd} exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        log_success "PostgreSQL está listo"
        break
    fi
    log_info "Intento ${i}/${MAX_ATTEMPTS}..."
    sleep 2
done

# Inicializar base de datos principal si existe schema.sql
if [[ -f "schema.sql" ]]; then
    log_info "Aplicando schema.sql en atcdb..."
    ${compose_cmd} exec -T postgres psql -U atc -d atcdb -f - < schema.sql 2>&1 | grep -v "already exists" || true
    log_success "Esquema aplicado (o ya presente)"
else
    log_warning "schema.sql no encontrado; saltando inicialización de atcdb"
fi

# Crear bases de datos auxiliares con variables de entorno (evitar credenciales hardcodeadas)
N8N_DB_USER=${N8N_DB_USER:-n8n}
N8N_DB_PASSWORD=${N8N_DB_PASSWORD:-n8n_pass}
CHATWOOT_DB_USER=${CHATWOOT_DB_USER:-chatwoot}
CHATWOOT_DB_PASSWORD=${CHATWOOT_DB_PASSWORD:-chatwoot_pass}

if [[ "$N8N_DB_PASSWORD" == "n8n_pass" || "$CHATWOOT_DB_PASSWORD" == "chatwoot_pass" ]]; then
    log_warning "Usando contraseñas por defecto para DB auxiliares. Exporta N8N_DB_PASSWORD/CHATWOOT_DB_PASSWORD para cambiarlas."
fi

log_info "Creando DBs auxiliares (n8n, chatwoot) si no existen..."
${compose_cmd} exec -T postgres psql -U postgres -c "CREATE USER \"${N8N_DB_USER}\" WITH PASSWORD '${N8N_DB_PASSWORD}';" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE n8n TO \"${N8N_DB_USER}\";" 2>/dev/null || true

${compose_cmd} exec -T postgres psql -U postgres -c "CREATE USER \"${CHATWOOT_DB_USER}\" WITH PASSWORD '${CHATWOOT_DB_PASSWORD}';" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "CREATE DATABASE chatwoot_production;" 2>/dev/null || true
${compose_cmd} exec -T postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE chatwoot_production TO \"${CHATWOOT_DB_USER}\";" 2>/dev/null || true
log_success "Bases auxiliares listas"

# Iniciar Qdrant y preparar colección products
log_info "Iniciando Qdrant..."
${compose_cmd} up -d qdrant
sleep 5
log_info "Creando colección 'products' en Qdrant (idempotente)..."
curl -s -X PUT "http://localhost:6333/collections/products" \
    -H 'Content-Type: application/json' \
    -d '{"vectors":{"size":384,"distance":"Cosine"}}' >/dev/null 2>&1 || true

# Iniciar Rasa, n8n, Chatwoot y Traefik
log_info "Iniciando Rasa..."
${compose_cmd} up -d rasa
log_info "Iniciando n8n..."
${compose_cmd} up -d n8n
log_info "Iniciando Chatwoot..."
${compose_cmd} up -d chatwoot
log_info "Iniciando Traefik..."
${compose_cmd} up -d traefik

# Configurar entorno Python (después de levantar servicios para paralelizar tiempos)
PYBIN=$(ensure_python_310 || true)
setup_python_env "${PYBIN:-}"

# Validación rápida de Rasa (si hay Python)
if [[ -n "${PYBIN:-}" ]]; then
    if command -v make >/dev/null 2>&1; then
        log_info "Validando datos de Rasa (make validate)..."
        make validate || true
    else
        log_info "Validando datos de Rasa (python -m rasa data validate)..."
        python -m rasa data validate || true
    fi
fi

echo ""
log_success "🌐 Servicios disponibles:"
echo "- Chatwoot: http://localhost:3000"
echo "- n8n:      http://localhost:5678"
echo "- Rasa:     http://localhost:5005"
echo "- Qdrant:   http://localhost:6333"
echo ""
log_success "📝 Próximos pasos:"
echo "1) Abre n8n e importa los workflows JSON (WF_*.json)."
echo "2) Configura WhatsApp en Chatwoot (usa .env.chatwoot)."
echo "3) Carga la KB de productos con WF_KB_ingest_v2."
echo "4) Ejecuta 'make test-nlu' y 'make benchmark' para validar NLU."
echo ""
log_info "Tip macOS: si obtuviste 'Exit 127' al crear .venv, instala Python 3.10 con Homebrew o pyenv."
