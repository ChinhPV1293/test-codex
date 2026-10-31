#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
# Run after Spring Boot has started and applied Liquibase changes.
compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql --protocol=TCP -h 127.0.0.1 -u "$MYSQL_USER" "$MYSQL_DATABASE"' <<'SQL'
SELECT ID, AUTHOR, EXECTYPE FROM DATABASECHANGELOG ORDER BY ORDEREXECUTED;
START TRANSACTION;
INSERT INTO database_probe (message) VALUES ('Liquibase MySQL smoke test');
SELECT * FROM database_probe WHERE id = LAST_INSERT_ID();
ROLLBACK;
SQL
