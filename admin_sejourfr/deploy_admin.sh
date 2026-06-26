#!/usr/bin/env bash
set -euo pipefail

# Déploiement Admin (React + Vite) — build statique servi par Nginx.
# Workflow : build local -> rsync vers /tmp/admin-build -> écrasement des fichiers servis.

# --- Config ---
SERVER="root@82.223.165.43"
LOCAL_DIST="dist/"
REMOTE_TMP="/tmp/admin-build/"
REMOTE_HTML="/var/www/admin.sejourfr.fr/html/"
WEB_OWNER="www-data:www-data"
URL="https://admin.sejourfr.fr"

cd "$(dirname "$0")"

echo "==> Build"
npm run build

echo "==> Upload (rsync vers $REMOTE_TMP)"
rsync -avz --delete "$LOCAL_DIST" "$SERVER:$REMOTE_TMP"

echo "==> Déploiement distant"
ssh "$SERVER" bash -s <<EOF
set -euo pipefail
sudo rsync -avz --delete "$REMOTE_TMP" "$REMOTE_HTML"
sudo chown -R $WEB_OWNER /var/www/admin.sejourfr.fr
sudo rm -rf "$REMOTE_TMP"
EOF

echo "==> Vérification"
curl -I "$URL"
echo "==> Admin déployé : $URL"
