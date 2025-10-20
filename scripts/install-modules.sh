#!/usr/bin/env bash
set -euo pipefail

# Odoo Module Installation Script
# Install modules in dependency order with health checks

ODOO_HOST="${ODOO_HOST:-localhost}"
ODOO_PORT="${ODOO_PORT:-8069}"
ODOO_DB="${ODOO_DB:-production}"
DOCKER_COMPOSE_PATH="${DOCKER_COMPOSE_PATH:-/opt/odoo}"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Install Odoo modules in dependency order with health checks.

OPTIONS:
  -h, --help              Show this help message
  -d, --database NAME     Database name (default: production)
  -H, --host HOST         Odoo host (default: localhost)
  -p, --port PORT         Odoo port (default: 8069)
  -m, --mode MODE         Installation mode: cli or ui (default: cli)
  --skip-health-check     Skip pre-installation health check
  --dry-run               Show installation plan without executing

EXAMPLES:
  # Install via CLI (recommended for automation)
  $0 --database production --mode cli

  # Show installation plan
  $0 --dry-run

  # Install via UI (manual)
  $0 --mode ui
EOF
  exit 0
}

# Parse arguments
MODE="cli"
DRY_RUN=false
SKIP_HEALTH_CHECK=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    -d|--database)
      ODOO_DB="$2"
      shift 2
      ;;
    -H|--host)
      ODOO_HOST="$2"
      shift 2
      ;;
    -p|--port)
      ODOO_PORT="$2"
      shift 2
      ;;
    -m|--mode)
      MODE="$2"
      shift 2
      ;;
    --skip-health-check)
      SKIP_HEALTH_CHECK=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      usage
      ;;
  esac
done

# Module installation phases (dependency order)
declare -A MODULE_PHASES

# Phase 1: Base dependencies
MODULE_PHASES[1]="queue_job"

# Phase 2: Core functionality
MODULE_PHASES[2]="knowledge project hr_expense"

# Phase 3: UI enhancements
MODULE_PHASES[3]="web_responsive"

# Phase 4: Custom modules
MODULE_PHASES[4]="hr_expense_ocr_audit"

echo "==> Odoo Module Installation Plan"
echo "Database: $ODOO_DB"
echo "Host: $ODOO_HOST:$ODOO_PORT"
echo "Mode: $MODE"
echo ""

for phase in $(echo "${!MODULE_PHASES[@]}" | tr ' ' '\n' | sort -n); do
  echo "Phase $phase: ${MODULE_PHASES[$phase]}"
done

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "Dry run complete. Use without --dry-run to execute."
  exit 0
fi

# Health check
if [ "$SKIP_HEALTH_CHECK" = false ]; then
  echo ""
  echo "==> Health Check"

  if ! curl -sf "http://$ODOO_HOST:$ODOO_PORT/web/health" >/dev/null; then
    echo "ERROR: Odoo health check failed"
    echo "Ensure Odoo is running: docker compose ps"
    exit 1
  fi

  echo "✅ Odoo is healthy"
fi

# CLI installation
if [ "$MODE" = "cli" ]; then
  echo ""
  echo "==> CLI Installation Mode"

  cd "$DOCKER_COMPOSE_PATH"

  for phase in $(echo "${!MODULE_PHASES[@]}" | tr ' ' '\n' | sort -n); do
    MODULES="${MODULE_PHASES[$phase]}"
    MODULE_LIST=$(echo "$MODULES" | tr ' ' ',')

    echo ""
    echo "Phase $phase: Installing $MODULES"

    docker compose exec -T odoo odoo \
      -d "$ODOO_DB" \
      -i "$MODULE_LIST" \
      --stop-after-init \
      --no-http

    if [ $? -eq 0 ]; then
      echo "✅ Phase $phase complete"
    else
      echo "❌ Phase $phase failed"
      exit 1
    fi
  done

  echo ""
  echo "==> Restarting Odoo"
  docker compose restart odoo

  echo "Waiting for Odoo to be healthy..."
  until curl -sf "http://$ODOO_HOST:$ODOO_PORT/web/health" >/dev/null; do
    sleep 5
  done

  echo "✅ Odoo restarted successfully"

  echo ""
  echo "==> Verifying Module Installation"

  docker compose exec -T db psql -U odoo -d "$ODOO_DB" -t <<'SQL'
SELECT
  name,
  state,
  latest_version
FROM ir_module_module
WHERE name IN (
  'queue_job',
  'knowledge',
  'project',
  'hr_expense',
  'web_responsive',
  'hr_expense_ocr_audit'
)
ORDER BY name;
SQL

  echo ""
  echo "✅ Module installation complete"

elif [ "$MODE" = "ui" ]; then
  echo ""
  echo "==> UI Installation Mode"
  echo ""
  echo "Manual installation steps:"
  echo ""
  echo "1. Navigate to: http://$ODOO_HOST:$ODOO_PORT"
  echo "2. Log in with admin credentials"
  echo "3. Go to: Apps → Update Apps List"
  echo "4. Install modules in order:"
  echo ""

  for phase in $(echo "${!MODULE_PHASES[@]}" | tr ' ' '\n' | sort -n); do
    echo "   Phase $phase:"
    for module in ${MODULE_PHASES[$phase]}; do
      echo "     - $module"
    done
  done

  echo ""
  echo "5. After installation, verify:"
  echo "   Apps → Installed Apps"
  echo ""

else
  echo "ERROR: Invalid mode: $MODE"
  echo "Use 'cli' or 'ui'"
  exit 1
fi

# Final verification
echo ""
echo "==> Final Verification"

INSTALLED_COUNT=$(docker compose exec -T db psql -U odoo -d "$ODOO_DB" -t -c \
  "SELECT COUNT(*) FROM ir_module_module WHERE state='installed' AND name IN ('queue_job','knowledge','project','hr_expense','web_responsive','hr_expense_ocr_audit');" \
  | tr -d ' ')

EXPECTED_COUNT=6

if [ "$INSTALLED_COUNT" -eq "$EXPECTED_COUNT" ]; then
  echo "✅ All $EXPECTED_COUNT modules installed successfully"
else
  echo "⚠️  Expected $EXPECTED_COUNT modules, found $INSTALLED_COUNT installed"
  echo "Run verification query manually:"
  echo "  docker compose exec db psql -U odoo -d $ODOO_DB"
  echo "  SELECT name, state FROM ir_module_module WHERE name IN ('queue_job','knowledge','project','hr_expense','web_responsive','hr_expense_ocr_audit');"
fi

echo ""
echo "==> Next Steps"
echo ""
echo "1. Configure OCR integration:"
echo "   Settings → Technical → System Parameters"
echo "   Add: ocr.api.url, ocr.api.secret, ocr.confidence.threshold"
echo ""
echo "2. Configure queue jobs:"
echo "   Settings → Technical → Job Channels"
echo "   Create channel: 'ocr' with priority 5"
echo ""
echo "3. Test expense OCR:"
echo "   Expenses → New Expense → Upload receipt → Process with OCR"
echo ""
echo "See docs/OCR_SERVICE_DEPLOYMENT.md for complete configuration guide"
