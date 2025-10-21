#!/bin/bash
# Install Magic Link Authentication Module
# Usage: ./install-magic-link.sh [database_name]

DB="${1:-insightpulse_prod}"
DB_HOST="${2:-odoo-db}"

echo "=================================="
echo "Installing Magic Link Auth to: $DB"
echo "=================================="

# Install the magic link authentication module
docker exec -t odoo18 \
  odoo -d "$DB" --db_host="$DB_HOST" --db_user=odoo --db_password=odoo \
  --without-demo=all --stop-after-init \
  -i auth_magic_link

echo ""
echo "=================================="
echo "✅ Magic Link Auth installed!"
echo "=================================="
echo ""
echo "Access the magic link login at:"
echo "http://your-odoo-url/auth/magic-link-form"
echo ""
echo "Magic link features:"
echo "1. Passwordless authentication"
echo "2. 15-minute expiration"
echo "3. Automatic email delivery"
echo "4. Secure token-based system"
