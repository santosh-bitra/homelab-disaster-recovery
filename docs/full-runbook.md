DISASTER RECOVERY RUNBOOK
Scenario

Your homelab disk dies, OS is corrupted, or server is unrecoverable.

Step 0 — What you need before starting

You need:

fresh Ubuntu installed on replacement server/disk

internet connectivity

SSH access or console access

the contents of your Restic env file:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

RESTIC_REPOSITORY

RESTIC_PASSWORD

Step 1 — Install fresh Ubuntu

Install Ubuntu normally.

During setup:

create a temporary admin user if needed

ensure SSH can be enabled

ensure internet works

Once logged in, become root:

sudo -i
Step 2 — Put the bootstrap script on the new server

Create the script:

nano /usr/local/bin/homelab-bootstrap.sh

Paste the bootstrap script content from above, save, then:

chmod +x /usr/local/bin/homelab-bootstrap.sh

Run it:

/usr/local/bin/homelab-bootstrap.sh

This prepares the base machine.

Step 3 — Recreate the Restic env file

Create:

nano /etc/restic/homelab-backup.env

Add:

export AWS_ACCESS_KEY_ID="YOUR_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET"
export RESTIC_REPOSITORY="s3:s3.amazonaws.com/bitra-cloud-backup/homelab"
export RESTIC_PASSWORD="YOUR_RESTIC_PASSWORD"

Lock it:

chmod 600 /etc/restic/homelab-backup.env
chown root:root /etc/restic/homelab-backup.env

Test repository access:

source /etc/restic/homelab-backup.env
restic snapshots

You should see snapshots listed.

Step 4 — Put the restore script on the new server

Create:

nano /usr/local/bin/homelab-restore.sh

Paste the restore script content, save, then:

chmod +x /usr/local/bin/homelab-restore.sh

Run it:

/usr/local/bin/homelab-restore.sh

This will:

restore latest snapshot to staging

copy restored files back into /

reload systemd

restart cron and Docker

Step 5 — Reboot once

After restore:

reboot

This helps:

reload service units

re-read configs

make restored environment settle cleanly

Step 6 — Restart services and Docker stacks

After reboot, become root again:

sudo -i

Create/run the post-restore script:

/usr/local/bin/homelab-post-restore.sh

This will try to:

restart Docker

detect Compose files

bring stacks up

Step 7 — Verify the machine

Check these one by one:

Core checks
systemctl status docker --no-pager
systemctl status cron --no-pager
systemctl --failed
Restore checks
ls /home/bitra
ls /root
ls /opt
ls /var/backups/homelab-metadata
Docker checks
docker ps -a
docker volume ls
docker network ls
SSH/config checks
ls -la /home/bitra/.ssh
ls -la /root/.ssh
OpenClaw checks
find /opt /home/bitra /root -maxdepth 3 \( -iname "*openclaw*" -o -iname ".openclaw" \) 2>/dev/null
Step 8 — Review network config before applying anything risky

If your old server used custom netplan or interface config, do not blindly apply it before checking interface names.

Check:

ip a
ls /etc/netplan
cat /etc/netplan/*.yaml

Interface names may differ on new hardware.

Apply carefully:

netplan try

Use netplan try, not instant apply, unless you enjoy accidental self-lockout.

Step 9 — Reapply firewall carefully

Check saved firewall-related files:

cat /var/backups/homelab-metadata/ufw-status.txt
cat /var/backups/homelab-metadata/iptables.txt

Make sure SSH remains allowed before changing firewall rules.

Step 10 — Final validation

Confirm that:

SSH works

Docker services are up

OpenClaw works

cron jobs exist

your scripts exist

mounted disks look correct

important apps respond

At that point your homelab is back.

6) Recommended improvement: pin exact snapshots during restore

Right now the restore script uses:

restic restore latest

That is fine for quick recovery.

But if you ever want to restore a specific snapshot, use:

restic snapshots
restic restore <SNAPSHOT_ID> --target /mnt/homelab-restore

That is useful if latest backup captured some bad config or corruption.

7) Strongly recommended: save these three scripts outside the server too

Keep copies of:

homelab-bootstrap.sh

homelab-restore.sh

homelab-post-restore.sh

Store them somewhere outside this server:

Git repo

private notes vault

secure cloud drive

password manager attachment

USB drive

Because if the server is gone, scripts stored only on the server are comedy, not recovery.

8) Tiny machine-specific notes for your setup

Because your homelab likely includes Docker/OpenClaw and maybe some custom drivers:

OpenClaw

After restore, verify:

config file paths

bind addresses

env files

Docker or systemd startup mode

Drivers

Since you had folders like:

/root/8821au-20210708

/root/rtl8812au

the source folders restore, but kernel modules may need reinstall/rebuild on a fresh OS kernel.

That means:

source is recovered

active kernel module state is not “magically live” until rebuilt/loaded if needed

Kubernetes

If this box is only a kubectl client, your kube config likely restores fine.

If it is a control-plane node, that is a different beast. Then you’d want dedicated recovery handling for:

/etc/kubernetes

/var/lib/etcd

That would deserve its own runbook.

9) My blunt recommendation

Right now, do these next on your current healthy server:

Save the scripts

Create the three scripts now.

Test the restore non-destructively

Do this:

sudo mkdir -p /tmp/restore-test
sudo bash -c 'source /etc/restic/homelab-backup.env && restic restore latest --target /tmp/restore-test'

Then inspect:

ls /tmp/restore-test/home/bitra
ls /tmp/restore-test/root
ls /tmp/restore-test/etc
ls /tmp/restore-test/opt

That proves the restore path works.

Save the env file contents somewhere safe

This is absolutely mandatory.

10) Super short disaster version

If catastrophe happens, the compact version is:

Install Ubuntu
sudo -i
Create /usr/local/bin/homelab-bootstrap.sh
Run bootstrap
Recreate /etc/restic/homelab-backup.env
Create /usr/local/bin/homelab-restore.sh
Run restore
Reboot
Run post-restore
Verify Docker/OpenClaw/network/firewall

That’s your phoenix ritual.
