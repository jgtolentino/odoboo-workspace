#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Odoo 18 Production Bootstrap ===${NC}"

# Initialize OCA submodules
echo -e "${YELLOW}Initializing OCA submodules...${NC}"
git submodule update --init --recursive
echo -e "${GREEN}✓ Submodules initialized${NC}"

# Build Odoo image
echo -e "${YELLOW}Building Odoo image...${NC}"
docker compose build odoo
echo -e "${GREEN}✓ Image built${NC}"

# Start services
echo -e "${YELLOW}Starting services...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Services started${NC}"

# Wait for Odoo health check
echo -e "${YELLOW}Waiting for Odoo to be ready...${NC}"
for i in {1..30}; do
  if docker compose exec odoo curl -sf http://localhost:8069/web/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Odoo is healthy${NC}"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo -e "Next steps:"
echo -e "1. Restore production data: make restore DB_DUMP=<dump> FILESTORE_TAR=<tar>"
echo -e "2. Set base URL: make set-base-url URL=https://insightpulseai.net"
echo -e "3. Run health checks: make health"
