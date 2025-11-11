# Usar el Chatbot - Guía Rápida

## 🚀 Servidor Iniciado

El modelo entrenado está listo para usar. El servidor de Rasa está corriendo en:

**URL**: http://localhost:5005

## 📡 Endpoints Disponibles

### 1. Verificar Estado
```bash
curl http://localhost:5005/status
```

### 2. Enviar Mensaje (Webhook)
```bash
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "test_user",
    "message": "hola"
  }'
```

### 3. Predecir Intención (NLU)
```bash
curl -X POST http://localhost:5005/model/parse \
  -H "Content-Type: application/json" \
  -d '{
    "text": "quiero cotizar remera"
  }'
```

### 4. Conversación Completa
```bash
curl -X POST http://localhost:5005/conversations/test_user/messages \
  -H "Content-Type: application/json" \
  -d '{
    "text": "hola"
  }'
```

## 🧪 Probar el Chatbot

### Opción 1: Desde Terminal

```bash
# Activar entorno
source .venv/bin/activate

# Probar saludo
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "user1", "message": "hola"}'

# Probar cotización
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "user1", "message": "quiero cotizar remera"}'
```

### Opción 2: Usar Rasa Shell (Interactivo)

```bash
source .venv/bin/activate
rasa shell --model models/20251109-214427-visible-reservoir.tar.gz
```

Esto abrirá una sesión interactiva donde puedes chatear directamente.

### Opción 3: API REST Client

Usa Postman, Insomnia, o cualquier cliente REST:

**POST** `http://localhost:5005/webhooks/rest/webhook`
```json
{
  "sender": "test_user",
  "message": "hola"
}
```

## 🔧 Comandos Útiles

### Iniciar Servidor (si no está corriendo)
```bash
source .venv/bin/activate
python -m rasa run \
  --model models/20251109-214427-visible-reservoir.tar.gz \
  --enable-api \
  --cors "*" \
  --port 5005
```

### Detener Servidor
```bash
# Encontrar proceso
ps aux | grep "rasa run"

# Matar proceso (reemplaza PID)
kill <PID>
```

### Ver Logs
El servidor muestra logs en tiempo real en la terminal donde se ejecutó.

## 📝 Intents Disponibles

Según el modelo entrenado:

1. **saludo**: "hola", "buen día"
2. **despedida**: "chau", "adiós"
3. **cotizar_producto**: "quiero cotizar remera", "necesito precio de zapatillas SKU-123"

## 🎯 Ejemplo de Conversación

```bash
# 1. Saludo
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "user1", "message": "hola"}'

# Respuesta esperada: Saludo del bot

# 2. Cotización
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "user1", "message": "quiero cotizar remera"}'

# Respuesta esperada: Procesamiento de cotización
```

## 🔗 Integración con Chatwoot/n8n

Si tienes Chatwoot y n8n configurados:

1. **Configura el webhook en n8n**:
   - URL: `http://localhost:5005/webhooks/rest/webhook`
   - Método: POST
   - Content-Type: application/json

2. **Estructura del mensaje**:
```json
{
  "sender": "chatwoot_user_id",
  "message": "texto del mensaje"
}
```

3. **Respuesta del bot**:
```json
[
  {
    "text": "Respuesta del bot",
    "recipient_id": "chatwoot_user_id"
  }
]
```

## 🐛 Troubleshooting

**Servidor no responde**:
```bash
# Verificar que esté corriendo
curl http://localhost:5005/status

# Reiniciar si es necesario
pkill -f "rasa run"
source .venv/bin/activate
python -m rasa run --model models/20251109-214427-visible-reservoir.tar.gz --enable-api --cors "*" --port 5005
```

**Puerto ocupado**:
```bash
# Cambiar puerto
python -m rasa run --model models/20251109-214427-visible-reservoir.tar.gz --enable-api --cors "*" --port 5006
```

**Error de modelo**:
```bash
# Verificar que el modelo existe
ls -lh models/*.tar.gz

# Usar el modelo más reciente
python -m rasa run --model models/ --enable-api --cors "*" --port 5005
```

## 📊 Monitoreo

### Ver métricas en tiempo real
```bash
# Estado del servidor
curl http://localhost:5005/status

# Health check
curl http://localhost:5005/
```

### Logs
Los logs se muestran en la terminal donde se ejecutó el servidor. Incluyen:
- Mensajes recibidos
- Intents detectados
- Respuestas generadas
- Errores (si los hay)

---

**¡El chatbot está listo para usar!** 🎉

