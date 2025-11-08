# AUTO-ATC Playbook v3 (Self-hosted)

Sistema completo de chatbot auto-ATC self-hosted con stack Docker Compose. Soporta mensajería multi-canal (WhatsApp, web), NLP avanzado, y knowledge base vectorial.

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   WhatsApp/Web  │───▶│   Chatwoot      │───▶│   n8n           │
│   (Meta API)    │    │ (Mensajería)    │    │ (Orquestación)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         │                        │                        ▼
         │                        │               ┌─────────────────┐
         │                        │               │   Rasa          │
         │                        │               │ (NLP/Chatbot)   │
         │                        │               └─────────────────┘
         │                        │                        │
         │                        │                        ▼
         │                        │               ┌─────────────────┐
         │                        │               │   Qdrant        │
         │                        │               │ (Vector DB)     │
         │                        │               └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Postgres      │    │   Redis         │    │   Templates     │
│ (DB Principal)  │    │ (Caching)       │    │ (WhatsApp)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Inicio Rápido

### Prerrequisitos
- Docker & Docker Compose
- 8GB RAM mínimo, 4GB disco
- Token WhatsApp Business API
- Dominio para webhooks (opcional)

### Instalación
```bash
# 1. Clonar repositorio
git clone https://github.com/matiasportugau-ui/ChatBOT.git
cd ChatBOT

# 2. Configurar variables de entorno
cp .env.example .env.chatwoot
cp .env.example .env.n8n
# Editar con tus valores reales

# 3. Levantar servicios
docker compose up -d

# 4. Provisionar Chatwoot
./scripts/provision_chatwoot.sh

# 5. Importar workflows en n8n (http://localhost:5678)
# Importar los 4 archivos .json desde n8n/

# 6. Entrenar modelo Rasa
docker compose exec rasa rasa train

# 7. Cargar knowledge base
# Ejecutar WF_KB_ingest_v2 en n8n con datos de productos
```

## 📋 Estructura del Proyecto

```
├── docker-compose.yml          # Definición de servicios
├── .env.chatwoot              # Variables Chatwoot
├── .env.n8n                   # Variables n8n
├── scripts/
│   └── provision_chatwoot.sh  # Script de configuración
├── rasa/
│   ├── domain.yml             # Configuración intents/entidades
│   ├── rules.yml              # Reglas de conversación
│   └── actions.py             # Acciones customizadas
├── db/
│   └── schema.sql             # Esquema base de datos
├── n8n/
│   ├── WF_MAIN_orchestrator_v4.json     # Workflow principal
│   ├── WF_TOGGLE_reply_mode_v1.json     # Toggle modo respuesta
│   ├── WF_KB_ingest_v2.json             # Ingestión KB
│   └── WF_ERRORS_notify_v1.json         # Notificaciones errores
├── whatsapp/
│   └── template_cotizacion_inicial.json # Templates WhatsApp
└── tests/                      # Tests automatizados
```

## 🔧 Configuración Detallada

### Chatwoot
- Puerto: 3000
- Inbox WhatsApp configurada automáticamente
- Webhook a n8n integrado
- AgentBot Rasa conectado

### n8n
- Puerto: 5678
- 4 workflows principales
- Integración con Rasa, Qdrant, WhatsApp

### Rasa
- Puerto: 5005
- Modelo entrenado en español
- Actions server integrado
- CORS habilitado

### Qdrant
- Puerto: 6333 (API), 6334 (gRPC)
- Colección `products` para knowledge base
- Embeddings OpenAI/HuggingFace

## 🧪 Testing

```bash
# Tests unitarios
docker compose exec rasa python -m pytest tests/

# Test integración
curl -X POST http://localhost:3000/webhooks/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"message": "Hola, cotiza laptop"}'
```

## 🔒 Seguridad

- Variables sensibles en archivos .env (no commited)
- Secrets Docker para contraseñas
- Validación de inputs en actions.py
- CORS configurado apropiadamente

## 📊 Monitoreo

```bash
# Ver logs de todos los servicios
docker compose logs -f

# Status de servicios
docker compose ps

# Monitoreo específico
docker compose logs chatwoot | tail -50
```

## 🚨 Troubleshooting

### Problemas Comunes

**Chatwoot no inicia:**
- Verificar variables .env.chatwoot
- Revisar conectividad Postgres/Redis

**n8n workflows fallan:**
- Verificar URLs y tokens en workflows
- Chequear conectividad con servicios externos

**Rasa no responde:**
- Entrenar modelo: `rasa train`
- Verificar puerto 5005 disponible

**Qdrant vacío:**
- Ejecutar WF_KB_ingest_v2
- Verificar colección `products` existe

## 🤝 Contribuir

1. Fork el proyecto
2. Crea rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -m 'feat: descripción'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abre Pull Request

## 📝 Notas de Desarrollo

- Todos los archivos contienen **EXPORT_SEAL v1** para tracking
- Sustituye `{PLACEHOLDER}` por valores reales antes del deploy
- El sistema está diseñado para ser 100% self-hosted
- Escalabilidad: añadir Redis Cluster y Postgres replicas para alta carga

## 🏷️ Badges

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Chatwoot](https://img.shields.io/badge/Chatwoot-1F77B4?style=flat)
![n8n](https://img.shields.io/badge/n8n-FF6B35?style=flat)
![Rasa](https://img.shields.io/badge/Rasa-5C3EE8?style=flat)
![Qdrant](https://img.shields.io/badge/Qdrant-000000?style=flat)

<!-- EXPORT_SEAL v1 -->
<!-- project: auto-atc -->
<!-- prompt_id: readme-v3 -->
<!-- version: 3.0.0 -->
<!-- file: README.md -->
<!-- lang: md -->
<!-- created_at: 2025-10-31T00:10:55Z -->
<!-- author: GPT-5 Thinking -->
<!-- origin: docs -->
<!-- body_sha256: e904ee025bdf0b39ce430b84b9d82f96a43735d5c16c818954cfe41f2b1ba72c -->
