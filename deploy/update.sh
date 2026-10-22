#!/bin/sh
# Pull the newest site image and restart the container only if it changed.
# Run by cron every 5 minutes (see README):
#   */5 * * * * /opt/personal-site/update.sh 2>&1 | logger -t site-update
# See what it did:  journalctl -t site-update   (or: grep site-update /var/log/syslog)
set -eu
cd "$(dirname "$0")"

before=$(docker compose images -q site 2>/dev/null || true)
docker compose pull --quiet site
docker compose up -d --remove-orphans site
after=$(docker compose images -q site 2>/dev/null || true)

if [ "$before" != "$after" ]; then
    echo "site updated: ${before:-none} -> ${after}"
    docker image prune -f >/dev/null
fi
