#!/bin/bash
# Script para verificar el estado del conocimiento del chatbot

echo "🔍 Verificando estado del conocimiento del Chatbot..."
echo ""

# 1. Verificar Rasa
echo "1️⃣  Verificando Rasa Server..."
if curl -s http://localhost:5005/status > /dev/null 2>&1; then
    echo "   ✅ Rasa está corriendo"
else
    echo "   ❌ Rasa NO está corriendo"
fi

# 2. Verificar Training API
echo ""
echo "2️⃣  Verificando Training API..."
if curl -s http://localhost:5006/api/health > /dev/null 2>&1; then
    echo "   ✅ Training API está corriendo"
    INTENTS=$(curl -s http://localhost:5006/api/intents | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"   📊 {len(data.get('intents', []))} intents disponibles\")" 2>/dev/null || echo "   ⚠️  No se pudieron cargar intents")
    echo "$INTENTS"
else
    echo "   ❌ Training API NO está corriendo"
fi

# 3. Verificar PostgreSQL
echo ""
echo "3️⃣  Verificando Base de Conocimiento (PostgreSQL)..."
if docker ps 2>/dev/null | grep -q postgres; then
    echo "   ✅ PostgreSQL está corriendo en Docker"
    COUNT=$(docker exec $(docker ps -q -f name=postgres) psql -U atc -d atcdb -t -c "SELECT COUNT(*) FROM knowledge_base;" 2>/dev/null | tr -d ' ' || echo "0")
    echo "   📊 Registros en knowledge_base: $COUNT"
elif python3 -c "import psycopg2; psycopg2.connect('dbname=atcdb user=atc password=atc_pass host=localhost')" 2>/dev/null; then
    echo "   ✅ PostgreSQL está corriendo (local)"
    COUNT=$(python3 -c "import psycopg2; conn=psycopg2.connect('dbname=atcdb user=atc password=atc_pass host=localhost'); cur=conn.cursor(); cur.execute('SELECT COUNT(*) FROM knowledge_base;'); print(cur.fetchone()[0]); conn.close()" 2>/dev/null || echo "0")
    echo "   📊 Registros en knowledge_base: $COUNT"
else
    echo "   ❌ PostgreSQL NO está corriendo"
    echo "   💡 Solución: ./start_knowledge_base.sh"
fi

# 4. Resumen
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "El chatbot puede:"
echo "  ✅ Entender intents básicos (saludo, despedida, etc.)"
if docker ps 2>/dev/null | grep -q postgres || python3 -c "import psycopg2; psycopg2.connect('dbname=atcdb user=atc password=atc_pass host=localhost')" 2>/dev/null; then
    echo "  ✅ Buscar en base de conocimiento"
else
    echo "  ❌ NO puede buscar en base de conocimiento (PostgreSQL no está corriendo)"
fi
echo ""
