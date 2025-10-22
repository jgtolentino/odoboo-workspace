#!/usr/bin/env bash
set -euo pipefail

# Comprehensive Odoo health check script
# Usage: ./odoobo-health.sh [--alert-email email@example.com]

ALERT_EMAIL="${1:-${ALERT_EMAIL:-ops@example.com}}"
HEALTH_URL="https://insightpulseai.net/web/health"
DOMAIN="insightpulseai.net"
COMPOSE_DIR="/opt/odoobo"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FAILED_CHECKS=0

check() {
    local name="$1"
    shift
    echo -n "Checking ${name}... "
    if "$@" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED_CHECKS++))
        return 1
    fi
}

header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 1. External Smoke Tests
header "1. EXTERNAL SMOKE TESTS"

check "HTTP health endpoint" curl -sf "${HEALTH_URL}"

check "DNS resolution" dig +short "${DOMAIN}" A

check "TLS certificate valid" bash -c "echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null | openssl x509 -noout -checkend 604800"

# Response time check
RESPONSE=$(curl -sS -o /dev/null -w '%{http_code} %{time_connect}s %{time_starttransfer}s' "${HEALTH_URL}" 2>&1 || echo "000 0 0")
HTTP_CODE=$(echo "$RESPONSE" | awk '{print $1}')
CONNECT_TIME=$(echo "$RESPONSE" | awk '{print $2}')
TTFB=$(echo "$RESPONSE" | awk '{print $3}')

echo "  HTTP ${HTTP_CODE}, Connect: ${CONNECT_TIME}, TTFB: ${TTFB}"

if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}  ❌ HTTP status code not 200${NC}"
    ((FAILED_CHECKS++))
fi

# 2. Droplet Health
header "2. DROPLET HEALTH"

# Uptime
UPTIME=$(uptime)
echo "  Uptime: ${UPTIME}"

# Memory check (warn if >80%)
MEMORY=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
MEMORY_INT=${MEMORY%.*}
echo -n "  Memory usage: ${MEMORY_INT}%... "
if [ "$MEMORY_INT" -lt 80 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  HIGH${NC}"
fi

# Disk check (warn if >85%)
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo -n "  Disk usage: ${DISK}%... "
if [ "$DISK" -lt 85 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  HIGH${NC}"
fi

# Load average
LOAD=$(cat /proc/loadavg | awk '{print $1}')
echo "  Load average (1min): ${LOAD}"

# 3. Docker Stack
header "3. DOCKER STACK"

cd "${COMPOSE_DIR}" || exit 1

check "Docker daemon" docker ps

check "Compose project running" docker compose ps

# Container health checks
for service in db odoo traefik; do
    HEALTH=$(docker inspect "odoobo-${service}-1" --format='{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
    echo -n "  ${service} health: ${HEALTH}... "
    if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "no-healthcheck" ]; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        ((FAILED_CHECKS++))
    fi
done

# 4. Application Probes
header "4. APPLICATION PROBES"

# Traefik logs (check for recent errors)
TRAEFIK_ERRORS=$(docker logs --since 10m odoobo-traefik-1 2>&1 | grep -c "ERR" || echo 0)
echo -n "  Traefik errors (last 10min): ${TRAEFIK_ERRORS}... "
if [ "$TRAEFIK_ERRORS" -lt 5 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  ${TRAEFIK_ERRORS} errors${NC}"
fi

# Odoo logs (check for recent errors)
ODOO_ERRORS=$(docker logs --since 10m odoobo-odoo-1 2>&1 | grep -c "ERROR\|CRITICAL" || echo 0)
echo -n "  Odoo errors (last 10min): ${ODOO_ERRORS}... "
if [ "$ODOO_ERRORS" -lt 5 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  ${ODOO_ERRORS} errors${NC}"
fi

# PostgreSQL connectivity
check "PostgreSQL connectivity" docker exec odoobo-db-1 psql -U odoo -d insightpulseai.net -c "SELECT 1"

# Database user count
USER_COUNT=$(docker exec odoobo-db-1 psql -U odoo -d insightpulseai.net -t -c "SELECT COUNT(*) FROM res_users" | tr -d ' ')
echo "  Database users: ${USER_COUNT}"

# 5. Backup Verification
header "5. BACKUP VERIFICATION"

# Check backup directory
if [ -d "${COMPOSE_DIR}/backup" ]; then
    echo -e "  Backup directory: ${GREEN}✅ exists${NC}"

    # Check latest backup
    LATEST_DB=$(ls -t "${COMPOSE_DIR}/backup/db_"*.dump 2>/dev/null | head -1 || echo "")
    LATEST_FS=$(ls -t "${COMPOSE_DIR}/backup/filestore_"*.tgz 2>/dev/null | head -1 || echo "")

    if [ -n "$LATEST_DB" ]; then
        DB_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_DB")) / 86400 ))
        echo "  Latest DB backup: $(basename "$LATEST_DB") (${DB_AGE} days old)"
    else
        echo -e "  ${YELLOW}⚠️  No database backups found${NC}"
    fi

    if [ -n "$LATEST_FS" ]; then
        FS_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_FS")) / 86400 ))
        echo "  Latest filestore backup: $(basename "$LATEST_FS") (${FS_AGE} days old)"
    else
        echo -e "  ${YELLOW}⚠️  No filestore backups found${NC}"
    fi
else
    echo -e "  ${RED}❌ Backup directory not found${NC}"
    ((FAILED_CHECKS++))
fi

# Check cron jobs
if [ -f "/etc/cron.d/odoobo_backup" ]; then
    echo -e "  Backup cron jobs: ${GREEN}✅ installed${NC}"
else
    echo -e "  ${RED}❌ Backup cron jobs not found${NC}"
    ((FAILED_CHECKS++))
fi

# 6. Security Checks
header "6. SECURITY CHECKS"

# Check firewall
UFW_STATUS=$(ufw status | head -1)
echo "  Firewall: ${UFW_STATUS}"

# Check Traefik security headers
HEADERS=$(curl -sI "https://${DOMAIN}/web" | grep -E "Strict-Transport-Security|X-Frame-Options|Content-Security-Policy" | wc -l)
echo -n "  Security headers: ${HEADERS}/3... "
if [ "$HEADERS" -ge 3 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  Missing headers${NC}"
fi

# 7. Resource Usage Summary
header "7. RESOURCE USAGE"

# Docker container stats (single snapshot)
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep odoobo

# 8. Summary
header "8. HEALTH CHECK SUMMARY"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ ${FAILED_CHECKS} check(s) failed${NC}"

    # Send alert email if configured
    if command -v mail &>/dev/null && [ -n "$ALERT_EMAIL" ]; then
        echo "Odoo health check failed with ${FAILED_CHECKS} issues on $(hostname) at $(date)" | \
            mail -s "⚠️  Odoo Health Check FAILED - ${DOMAIN}" "${ALERT_EMAIL}"
        echo "Alert email sent to ${ALERT_EMAIL}"
    fi

    exit 1
fi
