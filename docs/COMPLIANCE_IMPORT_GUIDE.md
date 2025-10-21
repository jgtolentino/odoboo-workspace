# Compliance Data Import Guide

Complete guide for importing compliance/regulatory CSV data into Odoo 18.

---

## Overview

This system imports compliance and regulatory data from CSV files into Odoo project tasks with custom fields for tracking:

- **Tax filing requirements** (BIR deadlines, forms)
- **Regulatory compliance** (monthly, quarterly, annual tasks)
- **Evidence management** (links to supporting documents)
- **Workflow tracking** (Owner, Reviewer, Approver)
- **Timeline management** (Prep/Review/Approval target dates)

---

## Quick Start

**One-command import** (imports all CSV files):

```bash
./scripts/import_all_compliance.sh
```

That's it! The script will:

1. ✅ Setup 14 custom fields on project.task
2. ✅ Import all CSV files to appropriate projects
3. ✅ Create tags for categories and frequencies
4. ✅ Link tasks to deadlines and target dates

---

## Manual Import (Step-by-Step)

### Step 1: Setup Custom Fields

```bash
python3 scripts/setup_compliance_fields.py
```

This creates 14 custom fields on `project.task`:

**Text Fields:**

- `x_task_category` - Task Category (Tax, Regulatory, etc.)
- `x_frequency` - Frequency (Monthly, Quarterly, Annual)
- `x_owner` - Task Owner
- `x_reviewer` - Reviewer
- `x_approver` - Approver
- `x_status_text` - Status
- `x_evidence_url` - Evidence Link URL
- `x_due_window` - Due Window
- `x_form` - Form type/number
- `x_period_covered` - Period Covered

**Date Fields:**

- `x_bir_deadline` - BIR Deadline
- `x_prep_target` - Prep Target Date
- `x_review_target` - Review Target Date
- `x_approval_target` - Approval Target Date

### Step 2: Import CSV Files

**Single file import:**

```bash
python3 scripts/import_compliance_csv.py <csv_file> <project_name>
```

**Example:**

```bash
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Compliance_Master_ODOO_READY.csv \
    "Compliance Master"
```

**Import all files:**

```bash
# Compliance Master
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Compliance_Master_ODOO_READY.csv \
    "Compliance Master"

# Compliance Tasks
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Compliance_Tasks_Full_ODOO_READY.csv \
    "Compliance Tasks"

# Regulatory Calendar 2026
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Regulatory_Calendar_2026_ODOO_READY.csv \
    "Regulatory Calendar 2026"

# Month-end Closing & Tax Filing
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Enhanced_Monthend_Closing_Tax_Filing_Complete_ODOO_READY.csv \
    "Month-end Closing & Tax Filing"

# Evidence Repository
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Evidence_Repository_ODOO_READY.csv \
    "Evidence Repository"
```

---

## CSV File Format

### Required Columns

- `Task` or `Description` - Task name (required)

### Optional Columns

All other columns are optional and will be imported if present:

- `Task Category` - Creates tags (e.g., "Tax", "Regulatory")
- `Frequency` - Creates tags (e.g., "Monthly", "Quarterly", "Annual")
- `Owner` - Task owner name
- `Reviewer` - Reviewer name
- `Approver` - Approver name
- `Status` - Status text
- `Evidence Link` - URL to evidence/documentation
- `Due Window` - Due window description
- `Form` - Form type/number (e.g., "2551Q", "2550M")
- `Period Covered` - Period description (e.g., "January 2026", "Q1 2026")
- `BIR Deadline` - Date (YYYY-MM-DD or MM/DD/YYYY)
- `Prep Target` - Preparation target date
- `Review Target` - Review target date
- `Approval Target` - Approval target date

### Example CSV

```csv
Task,Task Category,Frequency,Owner,Reviewer,Approver,Status,Evidence Link,Due Window,Form,Period Covered,BIR Deadline,Prep Target,Review Target,Approval Target
File Monthly VAT,Tax,Monthly,John Doe,Jane Smith,Finance Manager,Pending,https://drive.google.com/...,Within 25 days,2550M,January 2026,2026-01-25,2026-01-20,2026-01-23,2026-01-24
Submit Quarterly Income Tax,Tax,Quarterly,John Doe,Jane Smith,Finance Manager,In Progress,https://drive.google.com/...,Within 60 days,2551Q,Q1 2026,2026-04-30,2026-04-15,2026-04-25,2026-04-28
```

---

## Configuration

### Environment Variables

```bash
# Odoo connection
export ODOO_URL="http://localhost:8069"           # Odoo URL
export ODOO_DB="odoboo_local"                    # Database name
export ODOO_USER="jgtolentino_rn@yahoo.com"       # Login email
export ODOO_PASSWORD="admin123"                   # Password
```

### Default Values

If environment variables are not set, defaults are used:

- `ODOO_URL`: http://localhost:8069
- `ODOO_DB`: odoboo_local
- `ODOO_USER`: jgtolentino_rn@yahoo.com
- `ODOO_PASSWORD`: admin123

---

## Projects Created

The import creates the following projects in Odoo:

1. **Compliance Master** - Master compliance tracking
2. **Compliance Tasks** - Detailed compliance tasks
3. **Regulatory Calendar 2026** - Annual regulatory calendar
4. **Month-end Closing & Tax Filing** - Monthly closing tasks
5. **Evidence Repository** - Evidence and documentation links

---

## View Configuration

### Kanban View

**Recommended grouping:**

1. Primary: Group by `Task Category`
2. Secondary: Group by `Frequency`

**Result:** Visual board organized by category (Tax, Regulatory) and frequency (Monthly, Quarterly, Annual)

**To configure:**

1. Open Project → All Tasks
2. Switch to Kanban view
3. Click "Group By" → Task Category
4. Add second grouping → Frequency

### Calendar View

**Recommended date field:** `BIR Deadline`

**Optional additional calendars:**

- Prep Target
- Review Target
- Approval Target

**To configure:**

1. Open Project → All Tasks
2. Switch to Calendar view
3. Click "..." → Settings
4. Set Date Field: BIR Deadline

### List View

**Recommended columns:**

- Task (name)
- Task Category
- Frequency
- Owner
- Reviewer
- Approver
- Status
- BIR Deadline
- Evidence Link

**To configure:**

1. Open Project → All Tasks
2. Switch to List view
3. Click "..." → Add Custom Column
4. Select custom fields to display

### Pivot View

**Recommended analysis:**

- Rows: Task Category
- Columns: Month (from BIR Deadline)
- Measure: Count

**To configure:**

1. Open Project → All Tasks
2. Switch to Pivot view
3. Add Row: Task Category
4. Add Column: BIR Deadline (by Month)
5. Measure: Count

---

## Troubleshooting

### Error: Authentication failed

**Problem:** Cannot authenticate with Odoo

**Solution:**

```bash
# Check credentials
export ODOO_USER="jgtolentino_rn@yahoo.com"
export ODOO_PASSWORD="admin123"

# Verify login works
curl -X POST http://localhost:8069/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "params": {
      "db": "odoboo_local",
      "login": "jgtolentino_rn@yahoo.com",
      "password": "admin123"
    }
  }'
```

### Error: Database does not exist

**Problem:** Target database not found

**Solution:**

```bash
# List available databases
docker exec -i postgres15 psql -U odoo -l

# Use correct database name
export ODOO_DB="odoboo_local"  # or insightpulse_prod
```

### Error: Field does not exist

**Problem:** Custom fields not created

**Solution:**

```bash
# Run field setup first
python3 scripts/setup_compliance_fields.py

# Verify fields were created
# Login to Odoo → Settings → Technical → Database Structure → Models
# Search for "project.task" → Open → Fields tab
# Look for fields starting with "x_"
```

### Error: CSV file not found

**Problem:** CSV file path is incorrect

**Solution:**

```bash
# Check file exists
ls -la /mnt/data/odoo_import/

# Use absolute path
python3 scripts/import_compliance_csv.py \
    "/mnt/data/odoo_import/Compliance_Master_ODOO_READY.csv" \
    "Compliance Master"
```

### Warning: Tasks skipped

**Problem:** Duplicate tasks detected

**Behavior:** Import script skips tasks that already exist in the same project (same name + same project)

**This is normal** - re-running import is safe and will only create new tasks.

---

## Advanced Usage

### Import to Different Database

```bash
export ODOO_DB="insightpulse_prod"
python3 scripts/import_compliance_csv.py <csv_file> <project_name>
```

### Import to Remote Odoo

```bash
export ODOO_URL="https://insightpulseai.net"
export ODOO_DB="insightpulse_prod"
export ODOO_USER="jgtolentino_rn@yahoo.com"
export ODOO_PASSWORD="your_password"

python3 scripts/import_compliance_csv.py <csv_file> <project_name>
```

### Import Specific Files Only

```bash
# Setup fields first
python3 scripts/setup_compliance_fields.py

# Import only Regulatory Calendar
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Regulatory_Calendar_2026_ODOO_READY.csv \
    "Regulatory Calendar 2026"

# Import only Evidence Repository
python3 scripts/import_compliance_csv.py \
    /mnt/data/odoo_import/Evidence_Repository_ODOO_READY.csv \
    "Evidence Repository"
```

### Custom CSV Format

If your CSV has different column names, update the mapping in `import_compliance_csv.py`:

```python
# Find this section in the script
task_name = row.get('Task') or row.get('Description') or row.get('Name')

# Add your custom column names
task_name = row.get('Task') or row.get('Description') or row.get('Your_Column_Name')
```

---

## Files Reference

### Scripts

- [scripts/setup_compliance_fields.py](../scripts/setup_compliance_fields.py) - Setup custom fields
- [scripts/import_compliance_csv.py](../scripts/import_compliance_csv.py) - Import single CSV file
- [scripts/import_all_compliance.sh](../scripts/import_all_compliance.sh) - Batch import all files

### CSV Files (Odoo-Ready)

Located in `/mnt/data/odoo_import/`:

- `Compliance_Master_ODOO_READY.csv`
- `Compliance_Tasks_Full_ODOO_READY.csv`
- `Compliance_Tasks_Full (1)_ODOO_READY.csv`
- `Regulatory_Calendar_2026_ODOO_READY.csv`
- `Regulatory_Calendar_2026 (1)_ODOO_READY.csv`
- `Enhanced_Monthend_Closing_Tax_Filing_Complete_ODOO_READY.csv`
- `Month-end Closing Task and Tax Filing_ODOO_READY.csv`
- `Evidence_Repository_ODOO_READY.csv`
- `Evidence_Repository_Sample_ODOO_READY.csv`

---

## Next Steps

After importing data:

1. **Configure Views**
   - Setup Kanban grouping (Category → Frequency)
   - Setup Calendar view (BIR Deadline)
   - Customize List columns
   - Create Pivot analysis

2. **Assign Users**
   - Replace text owner/reviewer/approver with actual Odoo users
   - Settings → Users & Companies → Users
   - Assign to project teams

3. **Setup Automation**
   - Create automated actions for deadline reminders
   - Settings → Technical → Automation → Automated Actions
   - Trigger: Date (BIR Deadline - 7 days)
   - Action: Send email to Owner

4. **Create Dashboard**
   - Project → Dashboard
   - Add widgets for upcoming deadlines
   - Add charts for tasks by category
   - Add pivot tables for monthly breakdown

5. **Portal Access** (Optional)
   - Enable portal access for external reviewers
   - Settings → Users → Portal Access
   - Share specific projects with reviewers

---

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review script output for error messages
3. Verify Odoo connection and credentials
4. Check CSV file format matches expected columns

---

**Import Status**: ✅ Ready to use
**Last Updated**: 2025-10-21
