#!/usr/bin/env bash
set -euo pipefail

# Configuration
URL="${1:-https://insightpulseai.net}"
DB_NAME="${POSTGRES_DB:-insightpulse_prod}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Setting base URL to: ${URL}${NC}"

# Configure domain locking via Odoo shell
docker compose exec -T odoo odoo shell -d "${DB_NAME}" <<PYTHON
# Set base URL and freeze it
env['ir.config_parameter'].sudo().set_param('web.base.url', '${URL}')
env['ir.config_parameter'].sudo().set_param('web.base.url.freeze', 'True')

# Disable Odoo SaaS endpoints
env['ir.config_parameter'].sudo().set_param('publisher_warranty_url', '')
env['ir.config_parameter'].sudo().set_param('iap.endpoint', 'http://localhost')
env['ir.config_parameter'].sudo().set_param('database.expiration_date', '')

env.cr.commit()
print("✓ Base URL configured and locked to: ${URL}")
print("✓ SaaS features disabled")
PYTHON

echo -e "${GREEN}Domain locking complete!${NC}"
echo -e "The instance will only respond to: ${URL}"
