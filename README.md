# homelab-disaster-recovery
During Disaster Recovery, do the below:
 - git clone recovery repo
 - paste env file (Saved in my bit-warden secret notes)
 - run bootstrap
 - run restore


---

```markdown
# Homelab Disaster Recovery System (Restic + S3)

A production-style disaster recovery system for a Linux homelab server using **Restic incremental backups to Amazon S3**, combined with **automated restore and bootstrap scripts**.

This project demonstrates how to build a **cost-efficient, encrypted, automated backup and disaster recovery pipeline** for a self-hosted environment.

The goal is simple:

> If the server dies, rebuild everything in minutes.

---

# Problem

Homelabs evolve quickly and often contain:

- Docker workloads
- Kubernetes configs
- AI tools (OpenClaw, models)
- scripts and automation
- system configurations
- SSH keys and secrets
- databases and application data

If the server fails, recovering manually is slow and error-prone.

Most basic backup solutions also have problems:

| Approach | Problems |
|--------|---------|
| `tar.gz` backups | Full upload every time |
| rsync | No versioning |
| snapshots | not cloud portable |
| manual backups | unreliable |

We need a system that is:

- automated
- incremental
- encrypted
- cloud-stored
- easily restorable

---

# Solution Architecture

This project implements a **3-layer disaster recovery system**.

```

```markdown
Homelab Server
│
│ nightly cron job
▼
Restic Backup Engine
│
│ encrypted + deduplicated
▼
Amazon S3 Repository
│
│ snapshot history
▼
Disaster Recovery Scripts

```

The system consists of:

1. **Restic backup engine**
2. **S3 storage**
3. **automated cron backups**
4. **bootstrap script**
5. **restore script**
6. **post-restore service recovery**

---

# Key Features

- Incremental backups
- client-side encryption
- snapshot versioning
- deduplication
- automated retention policy
- minimal storage cost
- full disaster recovery workflow

---

# Repository Structure

```

homelab-disaster-recovery
│
├── bootstrap
│   └── homelab-bootstrap.sh
│
├── restore
│   ├── homelab-restore.sh
│   └── homelab-post-restore.sh
│
├── backup
│   └── homelab-restic-backup.sh
│
├── config
│   └── homelab-backup.env.example
│
└── docs
└── disaster-recovery-runbook.md

```

---

# Technologies Used

- **Restic** – backup engine
- **Amazon S3** – backup storage
- **Cron** – backup scheduling
- **Docker** – container workloads
- **Linux (Ubuntu)** – base system
- **Bash** – automation

---

# What Gets Backed Up

Critical system areas are included:

```

/home/bitra
/root
/etc
/opt
/usr/local/bin
/usr/local/share
/var/spool/cron
/var/lib/docker/volumes
/var/backups/homelab-metadata

```

These contain:

- scripts
- configs
- Docker volumes
- application state
- SSH keys
- system configuration
- automation tools
- OpenClaw data
- Kubernetes config
- cron jobs

---

# What Is Excluded

To reduce cost and noise:

```

/proc
/sys
/dev
/run
/tmp
/mnt
/media
/var/cache
/home/*/.cache
Docker overlay filesystem

```

These paths contain temporary or rebuildable data.

---

# Backup Workflow

Nightly backup runs via cron:

```

0 2 * * * /usr/local/bin/homelab-restic-backup.sh

```

Backup stages:

1. capture system metadata
2. scan filesystem
3. deduplicate chunks
4. upload only new data
5. create snapshot
6. enforce retention policy

---

# Backup Retention Policy

Snapshots are automatically pruned:

```

Daily snapshots   → 7
Weekly snapshots  → 4
Monthly snapshots → 6

```

This ensures historical backups without unbounded storage growth.

---

# Backup Cost Efficiency

Restic uses:

- chunking
- deduplication
- compression
- encryption

Only **changed data is uploaded**.

Example:

| Backup | Data Uploaded |
|------|---------------|
| first | ~70GB |
| daily after | few MB |

Typical S3 storage cost for homelab:

```

$2 – $5 / month

```

---

# Disaster Recovery Design

Recovery consists of **three steps**.

```

Install Ubuntu
│
run bootstrap script
│
run restore script
│
restart services

```

Total rebuild time:

```

10 – 20 minutes

```

---

# Bootstrap Script

Purpose:

Prepare a fresh server with required tools.

Installs:

- Docker
- Restic
- AWS CLI
- system tools
- networking tools
- firewall
- user accounts

Run:

```

sudo /usr/local/bin/homelab-bootstrap.sh

```

---

# Restore Script

Restores data from the Restic repository.

Process:

1. access S3 repository
2. download snapshot
3. restore to staging directory
4. sync files back to filesystem
5. reload systemd
6. restart Docker and cron

Run:

```

sudo /usr/local/bin/homelab-restore.sh

```

---

# Post-Restore Script

Restarts services and container workloads.

Automatically:

- restarts Docker
- finds docker compose files
- starts containers
- checks failed systemd services

Run:

```

sudo /usr/local/bin/homelab-post-restore.sh

```

---

# Disaster Recovery Runbook

## Step 1

Install fresh Ubuntu.

## Step 2

Run bootstrap script.

```

sudo /usr/local/bin/homelab-bootstrap.sh

```

---

## Step 3

Recreate Restic credentials file.

```

/etc/restic/homelab-backup.env

```

Example:

```

AWS_ACCESS_KEY_ID=xxxx
AWS_SECRET_ACCESS_KEY=xxxx
RESTIC_REPOSITORY=s3:s3.amazonaws.com/bucket-name/homelab
RESTIC_PASSWORD=xxxx

```

---

## Step 4

Restore system backup.

```

sudo /usr/local/bin/homelab-restore.sh

```

---

## Step 5

Reboot server.

```

reboot

```

---

## Step 6

Recover services.

```

sudo /usr/local/bin/homelab-post-restore.sh

```

---

# Validation Checklist

After restore verify:

```

docker ps
systemctl --failed
ls /home/bitra
ls /opt
ls /var/lib/docker/volumes

```

Confirm applications respond correctly.

---

# Security Considerations

Secrets are **never committed to Git**.

Sensitive files:

```

/etc/restic/homelab-backup.env

```

Recommended storage:

- password manager
- encrypted backup
- offline copy

---

# Lessons Learned

Key takeaways from building this system:

- backups must be **tested**
- incremental backups reduce cloud cost
- metadata capture is critical for restore
- automation reduces human error
- disaster recovery should be documented

---

# Future Improvements

Possible enhancements:

- Infrastructure-as-Code server rebuild
- automated health verification
- restore testing pipeline
- multi-region backup replication
- automated Docker stack restart logic

---

# Author

**Santosh Bitra**

DevOps Engineer  
Cloud / Infrastructure Automation Enthusiast

This project is part of my ongoing work building **production-style reliability systems inside a homelab environment**.

---


```

---


1️⃣ **Architecture diagram**

## System Architecture
The backup and disaster recovery system is designed as a **3-layer architecture**:

1. **Backup Automation Layer**
2. **Storage Layer**
3. **Disaster Recovery Layer**

```markdown
flowchart LR

    A[Homelab Server] --> B[Cron Job Scheduler]
    B --> C[Restic Backup Script]

    C --> D[Chunking + Deduplication]
    D --> E[Client-side Encryption]

    E --> F[Amazon S3 Backup Repository]

    F --> G[Snapshot History]

    G --> H[Restore Script]
    H --> I[System Restore]
    I --> J[Post-Restore Service Recovery]

    J --> K[Docker Services Restarted]
    J --> L[OpenClaw / Applications Restored]

2️⃣ **Before/after cost comparison graph for backups**

```markdown
## Backup Storage Cost Comparison

One of the key design goals of this system was **minimizing cloud storage cost**.

Traditional backups (like `tar.gz`) upload the **entire dataset every time**, while Restic uploads **only changed data chunks**.

### Example Scenario

Assume a homelab with **70 GB of data**.

| Backup Type | Upload Size Per Backup | Monthly Storage Estimate |
|-------------|------------------------|--------------------------|
| Full tar backup | 70 GB every backup | Very expensive |
| Rsync mirror | ~70 GB mirror | Medium |
| Restic incremental | only changed data | Very low |

### Realistic Daily Backup Pattern

| Day | Data Changed | Upload Size |
|----|--------------|-------------|
| Day 1 | Initial backup | 70 GB |
| Day 2 | Small changes | 50 MB |
| Day 3 | Logs + configs | 30 MB |
| Day 4 | Minor updates | 20 MB |

### Monthly Cost Example (Amazon S3)
Storage cost ≈ $0.023 per GB per month


| Backup Strategy | Estimated Monthly Cost |
|----------------|-----------------------|
| Full backups daily | $48+ |
| Incremental Restic backups | ~$2-4 |

### Cost Efficiency Graph

```markdown
graph LR
    A[Day 1<br>70GB] --> B[Day 2<br>50MB]
    B --> C[Day 3<br>30MB]
    C --> D[Day 4<br>20MB]
    D --> E[Day 5<br>10MB]

    style A fill:#ffb3b3
    style B fill:#b3e6ff
    style C fill:#b3e6ff
    style D fill:#b3e6ff
    style E fill:#b3e6ff
