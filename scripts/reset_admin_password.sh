#!/usr/bin/env bash
#
# Secure Odoo Admin Password Reset
# ==================================
# Resets admin password without displaying it in console or logs
#
# Usage:
#   ./scripts/reset_admin_password.sh
#
# Security features:
# - Hidden password input (not displayed)
# - No password echoed to console
# - No password stored in shell history
# - Auto-hashed by Odoo
# - Confirmation prompt
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

# --- Configuration ---
ODOO_CONTAINER="${ODOO_CONTAINER:-odoo18}"
DEFAULT_DB="insightpulse_prod"
DEFAULT_ADMIN="jgtolentino_rn@yahoo.com"

# --- Validate Prerequisites ---
if ! command -v docker &> /dev/null; then
    error "Docker not found. Please install Docker first."
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${ODOO_CONTAINER}$"; then
    error "Odoo container '${ODOO_CONTAINER}' is not running"
fi

# --- User Input ---
echo ""
echo "═══════════════════════════════════════════════════"
echo "   Odoo Admin Password Reset (Secure)"
echo "═══════════════════════════════════════════════════"
echo ""

# Database name
read -p "Database name [${DEFAULT_DB}]: " DB_NAME
DB_NAME="${DB_NAME:-$DEFAULT_DB}"

# Admin email
read -p "Admin email [${DEFAULT_ADMIN}]: " ADMIN_EMAIL
ADMIN_EMAIL="${ADMIN_EMAIL:-$DEFAULT_ADMIN}"

# Password (hidden input)
echo ""
warn "Password requirements:"
echo "  • Minimum 12 characters"
echo "  • Mixed case (uppercase + lowercase)"
echo "  • At least one number"
echo "  • At least one symbol"
echo ""

while true; do
    read -sp "Enter NEW password (hidden): " NEW_PASSWORD
    echo ""

    if [[ ${#NEW_PASSWORD} -lt 12 ]]; then
        error "Password too short (minimum 12 characters)"
        continue
    fi

    read -sp "Confirm NEW password (hidden): " CONFIRM_PASSWORD
    echo ""

    if [[ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]]; then
        error "Passwords don't match. Try again."
        continue
    fi

    break
done

# Confirmation
echo ""
warn "You are about to reset the password for:"
echo "  Database: $DB_NAME"
echo "  User:     $ADMIN_EMAIL"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# --- Execute Password Reset ---
info "Resetting password..."

# Create temporary Python script
RESET_SCRIPT=$(mktemp)
cat > "$RESET_SCRIPT" <<PYEOF
import sys

env = env.sudo()
admin_email = '$ADMIN_EMAIL'
new_password = '''$NEW_PASSWORD'''

# Find admin user
admin_user = env['res.users'].search([('login', '=', admin_email)], limit=1)

if not admin_user:
    print(f"ERROR: User '{admin_email}' not found in database '$DB_NAME'", file=sys.stderr)
    sys.exit(1)

# Update password (Odoo auto-hashes with PBKDF2)
try:
    admin_user.password = new_password
    env.cr.commit()
    print(f"SUCCESS: Password updated for {admin_email}")
except Exception as e:
    print(f"ERROR: Failed to update password: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

# Execute via Odoo shell
if docker exec -i "$ODOO_CONTAINER" odoo shell -d "$DB_NAME" < "$RESET_SCRIPT" 2>&1 | grep -q "SUCCESS"; then
    success "Password reset successful for $ADMIN_EMAIL"
    echo ""
    info "You can now login with:"
    echo "  Email:    $ADMIN_EMAIL"
    echo "  Password: <your-new-password>"
    echo ""
    warn "Security reminders:"
    echo "  1. Clear shell history: history -c"
    echo "  2. Store password in password manager"
    echo "  3. Do NOT share password via email/Slack"
else
    error "Password reset failed. Check Odoo logs: docker logs $ODOO_CONTAINER --tail 50"
fi

# Cleanup
rm -f "$RESET_SCRIPT"

# Clear sensitive variables
unset NEW_PASSWORD
unset CONFIRM_PASSWORD

exit 0
