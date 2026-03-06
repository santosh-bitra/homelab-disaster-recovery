#!/bin/bash

### WHAT THIS SCRIPT DOES:
'''
This script is meant to be run on a fresh Ubuntu install after disaster.
  It does not restore your data.
  It prepares the machine so restore can happen cleanly.
  It prepares the skeleton of the machine:

This script does the below:
 - installs admin tools
 - installs Docker
 - installs Restic and AWS CLI
 - enables Docker and cron
 - creates user bitra if missing
 - prepares directories for logs and metadata
 - enables basic SSH firewall access

It is intentionally conservative. No wild stunts, no mysterious framework yoga.
'''


set -Eeuo pipefail

echo "========== Homelab bootstrap started at $(date '+%Y-%m-%d %H:%M:%S') =========="

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

PRIMARY_USER="bitra"
PRIMARY_HOME="/home/${PRIMARY_USER}"

echo "[1/10] Updating apt cache..."
apt update

echo "[2/10] Installing core packages..."
apt install -y \
  curl \
  wget \
  vim \
  nano \
  git \
  unzip \
  zip \
  rsync \
  jq \
  tree \
  htop \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https \
  python3 \
  python3-pip \
  net-tools \
  dnsutils \
  iputils-ping \
  traceroute \
  ufw \
  cron \
  restic \
  awscli \
  lshw

echo "[3/10] Installing Docker if missing..."
if ! command -v docker >/dev/null 2>&1; then
  apt install -y docker.io
fi

echo "[4/10] Enabling Docker and cron..."
systemctl enable docker
systemctl start docker
systemctl enable cron
systemctl start cron

echo "[5/10] Creating primary user if missing..."
if ! id "${PRIMARY_USER}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${PRIMARY_USER}"
fi

echo "[6/10] Adding ${PRIMARY_USER} to docker and sudo groups..."
usermod -aG docker "${PRIMARY_USER}" || true
usermod -aG sudo "${PRIMARY_USER}" || true

echo "[7/10] Creating required directories..."
mkdir -p /etc/restic
mkdir -p /var/log/homelab-backup
mkdir -p /var/backups/homelab-metadata
mkdir -p "${PRIMARY_HOME}"

echo "[8/10] Setting ownership on ${PRIMARY_HOME}..."
chown -R "${PRIMARY_USER}:${PRIMARY_USER}" "${PRIMARY_HOME}"

echo "[9/10] Enabling basic firewall rule for SSH (safe default)..."
ufw allow OpenSSH || true
ufw --force enable || true

echo "[10/10] Bootstrap complete."
echo "========== Homelab bootstrap finished at $(date '+%Y-%m-%d %H:%M:%S') =========="
echo
echo "Next steps:"
echo "1. Recreate /etc/restic/homelab-backup.env"
echo "2. Run the restore script"
echo "3. Reapply networking/firewall tweaks if needed"
echo "4. Restart Docker stacks"
