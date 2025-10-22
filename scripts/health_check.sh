#!/usr/bin/env bash
set -euo pipefail

# Configuration
HEALTH_URL="${HEALTH_URL:-https://insightpulseai.net/web/health}"
POSTGRES_USER="${POSTGRES_USER:-odoo}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Running Health Checks ===${NC}"

# Check 1: Containers running
echo -e "${YELLOW}Checking containers...${NC}"
if ! docker compose ps | grep -q "Up"; then
  echo -e "${RED}✗ Containers not running${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Containers running${NC}"

# Check 2: Database connectivity
echo -e "${YELLOW}Checking database...${NC}"
if ! docker compose exec -T db pg_isready -U "${POSTGRES_USER}" > /dev/null 2>&1; then
  echo -e "${RED}✗ Database not ready${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Database ready${NC}"

# Check 3: Odoo health endpoint (local)
echo -e "${YELLOW}Checking Odoo (local)...${NC}"
if ! curl -sf http://localhost:8069/web/health > /dev/null 2>&1; then
  echo -e "${RED}✗ Odoo health check failed (local)${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Odoo healthy (local)${NC}"

# Check 4: HTTPS endpoint (production)
echo -e "${YELLOW}Checking HTTPS endpoint...${NC}"
if ! curl -sf "${HEALTH_URL}" > /dev/null 2>&1; then
  echo -e "${RED}✗ HTTPS health check failed${NC}"
  exit 1
fi
echo -e "${GREEN}✓ HTTPS endpoint healthy${NC}"

# Check 5: TLS certificate validity
echo -e "${YELLOW}Checking TLS certificate...${NC}"
if ! echo | openssl s_client -servername insightpulseai.net -connect insightpulseai.net:443 2>/dev/null | grep -q "Verify return code: 0"; then
  echo -e "${RED}✗ TLS certificate invalid${NC}"
  exit 1
fi
echo -e "${GREEN}✓ TLS certificate valid${NC}"

echo -e "${GREEN}=== All Health Checks Passed ===${NC}"
