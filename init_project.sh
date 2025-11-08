#!/bin/bash

echo "🚀 Iniciando AUTO-ATC ChatBot en modo autopilot..."
echo "=================================================="

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para logs con colores
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

# Verificar si Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    log_error "Docker no está corriendo. Por favor inicia Docker primero."
    exit 1
fi

# Crear directorios necesarios
log_info "Creando directorios necesarios..."
mkdir -p rasa/models
mkdir -p chatwoot/storage
mkdir -p n8n/data
mkdir -p qdrant/storage
mkdir -p pgdata

# Configurar permisos
chmod +x scripts/provision_chatwoot.sh 2>/dev/null || true
chmod 755 rasa/data 2>/dev/null || true
chmod 755 n8n/data 2>/dev/null || true
chmod 755 qdrant/storage 2>/dev/null || true
chmod 755 pgdata 2>/dev/null || true

log_success "Directorios creados correctamente"

# Verificar si docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    log_error "Archivo docker-compose.yml no encontrado"
    exit 1
fi

log_info "Construyendo e iniciando servicios base..."

# Parar contenedores existentes si están corriendo
docker compose down 2>/dev/null || true

# Iniciar servicios base (bases de datos primero)
log_info "Iniciando PostgreSQL y Redis..."
docker compose up -d postgres redis

log_info "Esperando que PostgreSQL esté listo..."
sleep 20

# Verificar conexión a PostgreSQL
MAX_ATTEMPTS=30
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if docker exec auto-atc-network-postgres-1 pg_isready -U atc_user -d atc_db > /dev/null 2>&1; then
        log_success "PostgreSQL está listo"
        break
    fi
    log_info "Esperando PostgreSQL... intento $ATTEMPT/$MAX_ATTEMPTS"
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    log_error "PostgreSQL no pudo iniciarse"
    docker compose logs postgres
    exit 1
fi

# Inicializar base de datos principal
log_info "Inicializando base de datos principal..."
if [ -f "db/schema.sql" ]; then
    docker exec -i auto-atc-network-postgres-1 psql -U atc_user -d atc_db < db/schema.sql 2>&1 | grep -v "already exists" || true
    log_success "Base de datos principal inicializada"
else
    log_warning "Archivo db/schema.sql no encontrado, saltando inicialización"
fi

# Crear bases de datos adicionales
log_info "Creando bases de datos para n8n y Chatwoot..."

# Base de datos para n8n
docker exec -i auto-atc-network-postgres-1 psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || log_warning "Base de datos n8n ya existe"
docker exec -i auto-atc-network-postgres-1 psql -U postgres -c "CREATE USER n8n WITH PASSWORD 'n8n_pass';" 2>/dev/null || log_warning "Usuario n8n ya existe"
docker exec -i auto-atc-network-postgres-1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;" 2>/dev/null

# Base de datos para Chatwoot
docker exec -i auto-atc-network-postgres-1 psql -U postgres -c "CREATE DATABASE chatwoot_production;" 2>/dev/null || log_warning "Base de datos chatwoot_production ya existe"
docker exec -i auto-atc-network-postgres-1 psql -U postgres -c "CREATE USER chatwoot WITH PASSWORD 'chatwoot_pass';" 2>/dev/null || log_warning "Usuario chatwoot ya existe"
docker exec -i auto-atc-network-postgres-1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE chatwoot_production TO chatwoot;" 2>/dev/null

log_success "Bases de datos configuradas"

# Iniciar Qdrant
log_info "Iniciando Qdrant..."
docker compose up -d qdrant
sleep 10

# Configurar Qdrant
log_info "Configurando colección en Qdrant..."
curl -X PUT "http://localhost:6333/collections/products" \
    -H "Content-Type: application/json" \
    -d '{
      "vectors": {
        "size": 1536,
        "distance": "Cosine"
      },
      "optimizers_config": {
        "default_segment_number": 2
      },
      "replication_factor": 1
    }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log_success "Colección de productos creada en Qdrant"
else
    log_warning "No se pudo crear la colección en Qdrant (posiblemente ya existe)"
fi

# Iniciar Rasa
log_info "Iniciando Rasa..."
docker compose up -d rasa
log_info "Esperando que Rasa entrene el modelo inicial..."
sleep 45

# Verificar si Rasa está corriendo
if curl -s http://localhost:5005/status > /dev/null; then
    log_success "Rasa está operativo"
else
    log_warning "Rasa puede necesitar más tiempo para iniciarse"
fi

# Iniciar n8n
log_info "Iniciando n8n..."
docker compose up -d n8n
sleep 15

if curl -s http://localhost:5678 > /dev/null; then
    log_success "n8n está operativo"
else
    log_warning "n8n puede necesitar más tiempo para iniciarse"
fi

# Iniciar Chatwoot
log_info "Iniciando Chatwoot..."
docker compose up -d chatwoot
sleep 20

if curl -s http://localhost:3000 > /dev/null; then
    log_success "Chatwoot está operativo"
else
    log_warning "Chatwoot puede necesitar más tiempo para iniciarse"
fi

# Iniciar Traefik
log_info "Iniciando Traefik..."
docker compose up -d traefik

echo ""
echo "✅ ¡Proyecto AUTO-ATC ChatBot inicializado correctamente!"
echo "======================================================="
echo ""
log_success "🌐 Servicios disponibles:"
echo "- Chatwoot: http://localhost:3000"
echo "- n8n: http://localhost:5678"
echo "- Rasa: http://localhost:5005"
echo "- Qdrant: http://localhost:6333"
echo "- Traefik Dashboard: http://localhost:8080"
echo ""
log_success "🔑 Credenciales por defecto:"
echo "- Chatwoot: admin@example.com / admin123456"
echo "- n8n: admin / admin123"
echo ""
log_success "📝 Próximos pasos:"
echo "1. Acceder a n8n e importar los workflows JSON desde n8n/"
echo "2. Configurar WhatsApp Business API en Chatwoot"
echo "3. Ejecutar scripts/provision_chatwoot.sh para conectar servicios"
echo "4. Cargar productos en la base de conocimiento via WF_KB_ingest_v2"
echo "5. Testear el flujo completo"
echo ""
echo "Para monitorear el sistema ejecuta: docker compose logs -f"

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: init-script-v3
# version: 3.1.0
# file: init_project.sh
# lang: sh
# created_at: 2025-11-08T00:00:00Z
# author: auto-atc-setup
# origin: init-script-clean
