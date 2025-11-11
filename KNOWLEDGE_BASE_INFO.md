# 📚 Base de Conocimiento - Información y Mejores Prácticas

## 🗄️ Dónde se Almacena Actualmente

### 1. **PostgreSQL** (Principal - Fallback)
- **Ubicación Docker**: `./pgdata/` (volumen persistente)
- **Ubicación Local**: `./pgdata/` en el directorio del proyecto
- **Tabla**: `knowledge_base`
- **Estructura**:
  ```sql
  CREATE TABLE knowledge_base (
    id SERIAL PRIMARY KEY,
    topic TEXT,              -- Tema de la corrección (precio, producto, etc.)
    correction TEXT,         -- Texto de la corrección
    context JSONB,           -- Contexto completo (mensajes, slots, etc.)
    timestamp BIGINT,        -- Timestamp Unix
    type TEXT,               -- Tipo: "correction"
    created_at TIMESTAMP     -- Fecha de creación
  )
  ```

### 2. **Qdrant** (Opcional - Búsqueda Vectorial)
- **Ubicación Docker**: `./qdrant_storage/` (volumen persistente)
- **URL**: `http://qdrant:6333` (Docker) o `http://localhost:6333` (local)
- **Colección**: `knowledge_base`
- **Uso**: Búsqueda semántica avanzada (cuando está disponible)

## 🔧 Configuración Actual

### Variables de Entorno

```bash
# PostgreSQL
PG_DSN=dbname=atcdb user=atc password=atc_pass host=postgres  # Docker
PG_DSN=dbname=atcdb user=atc password=atc_pass host=localhost  # Local

# Qdrant
QDRANT_URL=http://qdrant:6333      # Docker
QDRANT_URL=http://localhost:6333   # Local

# Base de Conocimiento
KB_COLLECTION=knowledge_base
DOCKER_ENV=true                     # Solo en Docker
```

### Comportamiento del Sistema

1. **Intenta conectar a Qdrant primero**
   - Si Qdrant está disponible → Guarda en Qdrant
   - Si falla → Usa PostgreSQL como fallback

2. **Búsqueda siempre usa PostgreSQL**
   - Más simple para búsqueda de texto
   - Qdrant se usaría para búsqueda semántica (futuro)

## ✅ Mejores Prácticas

### 1. **Arquitectura Híbrida (Recomendada)**

```
┌─────────────────────────────────────────┐
│         Sistema de Corrección           │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
   ┌────▼────┐            ┌─────▼─────┐
   │ Qdrant  │            │PostgreSQL │
   │(Vectores)│            │(Estructurado)│
   └─────────┘            └───────────┘
```

**Ventajas:**
- ✅ Qdrant: Búsqueda semántica rápida
- ✅ PostgreSQL: Datos estructurados, queries SQL, backup fácil
- ✅ Fallback automático si Qdrant falla

### 2. **Estrategia de Almacenamiento**

#### **Opción A: Solo PostgreSQL** (Actual - Simple)
- ✅ Más simple de mantener
- ✅ Backup fácil (pg_dump)
- ✅ Queries SQL directas
- ❌ Búsqueda semántica limitada

#### **Opción B: Qdrant + PostgreSQL** (Recomendada)
- ✅ Qdrant: Búsqueda semántica/vectorial
- ✅ PostgreSQL: Datos estructurados y backup
- ✅ Sincronización entre ambos
- ⚠️ Más complejo de mantener

#### **Opción C: Solo Qdrant** (No recomendada)
- ✅ Búsqueda semántica excelente
- ❌ Sin datos estructurados
- ❌ Backup más complejo
- ❌ Sin fallback

### 3. **Recomendación para Tu Caso**

**Usar PostgreSQL como principal** (como está ahora):
- ✅ Ya está configurado y funcionando
- ✅ Fácil de hacer backup
- ✅ Queries simples
- ✅ Datos estructurados

**Agregar Qdrant opcionalmente** para:
- Búsqueda semántica avanzada
- Mejora de relevancia
- Escalabilidad futura

### 4. **Backup y Persistencia**

#### PostgreSQL
```bash
# Backup
docker exec chatbot-postgres-1 pg_dump -U atc atcdb > backup.sql

# Restore
docker exec -i chatbot-postgres-1 psql -U atc atcdb < backup.sql
```

#### Qdrant
```bash
# Los datos están en ./qdrant_storage/
# Backup: copiar el directorio
cp -r ./qdrant_storage ./qdrant_storage_backup
```

### 5. **Volúmenes Docker**

```yaml
volumes:
  - ./pgdata:/var/lib/postgresql/data          # PostgreSQL
  - ./qdrant_storage:/qdrant/storage           # Qdrant
```

**Ubicación física:**
- `./pgdata/` - Datos de PostgreSQL
- `./qdrant_storage/` - Datos de Qdrant

## 🔍 Verificar Estado Actual

```bash
# Verificar PostgreSQL
docker exec chatbot-postgres-1 psql -U atc -d atcdb -c "\dt knowledge_base"

# Verificar Qdrant
curl http://localhost:6333/collections/knowledge_base

# Ver correcciones guardadas
docker exec chatbot-postgres-1 psql -U atc -d atcdb -c "SELECT * FROM knowledge_base LIMIT 5;"
```

## 📊 Resumen

| Aspecto | PostgreSQL | Qdrant |
|---------|-----------|--------|
| **Estado** | ✅ Activo | ⚠️ Opcional |
| **Ubicación** | `./pgdata/` | `./qdrant_storage/` |
| **Uso Principal** | Almacenamiento principal | Búsqueda semántica |
| **Backup** | Fácil (pg_dump) | Copiar directorio |
| **Búsqueda** | SQL (texto) | Vectorial (semántica) |
| **Recomendación** | ✅ Usar | ⚠️ Opcional |

## 🚀 Próximos Pasos

1. ✅ **Ya configurado**: PostgreSQL como principal
2. ⚠️ **Opcional**: Habilitar Qdrant para búsqueda semántica
3. 📝 **Mejora futura**: Sincronizar ambos sistemas

