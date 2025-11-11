#!/bin/bash
# Script para reiniciar Rasa con el nuevo modelo

cd "$(dirname "$0")"
source .venv/bin/activate

# Encontrar y matar el proceso de Rasa actual
echo "🛑 Deteniendo Rasa actual..."
pkill -f "rasa run" || true
sleep 2

# Encontrar el modelo más reciente
LATEST_MODEL=$(ls -t models/*.tar.gz | head -1)
echo "📦 Usando modelo: $LATEST_MODEL"

# Iniciar Rasa en background
echo "🚀 Iniciando Rasa con nuevo modelo..."
rasa run --model "$LATEST_MODEL" --enable-api --cors '*' --port 5005 > rasa_server.log 2>&1 &

sleep 3

# Verificar que esté corriendo
if curl -s http://localhost:5005/status > /dev/null 2>&1; then
    echo "✅ Rasa está corriendo en http://localhost:5005"
    echo "📋 Logs: tail -f rasa_server.log"
else
    echo "❌ Error: Rasa no está respondiendo"
    echo "📋 Revisa los logs: cat rasa_server.log"
fi

