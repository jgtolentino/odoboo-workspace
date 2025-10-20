#!/usr/bin/env bash
set -euo pipefail

# Setup Development Database with Demo Data
# Creates a development database with Odoo demo data for testing

DB_NAME="${DB_NAME:-insightpulse_dev}"
ODOO_CTN="${ODOO_CTN:-odoo18}"
ADMIN_EMAIL="jgtolentino_rn@yahoo.com"
ADMIN_PASS="Postgres_26"
BASE_URL="${BASE_URL:-https://insightpulseai.net}"
OCR_URL="${OCR_URL:-https://insightpulseai.net/ocr}"

echo "==> Setting up Development Database with Demo Data"
echo "Database: $DB_NAME"
echo "Container: $ODOO_CTN"
echo "Admin: $ADMIN_EMAIL"
echo ""

# Check if database already exists
if docker exec -i "$ODOO_CTN" psql -U odoo -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    echo "⚠️  Database $DB_NAME already exists"
    read -p "Drop and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec -i "$ODOO_CTN" psql -U odoo -d postgres -c "DROP DATABASE $DB_NAME;"
        echo "✅ Dropped existing database"
    else
        echo "❌ Cancelled"
        exit 1
    fi
fi

echo "==> Step 1: Creating database with demo data"

# Initialize database with demo data (without-demo=False means include demo data)
docker exec -i "$ODOO_CTN" odoo \
    -d "$DB_NAME" \
    -i base \
    --db-filter="^$DB_NAME$" \
    --stop-after-init

echo "✅ Database created with demo data"

echo ""
echo "==> Step 2: Installing base modules with demo data"

# Install core modules with demo data
docker exec -i "$ODOO_CTN" odoo \
    -d "$DB_NAME" \
    -i contacts,project,sale_management,purchase,hr,hr_expense,crm,accounting,portal \
    --stop-after-init

echo "✅ Base modules installed"

echo ""
echo "==> Step 3: Setting admin credentials"

docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<PY
# Update admin credentials
admin = env['res.users'].search([('login', '=', 'admin')], limit=1)
if not admin:
    admin = env['res.users'].browse(2)

admin.write({
    'login': '$ADMIN_EMAIL',
    'email': '$ADMIN_EMAIL',
    'password': '$ADMIN_PASS'
})

# Set system parameters
env['ir.config_parameter'].sudo().set_param('web.base.url', '$BASE_URL')
env['ir.config_parameter'].sudo().set_param('hr_expense_ocr_audit.ocr_api_url', '$OCR_URL')

env.cr.commit()

print("✅ Admin credentials and system parameters set")
PY

echo ""
echo "==> Step 4: Creating sample data"

docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<'PY'
# Create sample projects
projects = [
    {'name': 'Website Redesign', 'description': 'Complete website overhaul'},
    {'name': 'Mobile App Launch', 'description': 'iOS and Android app development'},
    {'name': 'Marketing Campaign Q1', 'description': 'Q1 2025 marketing initiatives'},
]

for proj_data in projects:
    proj = env['project.project'].create(proj_data)
    print(f"✅ Created project: {proj.name}")

    # Create sample tasks for each project
    for i in range(5):
        env['project.task'].create({
            'name': f'{proj.name} - Task {i+1}',
            'project_id': proj.id,
            'stage_id': env['project.task.type'].search([], limit=1).id
        })

# Create sample customers with paper billing opt-in
customers = [
    {'name': 'Acme Corporation', 'email': 'info@acme.com', 'phone': '+1-555-0100'},
    {'name': 'TechStart Inc', 'email': 'hello@techstart.io', 'phone': '+1-555-0200'},
    {'name': 'Global Solutions Ltd', 'email': 'contact@globalsolutions.com', 'phone': '+1-555-0300'},
]

# Add paper_billing_opt_in field if not exists
if 'paper_billing_opt_in' not in env['res.partner']._fields:
    env['ir.model.fields'].create({
        'name': 'paper_billing_opt_in',
        'model': 'res.partner',
        'field_description': 'Paper Billing Opt-in',
        'ttype': 'boolean'
    })

for cust_data in customers:
    cust_data['customer_rank'] = 1
    cust_data['paper_billing_opt_in'] = True
    cust = env['res.partner'].create(cust_data)
    print(f"✅ Created customer: {cust.name}")

# Create sample vendors
vendors = [
    {'name': 'Office Supplies Co', 'email': 'sales@officesupplies.com'},
    {'name': 'Tech Equipment Ltd', 'email': 'orders@techequipment.com'},
    {'name': 'Consulting Services Inc', 'email': 'info@consultingservices.com'},
]

for vendor_data in vendors:
    vendor_data['supplier_rank'] = 1
    vendor = env['res.partner'].create(vendor_data)
    print(f"✅ Created vendor: {vendor.name}")

# Create sample expenses (for OCR testing)
expenses = [
    {'name': 'Office Supplies', 'employee_id': 1, 'total_amount': 125.50, 'date': '2025-01-15'},
    {'name': 'Client Lunch', 'employee_id': 1, 'total_amount': 87.30, 'date': '2025-01-16'},
    {'name': 'Taxi to Airport', 'employee_id': 1, 'total_amount': 45.00, 'date': '2025-01-17'},
]

for exp_data in expenses:
    exp = env['hr.expense'].create(exp_data)
    print(f"✅ Created expense: {exp.name}")

env.cr.commit()

print("\n" + "="*60)
print("✅ Sample data created successfully")
print("="*60)
PY

echo ""
echo "==> Step 5: Summary"
echo ""
echo "=" * 60
echo "✅ Development Database Ready!"
echo "=" * 60
echo ""
echo "📊 What was created:"
echo "   - Database: $DB_NAME (with Odoo demo data)"
echo "   - 3 sample projects with 15 tasks"
echo "   - 3 sample customers (paper billing enabled)"
echo "   - 3 sample vendors"
echo "   - 3 sample expenses (for OCR testing)"
echo ""
echo "🔑 Login credentials:"
echo "   Email: $ADMIN_EMAIL"
echo "   Password: $ADMIN_PASS"
echo "   URL: $BASE_URL/web/login"
echo ""
echo "🌐 Available apps:"
echo "   - Contacts, CRM, Sales, Purchase"
echo "   - Project Management, Accounting"
echo "   - HR, Expenses, Portal"
echo ""
echo "📚 Next steps:"
echo "   1. Login and explore demo data"
echo "   2. Install OCA modules: ./scripts/install-oca.sh"
echo "   3. Import Notion data: python3 scripts/notion-to-odoo.py"
echo "   4. Test OCR: Upload receipt in Expenses"
echo "   5. Configure portal: Settings → Portal"
echo ""
echo "💡 Switch between databases:"
echo "   Production: $BASE_URL/web/database/selector"
echo "   Select: insightpulse_prod or insightpulse_dev"
