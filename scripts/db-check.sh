#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql --protocol=TCP -h 127.0.0.1 -u "$MYSQL_USER" "$MYSQL_DATABASE"' <<'SQL'
SELECT DATABASE() AS database_name, VERSION() AS mysql_version;
SELECT 1 AS connection_ok;
SQL
