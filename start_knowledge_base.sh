#!/bin/bash
# Start Knowledge Base (PostgreSQL) for ChatBOT

cd "$(dirname "$0")"

echo "🔍 Verificando si PostgreSQL está corriendo..."

# Check if PostgreSQL is running
if docker ps | grep -q postgres; then
    echo "✅ PostgreSQL ya está corriendo en Docker"
    exit 0
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado o no está corriendo"
    echo ""
    echo "Opciones:"
    echo "1. Instalar Docker Desktop"
    echo "2. Usar PostgreSQL local (requiere instalación)"
    exit 1
fi

echo "🚀 Iniciando PostgreSQL con docker-compose..."

# Start only PostgreSQL service
if command -v docker-compose &> /dev/null; then
    docker-compose up -d postgres
elif command -v docker &> /dev/null; then
    docker compose up -d postgres
else
    echo "❌ No se encontró docker-compose"
    exit 1
fi

echo "⏳ Esperando que PostgreSQL esté listo..."
sleep 5

# Verify connection
echo "🔍 Verificando conexión..."
python3 << EOF
import os
import psycopg2
import time

PG_DSN = 'dbname=atcdb user=atc password=atc_pass host=localhost'
max_retries = 10

for i in range(max_retries):
    try:
        conn = psycopg2.connect(PG_DSN)
        conn.close()
        print("✅ PostgreSQL está listo!")
        exit(0)
    except Exception as e:
        if i < max_retries - 1:
            time.sleep(2)
        else:
            print(f"❌ Error: {e}")
            exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Base de conocimiento lista!"
    echo "📊 Puedes verificar con:"
    echo "   docker exec \$(docker ps -q -f name=postgres) psql -U atc -d atcdb -c 'SELECT COUNT(*) FROM knowledge_base;'"
else
    echo ""
    echo "⚠️  PostgreSQL inició pero aún no está listo. Espera unos segundos más."
fi

