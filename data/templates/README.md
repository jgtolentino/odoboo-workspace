# CSV Import Templates for Notion-Style Workspace

This directory contains CSV templates for importing data into your Odoo 18 Notion-style workspace.

## 📋 Templates

### 1. Tasks Import Template (`01_tasks_import_template.csv`)

Import tasks into the Kanban board.

**Columns:**
- `name` - Task title (required)
- `project_id/name` - Project name (e.g., "Compliance & Month-End")
- `user_id/email` - Assignee email address
- `date_deadline` - Due date (YYYY-MM-DD format)
- `priority` - 0=Normal, 1=High, 2=Very High
- `tag_ids/name` - Comma-separated tags
- `stage_id/name` - Stage name (e.g., "To Do", "Doing", "Done")
- `description` - Task description (supports basic HTML)
- `parent_id/id` - Parent task ID (for subtasks)
- `planned_hours` - Estimated hours
- `x_area` - Compliance area (custom field)
- `x_evidence_url` - Link to evidence document
- `x_knowledge_page_id/name` - Link to related SOP/guide

**Example:**
```csv
name,project_id/name,user_id/email,date_deadline,priority,tag_ids/name,stage_id/name
Complete Month-End Closing,Compliance & Month-End,accountant@company.com,2026-01-31,1,"Month-End,Finance",In Progress
```

### 2. Calendar Events Template (`02_calendar_events_template.csv`)

Import calendar events and deadlines.

**Columns:**
- `name` - Event title (required)
- `start` - Start date/time (YYYY-MM-DD HH:MM:SS)
- `stop` - End date/time (YYYY-MM-DD HH:MM:SS)
- `allday` - All-day event (TRUE/FALSE)
- `location` - Event location
- `description` - Event description
- `partner_ids/email` - Comma-separated attendee emails
- `alarm_ids/name` - Comma-separated alarm names
- `categ_ids/name` - Comma-separated event categories

**Example:**
```csv
name,start,stop,allday,location,partner_ids/email,alarm_ids/name,categ_ids/name
BIR Tax Filing Deadline,2026-02-10 09:00:00,2026-02-10 17:00:00,TRUE,BIR RDO,"tax@company.com",1 day before,Tax Deadlines
```

### 3. Evidence Repository Template (`03_evidence_repository_template.csv`)

Import documents into the DMS (Document Management System).

**Columns:**
- `name` - Document name (required)
- `directory_id/name` - Folder path
- `url` - External URL to document (for linked documents)
- `mimetype` - MIME type (e.g., application/pdf)
- `tag_ids/name` - Comma-separated tags
- `owner_id/email` - Owner email address
- `description` - Document description
- `x_task_id/name` - Related task name
- `x_compliance_area` - Compliance area

**Example:**
```csv
name,directory_id/name,url,mimetype,tag_ids/name,owner_id/email
January 2026 Bank Reconciliation,Compliance Evidence,https://spaces.company.com/bank-recon.xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,"Month-End,Reconciliation",accountant@company.com
```

### 4. Knowledge Pages Template (`04_knowledge_pages_template.csv`)

Import knowledge base pages (wiki, SOPs, guides).

**Columns:**
- `name` - Page title (required)
- `parent_id/name` - Parent page name (leave empty for root pages)
- `content` - Page content (HTML format)
- `tag_ids/name` - Comma-separated tags
- `x_task_ids/name` - Related tasks (read-only, set via tasks)
- `owner_id/email` - Owner email address
- `summary` - Short description

**Example:**
```csv
name,parent_id/name,content,tag_ids/name,owner_id/email,summary
Month-End Closing SOP,Operations Workspace,"<h1>Month-End Closing Procedure</h1><p>Step-by-step guide...</p>","Month-End,SOP",accountant@company.com,Complete month-end closing procedures
```

## 🚀 Usage

### Option 1: Import via Web UI

1. **Open Odoo** at https://insightpulseai.net:8069
2. **Navigate to the target model:**
   - Tasks: Project → Tasks → List view
   - Calendar: Calendar → Events
   - Documents: Documents → Documents
   - Knowledge: Knowledge → Pages
3. **Click Favorites → Import records**
4. **Upload CSV file**
5. **Map columns** (Odoo will auto-map if column names match)
6. **Test** with a few records first
7. **Import all**

### Option 2: Import via Python Script

```bash
# On server
cd /opt/odoo/scripts

# Copy CSV files to container
docker cp /opt/odoo/data/templates/*.csv odoo18:/tmp/

# Run bulk import
docker exec -i odoo18 odoo shell -d odoo_production < bulk-import-data.py
```

## 📝 Tips

### Date Formats

- **Date:** YYYY-MM-DD (e.g., 2026-01-31)
- **DateTime:** YYYY-MM-DD HH:MM:SS (e.g., 2026-01-31 14:00:00)
- **All-day events:** Use TRUE/FALSE for `allday` column

### Email References

- Emails must exist in Odoo as users or partners
- Format: exact email address (e.g., user@company.com)
- Multiple emails: comma-separated (e.g., "user1@company.com,user2@company.com")

### Foreign Key References

- Use `/name` suffix for text lookups (e.g., `project_id/name`)
- Use `/id` suffix for ID lookups (e.g., `parent_id/id`)
- Values must match existing records exactly

### Tags and Categories

- Multiple tags: comma-separated (e.g., "Month-End,Finance,High Priority")
- Tags will be created automatically if they don't exist
- Wrap in quotes if tags contain commas

### HTML Content

- Basic HTML tags supported: `<h1>`, `<p>`, `<ul>`, `<li>`, `<strong>`, `<em>`
- Wrap HTML in quotes to preserve formatting
- Escape quotes inside HTML: `\"` or use single quotes for HTML attributes

### Import Order

Import in this order to avoid reference errors:

1. **Users/Partners** (if creating new users)
2. **Tags and Categories**
3. **Projects**
4. **Stages**
5. **DMS Folders**
6. **Knowledge Pages** (root pages first, then sub-pages)
7. **Tasks**
8. **Calendar Events**
9. **Evidence Documents**

## 🔧 Customizing Templates

### Add Custom Columns

1. **Create custom field** in Odoo:
   - Settings → Technical → Database Structure → Models
   - Find model (e.g., project.task)
   - Add field

2. **Add column to CSV:**
   - Add field name to header row
   - Prefix with `x_` for custom fields (e.g., `x_custom_field`)

### Modify Examples

The provided templates include sample data. Replace with your own:

1. Open CSV in Excel/Google Sheets
2. Delete sample rows (keep header row)
3. Add your data
4. Save as CSV (UTF-8 encoding)

### Batch Updates

You can also use CSV import to update existing records:

1. **Export existing records** first to get IDs
2. **Add `id` column** to CSV with record IDs
3. **Import with update mode** (Odoo will update instead of create)

## ⚠️ Common Issues

### Issue: "External ID not found"

**Cause:** Referenced record doesn't exist (e.g., project, user, stage)

**Fix:** Create referenced records first or check spelling

### Issue: "Invalid date format"

**Cause:** Date not in YYYY-MM-DD format

**Fix:** Format dates correctly in Excel before export

### Issue: "Required field missing"

**Cause:** Required field is empty

**Fix:** Fill required fields (usually `name` and model-specific fields)

### Issue: "Duplicate external ID"

**Cause:** Importing same record twice

**Fix:** Delete existing record or use update mode

## 📚 Additional Resources

- **Full Documentation:** `/docs/NOTION_WORKSPACE_DEPLOYMENT_GUIDE.md`
- **Import Scripts:** `/scripts/bulk-import-data.py`
- **Odoo Import Guide:** https://www.odoo.com/documentation/18.0/applications/general/export_import_data.html

## 🎯 Sample Data

All templates include sample data based on common compliance and finance workflows:

- **Tasks:** Month-end closing, tax filing, bank reconciliation
- **Calendar:** BIR deadlines, SSS/PhilHealth/Pag-IBIG contributions
- **Documents:** Bank reconciliations, tax returns, financial statements
- **Knowledge:** SOPs for month-end, tax filing, procurement, expenses

Customize these to match your organization's workflows!
