#!/bin/bash#!/bin/bash



echo "🚀 Iniciando AUTO-ATC ChatBot en modo autopilot..."echo "🚀 Iniciando AUTO-ATC ChatBot en modo autopilot..."

echo "=================================================="echo "=================================================="



# Colores para output# Colores para output

GREEN='\033[0;32m'GREEN='\033[0;32m'

BLUE='\033[0;34m'BLUE='\033[0;34m'

YELLOW='\033[1;33m'YELLOW='\033[1;33m'

RED='\033[0;31m'RED='\033[0;31m'

NC='\033[0m' # No ColorNC='\033[0m' # No Color



# Función para logs con colores# Función para logs con colores

log_info() {log_info() {

    echo -e "${BLUE}[INFO]${NC} $1"    echo -e "${BLUE}[INFO]${NC} $1"

}}



log_success() {log_success() {

    echo -e "${GREEN}[SUCCESS]${NC} $1"    echo -e "${GREEN}[SUCCESS]${NC} $1"

}}



log_warning() {log_warning() {

    echo -e "${YELLOW}[WARNING]${NC} $1"    echo -e "${YELLOW}[WARNING]${NC} $1"

}}



log_error() {log_error() {

    echo -e "${RED}[ERROR]${NC} $1"    echo -e "${RED}[ERROR]${NC} $1"

}}



# Verificar si Docker está corriendo# Verificar si Docker está corriendo

if ! docker info > /dev/null 2>&1; thenif ! docker info > /dev/null 2>&1; then

    log_error "Docker no está corriendo. Por favor inicia Docker primero."    log_error "Docker no está corriendo. Por favor inicia Docker primero."

    exit 1    exit 1

fifi



# Crear directorios necesarios# Crear directorios necesarios

log_info "Creando directorios necesarios..."log_info "Creando directorios necesarios..."

mkdir -p rasa/modelsmkdir -p rasa/models

mkdir -p rasa/datamkdir -p chatwoot/storage

mkdir -p chatwoot/storagemkdir -p n8n/data

mkdir -p n8n_datamkdir -p qdrant/storage

mkdir -p qdrant_storagemkdir -p postgres/data

mkdir -p pgdata

# Configurar permisos

# Configurar permisoschmod +x provision_chatwoot.sh

chmod +x provision_chatwoot.sh 2>/dev/null || truechmod 755 rasa/data

chmod 755 rasa/datachmod 755 n8n/data

chmod 755 n8n_datachmod 755 qdrant/storage

chmod 755 qdrant_storagechmod 755 postgres/data

chmod 755 pgdata

log_success "Directorios creados correctamente"

log_success "Directorios creados correctamente"

# Verificar si docker-compose.yml existe

# Verificar si docker-compose.yml existeif [ ! -f "docker-compose.yml" ]; then

if [ ! -f "docker-compose.yml" ]; then    log_error "Archivo docker-compose.yml no encontrado"

    log_error "Archivo docker-compose.yml no encontrado"    exit 1

    exit 1fi

fi

log_info "Construyendo e iniciando servicios base..."

log_info "Construyendo e iniciando servicios base..."

# Parar contenedores existentes si están corriendo

# Parar contenedores existentes si están corriendodocker-compose down

docker-compose down 2>/dev/null || true

# Iniciar servicios base (bases de datos primero)

# Iniciar servicios base (bases de datos primero)log_info "Iniciando PostgreSQL y Redis..."

log_info "Iniciando PostgreSQL y Redis..."docker-compose up -d postgres redis

docker-compose up -d postgres redis

log_info "Esperando que PostgreSQL esté listo..."

log_info "Esperando que PostgreSQL esté listo..."sleep 20

sleep 20

# Verificar conexión a PostgreSQL

# Verificar conexión a PostgreSQLMAX_ATTEMPTS=30

MAX_ATTEMPTS=30ATTEMPT=1

ATTEMPT=1while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do    if docker exec chatbot-postgres-1 pg_isready -U postgres > /dev/null 2>&1; then

    if docker exec chatbot-postgres-1 pg_isready -U postgres > /dev/null 2>&1; then        log_success "PostgreSQL está listo"

        log_success "PostgreSQL está listo"        break

        break    fi

    fi    log_info "Intento $ATTEMPT/$MAX_ATTEMPTS - Esperando PostgreSQL..."

    log_info "Esperando PostgreSQL... intento $ATTEMPT/$MAX_ATTEMPTS"    sleep 2

    sleep 2    ATTEMPT=$((ATTEMPT + 1))

    ATTEMPT=$((ATTEMPT + 1))done

done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then    log_error "PostgreSQL no responde después de $MAX_ATTEMPTS intentos"

    log_error "PostgreSQL no pudo iniciarse"    exit 1

    docker-compose logs postgresfi

    exit 1

fi# Inicializar base de datos principal

log_info "Inicializando base de datos principal..."

# Inicializar base de datos principalif [ -f "schema.sql" ]; then

log_info "Inicializando base de datos principal..."    docker exec -i chatbot-postgres-1 psql -U atc -d atcdb < schema.sql

if [ -f "schema.sql" ]; then    log_success "Base de datos principal inicializada"

    docker exec -i chatbot-postgres-1 psql -U atc -d atcdb < schema.sql 2>&1 | grep -v "already exists" || trueelse

    log_success "Base de datos principal inicializada"    log_warning "Archivo schema.sql no encontrado, saltando inicialización"

elsefi

    log_warning "Archivo schema.sql no encontrado, saltando inicialización"

fi# Crear bases de datos adicionales

log_info "Creando bases de datos para n8n y Chatwoot..."

# Crear bases de datos adicionales

log_info "Creando bases de datos para n8n y Chatwoot..."# Base de datos para n8n

docker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || log_warning "Base de datos n8n ya existe"

# Base de datos para n8ndocker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE USER n8n WITH PASSWORD 'n8n_pass';" 2>/dev/null || log_warning "Usuario n8n ya existe"

docker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE DATABASE n8n;" 2>/dev/null || log_warning "Base de datos n8n ya existe"docker exec -i chatbot-postgres-1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;" 2>/dev/null

docker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE USER n8n WITH PASSWORD 'n8n_pass';" 2>/dev/null || log_warning "Usuario n8n ya existe"

docker exec -i chatbot-postgres-1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;" 2>/dev/null# Base de datos para Chatwoot

docker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE DATABASE chatwoot_production;" 2>/dev/null || log_warning "Base de datos chatwoot_production ya existe"

# Base de datos para Chatwootdocker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE USER chatwoot WITH PASSWORD 'chatwoot_pass';" 2>/dev/null || log_warning "Usuario chatwoot ya existe"

docker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE DATABASE chatwoot_production;" 2>/dev/null || log_warning "Base de datos chatwoot_production ya existe"docker exec -i chatbot-postgres-1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE chatwoot_production TO chatwoot;" 2>/dev/null

docker exec -i chatbot-postgres-1 psql -U postgres -c "CREATE USER chatwoot WITH PASSWORD 'chatwoot_pass';" 2>/dev/null || log_warning "Usuario chatwoot ya existe"

docker exec -i chatbot-postgres-1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE chatwoot_production TO chatwoot;" 2>/dev/nulllog_success "Bases de datos configuradas"



log_success "Bases de datos configuradas"# Iniciar Qdrant

log_info "Iniciando Qdrant..."

# Iniciar Qdrantdocker-compose up -d qdrant

log_info "Iniciando Qdrant..."sleep 10

docker-compose up -d qdrant

sleep 10# Configurar Qdrant

log_info "Configurando colección en Qdrant..."

# Configurar Qdrantcurl -X PUT "http://localhost:6333/collections/products" \

log_info "Configurando colección en Qdrant..."-H "Content-Type: application/json" \

curl -X PUT "http://localhost:6333/collections/products" \-d '{

-H "Content-Type: application/json" \  "vectors": {

-d '{    "size": 384,

  "vectors": {    "distance": "Cosine"

    "size": 384,  },

    "distance": "Cosine"  "optimizers_config": {

  },    "default_segment_number": 2

  "optimizers_config": {  },

    "default_segment_number": 2  "replication_factor": 1

  },}' > /dev/null 2>&1

  "replication_factor": 1

}' > /dev/null 2>&1if [ $? -eq 0 ]; then

    log_success "Colección de productos creada en Qdrant"

if [ $? -eq 0 ]; thenelse

    log_success "Colección de productos creada en Qdrant"    log_warning "No se pudo crear la colección en Qdrant (posiblemente ya existe)"

elsefi

    log_warning "No se pudo crear la colección en Qdrant (posiblemente ya existe)"

fi# Iniciar Rasa

log_info "Iniciando Rasa..."

# Iniciar Rasadocker-compose up -d rasa

log_info "Iniciando Rasa..."

docker-compose up -d rasalog_info "Esperando que Rasa entrene el modelo inicial..."

sleep 45

log_info "Esperando que Rasa entrene el modelo inicial..."

sleep 45# Verificar si Rasa está corriendo

if curl -s http://localhost:5005/status > /dev/null; then

# Verificar si Rasa está corriendo    log_success "Rasa está operativo"

if curl -s http://localhost:5005/status > /dev/null; thenelse

    log_success "Rasa está operativo"    log_warning "Rasa puede necesitar más tiempo para iniciarse"

elsefi

    log_warning "Rasa puede necesitar más tiempo para iniciarse"

fi# Iniciar n8n

log_info "Iniciando n8n..."

# Iniciar n8ndocker-compose up -d n8n

log_info "Iniciando n8n..."sleep 15

docker-compose up -d n8n

sleep 15if curl -s http://localhost:5678 > /dev/null; then

    log_success "n8n está operativo"

if curl -s http://localhost:5678 > /dev/null; thenelse

    log_success "n8n está operativo"    log_warning "n8n puede necesitar más tiempo para iniciarse"

elsefi

    log_warning "n8n puede necesitar más tiempo para iniciarse"

fi# Iniciar Chatwoot

log_info "Iniciando Chatwoot..."

# Iniciar Chatwootdocker-compose up -d chatwoot

log_info "Iniciando Chatwoot..."sleep 20

docker-compose up -d chatwoot

sleep 20if curl -s http://localhost:3000 > /dev/null; then

    log_success "Chatwoot está operativo"

if curl -s http://localhost:3000 > /dev/null; thenelse

    log_success "Chatwoot está operativo"    log_warning "Chatwoot puede necesitar más tiempo para iniciarse"

elsefi

    log_warning "Chatwoot puede necesitar más tiempo para iniciarse"

fiecho ""

echo "✅ ¡Proyecto AUTO-ATC ChatBot inicializado correctamente!"

# Iniciar Traefikecho "======================================================="

log_info "Iniciando Traefik..."echo ""

docker-compose up -d traefiklog_success "🌐 Servicios disponibles:"

echo "- Chatwoot: http://localhost:3000"

echo ""echo "- n8n: http://localhost:5678"

echo "✅ ¡Proyecto AUTO-ATC ChatBot inicializado correctamente!"echo "- Rasa: http://localhost:5005"

echo "======================================================="echo "- Qdrant: http://localhost:6333"

echo ""echo ""

log_success "🌐 Servicios disponibles:"log_success "🔑 Credenciales por defecto:"

echo "- Chatwoot: http://localhost:3000"echo "- Chatwoot: admin@example.com / admin123456"

echo "- n8n: http://localhost:5678"echo "- n8n: admin / admin123"

echo "- Rasa: http://localhost:5005"echo ""

echo "- Qdrant: http://localhost:6333"log_success "📝 Próximos pasos:"

echo ""echo "1. Acceder a n8n e importar los workflows JSON"

log_success "🔑 Credenciales por defecto:"echo "2. Configurar WhatsApp Business API en Chatwoot"

echo "- Chatwoot: admin@example.com / admin123456"echo "3. Cargar productos en la base de conocimiento"

echo "- n8n: admin / admin123"echo "4. Testear el flujo completo"

echo ""echo ""

log_success "📝 Próximos pasos:"echo "Para monitorear el sistema ejecuta: ./monitor.sh"
echo "1. Acceder a n8n e importar los workflows JSON"
echo "2. Configurar WhatsApp Business API en Chatwoot"
echo "3. Cargar productos en la base de conocimiento"
echo "4. Testear el flujo completo"
echo ""
echo "Para monitorear el sistema ejecuta: ./monitor.sh"
