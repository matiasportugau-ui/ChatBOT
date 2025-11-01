#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
This helper guides you to install Python 3.10 on macOS for Rasa 3.6.
It will NOT run privileged commands without your confirmation.

Options:
  1) Homebrew python@3.10 (simple)
  2) pyenv (recommended for multiple versions)
  q) Quit
MSG

read -r -p "Choose option [1/2/q]: " choice
case "$choice" in
  1)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew is not installed: https://brew.sh"
      exit 1
    fi
    echo "Installing python@3.10 via Homebrew..."
    brew install python@3.10
    echo "Linking as default 'python3' requires: brew link python@3.10 --force"
    ;;
  2)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew is required to install pyenv: https://brew.sh"
      exit 1
    fi
    echo "Installing pyenv..."
    brew install pyenv
    echo "Installing Python 3.10.14 via pyenv..."
    pyenv install 3.10.14 || true
    echo "Setting local version (in this folder): pyenv local 3.10.14"
    ;;
  q|Q)
    echo "Aborted."
    exit 0
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
 esac

echo "Done. Now run:"
echo "  python3.10 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
