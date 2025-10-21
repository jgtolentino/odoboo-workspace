# OCA Modules Installation Guide

Complete guide for installing OCA (Odoo Community Association) modules via GitHub Actions or scripts.

## ⚠️ Important: Odoo 18 Compatibility

**Current Status:**

- Odoo Version: **18.0** (Latest - Released October 2024)
- OCA Modules: **Most are for Odoo 17.0 and earlier**
- Compatibility: **Limited** - OCA is still updating modules for Odoo 18

**Recommendation:**

- Use Odoo 17.0 if you need extensive OCA module support
- For Odoo 18.0, only install OCA modules that explicitly support version 18.0
- The system will automatically fall back to 17.0 modules if 18.0 is unavailable

## 📦 Installation Methods

### Method 1: GitHub Actions (Recommended)

**Trigger Workflow:**

1. Go to: https://github.com/jgtolentino/odoboo-workspace/actions/workflows/install-oca-modules.yml
2. Click **Run workflow**
3. Enter parameters:
   - **Modules**: Comma-separated list (e.g., `web_responsive,server_mode`)
   - **Database**: `insightpulse_prod` (default)
   - **OCA Version**: `18.0` or `17.0`
4. Click **Run workflow**

**Example:**

```
Modules: web_responsive,web_environment_ribbon
Database: insightpulse_prod
OCA Version: 18.0
```

### Method 2: Direct Script Execution

**On the droplet:**

```bash
ssh root@188.166.237.231
cd /opt/odoo
./install-oca-module.sh web_responsive web insightpulse_prod 18.0
```

**Parameters:**

1. Module name (e.g., `web_responsive`)
2. OCA repository (e.g., `web`)
3. Database name (default: `insightpulse_prod`)
4. OCA version (default: `18.0`)

## 🗂️ Common OCA Repositories & Modules

### Web Enhancements (OCA/web)

- `web_responsive` - Mobile-friendly responsive interface
- `web_environment_ribbon` - Show environment indicator (dev/staging/prod)
- `web_theme_classic` - Classic Odoo theme
- `web_dialog_size` - Resizable dialogs
- `web_widget_color` - Color picker widget

### Server Tools (OCA/server-tools)

- `server_mode` - Show server mode indicator
- `base_technical_features` - Show technical features to admins
- `date_range` - Date range management
- `excel_import_export` - Excel import/export utilities
- `auto_backup` - Automatic database backups

### Server Environment (OCA/server-env)

- `server_environment` - Environment-based configuration

### Reporting (OCA/reporting-engine)

- `report_xlsx` - Excel report generation
- `report_qweb_pdf_watermark` - PDF watermarks
- `report_py3o` - LibreOffice report templates

### Partner/Contact (OCA/partner-contact)

- `partner_firstname` - Split first/last name for contacts
- `partner_second_lastname` - Second lastname support
- `partner_contact_gender` - Gender field for contacts

### Account/Finance (OCA/account-financial-tools)

- `account_move_line_tax_editable` - Editable taxes
- `account_fiscal_year` - Fiscal year management

## 📋 Installation Examples

### Example 1: Install Web Responsive

```bash
# Via GitHub Actions
Modules: web_responsive
OCA Version: 18.0

# Via Script
./install-oca-module.sh web_responsive web
```

### Example 2: Install Multiple Modules

```bash
# Via GitHub Actions
Modules: web_responsive,server_mode,web_environment_ribbon
OCA Version: 18.0
```

### Example 3: Install with Fallback to 17.0

```bash
# If module not available in 18.0, automatically uses 17.0
./install-oca-module.sh web_responsive web insightpulse_prod 18.0
```

## 🔍 Finding Available Modules

### Browse OCA Repositories:

- Web: https://github.com/OCA/web
- Server Tools: https://github.com/OCA/server-tools
- Reporting: https://github.com/OCA/reporting-engine
- Full List: https://github.com/OCA

### Check Module Availability:

```bash
# Clone repo and list modules
git clone --depth 1 --branch 18.0 https://github.com/OCA/web.git
ls web/
```

## ✅ Verifying Installation

### Method 1: Via Odoo UI

1. Go to: https://insightpulseai.net?debug=1
2. Click **Apps** menu
3. Remove **Apps** filter (to see all modules)
4. Search for your module name
5. Status should show **Installed**

### Method 2: Via Database Query

```bash
ssh root@188.166.237.231
docker exec odoo-db psql -U odoo -d insightpulse_prod -c "
  SELECT name, state, shortdesc
  FROM ir_module_module
  WHERE name = 'web_responsive';
"
```

### Method 3: Check Logs

```bash
ssh root@188.166.237.231
docker logs odoo18 | grep "web_responsive"
```

## 🐛 Troubleshooting

### Module Not Found in OCA Repository

**Problem:** `Module not found in OCA/web`

**Solution:**

1. Check if module exists: https://github.com/OCA/web/tree/18.0
2. Try different OCA version (17.0, 16.0)
3. Check alternative repositories

### Installation Failed

**Problem:** Module installation failed during `odoo -i`

**Causes:**

- Missing dependencies
- Python version mismatch (Odoo 18 needs Python 3.10+)
- Incompatible with Odoo 18

**Solution:**

1. Check module dependencies in `__manifest__.py`
2. Install dependencies first
3. Try Odoo 17.0 version if 18.0 incompatible

### Module Not Visible in Apps Menu

**Problem:** Installed but not showing in Odoo

**Solution:**

1. Enable Developer Mode: `?debug=1`
2. Apps → Update Apps List
3. Remove filter to show all modules (not just "Apps")

### Addons Path Not Updated

**Problem:** Odoo can't find OCA modules

**Solution:**

```bash
# Check odoo.conf
docker exec odoo18 cat /etc/odoo/odoo.conf | grep addons_path

# Should include: /opt/odoo/addons/oca
```

## 🔄 Upgrading OCA Modules

To upgrade existing OCA modules:

```bash
# Via GitHub Actions
Modules: web_responsive
OCA Version: 18.0
# (Will pull latest version)

# Via Script
./install-oca-module.sh web_responsive web insightpulse_prod 18.0
# Then restart Odoo
docker restart odoo18
```

## 📚 Recommended OCA Modules for Production

### Essential:

- `web_responsive` - Mobile support
- `server_mode` - Environment indicator
- `auto_backup` - Database backups

### Nice to Have:

- `web_environment_ribbon` - Visual environment indicator
- `date_range` - Date management
- `report_xlsx` - Excel exports

### Advanced:

- `server_environment` - Environment config
- `base_technical_features` - Advanced settings

## 🚨 Known Issues with Odoo 18

**OCA Module Availability:**

- Most OCA modules are still being updated for Odoo 18
- Check GitHub branch availability before installing
- Fall back to Odoo 17.0 for maximum OCA compatibility

**Python Dependencies:**

- Odoo 18 requires Python 3.10+
- Some OCA modules may have outdated Python dependencies

**Database Schema:**

- Odoo 18 has schema changes from 17.0
- OCA 17.0 modules may not be fully compatible

## 📞 Support

For OCA-specific issues:

- OCA GitHub: https://github.com/OCA
- OCA Documentation: https://odoo-community.org
- Admin: jgtolentino.rn@gmail.com
