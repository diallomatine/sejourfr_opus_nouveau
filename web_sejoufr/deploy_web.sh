#!/usr/bin/env bash
set -euo pipefail

# Déploiement Web public (Next.js) — SSR/ISR derrière systemd + Nginx.
# Workflow : push Git (develop) -> pull serveur -> build -> restart du service.
#
# Usage :
#   ./deploy_web.sh            # pull + build + restart (sans réinstaller les deps)
#   ./deploy_web.sh --install  # idem + npm ci (si package.json / lock ont changé)
#   ./deploy_web.sh --no-push  # ne pousse pas, déploie l'état déjà sur origin/develop

# --- Config ---
SERVER="root@82.223.165.43"
APP_USER="sejourfr"
REPO="/opt/sejourfr/repo"
WEB_DIR="$REPO/web_sejoufr"
BRANCH="develop"
SERVICE="sejourfr-web"
URL="https://sejourfr.fr"

INSTALL=0
PUSH=1
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --no-push) PUSH=0 ;;
    *) echo "Option inconnue: $arg"; exit 1 ;;
  esac
done

cd "$(dirname "$0")"

if [ "$PUSH" -eq 1 ]; then
  echo "==> Push Git ($BRANCH)"
  git push origin "$BRANCH"
fi

echo "==> Déploiement distant"
ssh "$SERVER" INSTALL="$INSTALL" bash -s <<EOF
set -euo pipefail
sudo -u $APP_USER git -C "$REPO" fetch origin
sudo -u $APP_USER git -C "$REPO" reset --hard origin/$BRANCH

if [ "\$INSTALL" -eq 1 ]; then
  echo "--> npm ci"
  sudo -u $APP_USER bash -c "cd $WEB_DIR && npm ci"
fi

echo "--> Build"
sudo -u $APP_USER bash -c "cd $WEB_DIR && npm run build"

echo "--> Restart $SERVICE"
sudo systemctl restart $SERVICE
sudo systemctl status $SERVICE --no-pager | head -10
EOF

echo "==> Vérification"
curl -I "$URL"
echo "==> Web déployé : $URL"
echo "==> Logs : ssh $SERVER 'sudo journalctl -u $SERVICE -f'"
