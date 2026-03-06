#!/bin/bash
set -Eeuo pipefail

echo "========== Post-restore service recovery started at $(date '+%Y-%m-%d %H:%M:%S') =========="

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

echo "[1/6] Reloading systemd..."
systemctl daemon-reload

echo "[2/6] Restarting Docker..."
systemctl restart docker

echo "[3/6] Restarting container stacks if compose files are found..."
find /opt /home/bitra /root -type f \( -name "docker-compose.yml" -o -name "compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yaml" \) 2>/dev/null | while read -r compose_file; do
  compose_dir="$(dirname "$compose_file")"
  echo "Found compose file: $compose_file"
  echo "Attempting docker compose up -d in: $compose_dir"
  (
    cd "$compose_dir"
    docker compose up -d || true
  )
done

echo "[4/6] Restarting cron..."
systemctl restart cron || true

echo "[5/6] Showing failed systemd units..."
systemctl --failed || true

echo "[6/6] Post-restore recovery complete."
echo "========== Post-restore service recovery finished at $(date '+%Y-%m-%d %H:%M:%S') =========="
