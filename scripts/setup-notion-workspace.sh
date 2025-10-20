#!/bin/bash
#
# Notion-Style Workspace Setup for Odoo 18
# This script installs all required modules and sets up the workspace
#
# Usage:
#   ssh root@188.166.237.231
#   cd /opt/odoo
#   ./setup-notion-workspace.sh
#

set -e

echo "════════════════════════════════════════════════════════════════"
echo "  Notion-Style Workspace Setup for Odoo 18"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Configuration
ODOO_CONTAINER="odoo18"
ODOO_DB="odoo_production"
ODOO_USER="odoo"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
step() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# Step 1: Check prerequisites
step "Checking prerequisites..."
if ! docker ps | grep -q "$ODOO_CONTAINER"; then
    error "Odoo container '$ODOO_CONTAINER' is not running"
    exit 1
fi
success "Odoo container is running"

# Step 2: Download OCA repositories
step "Downloading OCA repositories..."

OCA_DIR="/opt/odoo/addons/oca"
mkdir -p "$OCA_DIR"
cd "$OCA_DIR"

# Core OCA repositories for Notion-style workspace
OCA_REPOS=(
    "knowledge"           # Wiki/Knowledge base (document_page)
    "dms"                 # Document Management System
    "web"                 # Web enhancements (responsive, PWA)
    "server-tools"        # Server utilities (auditlog, etc.)
    "project"             # Project management enhancements
    "social"              # Mail tracking, activity board
    "mis-builder"         # Dashboards and BI
    "reporting-engine"    # Advanced reporting (XLSX export)
    "queue"               # Background job processing
    "server-ux"           # UX enhancements
    "attachment-indexation" # Full-text search for attachments
    "storage"             # External storage (DO Spaces)
)

for repo in "${OCA_REPOS[@]}"; do
    if [ -d "$repo/.git" ]; then
        warning "$repo already exists, skipping..."
    else
        echo "  Cloning $repo..."
        git clone --depth 1 --branch 18.0 "https://github.com/OCA/$repo.git" || \
            warning "Failed to clone $repo (may not exist for Odoo 18)"
    fi
done

success "OCA repositories downloaded"

# Step 3: Update docker-compose.yml to mount OCA addons
step "Updating docker-compose.yml..."

# Backup original docker-compose.yml
if [ -f /root/docker-compose.yml ]; then
    cp /root/docker-compose.yml /root/docker-compose.yml.backup.$(date +%Y%m%d-%H%M%S)
    success "Backup created"
fi

# Check if OCA volumes are already added
if grep -q "# OCA Addons" /root/docker-compose.yml; then
    warning "OCA volumes already configured in docker-compose.yml"
else
    echo "  Adding OCA volume mounts..."
    # Add OCA volumes to odoo service
    # Note: This is a simple append - you may need to adjust manually
    cat >> /root/docker-compose-oca-volumes.yml << 'EOF'
# OCA Addons Volumes
# Add these under the odoo service volumes section:
      - /opt/odoo/addons/oca/knowledge:/mnt/extra-addons/oca-knowledge
      - /opt/odoo/addons/oca/dms:/mnt/extra-addons/oca-dms
      - /opt/odoo/addons/oca/web:/mnt/extra-addons/oca-web
      - /opt/odoo/addons/oca/server-tools:/mnt/extra-addons/oca-server-tools
      - /opt/odoo/addons/oca/project:/mnt/extra-addons/oca-project
      - /opt/odoo/addons/oca/social:/mnt/extra-addons/oca-social
      - /opt/odoo/addons/oca/mis-builder:/mnt/extra-addons/oca-mis-builder
      - /opt/odoo/addons/oca/reporting-engine:/mnt/extra-addons/oca-reporting-engine
      - /opt/odoo/addons/oca/queue:/mnt/extra-addons/oca-queue
      - /opt/odoo/addons/oca/server-ux:/mnt/extra-addons/oca-server-ux
      - /opt/odoo/addons/oca/attachment-indexation:/mnt/extra-addons/oca-attachment-indexation
      - /opt/odoo/addons/oca/storage:/mnt/extra-addons/oca-storage
EOF
    warning "OCA volumes written to docker-compose-oca-volumes.yml"
    warning "Please manually merge these into your docker-compose.yml odoo service"
fi

# Step 4: Update odoo.conf to include OCA addons path
step "Updating Odoo configuration..."

docker exec -i "$ODOO_CONTAINER" bash << 'BASH_SCRIPT'
if ! grep -q "oca-" /etc/odoo/odoo.conf; then
    echo "  Adding OCA addons paths to odoo.conf..."
    sed -i 's|addons_path = .*|addons_path = /mnt/extra-addons,/mnt/extra-addons/oca-knowledge,/mnt/extra-addons/oca-dms,/mnt/extra-addons/oca-web,/mnt/extra-addons/oca-server-tools,/mnt/extra-addons/oca-project,/mnt/extra-addons/oca-social,/mnt/extra-addons/oca-mis-builder,/mnt/extra-addons/oca-reporting-engine,/mnt/extra-addons/oca-queue,/mnt/extra-addons/oca-server-ux,/mnt/extra-addons/oca-attachment-indexation,/mnt/extra-addons/oca-storage|' /etc/odoo/odoo.conf
    echo "✓ Addons path updated"
else
    echo "⚠ OCA addons paths already configured"
fi
BASH_SCRIPT

success "Odoo configuration updated"

# Step 5: Restart Odoo to recognize new addons
step "Restarting Odoo container..."
docker restart "$ODOO_CONTAINER"
echo "  Waiting for Odoo to start..."
sleep 15
success "Odoo restarted"

# Step 6: Update module list
step "Updating Odoo module list..."

docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" << 'ODOO_SHELL'
print("Updating module list...")
env['ir.module.module'].update_list()
env.cr.commit()
print("✓ Module list updated")
exit()
ODOO_SHELL

success "Module list updated"

# Step 7: Install core modules
step "Installing core Odoo modules..."

CORE_MODULES=(
    "project"
    "hr_expense"
    "calendar"
    "mail"
    "contacts"
    "documents"
)

docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" << ODOO_SHELL
modules_to_install = [
    'project',
    'hr_expense',
    'calendar',
    'mail',
    'contacts',
]

installed_count = 0
for module_name in modules_to_install:
    module = env['ir.module.module'].search([('name', '=', module_name)])
    if module and module.state == 'uninstalled':
        print(f"Installing {module_name}...")
        module.button_immediate_install()
        installed_count += 1
        print(f"✓ {module_name} installed")
    elif module and module.state == 'installed':
        print(f"⏭️  {module_name} already installed")
    else:
        print(f"⚠️  {module_name} not found")

env.cr.commit()
print(f"\n✓ Installed {installed_count} core modules")
exit()
ODOO_SHELL

success "Core modules installed"

# Step 8: Install OCA modules
step "Installing OCA modules for Notion-style workspace..."

docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" << 'ODOO_SHELL'
oca_modules = [
    # Knowledge & Wiki (Notion-style pages)
    'document_page',              # Wiki/knowledge pages
    'document_page_approval',     # Approval workflow
    'document_page_tag',          # Tagging

    # Document Management (Notion-style files)
    'dms',                        # Full DMS
    'attachment_indexation',      # Full-text search
    'attachment_preview',         # File previews

    # Web Enhancements
    'web_responsive',             # Mobile-friendly UI
    'web_pwa_oca',                # Progressive Web App
    'web_notify',                 # Toast notifications
    'web_advanced_search',        # Advanced filters

    # Project Management
    'project_stage_closed',       # Closed stages
    'project_task_dependency',    # Task dependencies
    'project_task_add_very_high', # Priority levels
    'project_timeline',           # Gantt-style timeline
    'project_template',           # Project templates
    'project_task_code',          # Task numbering

    # Mail & Communication
    'mail_tracking',              # Email read receipts
    'mail_activity_board',        # Activity Kanban
    'mail_debrand',               # Remove Odoo branding

    # Dashboards & Analytics
    'mis_builder',                # KPI dashboards
    'bi_sql_editor',              # SQL query builder
    'kpi_dashboard',              # KPI widgets

    # Reporting
    'report_xlsx',                # Excel exports
    'base_report_to_printer',     # Print queues

    # Background Jobs
    'queue_job',                  # Job queue

    # Audit & Security
    'auditlog',                   # Audit trail
    'password_security',          # Password policies
]

installed_count = 0
not_found = []
already_installed = []

print("Installing OCA modules...")
print("=" * 60)

for module_name in oca_modules:
    module = env['ir.module.module'].search([('name', '=', module_name)])
    if module and module.state == 'uninstalled':
        try:
            print(f"Installing {module_name}...")
            module.button_immediate_install()
            installed_count += 1
            print(f"✓ {module_name} installed")
        except Exception as e:
            print(f"✗ {module_name} failed: {str(e)[:100]}")
    elif module and module.state == 'installed':
        already_installed.append(module_name)
    else:
        not_found.append(module_name)

env.cr.commit()

print("\n" + "=" * 60)
print(f"✓ Installed {installed_count} OCA modules")
print(f"⏭️  Already installed: {len(already_installed)}")
print(f"⚠️  Not found: {len(not_found)}")

if not_found:
    print("\nModules not found (may not exist for Odoo 18):")
    for m in not_found:
        print(f"  - {m}")

exit()
ODOO_SHELL

success "OCA modules installation complete"

# Step 9: Summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✓ Notion-Style Workspace Setup Complete!${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Access Odoo: https://insightpulseai.net:8069"
echo "  2. Run base records setup: ./setup-base-records.py"
echo "  3. Import data using CSV templates in data/templates/"
echo "  4. Configure workflows: ./setup-workflows.py"
echo ""
echo "Documentation:"
echo "  - See docs/NOTION_WORKSPACE_GUIDE.md for complete guide"
echo "  - CSV templates: data/templates/"
echo "  - Import scripts: scripts/"
echo ""
