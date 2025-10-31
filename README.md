# AUTO-ATC Playbook v3 (Self-hosted)

## Estructura
- docker-compose.yml
- .env.chatwoot, .env.n8n
- scripts/provision_chatwoot.sh
- rasa/ (domain.yml, rules.yml, actions.py)
- db/schema.sql
- n8n/ (WF_MAIN_orchestrator_v4.json, WF_TOGGLE_reply_mode_v1.json, WF_KB_ingest_v2.json, WF_ERRORS_notify_v1.json)
- whatsapp/template_cotizacion_inicial.json

## Pasos rápidos
1. `docker compose up -d`
2. Configura Chatwoot y ejecuta `scripts/provision_chatwoot.sh` (exporta variables .env.chatwoot antes).
3. Importa los 4 workflows en n8n y ajusta credenciales/URLs `{PLACEHOLDER}`.
4. Crea colección `products` en Qdrant y carga KB con `WF_KB_ingest_v2`.
5. Verifica `reply_mode` con `WF_TOGGLE_reply_mode_v1` (POST {"reply_mode": true|false}).
6. Define templates WhatsApp y prueba caso fuera de 24h.

## Notas
- Sustituye `{PLACEHOLDER}` por tus valores reales.
- Cada archivo contiene **EXPORT_SEAL v1**.

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
