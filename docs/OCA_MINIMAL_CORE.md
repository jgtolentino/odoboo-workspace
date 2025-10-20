# Minimal Core OCA Modules (8 Essentials)

**Purpose**: Battle-tested OCA modules for OCR/audit/compliance Odoo 18 deployment.

## Module Matrix

| Priority | Module | Repository | Purpose | Integration |
|----------|--------|------------|---------|-------------|
| 🔴 CRITICAL | `web_responsive` | OCA/web | Mobile-friendly backend UI | Day 1 UX |
| 🔴 CRITICAL | `server_environment` | OCA/server-tools | 12-factor config (`ir.config_parameter`) | OCR API URL config |
| 🔴 CRITICAL | `queue_job` | OCA/queue | Async OCR processing | Background jobs |
| 🟡 HIGH | `web_pwa_oca` | OCA/web | Installable PWA (no App Store) | Mobile app |
| 🟡 HIGH | `auditlog` | OCA/server-tools | Model-level audit trail | hr_expense_ocr_audit |
| 🟢 MEDIUM | `storage_backend` | OCA/storage | S3/DO Spaces for receipts | Attachment storage |
| 🟢 MEDIUM | `web_environment_ribbon` | OCA/web | DEV/TEST/PROD badge | Safety control |
| ⚪ LOW | `module_auto_update` | OCA/server-tools | Auto-update on deploy | Deployment automation |

---

## Installation Guide

### Step 1: Download OCA Repositories

```bash
chmod +x scripts/download_oca_minimal.sh
./scripts/download_oca_minimal.sh
```

**Output**: `oca-modules/` directory with 4 repositories:
- `oca-modules/web/` (web_responsive, web_pwa_oca, web_environment_ribbon)
- `oca-modules/server-tools/` (server_environment, auditlog, module_auto_update)
- `oca-modules/queue/` (queue_job)
- `oca-modules/storage/` (storage_backend)

---

### Step 2: Update `odoo.conf`

```ini
[options]
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons,oca-modules/web,oca-modules/server-tools,oca-modules/queue,oca-modules/storage

# Server environment configuration
running_env = prod
server_environment_files = /etc/odoo/server_environment.json

# Queue job settings (for OCR async processing)
workers = 4
max_cron_threads = 2
```

---

### Step 3: Install Modules (Priority Order)

#### Option A: Via Odoo CLI (Recommended for CI/CD)

```bash
# Critical modules first (Day 1)
docker exec -i odoo18 odoo -d odoboo_local -i \
  web_responsive,server_environment,queue_job \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo

# High-priority modules (Week 1)
docker exec -i odoo18 odoo -d odoboo_local -i \
  web_pwa_oca,auditlog \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo

# Medium/Low-priority modules (as needed)
docker exec -i odoo18 odoo -d odoboo_local -i \
  storage_backend,web_environment_ribbon,module_auto_update \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo
```

#### Option B: Via Odoo Apps UI (Recommended for First-Time Setup)

1. **Update Apps List**: Settings → Apps → Update Apps List
2. **Search & Install** (in priority order):
   - `web_responsive` → Install
   - `server_environment` → Install
   - `queue_job` → Install
   - `web_pwa_oca` → Install
   - `auditlog` → Install
   - `storage_backend` → Install (configure DO Spaces)
   - `web_environment_ribbon` → Install
   - `module_auto_update` → Install

---

### Step 4: Configure Critical Modules

#### A. `server_environment` - OCR API Configuration

**Purpose**: Store OCR API URL in 12-factor config instead of hardcoding.

**Configuration File**: `/etc/odoo/server_environment.json`

```json
{
  "prod": {
    "ir.config_parameter": {
      "hr_expense_ocr_audit.ocr_api_url": "http://188.166.237.231:8000/ocr",
      "web.base.url": "https://your-odoo-domain.com"
    }
  },
  "dev": {
    "ir.config_parameter": {
      "hr_expense_ocr_audit.ocr_api_url": "http://localhost:8000/ocr",
      "web.base.url": "http://localhost:8069"
    }
  }
}
```

**Access in Python**:
```python
from odoo import models, fields

class HrExpense(models.Model):
    _inherit = 'hr.expense'

    def action_trigger_ocr(self):
        ocr_url = self.env['ir.config_parameter'].get_param('hr_expense_ocr_audit.ocr_api_url')
        # Use ocr_url for API call
```

---

#### B. `queue_job` - Async OCR Processing

**Purpose**: Move OCR processing to background jobs (don't block UI).

**Configuration**: Already configured in `odoo.conf` (workers=4, max_cron_threads=2)

**Usage in OCR Module**:
```python
from odoo import models
from odoo.addons.queue_job.job import job

class HrExpense(models.Model):
    _inherit = 'hr.expense'

    @job
    def process_ocr_async(self, attachment_id):
        """Background OCR processing via queue_job"""
        ocr_url = self.env['ir.config_parameter'].get_param('hr_expense_ocr_audit.ocr_api_url')
        # Call OCR API without blocking UI
        # ...

    def action_trigger_ocr(self):
        """Trigger async OCR job"""
        for expense in self:
            expense.with_delay().process_ocr_async(expense.attachment_ids[0].id)
```

**Monitor Jobs**: Settings → Technical → Queue Jobs

---

#### C. `auditlog` - Expense OCR Audit Trail

**Purpose**: Track all changes to hr_expense records for compliance.

**Configuration**: Settings → Technical → Audit → Audit Rules

**Create Rule for hr_expense**:
- **Model**: Expense (`hr.expense`)
- **Log Creates**: ✓ Yes
- **Log Writes**: ✓ Yes
- **Log Unlinks**: ✓ Yes
- **Log Reads**: ☐ No (performance)
- **Capture Action**: ✓ Yes

**Integration with `hr_expense_ocr_audit`**:
```python
# View audit log in OCR dashboard
def action_view_audit_log(self):
    return {
        'type': 'ir.actions.act_window',
        'name': 'Expense Audit Log',
        'res_model': 'auditlog.log',
        'view_mode': 'tree,form',
        'domain': [
            ('model_id.model', '=', 'hr.expense'),
            ('res_id', '=', self.id),
        ],
    }
```

---

#### D. `storage_backend` - DigitalOcean Spaces for Receipts

**Purpose**: Store receipt attachments in DO Spaces instead of PostgreSQL.

**Configuration**: Settings → Technical → Storage Backends

**Create DO Spaces Backend**:
- **Name**: DigitalOcean Spaces (Receipts)
- **Backend Type**: S3
- **Endpoint**: `https://sgp1.digitaloceanspaces.com`
- **Bucket**: `odoboo-receipts`
- **Access Key**: `DO_SPACES_ACCESS_KEY`
- **Secret Key**: `DO_SPACES_SECRET_KEY`
- **Region**: `sgp1`

**Apply to Attachments**:
- Settings → Technical → Attachment Storage Rules
- **Model**: Expense (`hr.expense`)
- **Field**: Attachment (`attachment_ids`)
- **Storage Backend**: DigitalOcean Spaces (Receipts)

---

#### E. `web_pwa_oca` - Progressive Web App

**Purpose**: Install Odoo as PWA on mobile devices (no App Store).

**Configuration**: Settings → Website → PWA Settings

**PWA Manifest**:
```json
{
  "name": "Odoboo Workspace",
  "short_name": "Odoboo",
  "description": "Odoo 18 with OCR Expense Management",
  "start_url": "/web",
  "display": "standalone",
  "theme_color": "#714B67",
  "background_color": "#FFFFFF",
  "icons": [
    {
      "src": "/web/static/src/img/odoo_logo.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
```

**Install on Mobile**:
1. Open `https://your-odoo-domain.com` in Chrome/Safari
2. Tap "Add to Home Screen"
3. PWA installs like native app

---

### Step 5: Verification Checklist

```bash
# Check installed modules
docker exec -i postgres15 psql -U odoo -d odoboo_local -c \
  "SELECT name, state FROM ir_module_module WHERE name IN (
    'web_responsive','web_pwa_oca','server_environment','queue_job',
    'auditlog','storage_backend','web_environment_ribbon','module_auto_update'
  ) ORDER BY name;"

# Expected output:
# auditlog                | installed
# module_auto_update      | installed
# queue_job               | installed
# server_environment      | installed
# storage_backend         | installed
# web_environment_ribbon  | installed
# web_pwa_oca             | installed
# web_responsive          | installed
```

---

## Integration with Existing Modules

### `hr_expense_ocr_audit`

**Enhanced with OCA**:
- `queue_job`: Async OCR processing (don't block UI on large receipts)
- `auditlog`: Track all OCR changes for compliance
- `server_environment`: Store OCR API URL in config (not hardcoded)
- `storage_backend`: Store receipt images in DO Spaces (not PostgreSQL)

### `web_dashboard_advanced`

**Enhanced with OCA**:
- `web_responsive`: Dashboard works on mobile devices
- `web_pwa_oca`: Install dashboard as PWA on mobile
- `server_environment`: Store Draxlr API keys in config

### `supabase_sync` (Future Module)

**Enhanced with OCA**:
- `queue_job`: Async Supabase sync jobs
- `server_environment`: Store Supabase credentials in config
- `auditlog`: Track all sync operations

---

## Deployment Checklist

- [ ] Download OCA repositories (`./scripts/download_oca_minimal.sh`)
- [ ] Update `odoo.conf` addons_path
- [ ] Install Critical modules (web_responsive, server_environment, queue_job)
- [ ] Configure `server_environment.json` with OCR API URL
- [ ] Configure `queue_job` workers (4 workers, 2 cron threads)
- [ ] Install High-priority modules (web_pwa_oca, auditlog)
- [ ] Configure `auditlog` rules for hr_expense
- [ ] Install Medium/Low-priority modules (storage_backend, web_environment_ribbon, module_auto_update)
- [ ] Configure DO Spaces backend for receipt storage
- [ ] Configure PWA manifest for mobile installation
- [ ] Verify all 8 modules installed (`ir_module_module` query)
- [ ] Test OCR async processing via queue_job
- [ ] Test mobile responsive UI
- [ ] Test PWA installation on mobile device

---

## Cost Impact

**OCA Modules**: **$0/month** (100% open-source)

**DO Spaces** (Optional for `storage_backend`):
- $5/month for 250GB + 1TB transfer
- Only needed if storing >500 receipt images/month

**Total Additional Cost**: $0-5/month (vs. Enterprise $100+/month)

---

## Next Steps

1. **Run Download Script**: `./scripts/download_oca_minimal.sh`
2. **Update odoo.conf**: Add OCA paths to `addons_path`
3. **Restart Odoo**: `docker-compose -f docker-compose.local.yml restart odoo`
4. **Install Critical Modules**: web_responsive, server_environment, queue_job
5. **Configure OCR Integration**: Update `hr_expense_ocr_audit` to use `queue_job` + `server_environment`

---

## Optional: Full OCA Suite (17 Additional Modules)

If you want the complete suite later, see [docs/OCA_FULL_SUITE.md](./OCA_FULL_SUITE.md) for:
- web_m2x_options, web_ir_actions_act_multi
- base_export_manager, base_view_inheritance_extension, base_user_role
- auth_session_timeout
- mis_builder (financial reporting)
- And 10 more enterprise-parity modules

**Recommendation**: Start with these 8, add others as needed.
