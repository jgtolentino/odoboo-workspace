#!/usr/bin/env bash
set -euo pipefail

# Configuration
HEALTH_URL="${HEALTH_URL:-https://insightpulseai.net/web/health}"
ALERT_EMAIL="${ALERT_EMAIL:-ops@example.com}"

# Check health endpoint
if ! curl -sf "${HEALTH_URL}" > /dev/null 2>&1; then
  echo "❌ Odoo health check failed at $(date)" | mail -s "Odoo DOWN - insightpulseai.net" "${ALERT_EMAIL}"
  exit 1
fi

echo "✅ Odoo health check passed at $(date)"
