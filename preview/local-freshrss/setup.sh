#!/bin/bash
set -e
cd "$(dirname "$0")"

CONTAINER="paperwhite-dev"
CLI="/app/www/cli"
DATA="/app/www/data"

echo "→ starting freshrss container..."
docker compose up -d

echo "→ waiting for FreshRSS HTTP to respond..."
for i in {1..60}; do
  if curl -fs -o /dev/null http://localhost:8888/; then
    echo "  up after ${i}s"
    break
  fi
  sleep 1
done

# Idempotent install
if ! docker exec "$CONTAINER" test -f "$DATA/config.php"; then
  echo "→ running do-install..."
  docker exec "$CONTAINER" php "$CLI/do-install.php" \
    --default-user admin \
    --base-url http://localhost:8888 \
    --db-type sqlite \
    --language en \
    --title "Paperwhite Dev"
fi

# Idempotent user create
if ! docker exec "$CONTAINER" test -d "$DATA/users/admin"; then
  echo "→ creating admin user..."
  docker exec "$CONTAINER" php "$CLI/create-user.php" \
    --user admin --password admin --api-password admin
fi

# Disable auth so headless Chrome bypasses login
echo "→ disabling auth (none)..."
docker exec "$CONTAINER" php "$CLI/update.php" --auth_type none 2>/dev/null || true

# Set theme to Paperwhite
echo "→ activating Paperwhite theme..."
docker exec "$CONTAINER" php "$CLI/update-user.php" \
  --user admin --theme Paperwhite 2>/dev/null || true

# Import sample OPML (idempotent: skip if user already has feeds)
FEED_COUNT=$(docker exec "$CONTAINER" sh -c "ls $DATA/users/admin/feeds/ 2>/dev/null | wc -l" || echo 0)
if [ "$FEED_COUNT" -eq 0 ]; then
  echo "→ importing sample OPML..."
  docker cp ./sample.opml "$CONTAINER":/tmp/sample.opml
  docker exec "$CONTAINER" php "$CLI/import-for-user.php" \
    --user admin --filename /tmp/sample.opml

  echo "→ fetching articles (may take ~30s, runs in background)..."
  docker exec -d "$CONTAINER" php "$CLI/actualize-user.php" --user admin
fi

echo "→ done. http://localhost:8888/"
