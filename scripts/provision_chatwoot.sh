#!/usr/bin/env bash
# AUTO-ATC Playbook v3 - Chatwoot Provisioning Script
# Configuración robusta de Chatwoot con validaciones y manejo de errores

set -euo pipefail

# ==========================================
# CONFIGURATION & VALIDATION
# ==========================================

# Required environment variables
: "${CHATWOOT_BASE_URL:?CHATWOOT_BASE_URL is required}"
: "${CHATWOOT_PLATFORM_TOKEN:?CHATWOOT_PLATFORM_TOKEN is required}"
: "${CHATWOOT_ACCOUNT_ID:?CHATWOOT_ACCOUNT_ID is required}"
: "${CHATWOOT_INBOX_ID:?CHATWOOT_INBOX_ID is required}"
: "${BOT_OUTGOING_URL:?BOT_OUTGOING_URL is required}"

# Optional environment variables with defaults
WEBHOOK_URL="${WEBHOOK_URL:-$BOT_OUTGOING_URL}"
AGENT_BOT_NAME="${AGENT_BOT_NAME:-RasaBot}"
AGENT_BOT_DESCRIPTION="${AGENT_BOT_DESCRIPTION:-Bot Rasa para AUTO-ATC}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-2}"

# Logging
LOG_FILE="${LOG_FILE:-provision_chatwoot.log}"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🚀 Starting Chatwoot provisioning..."
echo "📅 $(date)"
echo "🌐 Chatwoot URL: $CHATWOOT_BASE_URL"
echo "📊 Account ID: $CHATWOOT_ACCOUNT_ID"
echo "📥 Inbox ID: $CHATWOOT_INBOX_ID"

# ==========================================
# UTILITY FUNCTIONS
# ==========================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "❌ ERROR: $*" >&2
}

success() {
    log "✅ SUCCESS: $*"
}

retry() {
    local n=1
    local max=$MAX_RETRIES
    local delay=$RETRY_DELAY

    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                log "Attempt $n/$max failed. Retrying in $delay seconds..."
                ((n++))
                sleep $delay
            else
                error "Command failed after $n attempts: $@"
                return 1
            fi
        }
    done
}

validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        error "Invalid URL format: $url"
        return 1
    fi
}

validate_numeric() {
    local value="$1"
    local field="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        error "Invalid $field (must be numeric): $value"
        return 1
    fi
}

# ==========================================
# VALIDATION
# ==========================================

log "🔍 Validating configuration..."

validate_url "$CHATWOOT_BASE_URL" || exit 1
validate_url "$BOT_OUTGOING_URL" || exit 1
validate_numeric "$CHATWOOT_ACCOUNT_ID" "Account ID" || exit 1
validate_numeric "$CHATWOOT_INBOX_ID" "Inbox ID" || exit 1

# Test Chatwoot connectivity
log "🌐 Testing Chatwoot connectivity..."
if ! curl -s --max-time 10 "$CHATWOOT_BASE_URL/api" > /dev/null; then
    error "Cannot reach Chatwoot at $CHATWOOT_BASE_URL"
    exit 1
fi

success "Configuration validation passed"

# ==========================================
# AGENT BOT CREATION
# ==========================================

log "🤖 Creating AgentBot..."

# Prepare AgentBot data
AGENT_BOT_DATA=$(cat <<EOF
{
  "name": "$AGENT_BOT_NAME",
  "description": "$AGENT_BOT_DESCRIPTION",
  "outgoing_url": "$BOT_OUTGOING_URL",
  "account_id": $CHATWOOT_ACCOUNT_ID
}
EOF
)

# Create AgentBot with retry
BOT_RESPONSE=$(retry curl -s -w "\n%{http_code}" \
    -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$AGENT_BOT_DATA" \
    "$CHATWOOT_BASE_URL/platform/api/v1/agent_bots")

HTTP_CODE=$(echo "$BOT_RESPONSE" | tail -n1)
BOT_JSON=$(echo "$BOT_RESPONSE" | head -n -1)

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
    error "Failed to create AgentBot. HTTP $HTTP_CODE. Response: $BOT_JSON"
    exit 1
fi

BOT_ID=$(echo "$BOT_JSON" | jq -r '.id // empty')
if [[ -z "$BOT_ID" || "$BOT_ID" == "null" ]]; then
    error "Failed to extract AgentBot ID from response: $BOT_JSON"
    exit 1
fi

success "AgentBot created with ID: $BOT_ID"

# ==========================================
# INBOX AGENT BOT ATTACHMENT
# ==========================================

log "🔗 Attaching AgentBot to Inbox..."

# Prepare attachment data
ATTACH_DATA=$(cat <<EOF
{
  "agent_bot": {
    "id": $BOT_ID
  }
}
EOF
)

# Attach AgentBot to Inbox with retry
ATTACH_RESPONSE=$(retry curl -s -w "\n%{http_code}" \
    -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$ATTACH_DATA" \
    "$CHATWOOT_BASE_URL/platform/api/v1/accounts/$CHATWOOT_ACCOUNT_ID/inboxes/$CHATWOOT_INBOX_ID/agent_bot")

ATTACH_HTTP_CODE=$(echo "$ATTACH_RESPONSE" | tail -n1)
ATTACH_JSON=$(echo "$ATTACH_RESPONSE" | head -n -1)

if [[ "$ATTACH_HTTP_CODE" != "200" && "$ATTACH_HTTP_CODE" != "204" ]]; then
    error "Failed to attach AgentBot to Inbox. HTTP $ATTACH_HTTP_CODE. Response: $ATTACH_JSON"
    exit 1
fi

success "AgentBot attached to Inbox"

# ==========================================
# WEBHOOK CREATION
# ==========================================

log "🪝 Creating account webhook..."

# Prepare webhook data
WEBHOOK_DATA=$(cat <<EOF
{
  "url": "$WEBHOOK_URL",
  "subscriptions": [
    "conversation_created",
    "message_created",
    "conversation_updated",
    "message_updated"
  ]
}
EOF
)

# Create webhook with retry
WEBHOOK_RESPONSE=$(retry curl -s -w "\n%{http_code}" \
    -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$WEBHOOK_DATA" \
    "$CHATWOOT_BASE_URL/platform/api/v1/accounts/$CHATWOOT_ACCOUNT_ID/webhooks")

WEBHOOK_HTTP_CODE=$(echo "$WEBHOOK_RESPONSE" | tail -n1)
WEBHOOK_JSON=$(echo "$WEBHOOK_RESPONSE" | head -n -1)

if [[ "$WEBHOOK_HTTP_CODE" != "200" && "$WEBHOOK_HTTP_CODE" != "201" ]]; then
    error "Failed to create webhook. HTTP $WEBHOOK_HTTP_CODE. Response: $WEBHOOK_JSON"
    exit 1
fi

WEBHOOK_ID=$(echo "$WEBHOOK_JSON" | jq -r '.id // empty')
if [[ -n "$WEBHOOK_ID" && "$WEBHOOK_ID" != "null" ]]; then
    success "Webhook created with ID: $WEBHOOK_ID"
else
    success "Webhook created (no ID returned)"
fi

# ==========================================
# VERIFICATION
# ==========================================

log "🔍 Verifying configuration..."

# Verify AgentBot exists
VERIFY_BOT=$(curl -s \
    -H "api_access_token: $CHATWOOT_PLATFORM_TOKEN" \
    "$CHATWOOT_BASE_URL/platform/api/v1/agent_bots/$BOT_ID")

if echo "$VERIFY_BOT" | jq -e '.id' > /dev/null 2>&1; then
    success "AgentBot verification passed"
else
    error "AgentBot verification failed: $VERIFY_BOT"
    exit 1
fi

# ==========================================
# SUMMARY
# ==========================================

echo ""
echo "🎉 Chatwoot provisioning completed successfully!"
echo "📋 Summary:"
echo "   • AgentBot ID: $BOT_ID"
echo "   • Inbox ID: $CHATWOOT_INBOX_ID"
echo "   • Webhook URL: $WEBHOOK_URL"
if [[ -n "$WEBHOOK_ID" && "$WEBHOOK_ID" != "null" ]]; then
    echo "   • Webhook ID: $WEBHOOK_ID"
fi
echo ""
echo "📝 Next steps:"
echo "   1. Configure WhatsApp Business API credentials"
echo "   2. Test the webhook endpoint"
echo "   3. Import n8n workflows"
echo "   4. Train Rasa model"
echo ""
echo "📄 Logs saved to: $LOG_FILE"

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
