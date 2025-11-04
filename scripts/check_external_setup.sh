#!/usr/bin/env bash
# Check external data path and permissions for the ChatBOT docker external stack.
# Exit codes:
# 0 = OK (path exists and writable)
# 1 = Missing (path does not exist)
# 2 = Permission error (unwritable)
# 3 = Other error

set -euo pipefail

EXTERNAL_DATA_PATH="${EXTERNAL_DATA_PATH:-}"
if [ -z "$EXTERNAL_DATA_PATH" ]; then
  # follow the same fallback logic as external-stack.sh
  EXTERNAL_DRIVE="${EXTERNAL_DRIVE:-/Volumes/My Passport for Mac}"
  EXTERNAL_DATA_PATH="$EXTERNAL_DRIVE/docker/chatbot"
fi

# Normalize path (remove trailing slash)
EXTERNAL_DATA_PATH="${EXTERNAL_DATA_PATH%/}"

echo "Checking external data path: '$EXTERNAL_DATA_PATH'"

if [ ! -e "$EXTERNAL_DATA_PATH" ]; then
  echo "MISSING: path does not exist"
  exit 1
fi

if [ ! -d "$EXTERNAL_DATA_PATH" ]; then
  echo "ERROR: path exists but is not a directory"
  exit 3
fi

# Test writability: attempt to create and remove a temp file
TMPFILE="$EXTERNAL_DATA_PATH/.check_write_$$"
if touch "$TMPFILE" 2>/dev/null; then
  rm -f "$TMPFILE" || true
  echo "OK: path exists and is writable"
  exit 0
else
  echo "PERMISSION_ERROR: cannot write to path"
  echo "Try: sudo chown -R \$(id -u):\$(id -g) '$EXTERNAL_DATA_PATH'"
  exit 2
fi
