# Notion-Style Workspace Deployment Guide for Odoo 18

**Complete guide to deploying a Notion-style collaborative workspace in Odoo 18**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start (15 minutes)](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Data Import](#data-import)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This deployment creates a **Notion-style workspace** in Odoo 18 with:

- ✅ **Kanban Task Board** - Visual project management with drag-and-drop
- ✅ **Calendar Integration** - Regulatory deadlines, meetings, reminders
- ✅ **Evidence Repository** - Document management with full-text search
- ✅ **Knowledge Base** - Wiki-style SOPs, guides, and policies
- ✅ **Email Alerts** - Automated reminders and notifications
- ✅ **Approval Workflows** - Multi-level approval processes
- ✅ **Tagging System** - Organize by area, category, priority
- ✅ **Mobile Access** - Responsive UI and PWA support

### Key Features

| Feature | Odoo 18 Native | OCA Module | Custom |
|---------|----------------|------------|--------|
| **Project Kanban** | ✅ project | | |
| **Calendar** | ✅ calendar | | |
| **Wiki/Knowledge** | | ✅ document_page | |
| **Document Management** | | ✅ dms | |
| **Mobile UI** | | ✅ web_responsive | |
| **Audit Trail** | | ✅ auditlog | |
| **Email Tracking** | | ✅ mail_tracking | |
| **Dashboards** | | ✅ mis_builder | |
| **Linking System** | | | ✅ Custom fields |

---

## Prerequisites

### Server Requirements

- **Odoo 18** running on DigitalOcean droplet
- **PostgreSQL 15** database
- **Docker** (if using containers)
- **SSH access** to server

### Current Setup (Based on DEPLOYMENT_COMPLETE.md)

```
Server: 188.166.237.231
Domain: insightpulseai.net:8069
Database: odoo_production
Odoo Container: odoo18
DB Container: odoo-db
```

### Access Required

- SSH access: `ssh root@188.166.237.231`
- Odoo admin credentials
- Database admin credentials

---

## Quick Start (15 minutes)

### Step 1: SSH into Server

```bash
ssh root@188.166.237.231
cd /opt/odoo
```

### Step 2: Download Setup Scripts

```bash
# Create scripts directory
mkdir -p /opt/odoo/scripts
cd /opt/odoo/scripts

# Download all setup scripts (from your repo)
# Or copy from local machine:
# scp -r scripts/*.sh root@188.166.237.231:/opt/odoo/scripts/
# scp -r scripts/*.py root@188.166.237.231:/opt/odoo/scripts/
```

### Step 3: Run Complete Setup

```bash
# Make scripts executable
chmod +x /opt/odoo/scripts/*.sh

# Run complete setup (installs modules + creates base records)
./setup-notion-workspace.sh

# This will:
# - Download OCA repositories
# - Update docker-compose.yml
# - Install required modules
# - Update Odoo config
# - Restart Odoo
```

**⏱️ Time: 10-15 minutes**

### Step 4: Configure Base Records

```bash
# Create base records (projects, folders, tags, etc.)
docker exec -i odoo18 odoo shell -d odoo_production < /opt/odoo/scripts/setup-base-records.py

# Create custom fields
docker exec -i odoo18 odoo shell -d odoo_production < /opt/odoo/scripts/setup-custom-fields.py

# Setup workflows and email alerts
docker exec -i odoo18 odoo shell -d odoo_production < /opt/odoo/scripts/setup-workflows.py

# Restart Odoo to apply changes
docker restart odoo18
```

**⏱️ Time: 5 minutes**

### Step 5: Import Sample Data (Optional)

```bash
# Copy CSV templates to container
docker cp /opt/odoo/data/templates/*.csv odoo18:/tmp/

# Run bulk import
docker exec -i odoo18 odoo shell -d odoo_production < /opt/odoo/scripts/bulk-import-data.py
```

**⏱️ Time: 2 minutes**

### Step 6: Access Workspace

Open in browser: **https://insightpulseai.net:8069**

Navigate to:
- **Project** → Compliance & Month-End → Kanban view
- **Calendar** → All regulatory deadlines
- **Knowledge** → Operations Workspace
- **Documents** → Compliance Evidence

---

## Detailed Setup

### Module Installation Details

#### Core Odoo Modules (Native)

```python
# Installed automatically by setup script
modules = [
    'project',          # Project management
    'hr_expense',       # Expense management
    'calendar',         # Calendar & events
    'mail',             # Email & messaging
    'contacts',         # Contact management
]
```

#### OCA Modules (Community)

```python
# Knowledge & Wiki
'document_page',              # Wiki pages (Notion-style)
'document_page_approval',     # Approval workflow for pages
'document_page_tag',          # Page tagging

# Document Management
'dms',                        # Full DMS
'attachment_indexation',      # Full-text search
'attachment_preview',         # File previews

# Web & UI
'web_responsive',             # Mobile-friendly
'web_pwa_oca',                # Progressive Web App
'web_notify',                 # Toast notifications
'web_advanced_search',        # Advanced search

# Project Management
'project_stage_closed',       # Closed stages
'project_task_dependency',    # Task dependencies
'project_timeline',           # Gantt timeline
'project_template',           # Project templates

# Communication
'mail_tracking',              # Email tracking
'mail_activity_board',        # Activity Kanban
'mail_debrand',               # Remove Odoo branding

# Analytics
'mis_builder',                # Dashboards
'bi_sql_editor',              # SQL queries

# Reporting
'report_xlsx',                # Excel exports

# Background Jobs
'queue_job',                  # Job processing

# Security & Audit
'auditlog',                   # Audit trail
'password_security',          # Password policies
```

### Manual Module Installation (if needed)

If automatic installation fails for specific modules:

1. **Via Web UI:**
   - Go to **Apps**
   - Click **Update Apps List**
   - Search for module (e.g., "document_page")
   - Click **Activate**

2. **Via CLI:**
```bash
docker exec -i odoo18 odoo -d odoo_production -i document_page,dms,web_responsive --stop-after-init
docker restart odoo18
```

---

## Data Import

### Option 1: CSV Import via Web UI (Recommended for beginners)

1. **Download CSV templates** from `data/templates/`
2. **Edit with your data** (use Excel or Google Sheets)
3. **Navigate to target model** in Odoo:
   - Tasks: Project → Tasks → List view
   - Calendar: Calendar → Events
   - Documents: Documents → Documents
   - Knowledge: Knowledge → Pages
4. **Click Favorites → Import records**
5. **Upload CSV and map columns**
6. **Test import with 1-2 records** first
7. **Import all data**

### Option 2: Bulk Import via Python Script (Recommended for large datasets)

```bash
# Prepare your CSV files
cp your-data/*.csv /opt/odoo/data/templates/

# Copy to container
docker cp /opt/odoo/data/templates/*.csv odoo18:/tmp/

# Run import script
docker exec -i odoo18 odoo shell -d odoo_production < /opt/odoo/scripts/bulk-import-data.py
```

### CSV Templates Reference

#### 1. Tasks (`01_tasks_import_template.csv`)

```csv
name,project_id/name,user_id/email,date_deadline,priority,tag_ids/name,stage_id/name,description,planned_hours,x_area,x_evidence_url,x_knowledge_page_id/name
```

**Key columns:**
- `name`: Task title
- `project_id/name`: "Compliance & Month-End" (must exist)
- `user_id/email`: Assignee email (will create link by email)
- `date_deadline`: YYYY-MM-DD format
- `priority`: 0=Normal, 1=High, 2=Very High
- `tag_ids/name`: Comma-separated tags
- `stage_id/name`: Stage name (e.g., "To Do", "Doing", "Done")
- `x_area`: Compliance area (month_end, tax, procurement, etc.)
- `x_evidence_url`: Link to evidence document
- `x_knowledge_page_id/name`: Link to SOP/guide page

#### 2. Calendar Events (`02_calendar_events_template.csv`)

```csv
name,start,stop,allday,location,description,partner_ids/email,alarm_ids/name,categ_ids/name
```

**Key columns:**
- `start`: YYYY-MM-DD HH:MM:SS (UTC)
- `stop`: YYYY-MM-DD HH:MM:SS (UTC)
- `allday`: TRUE/FALSE
- `partner_ids/email`: Comma-separated attendee emails
- `alarm_ids/name`: "1 day before", "1 hour before", etc.
- `categ_ids/name`: "Tax Deadlines", "Finance Meetings", etc.

#### 3. Evidence Documents (`03_evidence_repository_template.csv`)

```csv
name,directory_id/name,url,mimetype,tag_ids/name,owner_id/email,description,x_task_id/name,x_compliance_area
```

**Key columns:**
- `directory_id/name`: Folder path (e.g., "Compliance Evidence")
- `url`: External link to file (DigitalOcean Spaces, etc.)
- `mimetype`: application/pdf, application/xlsx, etc.
- `x_task_id/name`: Related task name
- `x_compliance_area`: Same as task area

#### 4. Knowledge Pages (`04_knowledge_pages_template.csv`)

```csv
name,parent_id/name,content,tag_ids/name,owner_id/email,summary
```

**Key columns:**
- `parent_id/name`: Parent page name (leave empty for root pages)
- `content`: HTML content (basic HTML tags supported)
- `summary`: Short description

---

## Customization

### 1. Add Custom Tags

**Via Web UI:**
- Project → Configuration → Tags → Create
- Enter tag name and color

**Via Python:**
```python
env['project.tags'].create({'name': 'My Custom Tag'})
env.cr.commit()
```

### 2. Add Custom Stages

**Via Web UI:**
- Project → Configuration → Stages → Create
- Set name, sequence, and color

**Via Python:**
```python
stage = env['project.task.type'].create({
    'name': 'Custom Stage',
    'sequence': 10,
    'fold': False,
    'project_ids': [(4, project_id)],
})
env.cr.commit()
```

### 3. Configure Email Server

**Required for email alerts to work:**

1. Go to **Settings → Technical → Outgoing Mail Servers**
2. Create new server:
   ```
   Description: Company SMTP
   SMTP Server: smtp.gmail.com (or your provider)
   SMTP Port: 587
   Connection Security: TLS (STARTTLS)
   Username: your-email@company.com
   Password: your-app-password
   ```
3. Click **Test Connection**
4. Set as default

**Gmail Users:** Generate app password at https://myaccount.google.com/apppasswords

### 4. Configure Approval Workflow

The system includes approval workflow for tasks marked as "Submitted".

**Workflow:**
1. Account Manager creates vendor rate request
2. Sets `x_approval_status` = "Submitted"
3. Automated action:
   - Sends email to Finance Director
   - Creates activity for Finance Director
4. Finance Director approves/rejects
5. If approved, Procurement team proceeds

**Customize approvers:**

Edit `/opt/odoo/scripts/setup-workflows.py`:
```python
finance_director = env['res.users'].search([
    ('email', '=', 'your-approver@company.com')  # Change email
], limit=1)
```

### 5. Hide Vendor Names from Account Managers

**Create record rule:**

```python
# In Odoo shell
rule = env['ir.rule'].create({
    'name': 'AM: Hide Vendor Names',
    'model_id': env['ir.model'].search([('model', '=', 'res.partner')]).id,
    'groups': [(4, env.ref('sales_team.group_sale_salesman').id)],  # Account Manager group
    'domain_force': "[('is_company', '=', False)]",  # Hide companies, show individuals only
    'perm_read': True,
    'perm_write': False,
    'perm_create': False,
    'perm_unlink': False,
})
env.cr.commit()
```

---

## Verification Checklist

After deployment, verify these items:

### ✅ Modules Installed

```bash
# Check installed modules
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
modules = [
    'project', 'hr_expense', 'calendar', 'mail',
    'document_page', 'dms', 'web_responsive', 'queue_job', 'auditlog'
]
for m in modules:
    mod = env['ir.module.module'].search([('name', '=', m)])
    print(f"{m}: {mod.state if mod else 'NOT FOUND'}")
exit()
ODOO_SHELL
```

**Expected:** All modules show "installed"

### ✅ Base Records Created

```bash
# Check base records
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
print(f"Projects: {env['project.project'].search_count([])}")
print(f"Tags: {env['project.tags'].search_count([])}")
print(f"Stages: {env['project.task.type'].search_count([])}")
print(f"DMS Folders: {env['dms.directory'].search_count([]) if 'dms.directory' in env else 'DMS not installed'}")
print(f"Knowledge Pages: {env['document.page'].search_count([]) if 'document.page' in env else 'document_page not installed'}")
exit()
ODOO_SHELL
```

**Expected:** At least 1 project, multiple tags/stages

### ✅ Custom Fields Created

```bash
# Check custom fields
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
fields = env['ir.model.fields'].search([
    ('model', '=', 'project.task'),
    ('name', 'in', ['x_evidence_url', 'x_area', 'x_knowledge_page_id', 'x_approval_status'])
])
for f in fields:
    print(f"✓ {f.name} ({f.ttype})")
exit()
ODOO_SHELL
```

**Expected:** All 4 custom fields present

### ✅ Automations Active

```bash
# Check automations
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
automations = env['base.automation'].search([
    ('model_id.model', '=', 'project.task'),
    ('active', '=', True)
])
for a in automations:
    print(f"✓ {a.name} ({a.trigger})")
exit()
ODOO_SHELL
```

**Expected:** 4 automations (deadline reminder, overdue alert, approval, assignment)

### ✅ Web UI Access

1. Open https://insightpulseai.net:8069
2. Navigate to **Project** → should see "Compliance & Month-End"
3. Navigate to **Calendar** → should see event types
4. Navigate to **Knowledge** → should see "Operations Workspace"
5. Navigate to **Documents** → should see "Compliance Evidence" folder

---

## Troubleshooting

### Issue: Module installation fails

**Symptom:** Error during module installation

**Solution:**
```bash
# Update module list
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
env['ir.module.module'].update_list()
env.cr.commit()
exit()
ODOO_SHELL

# Restart Odoo
docker restart odoo18

# Try manual installation
docker exec -i odoo18 odoo -d odoo_production -i module_name --stop-after-init
```

### Issue: CSV import fails

**Symptom:** "External ID not found" or "Record not found"

**Solutions:**
1. **Check related records exist first**
   - Import users/partners before tasks
   - Create project before importing tasks
   - Create folders before importing documents

2. **Use exact names**
   - Column names must match exactly: `project_id/name` not `project_id`
   - Values must match existing records exactly (case-sensitive)

3. **Check date format**
   - Use YYYY-MM-DD for dates
   - Use YYYY-MM-DD HH:MM:SS for datetimes

4. **Import via Python script instead**
   - More forgiving with errors
   - Better error messages

### Issue: Email alerts not working

**Symptom:** No emails sent for task reminders

**Solutions:**
1. **Configure SMTP server**
   - Settings → Technical → Outgoing Mail Servers
   - Test connection

2. **Check automation is active**
```bash
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
automations = env['base.automation'].search([('active', '=', False)])
for a in automations:
    a.active = True
    print(f"Activated: {a.name}")
env.cr.commit()
exit()
ODOO_SHELL
```

3. **Check scheduled actions running**
   - Settings → Technical → Scheduled Actions
   - Find automation-related actions
   - Check "Next Execution Date" is in the future
   - Click "Run Manually" to test

### Issue: Custom fields not showing in views

**Symptom:** x_evidence_url field exists but not visible

**Solution:**
1. **Restart Odoo** (fields require restart):
```bash
docker restart odoo18
```

2. **Clear browser cache** (Ctrl+Shift+R)

3. **Add to view manually** (if still not showing):
   - Enable Developer Mode: Settings → Activate Developer Mode
   - Go to task form view
   - Click "Edit View: Form"
   - Add field to XML:
```xml
<field name="x_evidence_url"/>
```

### Issue: OCA modules not found

**Symptom:** Module shows "Not Found" in module list

**Solutions:**
1. **Check OCA repository exists**:
```bash
ls -la /opt/odoo/addons/oca/
```

2. **Check docker-compose.yml has volume mount**:
```bash
cat /root/docker-compose.yml | grep oca
```

3. **Check odoo.conf has addons path**:
```bash
docker exec odoo18 cat /etc/odoo/odoo.conf | grep addons_path
```

4. **Update module list**:
```bash
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
env['ir.module.module'].update_list()
env.cr.commit()
exit()
ODOO_SHELL
docker restart odoo18
```

---

## Performance Optimization

### For Production Use

1. **Enable caching**:
```conf
# In odoo.conf
workers = 4
max_cron_threads = 2
limit_memory_soft = 2147483648
limit_memory_hard = 2684354560
```

2. **Database indexing**:
```sql
-- Add indexes for custom fields
CREATE INDEX idx_task_evidence_url ON project_task(x_evidence_url);
CREATE INDEX idx_task_area ON project_task(x_area);
```

3. **Optimize attachments**:
   - Use external storage (DigitalOcean Spaces)
   - Install `storage_backend` OCA module
   - Configure S3-compatible storage

4. **Regular maintenance**:
```bash
# Vacuum database weekly
docker exec -i odoo-db psql -U odoo -d odoo_production -c "VACUUM ANALYZE;"

# Clear old logs
docker exec odoo18 bash -c "find /var/log/odoo -name '*.log' -mtime +30 -delete"
```

---

## Next Steps

After successful deployment:

1. ✅ **Customize for your needs**
   - Add your specific compliance areas
   - Create your organization's SOPs
   - Configure email templates

2. ✅ **Train users**
   - Create user accounts
   - Assign roles and permissions
   - Provide quick start guide

3. ✅ **Integrate with other systems**
   - Connect to email (IMAP/SMTP)
   - Set up API integrations
   - Configure webhooks

4. ✅ **Monitor and maintain**
   - Check automation logs weekly
   - Review audit trail monthly
   - Backup database regularly

---

## Support & Resources

- **Odoo Documentation**: https://www.odoo.com/documentation/18.0/
- **OCA Documentation**: https://github.com/OCA
- **Deployment Status**: See `DEPLOYMENT_COMPLETE.md`
- **Quick Start**: See `QUICK_START_GUIDE.md`

---

**Deployment completed successfully! 🎉**

Your Notion-style workspace is ready at: **https://insightpulseai.net:8069**
