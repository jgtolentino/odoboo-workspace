#!/usr/bin/env bash
#
# Automated Odoo Database Backup Script
# ======================================
# Designed for daily cron execution (recommended: 2 AM)
#
# Usage:
#   # Manual run
#   ./scripts/backup_odoo.sh
#
#   # Add to crontab
#   crontab -e
#   # Add line: 0 2 * * * /path/to/odoboo-workspace/scripts/backup_odoo.sh
#
# Environment variables (optional):
#   BACKUP_DIR         - Directory for backups (default: /var/backups/odoo)
#   RETENTION_DAYS     - Days to keep backups (default: 7)
#   DB_NAME            - Database name (default: insightpulse_prod)
#   ODOO_CONTAINER     - Docker container name (default: odoo18)
#   S3_BUCKET          - AWS S3 bucket for cloud backup (optional)
#   SPACES_BUCKET      - DigitalOcean Spaces bucket (optional)
#

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/odoo}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
DB_NAME="${DB_NAME:-insightpulse_prod}"
ODOO_CONTAINER="${ODOO_CONTAINER:-odoo18}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${DB_NAME}_${DATE}.dump"
LOG_FILE="${BACKUP_DIR}/backup.log"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        INFO)  echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$LOG_FILE" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac

    # Also log to syslog
    logger -t "odoo-backup" "$level: $message"
}

error_exit() {
    log ERROR "$1"
    exit 1
}

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

log INFO "Starting Odoo backup for database: $DB_NAME"

# Check if Docker container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${ODOO_CONTAINER}$"; then
    error_exit "Odoo container '${ODOO_CONTAINER}' is not running"
fi

# Create database dump
log INFO "Creating database dump..."
if docker exec "$ODOO_CONTAINER" pg_dump -U odoo -d "$DB_NAME" -F c -f "/tmp/${BACKUP_FILE}"; then
    log SUCCESS "Database dump created: /tmp/${BACKUP_FILE}"
else
    error_exit "Failed to create database dump"
fi

# Copy to host
log INFO "Copying backup to host: ${BACKUP_DIR}/${BACKUP_FILE}"
if docker cp "${ODOO_CONTAINER}:/tmp/${BACKUP_FILE}" "$BACKUP_DIR/"; then
    log SUCCESS "Backup copied to host"
else
    error_exit "Failed to copy backup to host"
fi

# Compress backup
log INFO "Compressing backup..."
if gzip "$BACKUP_DIR/${BACKUP_FILE}"; then
    COMPRESSED_FILE="${BACKUP_FILE}.gz"
    COMPRESSED_SIZE=$(du -h "$BACKUP_DIR/$COMPRESSED_FILE" | cut -f1)
    log SUCCESS "Backup compressed: ${COMPRESSED_FILE} (${COMPRESSED_SIZE})"
else
    error_exit "Failed to compress backup"
fi

# Clean up temporary file in container
docker exec "$ODOO_CONTAINER" rm -f "/tmp/${BACKUP_FILE}" || log WARN "Failed to clean up temp file in container"

# Upload to cloud storage (if configured)
if [[ -n "${S3_BUCKET:-}" ]]; then
    log INFO "Uploading to AWS S3: ${S3_BUCKET}"
    if command -v aws &> /dev/null; then
        if aws s3 cp "$BACKUP_DIR/$COMPRESSED_FILE" "s3://${S3_BUCKET}/odoo-backups/"; then
            log SUCCESS "Backup uploaded to S3"
        else
            log WARN "Failed to upload to S3 (backup still saved locally)"
        fi
    else
        log WARN "AWS CLI not found, skipping S3 upload"
    fi
fi

if [[ -n "${SPACES_BUCKET:-}" ]]; then
    log INFO "Uploading to DigitalOcean Spaces: ${SPACES_BUCKET}"
    if command -v aws &> /dev/null; then
        # Spaces uses S3-compatible API
        if aws s3 cp "$BACKUP_DIR/$COMPRESSED_FILE" "s3://${SPACES_BUCKET}/odoo-backups/" \
            --endpoint-url "https://nyc3.digitaloceanspaces.com"; then
            log SUCCESS "Backup uploaded to Spaces"
        else
            log WARN "Failed to upload to Spaces (backup still saved locally)"
        fi
    else
        log WARN "AWS CLI not found, skipping Spaces upload"
    fi
fi

# Remove old backups (keep only RETENTION_DAYS)
log INFO "Removing backups older than ${RETENTION_DAYS} days..."
REMOVED_COUNT=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.dump.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
if [[ $REMOVED_COUNT -gt 0 ]]; then
    log SUCCESS "Removed $REMOVED_COUNT old backup(s)"
else
    log INFO "No old backups to remove"
fi

# List current backups
CURRENT_BACKUPS=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.dump.gz" | wc -l)
log INFO "Current backup count: $CURRENT_BACKUPS"

# Verify backup integrity (optional)
if command -v pg_restore &> /dev/null; then
    log INFO "Verifying backup integrity..."
    if pg_restore -l "$BACKUP_DIR/$COMPRESSED_FILE" &> /dev/null; then
        log SUCCESS "Backup integrity verified"
    else
        log WARN "Backup integrity check failed (file may be corrupted)"
    fi
fi

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log SUCCESS "Backup completed successfully"
log INFO "Total backup directory size: $TOTAL_SIZE"
log INFO "Latest backup: $COMPRESSED_FILE"

# Send notification (optional - requires mail command)
if command -v mail &> /dev/null && [[ -n "${BACKUP_NOTIFY_EMAIL:-}" ]]; then
    echo "Odoo backup completed: $DB_NAME at $(date)" | \
        mail -s "Odoo Backup Success" "$BACKUP_NOTIFY_EMAIL"
fi

exit 0
