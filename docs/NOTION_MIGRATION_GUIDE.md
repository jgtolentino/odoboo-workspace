# Notion to Odoo Migration Guide

Complete guide for migrating Notion workspaces to Odoo 18 with OCA modules.

## Overview

This guide covers:

1. **Notion Export** - Extracting data from Notion
2. **OCA Installation** - Installing Community + OCA modules
3. **Notion Import** - Migrating pages, databases, and attachments
4. **Post-Migration** - Configuration and optimization

## What Gets Migrated

### From Notion

- **Pages** → Odoo Wiki (`document.page`)
- **Databases** → Projects and Tasks (`project.project`, `project.task`)
- **Status** → Kanban stages (Backlog → New, In Progress, Review, Done)
- **Attachments** → Odoo DMS (optional)

### Enterprise-Level Features on Community

- **UX**: web_responsive, web_timeline, web_pwa_oca
- **Knowledge**: document_page (wiki), dms (document management)
- **BI**: mis_builder (dashboards)
- **Ops**: queue_job, auditlog, base_automation
- **Finance**: account_financial_report, partner_statement
- **Sales**: sale_margin, sale_workflow
- **Purchase**: purchase_request, purchase_requisition
- **Inventory**: stock_picking_batch, stock_ux
- **HR**: hr_timesheet, hr_holidays_public, hr_expense

---

## Prerequisites

1. **Odoo 18 Deployed**
   - Droplet running with Docker Compose
   - Database created (`insightpulse_prod`)
   - Admin access configured

2. **Notion Exports**
   - HTML & Markdown export from Notion
   - Databases exported as CSV
   - Downloaded to local machine

3. **Server Access**
   - SSH access to Odoo droplet
   - sudo/root privileges

---

## Step 1: Export from Notion

### Export Workspace

1. **Navigate to Settings & Members**
   - Click workspace name (top-left)
   - Settings & Members

2. **Export**
   - Export content
   - Export format: **HTML** (recommended) or Markdown
   - Include content: **Everything**
   - Include subpages: **Yes**
   - Create folders for subpages: **No** (easier to import)

3. **Download**
   - Download ZIP file
   - Note: May take several minutes for large workspaces

### What You Get

```
ExportBlock-9810b2d5-....zip
├── Page 1 Title abc123.html
├── Page 2 Title def456.html
├── table/
│   ├── Projects.csv
│   └── Tasks.csv
└── images/
    ├── image1.png
    └── image2.jpg
```

---

## Step 2: Install OCA Modules

### Upload Installation Script

```bash
# From your local machine
scp scripts/install-oca.sh root@YOUR_ODOO_IP:/opt/odoo/
ssh root@YOUR_ODOO_IP "chmod +x /opt/odoo/install-oca.sh"
```

### Run Installation

```bash
# SSH to Odoo droplet
ssh root@YOUR_ODOO_IP

# Set environment variables
export DB_NAME="insightpulse_prod"
export OCR_URL="https://insightpulseai.net/ocr"
export BASE_URL="https://insightpulseai.net"
export ODOO_CTN="odoo18"

# Run installation (5-10 minutes)
/opt/odoo/install-oca.sh
```

### What Gets Installed

**Cloned Repositories (13):**

- OCA/web
- OCA/server-tools
- OCA/queue
- OCA/mis-builder
- OCA/dms
- OCA/knowledge
- OCA/account-financial-reporting
- OCA/account-financial-tools
- OCA/sale-workflow
- OCA/purchase-workflow
- OCA/stock-logistics-workflow
- OCA/hr-timesheet
- OCA/project

**Installed Modules (20+):**

- web_responsive, web_timeline, web_pwa_oca
- document_page, dms, attachment_indexation
- mis_builder, auditlog, queue_job, base_automation
- account_financial_report, account_payment_order, account_lock_date
- sale_margin, sale_workflow
- stock_picking_batch, stock_ux
- hr_timesheet, hr_holidays_public, hr_expense

**System Parameters:**

- `hr_expense_ocr_audit.ocr_api_url` → OCR endpoint
- `web.base.url` → Odoo public URL
- `paper_billing_opt_in` field added to partners

---

## Step 3: Migrate Notion Data

### Upload Notion Exports

```bash
# Create import directory on server
ssh root@YOUR_ODOO_IP "mkdir -p /opt/imports/notion"

# Upload Notion ZIP files
scp "/path/to/ExportBlock-9810b2d5-....zip" root@YOUR_ODOO_IP:/opt/imports/notion/notion-1.zip
scp "/path/to/ExportBlock-d27fff10-....zip" root@YOUR_ODOO_IP:/opt/imports/notion/notion-2.zip

# Upload migration script
scp scripts/notion-to-odoo.py root@YOUR_ODOO_IP:/opt/imports/
ssh root@YOUR_ODOO_IP "chmod +x /opt/imports/notion-to-odoo.py"
```

### Run Migration

```bash
# SSH to Odoo droplet
ssh root@YOUR_ODOO_IP

# Set environment variables
export ODOO_URL="https://insightpulseai.net"
export ODOO_DB="insightpulse_prod"
export ODOO_USER="admin@example.com"
export ODOO_PASS="your-admin-password"

# Run migration
cd /opt/imports
python3 notion-to-odoo.py notion/notion-1.zip notion/notion-2.zip
```

### Migration Process

**Phase 1: Authentication**

```
✅ Authenticated as user ID 2
```

**Phase 2: Stage Creation**

```
📊 Creating project stages...
✅ Created 4 project stages
```

**Phase 3: Wiki Root**

```
📚 Creating wiki root...
✅ Wiki root created (ID: 42)
```

**Phase 4: Page Import**

```
📦 Processing notion-1.zip...
📄 Found 150 HTML pages
  ✅ Finance Close Procedures
  ✅ VAT Filing Tasks
  ✅ Client Onboarding Checklist
  ...
```

**Phase 5: Database Import**

```
🏗️  Found Projects CSV: table/projects.csv
  ✅ Project: Website Redesign
  ✅ Project: Mobile App Launch
  ...

✓ Found Tasks CSV: table/tasks.csv
  ✅ Task: Design mockups (Todo → New)
  ✅ Task: API integration (In Progress → In Progress)
  ...
```

**Summary:**

```
============================================================
✅ Import complete!
📄 Pages imported: 150
🏗️  Projects created: 12
✓ Tasks created: 387
============================================================

🌐 Access your data at: https://insightpulseai.net
   - Wiki: Knowledge → Notion Import
   - Projects: Project → All Projects
   - Tasks: Project → All Tasks
```

---

## Step 4: Verify Migration

### Check Wiki Pages

1. Navigate to **Knowledge** → **Notion Import**
2. Verify page hierarchy and content
3. Check internal links (may need manual adjustment)

### Check Projects

1. Navigate to **Project** → **All Projects**
2. Verify project names and metadata
3. Check project-task associations

### Check Tasks

1. Navigate to **Project** → **All Tasks**
2. Verify task names, statuses, and stages
3. Check Kanban view (group by stage)

### Stage Mapping Verification

| Notion Status | Odoo Stage  | Verified |
| ------------- | ----------- | -------- |
| Backlog       | New         | ✓        |
| Todo          | New         | ✓        |
| To Do         | New         | ✓        |
| In Progress   | In Progress | ✓        |
| Doing         | In Progress | ✓        |
| Review        | In Review   | ✓        |
| In Review     | In Review   | ✓        |
| Done          | Done        | ✓        |
| Completed     | Done        | ✓        |
| Closed        | Done        | ✓        |

---

## Step 5: Post-Migration Configuration

### Configure Portal

**Enable Portal:**

1. Settings → Users & Companies → Portal
2. Activate portal access
3. Create portal menu: Customer Statements

**Portal Users:**

1. Contacts → Create portal user
2. Send invite email
3. Configure portal access rights

### Setup Automated Actions

**Email Alerts for Kanban Moves:**

```
Settings → Technical → Automation → Automated Actions

Name: Email on Kanban Stage Change
Model: project.task
Trigger: On stage changed
Action: Send email to assigned user
```

**Purchase Request Alerts:**

```
Name: Alert Finance on Purchase Request
Model: purchase.request
Trigger: On Creation
Action: Send email to finance@example.com
```

**Budget Threshold Alerts:**

```
Name: Budget Exceeded Alert
Model: mis.report.instance
Trigger: On Update
Condition: amount > threshold
Action: Send email to CFO
```

### Configure Customer Statements

**Install Partner Statement:**

```bash
docker exec -it odoo18 odoo -d insightpulse_prod -i partner_statement,portal_partner_statement --stop-after-init
```

**Access:**

- Navigate to: Accounting → Reporting → Partner Statement
- Configure email template for monthly statements
- Use `paper_billing_opt_in` field to filter

### Configure Access Control (Hide Vendor Rates from AMs)

**Create Security Groups:**

```xml
<!-- /opt/odoo/addons/custom_security/security/security.xml -->
<odoo>
  <record id="group_account_manager_limited" model="res.groups">
    <field name="name">Account Manager (Limited)</field>
    <field name="category_id" ref="base.module_category_hidden"/>
  </record>

  <!-- Hide vendor records -->
  <record id="rule_hide_vendors_for_am" model="ir.rule">
    <field name="name">Hide Vendors from AMs</field>
    <field name="model_id" ref="base.model_res_partner"/>
    <field name="domain_force">[('supplier_rank','=',0)]</field>
    <field name="groups" eval="[(4, ref('group_account_manager_limited'))]"/>
    <field name="perm_unlink" eval="0"/>
  </record>

  <!-- Hide product cost fields -->
  <record id="rule_hide_cost_fields" model="ir.rule">
    <field name="name">Hide Cost Fields from AMs</field>
    <field name="model_id" ref="product.model_product_template"/>
    <field name="domain_force">[]</field>
    <field name="groups" eval="[(4, ref('group_account_manager_limited'))]"/>
    <field name="perm_write" eval="0"/>
  </record>
</odoo>
```

**Install Custom Security Module:**

```bash
docker exec -it odoo18 odoo -d insightpulse_prod -i custom_security --stop-after-init
```

---

## Step 6: Optimize and Maintain

### Performance Tuning

**Workers Configuration:**

```ini
# /opt/odoo/config/odoo.conf
workers = 4  # for 8GB droplet
max_cron_threads = 2
```

**Database Indexing:**

```sql
-- Add indexes for common searches
CREATE INDEX idx_task_name ON project_task(name);
CREATE INDEX idx_page_name ON document_page(name);
CREATE INDEX idx_partner_billing ON res_partner(paper_billing_opt_in);
```

**Queue Job Configuration:**

```
Settings → Technical → Job Channels
- Create channel: 'default' with priority 10
- Create channel: 'ocr' with priority 5
- Create channel: 'reporting' with priority 3
```

### Backup Strategy

**Daily Database Backups:**

```bash
# Add to crontab
0 2 * * * cd /opt/odoo && docker compose exec -T db pg_dump -U odoo insightpulse_prod | gzip > /backups/odoo_$(date +\%Y\%m\%d).sql.gz

# Cleanup old backups (keep 30 days)
0 3 * * * find /backups -name "odoo_*.sql.gz" -mtime +30 -delete
```

**Wiki Page Backups:**

```bash
# Export wiki as HTML (monthly)
docker exec -i odoo18 odoo shell -d insightpulse_prod <<PY
pages = env['document.page'].search([])
for page in pages:
    with open(f'/backups/wiki/{page.name}.html', 'w') as f:
        f.write(page.content)
PY
```

### Monitoring

**Health Checks:**

```bash
# Add to monitoring script
curl -sf https://insightpulseai.net/web/health
curl -sf https://insightpulseai.net/web/database/selector
```

**Queue Job Monitoring:**

```sql
-- Check stuck jobs
SELECT id, name, state, date_created
FROM queue_job
WHERE state = 'started'
AND date_created < NOW() - INTERVAL '5 minutes';
```

---

## Troubleshooting

### Import Failures

**Authentication Errors:**

```
❌ Authentication failed. Check ODOO_USER and ODOO_PASS.
```

- Verify credentials with: `docker exec -i odoo18 odoo shell -d DB_NAME`
- Check user exists: `env['res.users'].search([('login','=','admin@example.com')])`

**Page Import Errors:**

```
⚠️  Failed to import Page Title.html: 'utf-8' codec can't decode
```

- Notion export encoding issue
- Manual fix: Open in text editor, save as UTF-8
- Re-run import for that file only

**CSV Import Errors:**

```
⚠️  Failed to import task: project_id required
```

- Projects must be imported before tasks
- Check CSV header names match script expectations
- Verify project names exist in Odoo

### Module Installation Errors

**Dependency Errors:**

```
❌ Module 'document_page' depends on 'knowledge' which is not installed
```

- Check OCA repository cloned correctly
- Verify `addons_path` includes `/mnt/oca-addons`
- Restart Odoo container

**Database Lock Errors:**

```
❌ could not obtain lock on row in relation "ir_module_module"
```

- Another process is modifying modules
- Wait 30 seconds and retry
- Check: `docker exec -i odoo18 odoo shell -d DB` → `env.cr.execute("SELECT pid FROM pg_locks WHERE NOT granted")`

### Performance Issues

**Slow Wiki Page Loading:**

- Enable `attachment_indexation` for full-text search
- Add database indexes on `document_page.name`
- Consider splitting large pages into subpages

**Slow Task Kanban:**

- Limit Kanban view to 200 records with domain filter
- Archive completed tasks older than 6 months
- Add index on `project_task(stage_id, project_id)`

---

## Advanced: Image Migration

If you need to migrate Notion images to Odoo attachments:

```python
#!/usr/bin/env python3
import zipfile, re, os, base64

def migrate_images(zip_path, wiki_root_id):
    with zipfile.ZipFile(zip_path) as zf:
        # Find all image files
        images = [n for n in zf.namelist() if n.startswith('images/')]

        for img_path in images:
            img_data = zf.read(img_path)
            img_name = os.path.basename(img_path)

            # Create attachment
            att_id = models.execute_kw(DB, uid, PASS, 'ir.attachment', 'create', [{
                'name': img_name,
                'datas': base64.b64encode(img_data).decode('utf-8'),
                'res_model': 'document.page',
                'res_id': wiki_root_id,
                'mimetype': 'image/png' if img_name.endswith('.png') else 'image/jpeg'
            }])

            # Update wiki content to reference new attachment
            # (implementation depends on HTML structure)
```

---

## Summary

✅ **Completed Steps:**

1. Exported Notion workspace (HTML + CSV)
2. Installed OCA modules (20+ enterprise-level features)
3. Migrated pages → Wiki, databases → Projects/Tasks
4. Configured portal, automation, and access control
5. Optimized performance and backups

🎯 **What You Have Now:**

- Complete Notion workspace in Odoo
- Enterprise-level features on Community
- Automated workflows and email alerts
- Customer portal with statements
- Comprehensive backup strategy

📚 **Next Steps:**

- Train team on Odoo interface
- Configure additional automation rules
- Setup mobile access (web_pwa_oca)
- Integrate with existing systems (API)
- Monitor and optimize performance

---

## Support

**Documentation:**

- [Odoo 18 Documentation](https://www.odoo.com/documentation/18.0/)
- [OCA Modules](https://github.com/OCA)
- [document_page](https://github.com/OCA/knowledge)
- [dms](https://github.com/OCA/dms)

**Common Issues:**

- See [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) for hardening
- See [OCR_SERVICE_DEPLOYMENT.md](OCR_SERVICE_DEPLOYMENT.md) for OCR config
- See [infra/odoo/README.md](../infra/odoo/README.md) for deployment issues
