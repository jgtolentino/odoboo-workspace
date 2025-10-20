#!/bin/bash
set -e

# ============================================================================
# PURGE SECRETS FROM GIT HISTORY
# ============================================================================
# This script removes sensitive files that were accidentally committed to git
#
# CRITICAL: After running this script, you MUST rotate ALL exposed secrets!
# ============================================================================

echo "🔐 GIT HISTORY CLEANUP - SENSITIVE FILES REMOVAL"
echo "================================================"
echo ""
echo "⚠️  WARNING: This will rewrite git history!"
echo "⚠️  All collaborators will need to re-clone the repository."
echo "⚠️  This operation is IRREVERSIBLE."
echo ""
echo "Files to be removed from ALL git history:"
echo "  - .env.production"
echo "  - config/odoo.supabase.conf"
echo "  - docker-compose.supabase.yml (contains hardcoded credentials)"
echo ""

# Check if BFG is installed
if ! command -v bfg &> /dev/null; then
    echo "❌ BFG Repo-Cleaner not found!"
    echo ""
    echo "Install with:"
    echo "  macOS:   brew install bfg"
    echo "  Ubuntu:  sudo apt install bfg"
    echo "  Manual:  Download from https://rtyley.github.io/bfg-repo-cleaner/"
    echo ""
    exit 1
fi

# Confirm with user
read -p "Do you want to proceed? (Type 'YES' to continue): " -r
echo
if [[ ! $REPLY == "YES" ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "📋 Step 1: Creating backup..."
echo "------------------------------"

# Create backup of current state
BACKUP_DIR="backup-before-purge-$(date +%F-%H%M%S)"
echo "Creating backup in: ../$BACKUP_DIR"
cd ..
cp -r odoboo-workspace "$BACKUP_DIR"
cd odoboo-workspace

echo "✅ Backup created: ../$BACKUP_DIR"
echo ""
echo "📋 Step 2: Removing files from git tracking..."
echo "----------------------------------------------"

# Remove from current working directory (if they still exist)
git rm --cached .env.production 2>/dev/null || echo ".env.production not in current tree"
git rm --cached config/odoo.supabase.conf 2>/dev/null || echo "odoo.supabase.conf not in current tree"
git rm --cached docker-compose.supabase.yml 2>/dev/null || echo "docker-compose.supabase.yml not in current tree"

echo ""
echo "📋 Step 3: Using BFG to purge from ALL commits..."
echo "-------------------------------------------------"

# Use BFG to remove from entire history
bfg --delete-files .env.production
bfg --delete-files odoo.supabase.conf
bfg --delete-files docker-compose.supabase.yml

echo ""
echo "📋 Step 4: Cleaning up repository..."
echo "------------------------------------"

# Clean up the repository
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "📋 Step 5: Verifying files are removed..."
echo "-----------------------------------------"

# Verify files are gone from history
if git log --all --full-history -- .env.production | grep -q "commit"; then
    echo "⚠️  WARNING: .env.production still found in history!"
else
    echo "✅ .env.production removed from history"
fi

if git log --all --full-history -- config/odoo.supabase.conf | grep -q "commit"; then
    echo "⚠️  WARNING: odoo.supabase.conf still found in history!"
else
    echo "✅ config/odoo.supabase.conf removed from history"
fi

if git log --all --full-history -- docker-compose.supabase.yml | grep -q "commit"; then
    echo "⚠️  WARNING: docker-compose.supabase.yml still found in history!"
else
    echo "✅ docker-compose.supabase.yml removed from history"
fi

echo ""
echo "📋 Step 6: Creating clean versions of removed files..."
echo "------------------------------------------------------"

# Re-create docker-compose.supabase.yml without hardcoded secrets
if [ ! -f docker-compose.supabase.yml ]; then
    cat > docker-compose.supabase.yml << 'EOF'
# docker-compose.supabase.yml - Odoo 18.0 connected to Supabase PostgreSQL
services:
  odoo:
    image: odoo:18.0
    container_name: odoo18-supabase
    ports:
      - "8069:8069"
      - "8072:8072"
    environment:
      # Supabase PostgreSQL connection (use environment variables!)
      - HOST=${DB_HOST}
      - PORT=${DB_PORT}
      - USER=${DB_USER}
      - PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      # Odoo configuration
      - DB_SSLMODE=require
      - LIMIT_TIME_CPU=600
      - LIMIT_TIME_REAL=1200
      - WORKERS=4
      - MAX_CRON_THREADS=2
    volumes:
      - odoo-data:/var/lib/odoo
      - ./addons:/mnt/extra-addons
      - ./oca/social:/mnt/oca/social:ro
      - ./oca/server-ux:/mnt/oca/server-ux:ro
      - ./oca/web:/mnt/oca/web:ro
      - ./config/odoo.supabase.conf:/etc/odoo/odoo.conf:ro
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  odoo-data:
    driver: local
EOF
    echo "✅ Created docker-compose.supabase.yml (using environment variables)"
fi

# Re-create config/odoo.supabase.conf without hardcoded secrets
if [ ! -f config/odoo.supabase.conf ]; then
    cat > config/odoo.supabase.conf << 'EOF'
[options]
# Admin password (set via environment variable or .env file)
admin_passwd = ${ODOO_ADMIN_PASSWORD}

# Supabase PostgreSQL Database settings (use environment variables!)
db_host = ${DB_HOST}
db_port = ${DB_PORT}
db_user = ${DB_USER}
db_password = ${DB_PASSWORD}
db_name = False
db_maxconn = 64
db_template = template0
db_sslmode = require

# Addons paths
addons_path = /mnt/extra-addons,/mnt/oca/social,/mnt/oca/server-ux,/mnt/oca/web,/usr/lib/python3/dist-packages/odoo/addons

# Data directory
data_dir = /var/lib/odoo

# Server configuration
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
limit_time_real_cron = 300

# Network ports
xmlrpc_port = 8069
longpolling_port = 8072

# Proxy mode (required for production)
proxy_mode = True

# Security
list_db = False
dbfilter = ^%d$

# Logging
log_level = info
log_handler = :INFO
logfile = None

# Performance
osv_memory_count_limit = 0
osv_memory_age_limit = 1.0

# Session configuration
session_gc = True

# Server-wide modules
server_wide_modules = base,web
EOF
    echo "✅ Created config/odoo.supabase.conf (using environment variables)"
fi

echo ""
echo "📋 Step 7: Committing cleanup..."
echo "--------------------------------"

# Commit the cleanup
git add .gitignore docker-compose.supabase.yml config/odoo.supabase.conf
git commit -m "security: purge secrets from git history + use environment variables

SECURITY FIX:
- Removed .env.production from ALL git history (contained Supabase credentials)
- Removed config/odoo.supabase.conf from ALL git history (contained DB passwords)
- Removed docker-compose.supabase.yml from history (contained hardcoded secrets)

CHANGES:
- Updated docker-compose.supabase.yml to use environment variables
- Updated config/odoo.supabase.conf to use environment variables
- Updated .gitignore to prevent future commits of sensitive files

ACTION REQUIRED:
- Rotate ALL exposed secrets immediately:
  * Supabase service_role_key
  * Supabase JWT secret
  * PostgreSQL passwords
  * Odoo admin password
  * DigitalOcean API token

See docs/GITHUB_SECRETS_SETUP.md for rotation procedures."

echo ""
echo "✅ CLEANUP COMPLETE!"
echo "==================="
echo ""
echo "📋 Next Steps (CRITICAL):"
echo ""
echo "1. ROTATE ALL EXPOSED SECRETS:"
echo "   - Supabase: Dashboard → Settings → API → Reset service_role_key"
echo "   - Supabase: Dashboard → Settings → Database → Reset password"
echo "   - Odoo: Change admin password"
echo "   - DigitalOcean: API → Tokens → Revoke old token, create new"
echo ""
echo "2. UPDATE ENVIRONMENT VARIABLES:"
echo "   - Copy .env.sample to .env"
echo "   - Fill in NEW rotated secrets"
echo "   - Update GitHub Secrets (see docs/GITHUB_SECRETS_SETUP.md)"
echo ""
echo "3. FORCE PUSH TO REMOTE (⚠️ This rewrites remote history!):"
echo "   git push origin --force --all"
echo "   git push origin --force --tags"
echo ""
echo "4. NOTIFY COLLABORATORS:"
echo "   - All collaborators must delete their local clones"
echo "   - Re-clone repository after force push"
echo "   - Update their local .env files with NEW secrets"
echo ""
echo "5. VERIFY CLEANUP:"
echo "   - Check GitHub: https://github.com/jgtolentino/odoboo-workspace/commits"
echo "   - Verify .env.production is not visible in any commit"
echo "   - Search for exposed strings (old passwords) on GitHub"
echo ""
echo "⚠️  REMINDER: Until you rotate secrets, exposed credentials are still valid!"
echo ""
