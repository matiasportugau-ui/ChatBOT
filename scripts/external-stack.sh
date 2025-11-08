#!/usr/bin/env bash
set -euo pipefail

# Safe wrapper for running docker compose with external drive mounts.
# Usage: external-stack.sh up|down|status|logs

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
validator="$script_dir/check_external_setup.sh"
if [ ! -x "$validator" ]; then
  validator="$script_dir/ci_validate_external.sh"
fi

case "${1:-}" in
  up)
    echo "Validating external data path before starting services..."
    "$validator"
    docker compose -f docker-compose.yml -f docker-compose.external.yml up -d
    ;;
  dry)
    echo "Validating external data path (dry run)..."
    "$validator"
    echo "DRY: would run: docker compose -f docker-compose.yml -f docker-compose.external.yml up -d"
    ;;
  down)
    docker compose down
    ;;
  status)
    docker compose ps
    ;;
  logs)
    shift || true
    docker compose logs "$@"
    ;;
  *)
    echo "Usage: $0 {up|down|status|logs}"
    exit 2
    ;;
esac
