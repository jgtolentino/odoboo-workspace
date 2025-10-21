#!/bin/bash
# Install OCA module from GitHub
# Usage: ./install-oca-module.sh [module_name] [oca_repo] [database_name]

MODULE_NAME="${1}"
OCA_REPO="${2:-web}"
DB="${3:-insightpulse_prod}"
OCA_VERSION="${4:-18.0}"

if [ -z "$MODULE_NAME" ]; then
    echo "Usage: ./install-oca-module.sh [module_name] [oca_repo] [database_name] [oca_version]"
    echo ""
    echo "Examples:"
    echo "  ./install-oca-module.sh web_responsive web insightpulse_prod 18.0"
    echo "  ./install-oca-module.sh server_mode server-tools insightpulse_prod 18.0"
    echo ""
    echo "Common OCA repositories:"
    echo "  - web (web_responsive, web_environment_ribbon, etc.)"
    echo "  - server-tools (server_mode, date_range, etc.)"
    echo "  - server-env (server_environment)"
    echo "  - reporting-engine (report_xlsx, etc.)"
    echo "  - account-financial-tools"
    echo "  - partner-contact"
    exit 1
fi

echo "=================================="
echo "Installing OCA Module: $MODULE_NAME"
echo "Repository: OCA/$OCA_REPO"
echo "Version: $OCA_VERSION"
echo "Database: $DB"
echo "=================================="

# Create temp directory
TEMP_DIR="/tmp/oca_install_$$"
mkdir -p "$TEMP_DIR"

echo ""
echo "Step 1/5: Cloning OCA repository..."
cd "$TEMP_DIR"

# Try to clone the specified version, fall back to 17.0 if not available
if git clone --depth 1 --branch "$OCA_VERSION" "https://github.com/OCA/$OCA_REPO.git" 2>/dev/null; then
    echo "✓ Cloned OCA/$OCA_REPO version $OCA_VERSION"
elif git clone --depth 1 --branch 17.0 "https://github.com/OCA/$OCA_REPO.git" 2>/dev/null; then
    echo "⚠ Version $OCA_VERSION not available, using 17.0"
    OCA_VERSION="17.0"
else
    echo "✗ Failed to clone repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check if module exists in repository
if [ ! -d "$OCA_REPO/$MODULE_NAME" ]; then
    echo "✗ Module $MODULE_NAME not found in OCA/$OCA_REPO"
    echo ""
    echo "Available modules in this repository:"
    ls -1 "$OCA_REPO" | grep -v "^\." | head -20
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "Step 2/5: Copying module to Odoo addons..."
# Create OCA addons directory if it doesn't exist
mkdir -p /opt/odoo/addons/oca

# Copy the module
cp -r "$OCA_REPO/$MODULE_NAME" /opt/odoo/addons/oca/
echo "✓ Module copied to /opt/odoo/addons/oca/$MODULE_NAME"

echo ""
echo "Step 3/5: Updating Odoo configuration..."
# Update Odoo config to include OCA path
if ! grep -q "/opt/odoo/addons/oca" /etc/odoo/odoo.conf 2>/dev/null; then
    echo "addons_path = /mnt/extra-addons,/opt/odoo/addons/oca,/var/lib/odoo/addons/18.0,/usr/lib/python3/dist-packages/odoo/addons" >> /etc/odoo/odoo.conf
    echo "✓ Added OCA path to odoo.conf"
else
    echo "✓ OCA path already in odoo.conf"
fi

echo ""
echo "Step 4/5: Installing module in Odoo..."
docker exec -t odoo18 odoo -d "$DB" \
    --db_host=odoo-db \
    --db_user=odoo \
    --db_password=odoo \
    --without-demo=all \
    --stop-after-init \
    -i "$MODULE_NAME"

if [ $? -eq 0 ]; then
    echo "✓ Module installation completed"
else
    echo "✗ Module installation failed"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "Step 5/5: Restarting Odoo..."
docker restart odoo18
sleep 5

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=================================="
echo "✅ OCA Module Installed!"
echo "=================================="
echo ""
echo "Module: $MODULE_NAME"
echo "Version: $OCA_VERSION"
echo "Database: $DB"
echo ""
echo "Next steps:"
echo "1. Go to https://insightpulseai.net?debug=1"
echo "2. Apps menu → Remove 'Apps' filter"
echo "3. Search for '$MODULE_NAME'"
echo "4. Module should show as 'Installed'"
