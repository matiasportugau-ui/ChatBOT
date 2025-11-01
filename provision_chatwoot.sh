#!/usr/bin/env bash
set -euo pipefail
: "${CHATWOOT_BASE_URL:?}"
: "${CHATWOOT_PLATFORM_TOKEN:?}"
: "${CHATWOOT_ACCOUNT_ID:?}"
: "${CHATWOOT_INBOX_ID:?}"
: "${BOT_OUTGOING_URL:?}"

# Create AgentBot
BOT=$(curl -s -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"RasaBot\",\"description\":\"Bot Rasa\",\"outgoing_url\":\"$BOT_OUTGOING_URL\",\"account_id\":$CHATWOOT_ACCOUNT_ID}" \
  "$CHATWOOT_BASE_URL/platform/api/v1/agent_bots")
BOT_ID=$(echo "$BOT" | jq -r '.id')

# Attach AgentBot to Inbox
curl -s -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"agent_bot\":{\"id\":$BOT_ID}}" \
  "$CHATWOOT_BASE_URL/platform/api/v1/accounts/$CHATWOOT_ACCOUNT_ID/inboxes/$CHATWOOT_INBOX_ID/agent_bot" >/dev/null

# Create Account Webhook to n8n
curl -s -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$BOT_OUTGOING_URL\",\"subscriptions\":[\"conversation_created\",\"message_created\",\"conversation_updated\"]}" \
  "$CHATWOOT_BASE_URL/platform/api/v1/accounts/$CHATWOOT_ACCOUNT_ID/webhooks" >/dev/null

echo "AgentBot $BOT_ID linked to Inbox $CHATWOOT_INBOX_ID and webhook created."
