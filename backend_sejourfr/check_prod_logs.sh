#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SERVER="root@82.223.165.43"
LOG="/opt/sejourfr/logs/backend-stdout.log"

echo "==> Logs $SERVER (Ctrl+C pour quitter)"
ssh -t "$SERVER" "sudo tail -f $LOG"