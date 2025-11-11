#!/bin/bash
# Script para iniciar el Action Server de Rasa

cd "$(dirname "$0")"
source .venv/bin/activate

echo "🚀 Iniciando Action Server en puerto 5055..."
echo "📋 Las acciones personalizadas estarán disponibles"
echo "🛑 Presiona Ctrl+C para detener"

rasa run actions --port 5055

