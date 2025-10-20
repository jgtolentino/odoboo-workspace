# Local Testing Guide - Odoo 18 + OCA Enterprise Modules

**Status**: ✅ Running
**Environment**: Local Docker (PostgreSQL + Odoo 18)
**Access**: http://localhost:8069

---

## Quick Start

### 1. Create Database

Open http://localhost:8069 and fill in:

```
Database Name: odoboo_local
Email: admin@odoboo.local
Password: admin
Language: English
Country: Philippines
Demo Data: ✅ Load demonstration data (recommended)
```

**Click "Create Database"** (takes 2-3 minutes)

---

## 2. Install OCA Enterprise Modules

After database creation, go to **Apps** menu and install:

### Core Enterprise Features (OCA Replacements)

**📚 Knowledge & Documents (Notion-style)**
- `knowledge` - Knowledge base with hierarchical pages
- `document_page` - Wiki-style documentation

**💰 Full Accounting**
- `account_asset_management` - Asset depreciation
- `account_financial_report` - Balance sheet, P&L, cash flow
- `account_budget` - Budget management
- `mis_builder` - Management reports & KPIs

**📧 Communication**
- `mail_gateway` - Multi-provider email gateway
- `mail_tracking` - Email tracking
- `mail_debrand` - Remove Odoo branding

**🎨 Enhanced UI**
- `web_responsive` - Mobile-responsive design
- `web_dashboard` - Customizable dashboards
- `web_timeline` - Timeline views

**📊 Project Management**
- `project_task_default_stage` - Default stages
- `project_timeline` - Gantt charts
- `project_template` - Project templates

**🔧 Server Tools**
- `base_tier_validation` - Multi-level approval workflows
- `auditlog` - Audit trails
- `server_environment` - Environment-based configuration

---

## 3. Access Points

**Web Interface**: http://localhost:8069
**Database**: `localhost:5432`
- User: `odoo`
- Password: `odoo`
- Database: `odoboo_local`

**Odoo Shell** (for development):
```bash
docker exec -it odoo18 odoo shell -d odoboo_local
```

**Logs**:
```bash
docker-compose -f docker-compose.local.yml logs -f odoo
```

---

## 4. Development Workflow

### Hot Reload Enabled
Changes to Python files automatically reload (dev mode active).

### Update Modules After Code Changes
```bash
docker exec odoo18 odoo -d odoboo_local -u module_name --stop-after-init
```

### Install New Module
```bash
docker exec odoo18 odoo -d odoboo_local -i module_name --stop-after-init
```

### Access Database Directly
```bash
docker exec -it postgres15 psql -U odoo -d odoboo_local
```

---

## 5. OCA Enterprise Feature Comparison

| Enterprise Feature | OCA Replacement | Status |
|--------------------|-----------------|---------|
| **Knowledge** (Notion-like) | knowledge, document_page | ✅ Available |
| **Full Accounting** | account_asset_management, mis_builder | ✅ Available |
| **Field Service** | fieldservice | ✅ Available (project repo) |
| **Studio** | Custom development (VS Code) | ⚠️ Code-based |
| **Helpdesk** | helpdesk_mgmt | ✅ Available |
| **Manufacturing PLM** | mrp_bom_version | ✅ Available |
| **Marketing Automation** | marketing_automation | ✅ Available (social repo) |

---

## 6. Testing Checklist

- [ ] Database created successfully
- [ ] All OCA modules visible in Apps menu
- [ ] Knowledge module installed (Notion-style workspace)
- [ ] Accounting modules installed (financial reports work)
- [ ] Project management with Gantt charts
- [ ] Responsive UI works on mobile
- [ ] Email gateway configured
- [ ] Multi-level approval workflows

---

## 7. Stop/Start Commands

**Stop**:
```bash
docker-compose -f docker-compose.local.yml down
```

**Start**:
```bash
docker-compose -f docker-compose.local.yml up -d
```

**Restart Odoo Only**:
```bash
docker-compose -f docker-compose.local.yml restart odoo
```

**View Addon Paths**:
```bash
docker exec odoo18 cat /etc/odoo/odoo.conf | grep addons_path
```

---

## 8. Next Steps

1. ✅ **Local Testing** (current stage)
2. **VS Code Extension** - Build Odoo workspace development tools
3. **CI/CD Pipeline** - GitHub Actions for automated testing
4. **DigitalOcean Deploy** - Production deployment with managed database

---

**Time to Complete**: ~15 minutes
**Ready for**: Enterprise feature testing with OCA modules
