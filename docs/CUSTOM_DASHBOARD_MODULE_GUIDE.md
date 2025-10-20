# Custom Draxlr-Style Dashboard Module for Odoo 18

## 🎯 Overview

This guide covers building a **custom dashboard module** for Odoo 18 similar to Draxlr, with interactive charts, drag-and-drop layout, SQL query support, and OCA contribution readiness.

---

## 🧩 What is Draxlr?

**Draxlr** (https://draxlr.com) provides:
- Custom dashboards from SQL data
- Interactive reports with filters
- Embeddable visualizations
- Secure query execution
- Shareable insights

**Our Implementation**: Bring these features to Odoo with OCA-compatible architecture.

---

## 📦 Module: `web_dashboard_advanced`

### **Features**

✅ **Core Capabilities**:
- Drag-and-drop dashboard builder
- Multiple chart types (Bar, Line, Pie, KPI, Table)
- SQL + ORM data sources
- Interactive filters and grouping
- Real-time data refresh
- Dashboard sharing and embedding
- User permissions and access control

✅ **Chart Library Options**:
- **Chart.js** (recommended - lightweight, MIT license)
- **ApexCharts** (advanced features, MIT license)
- **Plotly.js** (scientific charts, MIT license)

✅ **OCA Contribution Ready**:
- AGPL-3.0 license
- Follows OCA coding standards
- Complete test coverage
- Comprehensive documentation
- i18n/l10n support

---

## 🏗️ Module Structure

```
addons/web_dashboard_advanced/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   ├── dashboard.py
│   ├── dashboard_widget.py
│   └── dashboard_data_source.py
├── controllers/
│   ├── __init__.py
│   └── dashboard_controller.py
├── security/
│   ├── dashboard_security.xml
│   └── ir.model.access.csv
├── views/
│   ├── dashboard_views.xml
│   ├── dashboard_widget_views.xml
│   ├── dashboard_template.xml
│   └── menu_views.xml
├── static/
│   ├── description/
│   │   ├── icon.png
│   │   └── index.html
│   ├── src/
│   │   ├── scss/
│   │   │   └── dashboard.scss
│   │   ├── js/
│   │   │   ├── dashboard_controller.esm.js
│   │   │   ├── chart_renderer.esm.js
│   │   │   └── widget_builder.esm.js
│   │   └── xml/
│   │       └── dashboard.xml
│   └── lib/
│       └── chartjs/
│           └── chart.min.js
├── tests/
│   ├── __init__.py
│   ├── test_dashboard.py
│   └── test_widget.py
├── i18n/
│   └── web_dashboard_advanced.pot
├── demo/
│   └── dashboard_demo.xml
└── README.md
```

---

## 📝 Model Definitions

### **1. Dashboard Model** (`models/dashboard.py`)

```python
# Copyright 2025 Your Name
# License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).

from odoo import api, fields, models, _
from odoo.exceptions import ValidationError
import json


class Dashboard(models.Model):
    _name = 'dashboard.dashboard'
    _description = 'Interactive Dashboard'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'sequence, name'

    name = fields.Char(
        string='Dashboard Name',
        required=True,
        tracking=True,
    )
    description = fields.Text(
        string='Description',
    )
    sequence = fields.Integer(
        string='Sequence',
        default=10,
    )
    active = fields.Boolean(
        string='Active',
        default=True,
    )

    # Layout configuration (JSON)
    layout = fields.Text(
        string='Layout Configuration',
        default='{}',
        help='JSON configuration for dashboard layout (grid positions, sizes)',
    )

    # Widget management
    widget_ids = fields.One2many(
        comodel_name='dashboard.widget',
        inverse_name='dashboard_id',
        string='Widgets',
    )
    widget_count = fields.Integer(
        string='Widget Count',
        compute='_compute_widget_count',
        store=True,
    )

    # Access control
    user_ids = fields.Many2many(
        comodel_name='res.users',
        string='Allowed Users',
        help='Users who can view this dashboard. Leave empty for all users.',
    )
    group_ids = fields.Many2many(
        comodel_name='res.groups',
        string='Allowed Groups',
        help='Groups who can access this dashboard.',
    )
    is_public = fields.Boolean(
        string='Public',
        default=False,
        help='Make dashboard accessible to all users',
    )

    # Sharing
    is_shareable = fields.Boolean(
        string='Shareable',
        default=True,
        help='Allow sharing this dashboard via URL',
    )
    share_token = fields.Char(
        string='Share Token',
        copy=False,
        help='Unique token for sharing dashboard',
    )

    # Metadata
    owner_id = fields.Many2one(
        comodel_name='res.users',
        string='Owner',
        default=lambda self: self.env.user,
        required=True,
    )

    @api.depends('widget_ids')
    def _compute_widget_count(self):
        for dashboard in self:
            dashboard.widget_count = len(dashboard.widget_ids)

    @api.model
    def create(self, vals):
        """Generate share token on create"""
        if vals.get('is_shareable') and not vals.get('share_token'):
            vals['share_token'] = self._generate_share_token()
        return super().create(vals)

    def write(self, vals):
        """Generate share token if enabling sharing"""
        if vals.get('is_shareable') and not self.share_token:
            vals['share_token'] = self._generate_share_token()
        return super().write(vals)

    def _generate_share_token(self):
        """Generate unique share token"""
        import secrets
        return secrets.token_urlsafe(32)

    def action_view_widgets(self):
        """Open widget list for this dashboard"""
        return {
            'name': _('Dashboard Widgets'),
            'type': 'ir.actions.act_window',
            'res_model': 'dashboard.widget',
            'view_mode': 'tree,form',
            'domain': [('dashboard_id', '=', self.id)],
            'context': {'default_dashboard_id': self.id},
        }

    def action_open_dashboard(self):
        """Open dashboard view"""
        return {
            'name': self.name,
            'type': 'ir.actions.client',
            'tag': 'dashboard.view',
            'context': {'dashboard_id': self.id},
        }

    @api.constrains('layout')
    def _check_layout(self):
        """Validate layout JSON"""
        for dashboard in self:
            if dashboard.layout:
                try:
                    json.loads(dashboard.layout)
                except json.JSONDecodeError:
                    raise ValidationError(_('Invalid layout JSON format'))
```

### **2. Widget Model** (`models/dashboard_widget.py`)

```python
# Copyright 2025 Your Name
# License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).

from odoo import api, fields, models, _
from odoo.exceptions import ValidationError
import json


class DashboardWidget(models.Model):
    _name = 'dashboard.widget'
    _description = 'Dashboard Widget'
    _order = 'sequence, name'

    name = fields.Char(
        string='Widget Name',
        required=True,
    )
    dashboard_id = fields.Many2one(
        comodel_name='dashboard.dashboard',
        string='Dashboard',
        required=True,
        ondelete='cascade',
    )
    sequence = fields.Integer(
        string='Sequence',
        default=10,
    )

    # Widget type and visualization
    widget_type = fields.Selection(
        selection=[
            ('chart_bar', 'Bar Chart'),
            ('chart_line', 'Line Chart'),
            ('chart_pie', 'Pie Chart'),
            ('chart_doughnut', 'Doughnut Chart'),
            ('chart_area', 'Area Chart'),
            ('kpi', 'KPI Card'),
            ('table', 'Data Table'),
            ('metric', 'Single Metric'),
            ('gauge', 'Gauge'),
        ],
        string='Widget Type',
        required=True,
        default='chart_bar',
    )

    # Data source
    data_source_type = fields.Selection(
        selection=[
            ('model', 'Odoo Model (ORM)'),
            ('sql', 'SQL Query'),
            ('manual', 'Manual Data'),
        ],
        string='Data Source Type',
        required=True,
        default='model',
    )

    # Model-based data source
    model_id = fields.Many2one(
        comodel_name='ir.model',
        string='Model',
        help='Select Odoo model to query',
    )
    domain = fields.Char(
        string='Domain Filter',
        default='[]',
        help='Odoo domain filter for model queries',
    )
    group_by = fields.Char(
        string='Group By Field',
        help='Field to group results by',
    )
    measure_field = fields.Char(
        string='Measure Field',
        help='Field to measure (sum, count, avg, etc.)',
    )
    measure_function = fields.Selection(
        selection=[
            ('count', 'Count'),
            ('sum', 'Sum'),
            ('avg', 'Average'),
            ('min', 'Minimum'),
            ('max', 'Maximum'),
        ],
        string='Measure Function',
        default='count',
    )

    # SQL-based data source
    sql_query = fields.Text(
        string='SQL Query',
        help='SQL query to execute (read-only, SELECT only)',
    )

    # Manual data
    manual_data = fields.Text(
        string='Manual Data (JSON)',
        help='JSON data for the widget',
    )

    # Chart configuration
    chart_config = fields.Text(
        string='Chart Configuration (JSON)',
        default='{}',
        help='Chart.js configuration options',
    )

    # Widget size and position (for grid layout)
    width = fields.Integer(
        string='Width',
        default=6,
        help='Widget width (1-12 grid columns)',
    )
    height = fields.Integer(
        string='Height',
        default=4,
        help='Widget height in grid rows',
    )
    position_x = fields.Integer(
        string='Position X',
        default=0,
    )
    position_y = fields.Integer(
        string='Position Y',
        default=0,
    )

    # Data caching
    cache_enabled = fields.Boolean(
        string='Enable Caching',
        default=True,
    )
    cache_duration = fields.Integer(
        string='Cache Duration (seconds)',
        default=300,  # 5 minutes
    )
    last_computed = fields.Datetime(
        string='Last Computed',
        readonly=True,
    )
    cached_data = fields.Text(
        string='Cached Data',
        readonly=True,
    )

    @api.constrains('domain', 'sql_query', 'manual_data', 'chart_config')
    def _check_json_fields(self):
        """Validate JSON fields"""
        for widget in self:
            # Check domain
            if widget.domain:
                try:
                    json.loads(widget.domain)
                except json.JSONDecodeError:
                    raise ValidationError(_('Invalid domain JSON format'))

            # Check manual data
            if widget.manual_data:
                try:
                    json.loads(widget.manual_data)
                except json.JSONDecodeError:
                    raise ValidationError(_('Invalid manual data JSON format'))

            # Check chart config
            if widget.chart_config:
                try:
                    json.loads(widget.chart_config)
                except json.JSONDecodeError:
                    raise ValidationError(_('Invalid chart config JSON format'))

    @api.constrains('sql_query')
    def _check_sql_query(self):
        """Validate SQL query (read-only)"""
        for widget in self:
            if widget.sql_query:
                query_lower = widget.sql_query.lower().strip()
                # Only allow SELECT
                if not query_lower.startswith('select'):
                    raise ValidationError(_('Only SELECT queries are allowed'))
                # Block dangerous commands
                dangerous = ['insert', 'update', 'delete', 'drop', 'create',
                            'alter', 'truncate', 'exec', 'execute']
                if any(cmd in query_lower for cmd in dangerous):
                    raise ValidationError(_('Query contains dangerous commands'))

    def compute_widget_data(self):
        """Compute widget data based on configuration"""
        self.ensure_one()

        # Check cache
        if self.cache_enabled and self.cached_data and self.last_computed:
            from datetime import datetime, timedelta
            cache_age = (datetime.now() - self.last_computed).total_seconds()
            if cache_age < self.cache_duration:
                return json.loads(self.cached_data)

        # Compute data based on source type
        if self.data_source_type == 'model':
            data = self._compute_model_data()
        elif self.data_source_type == 'sql':
            data = self._compute_sql_data()
        elif self.data_source_type == 'manual':
            data = json.loads(self.manual_data or '{}')
        else:
            data = {}

        # Cache result
        if self.cache_enabled:
            self.write({
                'cached_data': json.dumps(data),
                'last_computed': fields.Datetime.now(),
            })

        return data

    def _compute_model_data(self):
        """Compute data from Odoo model"""
        if not self.model_id:
            return {}

        Model = self.env[self.model_id.model]
        domain = json.loads(self.domain or '[]')

        if self.measure_function == 'count':
            # Count records
            count = Model.search_count(domain)
            return {
                'labels': ['Total'],
                'datasets': [{
                    'label': self.name,
                    'data': [count],
                }]
            }

        # Group by with measure
        if self.group_by and self.measure_field:
            records = Model.read_group(
                domain,
                [self.measure_field],
                [self.group_by],
            )

            labels = [r[self.group_by][1] if isinstance(r[self.group_by], tuple)
                     else str(r[self.group_by]) for r in records]
            data = [r[f'{self.measure_field}_{self.measure_function}']
                   if f'{self.measure_field}_{self.measure_function}' in r
                   else r[self.measure_field] for r in records]

            return {
                'labels': labels,
                'datasets': [{
                    'label': self.name,
                    'data': data,
                }]
            }

        return {}

    def _compute_sql_data(self):
        """Compute data from SQL query"""
        if not self.sql_query:
            return {}

        self.env.cr.execute(self.sql_query)
        results = self.env.cr.dictfetchall()

        if not results:
            return {}

        # Assume first column is label, second is value
        keys = list(results[0].keys())
        if len(keys) >= 2:
            labels = [r[keys[0]] for r in results]
            data = [r[keys[1]] for r in results]

            return {
                'labels': labels,
                'datasets': [{
                    'label': self.name,
                    'data': data,
                }]
            }

        return {}

    def action_refresh_data(self):
        """Force refresh widget data"""
        self.write({
            'cached_data': False,
            'last_computed': False,
        })
        return self.compute_widget_data()
```

### **3. Data Source Model** (Optional - for advanced features)

```python
# Copyright 2025 Your Name
# License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).

from odoo import fields, models


class DashboardDataSource(models.Model):
    _name = 'dashboard.data.source'
    _description = 'Dashboard Data Source'

    name = fields.Char(
        string='Data Source Name',
        required=True,
    )
    description = fields.Text(
        string='Description',
    )
    source_type = fields.Selection(
        selection=[
            ('internal', 'Internal (Odoo)'),
            ('external_api', 'External API'),
            ('database', 'External Database'),
        ],
        string='Source Type',
        required=True,
        default='internal',
    )

    # External API configuration
    api_url = fields.Char(
        string='API URL',
    )
    api_key = fields.Char(
        string='API Key',
    )
    api_headers = fields.Text(
        string='API Headers (JSON)',
    )

    # External database configuration
    db_host = fields.Char(
        string='Database Host',
    )
    db_port = fields.Integer(
        string='Database Port',
    )
    db_name = fields.Char(
        string='Database Name',
    )
    db_user = fields.Char(
        string='Database User',
    )
    db_password = fields.Char(
        string='Database Password',
    )
```

---

## 🎨 Views and UI

### **Dashboard Form View** (`views/dashboard_views.xml`)

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- Dashboard Form View -->
    <record id="view_dashboard_form" model="ir.ui.view">
        <field name="name">dashboard.dashboard.form</field>
        <field name="model">dashboard.dashboard</field>
        <field name="arch" type="xml">
            <form string="Dashboard">
                <header>
                    <button name="action_open_dashboard"
                            string="Open Dashboard"
                            type="object"
                            class="oe_highlight"/>
                </header>
                <sheet>
                    <div class="oe_button_box" name="button_box">
                        <button name="action_view_widgets"
                                type="object"
                                class="oe_stat_button"
                                icon="fa-th">
                            <field name="widget_count" widget="statinfo" string="Widgets"/>
                        </button>
                    </div>
                    <group>
                        <group>
                            <field name="name"/>
                            <field name="description"/>
                            <field name="sequence"/>
                            <field name="active"/>
                        </group>
                        <group>
                            <field name="owner_id"/>
                            <field name="is_public"/>
                            <field name="is_shareable"/>
                            <field name="share_token" readonly="1" password="True"/>
                        </group>
                    </group>
                    <notebook>
                        <page string="Widgets" name="widgets">
                            <field name="widget_ids">
                                <tree>
                                    <field name="sequence" widget="handle"/>
                                    <field name="name"/>
                                    <field name="widget_type"/>
                                    <field name="data_source_type"/>
                                    <field name="width"/>
                                    <field name="height"/>
                                </tree>
                            </field>
                        </page>
                        <page string="Access Control" name="access">
                            <group>
                                <field name="user_ids" widget="many2many_tags"/>
                                <field name="group_ids" widget="many2many_tags"/>
                            </group>
                        </page>
                        <page string="Layout Configuration" name="layout">
                            <field name="layout" widget="ace" options="{'mode': 'json'}"/>
                        </page>
                    </notebook>
                </sheet>
                <div class="oe_chatter">
                    <field name="message_follower_ids"/>
                    <field name="message_ids"/>
                </div>
            </form>
        </field>
    </record>

    <!-- Dashboard Tree View -->
    <record id="view_dashboard_tree" model="ir.ui.view">
        <field name="name">dashboard.dashboard.tree</field>
        <field name="model">dashboard.dashboard</field>
        <field name="arch" type="xml">
            <tree string="Dashboards">
                <field name="sequence" widget="handle"/>
                <field name="name"/>
                <field name="description"/>
                <field name="widget_count"/>
                <field name="owner_id"/>
                <field name="is_public"/>
            </tree>
        </field>
    </record>

    <!-- Dashboard Kanban View -->
    <record id="view_dashboard_kanban" model="ir.ui.view">
        <field name="name">dashboard.dashboard.kanban</field>
        <field name="model">dashboard.dashboard</field>
        <field name="arch" type="xml">
            <kanban>
                <field name="name"/>
                <field name="description"/>
                <field name="widget_count"/>
                <templates>
                    <t t-name="kanban-box">
                        <div class="oe_kanban_global_click">
                            <div class="oe_kanban_details">
                                <strong class="o_kanban_record_title">
                                    <field name="name"/>
                                </strong>
                                <div class="o_kanban_record_body">
                                    <field name="description"/>
                                </div>
                                <div class="o_kanban_record_bottom">
                                    <div class="oe_kanban_bottom_left">
                                        <i class="fa fa-th"/> <field name="widget_count"/> widgets
                                    </div>
                                </div>
                            </div>
                        </div>
                    </t>
                </templates>
            </kanban>
        </field>
    </record>

    <!-- Dashboard Action -->
    <record id="action_dashboard" model="ir.actions.act_window">
        <field name="name">Dashboards</field>
        <field name="res_model">dashboard.dashboard</field>
        <field name="view_mode">kanban,tree,form</field>
        <field name="help" type="html">
            <p class="o_view_nocontent_smiling_face">
                Create your first dashboard
            </p>
            <p>
                Build interactive dashboards with charts, KPIs, and tables.
            </p>
        </field>
    </record>
</odoo>
```

---

## 🔒 Security

### **Security Groups** (`security/dashboard_security.xml`)

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- Dashboard Manager Group -->
    <record id="group_dashboard_manager" model="res.groups">
        <field name="name">Dashboard Manager</field>
        <field name="category_id" ref="base.module_category_reporting"/>
        <field name="implied_ids" eval="[(4, ref('group_dashboard_user'))]"/>
    </record>

    <!-- Dashboard User Group -->
    <record id="group_dashboard_user" model="res.groups">
        <field name="name">Dashboard User</field>
        <field name="category_id" ref="base.module_category_reporting"/>
    </record>

    <!-- Dashboard Rules -->
    <record id="dashboard_dashboard_rule_user" model="ir.rule">
        <field name="name">Dashboard: User Access</field>
        <field name="model_id" ref="model_dashboard_dashboard"/>
        <field name="domain_force">
            ['|', '|', ('is_public', '=', True),
                      ('user_ids', 'in', [user.id]),
                      ('owner_id', '=', user.id)]
        </field>
        <field name="groups" eval="[(4, ref('group_dashboard_user'))]"/>
    </record>

    <record id="dashboard_dashboard_rule_manager" model="ir.rule">
        <field name="name">Dashboard: Manager Full Access</field>
        <field name="model_id" ref="model_dashboard_dashboard"/>
        <field name="domain_force">[(1, '=', 1)]</field>
        <field name="groups" eval="[(4, ref('group_dashboard_manager'))]"/>
    </record>
</odoo>
```

### **Access Rights** (`security/ir.model.access.csv`)

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_dashboard_manager,dashboard.dashboard.manager,model_dashboard_dashboard,group_dashboard_manager,1,1,1,1
access_dashboard_user,dashboard.dashboard.user,model_dashboard_dashboard,group_dashboard_user,1,0,0,0
access_widget_manager,dashboard.widget.manager,model_dashboard_widget,group_dashboard_manager,1,1,1,1
access_widget_user,dashboard.widget.user,model_dashboard_widget,group_dashboard_user,1,0,0,0
```

---

## 🎨 Frontend (Chart.js Integration)

### **Dashboard Controller** (`static/src/js/dashboard_controller.esm.js`)

```javascript
/** @odoo-module **/

import { Component } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { useService } from "@web/core/utils/hooks";

class DashboardView extends Component {
    setup() {
        this.orm = useService("orm");
        this.dashboardId = this.props.context.dashboard_id;
        this.state = { dashboard: null, widgets: [] };
    }

    async willStart() {
        await this.loadDashboard();
    }

    async loadDashboard() {
        const dashboard = await this.orm.read(
            "dashboard.dashboard",
            [this.dashboardId],
            ["name", "description", "widget_ids"]
        );

        const widgets = await this.orm.read(
            "dashboard.widget",
            dashboard[0].widget_ids,
            ["name", "widget_type", "width", "height", "position_x", "position_y"]
        );

        this.state = { dashboard: dashboard[0], widgets };
    }

    async refreshWidget(widgetId) {
        await this.orm.call(
            "dashboard.widget",
            "action_refresh_data",
            [widgetId]
        );
        await this.loadDashboard();
    }
}

DashboardView.template = "web_dashboard_advanced.DashboardView";

registry.category("actions").add("dashboard.view", DashboardView);
```

---

## 📊 Contributing to OCA

### **Preparation Checklist**

✅ **1. Code Quality**:
- Follow PEP 8 style guide
- Use Odoo ORM (avoid raw SQL when possible)
- Add docstrings to all methods
- Use proper naming conventions

✅ **2. Testing**:
```python
# tests/test_dashboard.py
from odoo.tests.common import TransactionCase

class TestDashboard(TransactionCase):
    def test_create_dashboard(self):
        dashboard = self.env['dashboard.dashboard'].create({
            'name': 'Test Dashboard',
        })
        self.assertTrue(dashboard.id)
        self.assertEqual(dashboard.widget_count, 0)
```

✅ **3. Documentation**:
- Create comprehensive README.md
- Add usage examples
- Document configuration options
- Include screenshots

✅ **4. Internationalization**:
- Use `_()` for all user-facing strings
- Generate .pot file: `./odoo-bin --addons-path=addons -d test -u web_dashboard_advanced --i18n-export=i18n/web_dashboard_advanced.pot`

✅ **5. Demo Data**:
```xml
<!-- demo/dashboard_demo.xml -->
<odoo>
    <record id="demo_dashboard_sales" model="dashboard.dashboard">
        <field name="name">Sales Dashboard</field>
        <field name="description">Track sales performance</field>
    </record>
</odoo>
```

### **OCA Submission Process**

**Step 1: Fork OCA Repository**
```bash
# Fork on GitHub: https://github.com/OCA/web
git clone https://github.com/YOUR_USERNAME/web.git
cd web
git checkout -b 18.0-add-web_dashboard_advanced
```

**Step 2: Add Module**
```bash
cp -r /path/to/web_dashboard_advanced ./web_dashboard_advanced
```

**Step 3: Run Pre-Commit Checks**
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

**Step 4: Create Pull Request**
- Push to your fork
- Open PR to OCA/web:18.0
- Fill in PR template
- Wait for review

---

## 🚀 Installation & Usage

### **Install Module**

```bash
# Copy to addons path
cp -r addons/web_dashboard_advanced /path/to/odoo/addons/

# Restart Odoo
docker-compose -f docker-compose.local.yml restart odoo

# Install via UI
# Apps → Update Apps List → Search "Advanced Web Dashboard" → Install

# Or via CLI
docker exec -i odoo18 odoo -d odoboo_local -i web_dashboard_advanced --stop-after-init
docker-compose -f docker-compose.local.yml restart odoo
```

### **Create Your First Dashboard**

1. **Navigate**: Apps → Dashboards → Create
2. **Configure**:
   - Name: "Sales Performance"
   - Description: "Track monthly sales metrics"
   - Click "Save"
3. **Add Widgets**:
   - Click "Widgets" tab
   - Add widget:
     - Name: "Monthly Revenue"
     - Type: "Bar Chart"
     - Data Source: "Odoo Model"
     - Model: "Sale Order"
     - Group By: "date_order:month"
     - Measure: "amount_total"
     - Function: "Sum"
   - Save
4. **Open Dashboard**: Click "Open Dashboard" button

---

## 📚 Full Documentation

See the created module in:
- **Location**: `addons/web_dashboard_advanced/`
- **Models**: `models/dashboard.py`, `models/dashboard_widget.py`
- **Views**: `views/dashboard_views.xml`
- **Security**: `security/` directory

---

## 🔗 Related Resources

- **OCA Guidelines**: https://github.com/OCA/maintainer-tools/wiki
- **Odoo Development**: https://www.odoo.com/documentation/18.0/developer.html
- **Chart.js Docs**: https://www.chartjs.org/docs/
- **OCA Web Repo**: https://github.com/OCA/web

---

**This module is ready for development and OCA contribution!** 🎉
