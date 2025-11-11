# 🔍 Solución: El Chatbot "No Tiene Conocimiento"

## Problema Identificado

El chatbot tiene los **intents entrenados** (saludo, despedida, cotizar_producto, etc.), pero **no puede acceder a la base de conocimiento** porque PostgreSQL no está corriendo.

## Estado Actual

✅ **Funcionando:**
- Modelo de Rasa entrenado (hay 3 modelos en `models/`)
- Intents definidos: saludo, despedida, cotizar_producto, corregir, buscar_conocimiento
- Training API funcionando (puerto 5006)
- Interfaz web funcionando

❌ **No Funcionando:**
- Base de conocimiento (PostgreSQL no está corriendo)
- Búsqueda de productos/precios
- Acceso a información específica

## Solución Rápida

### ⚠️ IMPORTANTE: Docker debe estar corriendo primero

```bash
# 1. Iniciar Docker Desktop (si no está corriendo)
# Abre Docker Desktop desde Applications

# 2. Verificar que Docker está corriendo
docker ps

# 3. Iniciar PostgreSQL
./start_knowledge_base.sh

# O manualmente:
docker-compose up -d postgres
```

### Si Docker no está disponible

El chatbot funcionará para:
- ✅ Saludos y conversación básica
- ✅ Entender intents
- ❌ NO podrá buscar información específica (productos/precios)

Para funcionalidad completa, necesitas Docker corriendo.

### Opción 2: Verificar si Docker está corriendo

```bash
# Verificar Docker
docker ps

# Si no hay contenedores, iniciar PostgreSQL
docker-compose up -d postgres

# Verificar que está corriendo
docker ps | grep postgres
```

### Opción 3: Verificar conexión

```bash
# Probar conexión a PostgreSQL
python3 << EOF
import psycopg2
try:
    conn = psycopg2.connect('dbname=atcdb user=atc password=atc_pass host=localhost')
    print("✅ PostgreSQL está conectado!")
    conn.close()
except Exception as e:
    print(f"❌ Error: {e}")
EOF
```

## Qué Hace la Base de Conocimiento

La base de conocimiento almacena:
- **Correcciones** de precios/productos
- **Información** sobre productos
- **Contexto** de conversaciones anteriores

Sin ella, el chatbot puede:
- ✅ Responder saludos
- ✅ Entender intents básicos
- ❌ NO puede buscar información específica
- ❌ NO puede responder sobre precios/productos

## Verificar Estado Completo

```bash
# 1. Verificar Rasa
curl http://localhost:5005/status

# 2. Verificar Training API
curl http://localhost:5006/api/health

# 3. Verificar PostgreSQL
docker ps | grep postgres
# O
./start_knowledge_base.sh
```

## Próximos Pasos

1. **Iniciar PostgreSQL**: `./start_knowledge_base.sh`
2. **Verificar conexión**: El script lo hace automáticamente
3. **Agregar datos iniciales** (opcional):
   ```sql
   INSERT INTO knowledge_base (topic, correction, type, timestamp) 
   VALUES ('precio', 'El precio de X es Y', 'correction', extract(epoch from now()));
   ```

## Resumen

| Componente | Estado | Acción |
|------------|--------|--------|
| Rasa Server | ✅ Funcionando | Ninguna |
| Training API | ✅ Funcionando | Ninguna |
| Interfaz Web | ✅ Funcionando | Ninguna |
| PostgreSQL | ❌ No corriendo | `./start_knowledge_base.sh` |
| Base de Conocimiento | ❌ Vacía | Agregar datos después de iniciar PostgreSQL |

