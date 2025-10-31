#!/usr/bin/env bash
set -euo pipefail
: "${CHATWOOT_BASE_URL:?}"
: "${CHATWOOT_PLATFORM_TOKEN:?}"
: "${CHATWOOT_ACCOUNT_ID:?}"
: "${CHATWOOT_INBOX_ID:?}"
: "${BOT_OUTGOING_URL:?}"

# Create AgentBot
BOT=$(curl -s -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" -H "Content-Type: application/json"   -d "{"name":"RasaBot","description":"Bot Rasa","outgoing_url":"$BOT_OUTGOING_URL","account_id":$CHATWOOT_ACCOUNT_ID}"   "$CHATWOOT_BASE_URL/platform/api/v1/agent_bots")
BOT_ID=$(echo "$BOT" | jq -r '.id')

# Attach AgentBot to Inbox
curl -s -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" -H "Content-Type: application/json"   -d "{"agent_bot":{"id":$BOT_ID}}"   "$CHATWOOT_BASE_URL/platform/api/v1/accounts/$CHATWOOT_ACCOUNT_ID/inboxes/$CHATWOOT_INBOX_ID/agent_bot" >/dev/null

# Create Account Webhook to n8n
curl -s -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" -H "Content-Type: application/json"   -d "{"url":"$BOT_OUTGOING_URL","subscriptions":["conversation_created","message_created","conversation_updated"]}"   "$CHATWOOT_BASE_URL/platform/api/v1/accounts/$CHATWOOT_ACCOUNT_ID/webhooks" >/dev/null

echo "AgentBot $BOT_ID linked to Inbox $CHATWOOT_INBOX_ID and webhook created."

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: cw-prov-v3
# version: 3.0.0
# file: scripts/provision_chatwoot.sh
# lang: sh
# created_at: 2025-10-31T00:10:55Z
# author: GPT-5 Thinking
# origin: cw-provision
# body_sha256: 04b438ad9dba8632bbd4a1a1c0c7d3ca54e675d51bcbe79a135f1a47b0f20975
