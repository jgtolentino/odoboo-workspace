#!/usr/bin/env bash
set -euo pipefail

# Odoo backup script - database and filestore
# Usage: ./odoobo-backup.sh

cd /opt/odoobo

DB="insightpulseai.net"
PGUSER="odoo"
DOCKER="/usr/bin/docker"
BACKUP_DIR="/opt/odoobo/backup"
TIMESTAMP=$(date +%F_%H%M)

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Get database container ID
CID_DB="$($DOCKER compose ps -q db)"

if [ -z "$CID_DB" ]; then
    echo "ERROR: Database container not running"
    exit 1
fi

# Database backup (pg_dump with custom format for compression)
echo "Backing up database: $DB"
$DOCKER exec -i "$CID_DB" pg_dump -U "$PGUSER" -Fc "$DB" > "$BACKUP_DIR/db_${TIMESTAMP}.dump"

if [ $? -eq 0 ]; then
    echo "✅ Database backup: $BACKUP_DIR/db_${TIMESTAMP}.dump ($(du -h "$BACKUP_DIR/db_${TIMESTAMP}.dump" | cut -f1))"
else
    echo "❌ Database backup failed"
    exit 1
fi

# Filestore backup (tar.gz of Docker volume)
echo "Backing up filestore..."
VOLUME_NAME=$($DOCKER volume ls -q | grep odoobo_odoo-data || echo "")

if [ -n "$VOLUME_NAME" ]; then
    tar -C /var/lib/docker/volumes -czf "$BACKUP_DIR/fs_${TIMESTAMP}.tar.gz" "$VOLUME_NAME" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Filestore backup: $BACKUP_DIR/fs_${TIMESTAMP}.tar.gz ($(du -h "$BACKUP_DIR/fs_${TIMESTAMP}.tar.gz" | cut -f1))"
    else
        echo "⚠️  Filestore backup failed (non-critical)"
    fi
else
    echo "⚠️  Odoo data volume not found, skipping filestore backup"
fi

# Cleanup old backups (keep 14 days)
echo "Cleaning up old backups (>14 days)..."
find "$BACKUP_DIR" -name "db_*.dump" -mtime +14 -delete
find "$BACKUP_DIR" -name "fs_*.tar.gz" -mtime +14 -delete

echo "✅ Backup complete at $(date)"
