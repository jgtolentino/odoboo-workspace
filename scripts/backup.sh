#!/usr/bin/env bash
set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="${POSTGRES_DB:-insightpulse_prod}"
POSTGRES_USER="${POSTGRES_USER:-odoo}"
RETENTION_DAYS=14

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting backup...${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup database (PostgreSQL custom format)
echo -e "${YELLOW}Backing up database: ${DB_NAME}${NC}"
docker compose exec -T db pg_dump \
  -U "${POSTGRES_USER}" \
  -Fc "${DB_NAME}" > "${BACKUP_DIR}/db_${DATE}.dump"

echo -e "${GREEN}✓ Database backed up to: ${BACKUP_DIR}/db_${DATE}.dump${NC}"

# Backup filestore
echo -e "${YELLOW}Backing up filestore...${NC}"
docker cp odoo:/var/lib/odoo/filestore/"${DB_NAME}" "${BACKUP_DIR}/filestore_${DB_NAME}"
tar -C "${BACKUP_DIR}" -czf "${BACKUP_DIR}/filestore_${DATE}.tar.gz" "filestore_${DB_NAME}"
rm -rf "${BACKUP_DIR}/filestore_${DB_NAME}"

echo -e "${GREEN}✓ Filestore backed up to: ${BACKUP_DIR}/filestore_${DATE}.tar.gz${NC}"

# Clean old backups (older than RETENTION_DAYS)
echo -e "${YELLOW}Cleaning backups older than ${RETENTION_DAYS} days...${NC}"
find "${BACKUP_DIR}" -name "db_*.dump" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "filestore_*.tar.gz" -mtime +${RETENTION_DAYS} -delete

# Optional: Upload to DigitalOcean Spaces
if [ -n "${DO_SPACES_KEY:-}" ]; then
  echo -e "${YELLOW}Uploading to DigitalOcean Spaces...${NC}"
  s3cmd put "${BACKUP_DIR}/db_${DATE}.dump" "s3://${DO_SPACES_BUCKET}/backups/"
  s3cmd put "${BACKUP_DIR}/filestore_${DATE}.tar.gz" "s3://${DO_SPACES_BUCKET}/backups/"
  echo -e "${GREEN}✓ Backup uploaded to Spaces${NC}"
fi

echo -e "${GREEN}Backup complete!${NC}"
