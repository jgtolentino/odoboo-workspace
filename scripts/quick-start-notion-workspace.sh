#!/bin/bash
#
# Quick Start: Complete Notion-Style Workspace Setup
# Runs all setup steps in sequence
#
# Usage:
#   ssh root@188.166.237.231
#   cd /opt/odoo/scripts
#   ./quick-start-notion-workspace.sh
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════════════════════════"
echo "                    Notion-Style Workspace - Quick Start"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}This script will:${NC}"
echo "  1. Install required OCA modules"
echo "  2. Create base records (projects, folders, tags)"
echo "  3. Configure custom fields"
echo "  4. Setup workflow automations"
echo "  5. Import sample data (optional)"
echo ""
echo -e "${YELLOW}⏱️  Estimated time: 15-20 minutes${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Configuration
ODOO_CONTAINER="odoo18"
ODOO_DB="odoo_production"
SCRIPTS_DIR="/opt/odoo/scripts"

# Check prerequisites
echo ""
echo -e "${BLUE}▶ Checking prerequisites...${NC}"

if ! docker ps | grep -q "$ODOO_CONTAINER"; then
    echo -e "${RED}✗ Odoo container '$ODOO_CONTAINER' is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Odoo container is running${NC}"

if ! docker exec "$ODOO_CONTAINER" psql -U odoo -d "$ODOO_DB" -c "SELECT 1" &>/dev/null; then
    echo -e "${RED}✗ Cannot connect to database '$ODOO_DB'${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database connection OK${NC}"

# Step 1: Install modules
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}Step 1/5: Installing Modules${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

if [ -f "$SCRIPTS_DIR/setup-notion-workspace.sh" ]; then
    chmod +x "$SCRIPTS_DIR/setup-notion-workspace.sh"
    "$SCRIPTS_DIR/setup-notion-workspace.sh"
else
    echo -e "${YELLOW}⚠️  setup-notion-workspace.sh not found, skipping module installation${NC}"
    echo "   You may need to install modules manually via Web UI"
fi

# Step 2: Create base records
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}Step 2/5: Creating Base Records${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

if [ -f "$SCRIPTS_DIR/setup-base-records.py" ]; then
    docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" < "$SCRIPTS_DIR/setup-base-records.py"
    echo -e "${GREEN}✓ Base records created${NC}"
else
    echo -e "${RED}✗ setup-base-records.py not found${NC}"
    exit 1
fi

# Step 3: Create custom fields
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}Step 3/5: Creating Custom Fields${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

if [ -f "$SCRIPTS_DIR/setup-custom-fields.py" ]; then
    docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" < "$SCRIPTS_DIR/setup-custom-fields.py"
    echo -e "${GREEN}✓ Custom fields created${NC}"
else
    echo -e "${RED}✗ setup-custom-fields.py not found${NC}"
    exit 1
fi

# Step 4: Setup workflows
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}Step 4/5: Setting Up Workflows & Automations${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

if [ -f "$SCRIPTS_DIR/setup-workflows.py" ]; then
    docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" < "$SCRIPTS_DIR/setup-workflows.py"
    echo -e "${GREEN}✓ Workflows configured${NC}"
else
    echo -e "${RED}✗ setup-workflows.py not found${NC}"
    exit 1
fi

# Step 5: Import sample data (optional)
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}Step 5/5: Import Sample Data (Optional)${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

read -p "Import sample data (tasks, calendar, evidence, knowledge)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if CSV files exist
    DATA_DIR="/opt/odoo/data/templates"
    if [ -d "$DATA_DIR" ] && [ "$(ls -A $DATA_DIR/*.csv 2>/dev/null)" ]; then
        # Copy CSV files to container
        echo "  Copying CSV files to container..."
        docker cp "$DATA_DIR"/*.csv "$ODOO_CONTAINER":/tmp/

        # Run import script
        if [ -f "$SCRIPTS_DIR/bulk-import-data.py" ]; then
            docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" < "$SCRIPTS_DIR/bulk-import-data.py"
            echo -e "${GREEN}✓ Sample data imported${NC}"
        else
            echo -e "${YELLOW}⚠️  bulk-import-data.py not found, skipping data import${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No CSV files found in $DATA_DIR${NC}"
        echo "   You can import data manually later via Web UI"
    fi
else
    echo "  Skipping sample data import"
fi

# Restart Odoo to apply all changes
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}▶ Restarting Odoo to apply changes...${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

docker restart "$ODOO_CONTAINER"
echo "  Waiting for Odoo to start..."
sleep 20

# Verify setup
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}▶ Verifying Setup...${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"

docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" << 'VERIFY_SCRIPT'
print("\nChecking installation...")
print("=" * 60)

# Check modules
modules = ['project', 'calendar', 'document_page', 'dms', 'web_responsive', 'auditlog']
for m in modules:
    mod = env['ir.module.module'].search([('name', '=', m)])
    status = mod.state if mod else 'NOT FOUND'
    symbol = '✓' if status == 'installed' else ('⚠️' if mod else '✗')
    print(f"{symbol} {m}: {status}")

# Check base records
print("\nBase Records:")
print(f"  Projects: {env['project.project'].search_count([])}")
print(f"  Tags: {env['project.tags'].search_count([])}")
print(f"  Stages: {env['project.task.type'].search_count([])}")

if 'dms.directory' in env:
    print(f"  DMS Folders: {env['dms.directory'].search_count([])}")

if 'document.page' in env:
    print(f"  Knowledge Pages: {env['document.page'].search_count([])}")

# Check custom fields
custom_fields = env['ir.model.fields'].search([
    ('model', '=', 'project.task'),
    ('name', 'in', ['x_evidence_url', 'x_area', 'x_knowledge_page_id', 'x_approval_status'])
])
print(f"\nCustom Fields: {len(custom_fields)}/4")
for f in custom_fields:
    print(f"  ✓ {f.name}")

# Check automations
automations = env['base.automation'].search([
    ('model_id.model', '=', 'project.task'),
    ('active', '=', True)
])
print(f"\nActive Automations: {len(automations)}")
for a in automations:
    print(f"  ✓ {a.name}")

print("\n" + "=" * 60)

exit()
VERIFY_SCRIPT

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}                    ✓ Setup Complete!${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Your Notion-style workspace is ready!${NC}"
echo ""
echo "Access your workspace at:"
echo -e "  ${BLUE}https://insightpulseai.net:8069${NC}"
echo ""
echo "Navigate to:"
echo "  • Project → Compliance & Month-End (Kanban board)"
echo "  • Calendar → All Events (Regulatory deadlines)"
echo "  • Knowledge → Operations Workspace (Wiki/SOPs)"
echo "  • Documents → Compliance Evidence (Document repository)"
echo ""
echo "Next steps:"
echo "  1. Configure email server for alerts:"
echo "     Settings → Technical → Outgoing Mail Servers"
echo ""
echo "  2. Create user accounts:"
echo "     Settings → Users & Companies → Users"
echo ""
echo "  3. Import your own data:"
echo "     Edit CSV templates in /opt/odoo/data/templates/"
echo "     Then run: docker cp data/templates/*.csv odoo18:/tmp/"
echo "              docker exec -i odoo18 odoo shell -d $ODOO_DB < scripts/bulk-import-data.py"
echo ""
echo "  4. Customize workflows:"
echo "     Edit scripts/setup-workflows.py and re-run"
echo ""
echo "Documentation:"
echo "  • Full guide: docs/NOTION_WORKSPACE_DEPLOYMENT_GUIDE.md"
echo "  • Deployment status: DEPLOYMENT_COMPLETE.md"
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
