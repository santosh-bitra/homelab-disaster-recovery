#!/bin/bash


# This script restores the backup from Restic (S3)


set -Eeuo pipefail

echo "========== Homelab restore started at $(date '+%Y-%m-%d %H:%M:%S') =========="

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

ENV_FILE="/etc/restic/homelab-backup.env"
RESTORE_TARGET="/mnt/homelab-restore"
PRIMARY_USER="bitra"
PRIMARY_HOME="/home/${PRIMARY_USER}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Create it first before running restore."
  exit 1
fi

source "$ENV_FILE"

mkdir -p "$RESTORE_TARGET"

echo "[1/8] Checking repository access..."
restic snapshots >/dev/null

echo "[2/8] Listing available snapshots..."
restic snapshots

echo
echo "By default, latest snapshot will be used."
echo "Press Ctrl+C now if you want to stop."
sleep 5

echo "[3/8] Restoring latest snapshot to staging area: $RESTORE_TARGET"
restic restore latest --target "$RESTORE_TARGET"

echo "[4/8] Restoring critical directories to live filesystem..."

for dir in home root etc opt usr var; do
  if [[ -d "${RESTORE_TARGET}/${dir}" ]]; then
    rsync -aHAX "${RESTORE_TARGET}/${dir}/" "/${dir}/"
  fi
done

echo "[5/8] Recreating ownership for ${PRIMARY_HOME}..."
if id "${PRIMARY_USER}" >/dev/null 2>&1 && [[ -d "${PRIMARY_HOME}" ]]; then
  chown -R "${PRIMARY_USER}:${PRIMARY_USER}" "${PRIMARY_HOME}" || true
fi

echo "[6/8] Reloading systemd..."
systemctl daemon-reload

echo "[7/8] Enabling cron and Docker..."
systemctl enable cron || true
systemctl restart cron || true
systemctl enable docker || true
systemctl restart docker || true

echo "[8/8] Restore finished."
echo
echo "Important manual follow-ups:"
echo "- Review /var/backups/homelab-metadata"
echo "- Reapply netplan only after confirming interface names"
echo "- Review firewall rules before locking yourself out"
echo "- Restart Docker Compose stacks manually"
echo "- Verify OpenClaw paths and services"
echo
echo "========== Homelab restore completed at $(date '+%Y-%m-%d %H:%M:%S') =========="
