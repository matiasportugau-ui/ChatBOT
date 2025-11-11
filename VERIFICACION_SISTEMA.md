# ✅ Verificación del Sistema de Corrección

## 📊 Estado Actual

### ✅ Completado
1. **Modelo reentrenado** con nuevos intents:
   - `corregir` - Detecta cuando algo está mal
   - `buscar_conocimiento` - Busca en la base de conocimiento
   
2. **Acciones implementadas**:
   - `action_handle_correction` - Procesa correcciones
   - `action_search_knowledge` - Busca en KB

3. **Base de conocimiento configurada**:
   - PostgreSQL como principal
   - Qdrant como opcional (fallback automático)

### ⚠️ Pendiente

1. **Reiniciar Rasa** con el nuevo modelo:
   ```bash
   ./restart_rasa.sh
   ```

2. **Iniciar Action Server** (necesario para acciones personalizadas):
   ```bash
   source .venv/bin/activate
   rasa run actions --port 5055
   ```

3. **Verificar conexión a PostgreSQL**:
   - Si usas Docker: `docker-compose up -d postgres`
   - Si usas local: verificar que PostgreSQL esté corriendo

## 🧪 Probar el Sistema

### Opción 1: Script de prueba
```bash
python3 test_correccion.py
```

### Opción 2: Manualmente
```bash
# Test 1: Corrección simple
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "test", "message": "eso está mal"}'

# Test 2: Corrección específica
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "test", "message": "el precio está mal, debería ser $100"}'
```

### Opción 3: Interfaz Web
Abrir: http://localhost:8080/web_chat_interface.html

## 🔍 Verificar Base de Conocimiento

### PostgreSQL
```bash
# Si usas Docker
docker exec chatbot-postgres-1 psql -U atc -d atcdb -c "SELECT * FROM knowledge_base;"

# Si usas local (requiere psql instalado)
psql -U atc -d atcdb -h localhost -c "SELECT * FROM knowledge_base;"
```

### Qdrant
```bash
curl http://localhost:6333/collections/knowledge_base
```

## 📝 Notas Importantes

1. **Action Server es necesario**: Las acciones personalizadas (`action_handle_correction`, `action_search_knowledge`) solo funcionan si el action server está corriendo en el puerto 5055.

2. **PostgreSQL debe estar accesible**: El sistema intentará conectarse a PostgreSQL. Si no está disponible, las correcciones no se guardarán.

3. **El modelo necesita reconocer los intents**: Después de reentrenar, reinicia Rasa para que use el nuevo modelo.

## 🚀 Próximos Pasos

1. Reiniciar Rasa: `./restart_rasa.sh`
2. Iniciar Action Server: `rasa run actions --port 5055`
3. Probar: `python3 test_correccion.py`
4. Verificar KB: Consultar PostgreSQL para ver correcciones guardadas

