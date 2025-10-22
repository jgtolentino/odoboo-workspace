#!/usr/bin/env bash
set -euo pipefail

# Configuration
DB_DUMP="${1:-}"
FILESTORE_TAR="${2:-}"
DB_NAME="${POSTGRES_DB:-insightpulse_prod}"
POSTGRES_USER="${POSTGRES_USER:-odoo}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Validation
if [ -z "$DB_DUMP" ] || [ -z "$FILESTORE_TAR" ]; then
  echo -e "${RED}Usage: $0 <db_dump_file> <filestore_tar_file>${NC}"
  echo "Example: $0 backups/db_20251022.dump backups/filestore_20251022.tar.gz"
  exit 1
fi

if [ ! -f "$DB_DUMP" ]; then
  echo -e "${RED}Error: Database dump not found: $DB_DUMP${NC}"
  exit 1
fi

if [ ! -f "$FILESTORE_TAR" ]; then
  echo -e "${RED}Error: Filestore archive not found: $FILESTORE_TAR${NC}"
  exit 1
fi

# Confirmation
echo -e "${YELLOW}WARNING: This will replace the current database and filestore!${NC}"
echo -e "Database: ${DB_NAME}"
echo -e "Dump: ${DB_DUMP}"
echo -e "Filestore: ${FILESTORE_TAR}"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Restore cancelled."
  exit 0
fi

# Stop Odoo to prevent connections during restore
echo -e "${YELLOW}Stopping Odoo...${NC}"
docker compose stop odoo

# Restore database
echo -e "${YELLOW}Restoring database...${NC}"
cat "${DB_DUMP}" | docker compose exec -T db pg_restore \
  -U "${POSTGRES_USER}" \
  -d "${DB_NAME}" \
  --clean --if-exists

echo -e "${GREEN}✓ Database restored${NC}"

# Restore filestore
echo -e "${YELLOW}Restoring filestore...${NC}"
tar -xzf "${FILESTORE_TAR}" -C ./backups
docker cp "./backups/filestore_${DB_NAME}" odoo:/var/lib/odoo/filestore/
rm -rf "./backups/filestore_${DB_NAME}"

echo -e "${GREEN}✓ Filestore restored${NC}"

# Restart Odoo
echo -e "${YELLOW}Starting Odoo...${NC}"
docker compose up -d odoo

echo -e "${GREEN}Restore complete!${NC}"
echo -e "${YELLOW}Please verify the instance at https://insightpulseai.net${NC}"
