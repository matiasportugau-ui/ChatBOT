#!/usr/bin/env bash
set -euo pipefail

# CI-friendly validator for EXTERNAL_DATA_PATH
# Exits:
# 0 = OK
# 1 = missing env or directory
# 2 = permission / not writable
# 3 = other error

: "${EXTERNAL_DATA_PATH:=}"
if [ -z "$EXTERNAL_DATA_PATH" ]; then
  echo "ERROR: EXTERNAL_DATA_PATH is not set."
  exit 1
fi

DATA_ROOT="$EXTERNAL_DATA_PATH"

if [ ! -d "$DATA_ROOT" ]; then
  echo "ERROR: EXTERNAL_DATA_PATH '$DATA_ROOT' does not exist or is not a directory."
  exit 1
fi

# verify writability by touching a temp file
tmpfile="$DATA_ROOT/.ci_write_test_$$"
if ! touch "$tmpfile" 2>/dev/null; then
  echo "ERROR: Cannot write to '$DATA_ROOT'. Permission denied."
  exit 2
fi
rm -f "$tmpfile"

echo "OK: EXTERNAL_DATA_PATH exists and is writable: '$DATA_ROOT'"
exit 0
