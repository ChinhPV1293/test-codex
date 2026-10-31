#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
compose up -d --wait --wait-timeout 180 mysql
"$SCRIPT_DIR/db-check.sh"
