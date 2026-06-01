#!/usr/bin/env bash
set -euo pipefail

FRESHRSS_USER="${FRESHRSS_ADMIN_USER:-admin}"
FRESHRSS_PASS="${FRESHRSS_ADMIN_PASS:-admin}"
DB_USER="${DB_USER:-freshrss}"
DB_PASS="${DB_PASSWORD:-freshrss}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPML_FILE="${1:-$SCRIPT_DIR/feeds.opml}"

echo "Waiting for freshrss container to be ready..."
until docker exec freshrss php -r "exit(0);" 2>/dev/null; do
  sleep 2
done

if docker exec freshrss php ./cli/do-install.php \
    --default-user "$FRESHRSS_USER" \
    --auth-type form \
    --db-type pgsql \
    --db-host freshrss-db \
    --db-user "$DB_USER" \
    --db-password "$DB_PASS" \
    --db-base freshrss-db 2>&1 | grep -q "already installed"; then
  echo "FreshRSS already installed, skipping install step."
else
  echo "FreshRSS installed."
fi

if docker exec freshrss php ./cli/create-user.php \
    --user "$FRESHRSS_USER" \
    --password "$FRESHRSS_PASS" \
    --api-password "$FRESHRSS_PASS" \
    --no-default-feeds 2>&1 | grep -q "already exists"; then
  echo "User '$FRESHRSS_USER' already exists, skipping user creation."
else
  echo "User '$FRESHRSS_USER' created."
fi

echo "Applying archiving settings..."
docker exec freshrss php -r "
  \$path = '/var/www/FreshRSS/data/users/$FRESHRSS_USER/config.php';
  \$conf = include \$path;
  \$conf['archiving']['keep_unreads'] = true;
  \$conf['archiving']['keep_period'] = 0;
  \$conf['archiving']['keep_max'] = 0;
  file_put_contents(\$path, '<?php' . PHP_EOL . 'return ' . var_export(\$conf, true) . ';' . PHP_EOL);
  echo 'Done.' . PHP_EOL;
"

echo "Fixing data directory permissions..."
docker exec freshrss sh /var/www/FreshRSS/cli/access-permissions.sh

if [[ -f "$OPML_FILE" ]]; then
  echo "Importing feeds from $OPML_FILE..."
  docker cp "$OPML_FILE" freshrss:/tmp/feeds.opml
  docker exec freshrss php /var/www/FreshRSS/cli/import-for-user.php --user "$FRESHRSS_USER" --filename /tmp/feeds.opml
  docker exec freshrss rm /tmp/feeds.opml
  echo "Done. FreshRSS is ready at http://localhost:8082"
else
  echo "No OPML file found at '$OPML_FILE'. Skipping feed import."
  echo "FreshRSS is ready at http://localhost:8082 — import feeds manually or run:"
  echo "  $0 /path/to/feeds.opml"
fi
