#!/bin/bash
# Complete compliance data import workflow
# Usage: ./scripts/import_all_compliance.sh

set -e

# Configuration
export ODOO_URL="${ODOO_URL:-http://localhost:8069}"
export ODOO_DB="${ODOO_DB:-odoboo_local}"
export ODOO_USER="${ODOO_USER:-jgtolentino_rn@yahoo.com}"
export ODOO_PASSWORD="${ODOO_PASSWORD:-admin123}"

DATA_DIR="/mnt/data/odoo_import"

echo "🚀 Complete Compliance Data Import to Odoo"
echo "=========================================="
echo "   URL: $ODOO_URL"
echo "   Database: $ODOO_DB"
echo "   User: $ODOO_USER"
echo ""

# Step 1: Setup custom fields
echo "📋 Step 1/3: Setting up custom fields..."
echo ""
python3 scripts/setup_compliance_fields.py
echo ""

# Step 2: Import all CSV files
echo "📊 Step 2/3: Importing CSV files..."
echo ""

# Compliance Master
if [ -f "$DATA_DIR/Compliance_Master_ODOO_READY.csv" ]; then
    echo "📁 Importing Compliance Master..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Compliance_Master_ODOO_READY.csv" \
        "Compliance Master"
    echo ""
fi

# Compliance Tasks Full
if [ -f "$DATA_DIR/Compliance_Tasks_Full_ODOO_READY.csv" ]; then
    echo "📁 Importing Compliance Tasks (Full)..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Compliance_Tasks_Full_ODOO_READY.csv" \
        "Compliance Tasks"
    echo ""
fi

# Compliance Tasks Full (1)
if [ -f "$DATA_DIR/Compliance_Tasks_Full (1)_ODOO_READY.csv" ]; then
    echo "📁 Importing Compliance Tasks (Full - Version 2)..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Compliance_Tasks_Full (1)_ODOO_READY.csv" \
        "Compliance Tasks"
    echo ""
fi

# Regulatory Calendar 2026
if [ -f "$DATA_DIR/Regulatory_Calendar_2026_ODOO_READY.csv" ]; then
    echo "📁 Importing Regulatory Calendar 2026..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Regulatory_Calendar_2026_ODOO_READY.csv" \
        "Regulatory Calendar 2026"
    echo ""
fi

# Regulatory Calendar 2026 (1)
if [ -f "$DATA_DIR/Regulatory_Calendar_2026 (1)_ODOO_READY.csv" ]; then
    echo "📁 Importing Regulatory Calendar 2026 (Version 2)..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Regulatory_Calendar_2026 (1)_ODOO_READY.csv" \
        "Regulatory Calendar 2026"
    echo ""
fi

# Enhanced Month-end Closing
if [ -f "$DATA_DIR/Enhanced_Monthend_Closing_Tax_Filing_Complete_ODOO_READY.csv" ]; then
    echo "📁 Importing Enhanced Month-end Closing..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Enhanced_Monthend_Closing_Tax_Filing_Complete_ODOO_READY.csv" \
        "Month-end Closing & Tax Filing"
    echo ""
fi

# Month-end Closing Task and Tax Filing
if [ -f "$DATA_DIR/Month-end Closing Task and Tax Filing_ODOO_READY.csv" ]; then
    echo "📁 Importing Month-end Closing Task and Tax Filing..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Month-end Closing Task and Tax Filing_ODOO_READY.csv" \
        "Month-end Closing & Tax Filing"
    echo ""
fi

# Evidence Repository
if [ -f "$DATA_DIR/Evidence_Repository_ODOO_READY.csv" ]; then
    echo "📁 Importing Evidence Repository..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Evidence_Repository_ODOO_READY.csv" \
        "Evidence Repository"
    echo ""
fi

# Evidence Repository Sample
if [ -f "$DATA_DIR/Evidence_Repository_Sample_ODOO_READY.csv" ]; then
    echo "📁 Importing Evidence Repository Sample..."
    python3 scripts/import_compliance_csv.py \
        "$DATA_DIR/Evidence_Repository_Sample_ODOO_READY.csv" \
        "Evidence Repository"
    echo ""
fi

# Step 3: Summary
echo ""
echo "============================================================"
echo "✅ IMPORT COMPLETE!"
echo "============================================================"
echo ""
echo "🎯 Next steps:"
echo "   1. Open Odoo: $ODOO_URL"
echo "   2. Navigate to: Project → All Projects"
echo "   3. Select project to view tasks"
echo ""
echo "📊 Projects created:"
echo "   - Compliance Master"
echo "   - Compliance Tasks"
echo "   - Regulatory Calendar 2026"
echo "   - Month-end Closing & Tax Filing"
echo "   - Evidence Repository"
echo ""
echo "🎨 Recommended views:"
echo "   - Kanban: Group by Task Category + Frequency"
echo "   - Calendar: Show BIR Deadline dates"
echo "   - List: Show all custom fields"
echo "   - Pivot: Count by Category × Month"
echo ""
echo "============================================================"
