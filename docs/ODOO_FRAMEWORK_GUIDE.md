# Odoo as a Native Python Framework

**Understanding Odoo Framework**: Building custom business applications using Odoo's Python framework, not just using pre-built ERP modules.

---

## What is Odoo Framework?

**Odoo Framework** = Python web application framework specifically designed for business applications

Think of it like:
- **Django** → General web framework
- **Ruby on Rails** → General web framework
- **Odoo Framework** → Business application framework (built on top of Python)

### Architecture Layers

```
Your Custom Business App
        ↓
Odoo Framework (Python ORM + Web + Workflows)
        ↓
PostgreSQL Database
        ↓
Web Server (nginx/Apache)
```

---

## Odoo Framework Components

### 1. **ORM (Object-Relational Mapping)**

**Like**: Django ORM, SQLAlchemy, Prisma
**Purpose**: Define database models in Python, not SQL

**Example - Define a Customer Model**:

```python
# addons/my_custom_app/models/customer.py
from odoo import models, fields, api

class Customer(models.Model):
    _name = 'my_app.customer'  # Table name: my_app_customer
    _description = 'Customer Record'

    # Fields (automatic database columns)
    name = fields.Char(string='Customer Name', required=True)
    email = fields.Char(string='Email')
    phone = fields.Char(string='Phone')

    # Relational fields
    company_id = fields.Many2one('res.company', string='Company')
    order_ids = fields.One2many('my_app.order', 'customer_id', string='Orders')

    # Computed fields
    total_orders = fields.Integer(compute='_compute_total_orders')

    # Python methods (business logic)
    @api.depends('order_ids')
    def _compute_total_orders(self):
        for record in self:
            record.total_orders = len(record.order_ids)

    def send_welcome_email(self):
        """Business logic method"""
        # Send email using Odoo's email framework
        self.env['mail.mail'].create({
            'email_to': self.email,
            'subject': 'Welcome!',
            'body_html': '<p>Welcome to our platform!</p>'
        }).send()
```

**This creates**:
```sql
-- Automatic PostgreSQL table
CREATE TABLE my_app_customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    email VARCHAR,
    phone VARCHAR,
    company_id INTEGER REFERENCES res_company(id),
    create_date TIMESTAMP DEFAULT NOW(),
    write_date TIMESTAMP,
    create_uid INTEGER REFERENCES res_users(id),
    write_uid INTEGER REFERENCES res_users(id)
);
```

### 2. **Views (UI Framework)**

**Like**: React components, Vue templates, Django templates
**Purpose**: Define UI in XML (QWeb template engine)

**Example - Customer Form View**:

```xml
<!-- addons/my_custom_app/views/customer_views.xml -->
<odoo>
    <record id="view_customer_form" model="ir.ui.view">
        <field name="name">customer.form</field>
        <field name="model">my_app.customer</field>
        <field name="arch" type="xml">
            <form string="Customer">
                <sheet>
                    <group>
                        <field name="name"/>
                        <field name="email"/>
                        <field name="phone"/>
                        <field name="company_id"/>
                    </group>
                    <notebook>
                        <page string="Orders">
                            <field name="order_ids">
                                <tree>
                                    <field name="name"/>
                                    <field name="amount_total"/>
                                    <field name="state"/>
                                </tree>
                            </field>
                        </page>
                    </notebook>
                </sheet>
            </form>
        </field>
    </record>

    <!-- Tree/List View -->
    <record id="view_customer_tree" model="ir.ui.view">
        <field name="name">customer.tree</field>
        <field name="model">my_app.customer</field>
        <field name="arch" type="xml">
            <tree>
                <field name="name"/>
                <field name="email"/>
                <field name="phone"/>
                <field name="total_orders"/>
            </tree>
        </field>
    </record>

    <!-- Search View (filters) -->
    <record id="view_customer_search" model="ir.ui.view">
        <field name="name">customer.search</field>
        <field name="model">my_app.customer</field>
        <field name="arch" type="xml">
            <search>
                <field name="name"/>
                <field name="email"/>
                <filter name="has_orders" string="Has Orders"
                        domain="[('total_orders', '>', 0)]"/>
            </search>
        </field>
    </record>
</odoo>
```

### 3. **Controllers (Web Routes)**

**Like**: Express routes, Django views, Rails controllers
**Purpose**: Handle HTTP requests

```python
# addons/my_custom_app/controllers/main.py
from odoo import http
from odoo.http import request

class CustomerController(http.Controller):

    @http.route('/api/customers', type='json', auth='user')
    def get_customers(self, **kwargs):
        """JSON API endpoint"""
        customers = request.env['my_app.customer'].search([])
        return [{
            'id': c.id,
            'name': c.name,
            'email': c.email,
            'total_orders': c.total_orders
        } for c in customers]

    @http.route('/customers/<int:customer_id>', type='http', auth='public', website=True)
    def customer_detail(self, customer_id, **kwargs):
        """Public web page"""
        customer = request.env['my_app.customer'].sudo().browse(customer_id)
        return request.render('my_custom_app.customer_detail_template', {
            'customer': customer
        })

    @http.route('/api/customer/create', type='json', auth='user', methods=['POST'])
    def create_customer(self, name, email, phone, **kwargs):
        """REST API: Create customer"""
        customer = request.env['my_app.customer'].create({
            'name': name,
            'email': email,
            'phone': phone
        })
        return {'id': customer.id, 'status': 'created'}
```

### 4. **Security (Record Rules & Access Control)**

**Like**: Django permissions, Rails Cancancan, Supabase RLS
**Purpose**: Row-level security and access control

```xml
<!-- addons/my_custom_app/security/ir.model.access.csv -->
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_customer_user,customer.user,model_my_app_customer,base.group_user,1,1,1,0
access_customer_manager,customer.manager,model_my_app_customer,base.group_system,1,1,1,1
```

```xml
<!-- Record Rules (Row-Level Security) -->
<record id="customer_user_rule" model="ir.rule">
    <field name="name">User: Own Company Customers</field>
    <field name="model_id" ref="model_my_app_customer"/>
    <field name="domain_force">[('company_id', '=', user.company_id.id)]</field>
    <field name="groups" eval="[(4, ref('base.group_user'))]"/>
</record>
```

**Equivalent to Supabase RLS**:
```sql
CREATE POLICY "Users see own company customers"
ON my_app_customer
FOR SELECT
TO authenticated
USING (company_id = auth.jwt()->>'company_id');
```

### 5. **Workflows (State Machines)**

**Built-in state machine framework** for business processes

```python
class SalesOrder(models.Model):
    _name = 'my_app.order'

    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled')
    ], default='draft')

    def action_confirm(self):
        """Transition: draft → confirmed"""
        if self.state != 'draft':
            raise UserError('Can only confirm draft orders')
        self.state = 'confirmed'
        # Trigger other actions (inventory reservation, etc.)

    def action_ship(self):
        """Transition: confirmed → shipped"""
        self.state = 'shipped'
        # Create delivery order
        # Send tracking email

    def action_deliver(self):
        """Transition: shipped → delivered"""
        self.state = 'delivered'
        # Generate invoice
        # Update customer loyalty points
```

### 6. **Reports (PDF Generation)**

**Like**: ReportLab, wkhtmltopdf, Puppeteer
**Purpose**: Generate PDF reports from templates

```xml
<!-- QWeb Report Template -->
<template id="report_customer_card">
    <t t-call="web.html_container">
        <t t-foreach="docs" t-as="customer">
            <div class="page">
                <h2><span t-field="customer.name"/></h2>
                <p>Email: <span t-field="customer.email"/></p>
                <p>Phone: <span t-field="customer.phone"/></p>

                <h3>Recent Orders</h3>
                <table>
                    <tr t-foreach="customer.order_ids[:5]" t-as="order">
                        <td><span t-field="order.name"/></td>
                        <td><span t-field="order.amount_total"/></td>
                    </tr>
                </table>
            </div>
        </t>
    </t>
</template>
```

### 7. **Scheduled Actions (Cron Jobs)**

**Like**: node-cron, celery, pg_cron
**Purpose**: Background tasks and scheduled jobs

```xml
<record id="ir_cron_send_daily_report" model="ir.cron">
    <field name="name">Send Daily Customer Report</field>
    <field name="model_id" ref="model_my_app_customer"/>
    <field name="state">code</field>
    <field name="code">model.send_daily_report()</field>
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <field name="numbercall">-1</field>
</record>
```

```python
def send_daily_report(self):
    """Called by cron job"""
    customers = self.search([('total_orders', '>', 0)])
    # Generate and send report
```

---

## Module Structure

**Odoo Module** = Self-contained app (like Django app, Rails engine, npm package)

```
my_custom_app/
├── __init__.py              # Module initialization
├── __manifest__.py          # Module metadata (like package.json)
├── models/                  # Database models (ORM)
│   ├── __init__.py
│   ├── customer.py
│   └── order.py
├── views/                   # UI definitions (XML)
│   ├── customer_views.xml
│   └── order_views.xml
├── controllers/             # Web routes (HTTP endpoints)
│   ├── __init__.py
│   └── main.py
├── security/                # Access control
│   ├── ir.model.access.csv
│   └── security.xml
├── data/                    # Initial data
│   └── customer_data.xml
├── static/                  # Frontend assets
│   ├── src/
│   │   ├── js/
│   │   ├── css/
│   │   └── xml/
├── reports/                 # PDF report templates
│   └── customer_report.xml
├── wizard/                  # UI wizards (multi-step forms)
│   └── import_customers.py
└── tests/                   # Unit tests
    └── test_customer.py
```

### `__manifest__.py` (Module Metadata)

```python
{
    'name': 'My Custom App',
    'version': '16.0.1.0.0',
    'category': 'Sales',
    'summary': 'Custom customer management',
    'description': """
        Custom CRM application for managing customers and orders
    """,
    'author': 'Your Company',
    'website': 'https://yourcompany.com',
    'license': 'LGPL-3',

    # Dependencies (like package.json dependencies)
    'depends': [
        'base',           # Core Odoo framework
        'mail',           # Email features
        'web',            # Web interface
    ],

    # Data files (loaded on install)
    'data': [
        'security/ir.model.access.csv',
        'views/customer_views.xml',
        'data/customer_data.xml',
    ],

    # Frontend assets
    'assets': {
        'web.assets_backend': [
            'my_custom_app/static/src/js/custom_widget.js',
            'my_custom_app/static/src/css/custom_styles.css',
        ],
    },

    'installable': True,
    'application': True,  # Appears in Apps menu
    'auto_install': False,
}
```

---

## Odoo Framework vs Other Frameworks

### vs Django

| Feature | Odoo Framework | Django |
|---------|----------------|--------|
| **Purpose** | Business apps | General web apps |
| **ORM** | Odoo ORM (business-focused) | Django ORM (general) |
| **Admin UI** | Automatic full UI | Basic admin only |
| **Workflows** | Built-in state machines | Manual implementation |
| **Multi-tenancy** | Built-in (multi-company) | Manual setup |
| **Reports** | Built-in PDF generation | External libraries |
| **Email** | Built-in email templates | django-mailer |
| **Learning Curve** | Steeper (business concepts) | Moderate |

### vs Express/Node.js

| Feature | Odoo Framework | Express |
|---------|----------------|---------|
| **Language** | Python | JavaScript/TypeScript |
| **Database ORM** | Built-in (PostgreSQL only) | Manual (Prisma, TypeORM) |
| **UI Framework** | Built-in (QWeb/XML) | Manual (React, Vue) |
| **Authentication** | Built-in (users, groups, rules) | Manual (Passport.js) |
| **Real-time** | Built-in (long polling) | Socket.io |
| **Modularity** | Module system | npm packages |

### vs Ruby on Rails

| Feature | Odoo Framework | Rails |
|---------|----------------|-------|
| **Convention** | Strict business conventions | Convention over configuration |
| **ORM** | Odoo ORM | ActiveRecord |
| **UI** | XML templates | ERB/Haml |
| **Admin** | Automatic full UI | ActiveAdmin |
| **Workflows** | Built-in | state_machines gem |

---

## When to Use Odoo Framework

### ✅ GOOD Fit

**Use Odoo Framework when**:
- Building **business applications** (ERP, CRM, HR, etc.)
- Need **multi-company** support out of the box
- Want **automatic UI generation** from models
- Need **complex approval workflows** and state machines
- Building for **existing Odoo ecosystem** integration
- Team knows **Python** and comfortable with XML

**Examples**:
- Custom ERP system
- Industry-specific management system (hospital, school, hotel)
- Internal business tools with complex workflows
- B2B portals with multi-tenancy

### ❌ POOR Fit

**DON'T use Odoo Framework when**:
- Building **consumer apps** (social media, gaming, etc.)
- Need **modern frontend** (React, Vue, Next.js)
- Want **API-first architecture** (REST/GraphQL only)
- Team prefers **TypeScript** and modern JavaScript
- Need **serverless** or **edge computing**
- Want **JAMstack** architecture

**Examples**:
- Mobile apps (iOS/Android native)
- Real-time collaboration tools
- AI/ML-heavy applications
- Headless CMS
- **Your current stack** (Supabase + TypeScript + React)

---

## Odoo Framework in Your Context

### Your Current Stack (Keep) ✅

```
Frontend: Vercel (React/Next.js + TypeScript)
Backend: DO App Platform + Supabase Edge Functions
Database: Supabase PostgreSQL (with RLS)
AI/ML: OpenAI API + pgvector embeddings
```

**Why it's better than Odoo Framework**:
- ✅ Modern TypeScript everywhere
- ✅ React for flexible UI
- ✅ Serverless Edge Functions
- ✅ AI-native (pgvector, OpenAI integration)
- ✅ Git-based deployment
- ✅ Lower cost ($10-16/month vs $48+ with Odoo)

### Adopting Odoo Patterns (Without Framework) ✅

**Strategy**: Extract proven patterns, implement in modern stack

**What to Adopt from Odoo**:

1. **Database Schemas** → PostgreSQL tables
2. **State Machines** → Supabase RPC functions
3. **Record Rules** → Supabase RLS policies
4. **Workflows** → TypeScript business logic
5. **Module Structure** → TypeScript packages

**Example - Odoo Pattern in Your Stack**:

```typescript
// utils/workflows/order-state-machine.ts
export type OrderState = 'draft' | 'confirmed' | 'shipped' | 'delivered';

export class OrderStateMachine {
  async confirmOrder(orderId: string): Promise<void> {
    const { data: order } = await supabase
      .from('orders')
      .select('state')
      .eq('id', orderId)
      .single();

    if (order.state !== 'draft') {
      throw new Error('Can only confirm draft orders');
    }

    // Transition state (like Odoo)
    await supabase.rpc('confirm_order', { order_id: orderId });
  }
}
```

```sql
-- Supabase RPC function (Odoo method equivalent)
CREATE OR REPLACE FUNCTION confirm_order(order_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate state transition (Odoo pattern)
  IF (SELECT state FROM orders WHERE id = order_id) != 'draft' THEN
    RAISE EXCEPTION 'Can only confirm draft orders';
  END IF;

  -- Update state
  UPDATE orders SET state = 'confirmed' WHERE id = order_id;

  -- Trigger side effects (like Odoo)
  PERFORM reserve_inventory(order_id);
  PERFORM send_confirmation_email(order_id);
END;
$$;
```

---

## Conclusion: Odoo Framework vs Your Stack

### Odoo Framework Approach

```python
# Odoo way (Python monolith)
class SalesOrder(models.Model):
    _name = 'sale.order'

    customer_id = fields.Many2one('res.partner')
    state = fields.Selection([...])

    def action_confirm(self):
        self.state = 'confirmed'
```

### Your Modern Stack Approach

```typescript
// Your way (TypeScript microservices)
// Database: Supabase table with RLS
// Business logic: Edge Function
// Frontend: React component
// State management: Zustand/Redux

export async function confirmOrder(orderId: string) {
  const { data } = await supabase.rpc('confirm_order', {
    order_id: orderId
  });
  return data;
}
```

### Recommendation for You

**DO NOT** migrate to Odoo Framework - you'd lose:
- ❌ Modern TypeScript
- ❌ React ecosystem
- ❌ Serverless architecture
- ❌ AI/ML capabilities (OCR, embeddings)
- ❌ Developer experience

**DO** extract and adapt Odoo patterns:
- ✅ Database schemas
- ✅ State machine patterns
- ✅ Security models (RLS)
- ✅ Workflow concepts
- ✅ Module organization

**Use Odoo 1-Click as**: Reference library ($6/month) to study patterns, then implement in your modern stack.

---

**Generated**: 2025-10-19
**Framework**: Odoo Framework (Python) vs Your Stack (TypeScript)
**Recommendation**: Keep modern stack, adopt Odoo patterns
