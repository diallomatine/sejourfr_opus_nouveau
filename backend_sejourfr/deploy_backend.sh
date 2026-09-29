#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SERVER="root@82.223.165.43"
LOCAL_JAR_GLOB="target/sejourfr-backend-*.jar"
REMOTE_TMP="/tmp/sejourfr-backend.jar"
REMOTE_APP="/opt/sejourfr/backend/app.jar"
SERVICE="sejourfr-backend"
LOG="/opt/sejourfr/logs/backend-stdout.log"

echo "==> Build"
./mvnw clean package -DskipTests

# Résout le glob vers un chemin réel (et vérifie qu'il y en a bien un seul)
JAR=$(ls -1 $LOCAL_JAR_GLOB)
if [ "$(echo "$JAR" | wc -l)" -ne 1 ]; then
  echo "Erreur: 0 ou plusieurs jars trouvés:"; echo "$JAR"; exit 1
fi
echo "==> Jar: $JAR"

echo "==> Upload"
scp "$JAR" "$SERVER:$REMOTE_TMP"

echo "==> Déploiement distant"
ssh "$SERVER" bash -s <<EOF
set -euo pipefail
sudo systemctl stop $SERVICE
sudo mv $REMOTE_TMP $REMOTE_APP
sudo chown sejourfr:sejourfr $REMOTE_APP
sudo systemctl daemon-reload
sudo systemctl start $SERVICE
EOF

echo "==> Logs (Ctrl+C pour quitter)"
ssh -t "$SERVER" "sudo tail -f $LOG"