#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
  echo 'Missing scripts/.env. Copy scripts/.env.example to scripts/.env first.' >&2
  exit 1
fi
compose() {
  docker compose --env-file "$SCRIPT_DIR/.env" -f "$SCRIPT_DIR/compose.yaml" "$@"
}
