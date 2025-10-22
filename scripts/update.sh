#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Updating Odoo Deployment ===${NC}"

# Pull latest code
echo -e "${YELLOW}Pulling latest code...${NC}"
git pull --recurse-submodules
git submodule update --remote --merge
echo -e "${GREEN}✓ Code updated${NC}"

# Rebuild Odoo image
echo -e "${YELLOW}Rebuilding Odoo image...${NC}"
docker compose build odoo
echo -e "${GREEN}✓ Image rebuilt${NC}"

# Restart Odoo (zero-downtime with healthcheck)
echo -e "${YELLOW}Restarting Odoo...${NC}"
docker compose up -d odoo
echo -e "${GREEN}✓ Odoo restarted${NC}"

# Wait for health check to pass
echo -e "${YELLOW}Waiting for health check...${NC}"
for i in {1..30}; do
  if docker compose exec odoo curl -sf http://localhost:8069/web/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

echo -e "${GREEN}=== Update Complete ===${NC}"
