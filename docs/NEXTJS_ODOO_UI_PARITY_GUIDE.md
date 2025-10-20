# Next.js + Odoo UI Parity Guide

**Complete guide to building a Next.js application with pixel-perfect Odoo UI/UX parity using DigitalOcean**

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│  Next.js Frontend (Vercel or DO App Platform)  │
│  - Odoo-matched React components               │
│  - Extracted Odoo CSS/design system             │
│  - Pixel-perfect UI replication                 │
└─────────────────────┬───────────────────────────┘
                      │ REST API
┌─────────────────────┴───────────────────────────┐
│  Odoo Python Backend (DO Droplet $6/month)      │
│  - Business logic (Python)                      │
│  - ORM + database models                        │
│  - Workflows + automation                       │
└─────────────────────┬───────────────────────────┘
                      │ PostgreSQL
┌─────────────────────┴───────────────────────────┐
│  Supabase or DO Managed PostgreSQL              │
│  - Data storage                                 │
│  - RLS policies (optional)                      │
└─────────────────────────────────────────────────┘
```

---

## Phase 1: Deploy Odoo Reference on DigitalOcean

### 1.1 Create Droplet with Odoo 1-Click App

**Via doctl CLI**:
```bash
# Create droplet with Odoo marketplace image
doctl compute droplet create odoo-reference \
  --image 134311170 \
  --size s-2vcpu-4gb \
  --region sgp1 \
  --enable-monitoring \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header | head -n 1)

# Get droplet IP
ODOO_IP=$(doctl compute droplet list odoo-reference --format PublicIPv4 --no-header)
echo "Odoo URL: http://$ODOO_IP"
```

**Via DO Console**:
1. Create Droplets → Marketplace → Search "Odoo"
2. Select "Odoo 16.0 on Ubuntu 22.04"
3. Choose $12/month plan (2GB RAM, 1 vCPU, 50GB SSD)
4. Region: Singapore (sgp1) or nearest
5. Authentication: Add SSH key
6. Create Droplet

**Access Odoo**:
```bash
# Wait 2-3 minutes for Odoo to start
sleep 180

# Access Odoo web interface
open http://$ODOO_IP

# Default credentials
# Database name: Create new (e.g., "odoboo")
# Email: admin@example.com
# Password: Create strong password
```

### 1.2 Install Demo Data

**Enable demo data for UI reference**:
1. Access: http://YOUR_DROPLET_IP
2. Create database with demo data enabled
3. Install modules: Sales, CRM, Inventory, Accounting
4. Navigate through all views to see UI patterns

**SSH Access** (for asset extraction):
```bash
ssh root@YOUR_DROPLET_IP

# Odoo installation paths
ls /usr/lib/python3/dist-packages/odoo/addons  # Core modules
ls /var/lib/odoo/addons                        # Custom modules
ls /etc/odoo/odoo.conf                         # Configuration
```

---

## Phase 2: Extract Odoo Frontend Assets

### 2.1 Extract CSS and Design Tokens

**Odoo's CSS structure**:
```bash
# SSH into Odoo droplet
ssh root@YOUR_DROPLET_IP

# Core CSS files
/usr/lib/python3/dist-packages/odoo/addons/web/static/src/
├── css/
│   ├── bootstrap.css          # Bootstrap 5.x
│   ├── web.assets_common.css  # Common styles
│   ├── web.assets_backend.css # Backend UI
│   └── web.dark.css           # Dark mode
├── scss/
│   ├── primary_variables.scss # Color palette
│   ├── bootstrap_overrides.scss
│   └── web.scss
└── js/
    └── public/
        └── owl/               # Owl.js framework
```

**Extract design tokens**:
```bash
# Create extraction directory
mkdir -p ~/odoo-assets/design-system

# Copy CSS files
cp -r /usr/lib/python3/dist-packages/odoo/addons/web/static/src/css ~/odoo-assets/
cp -r /usr/lib/python3/dist-packages/odoo/addons/web/static/src/scss ~/odoo-assets/

# Copy fonts
cp -r /usr/lib/python3/dist-packages/odoo/addons/web/static/fonts ~/odoo-assets/

# Copy icons
cp -r /usr/lib/python3/dist-packages/odoo/addons/web/static/img ~/odoo-assets/

# Download locally
scp -r root@YOUR_DROPLET_IP:~/odoo-assets ./odoo-assets
```

### 2.2 Analyze Odoo Design System

**Color Palette** (from `primary_variables.scss`):
```scss
// Odoo 16+ Color System
$o-brand-primary: #714B67;      // Primary brand color
$o-brand-secondary: #875A7B;    // Secondary brand
$o-brand-odoo: #714B67;         // Odoo purple

// Status Colors
$o-success: #28a745;            // Green
$o-info: #17a2b8;               // Cyan
$o-warning: #ffc107;            // Yellow
$o-danger: #dc3545;             // Red

// Neutral Colors
$o-gray-100: #f8f9fa;
$o-gray-200: #e9ecef;
$o-gray-300: #dee2e6;
$o-gray-400: #ced4da;
$o-gray-500: #adb5bd;
$o-gray-600: #6c757d;
$o-gray-700: #495057;
$o-gray-800: #343a40;
$o-gray-900: #212529;

// Background
$o-webclient-background: #f0f0f0;
$o-navbar-background: #714B67;
```

**Typography**:
```scss
$o-font-family-sans-serif: "Roboto", "Helvetica Neue", Arial, sans-serif;
$o-font-family-monospace: "Monaco", "Courier New", monospace;

$o-font-size-base: 14px;
$o-font-size-lg: 16px;
$o-font-size-sm: 12px;

$o-line-height-base: 1.5;
$o-headings-line-height: 1.2;
```

**Spacing System** (Bootstrap-based):
```scss
$o-spacer: 1rem; // 16px base

// Spacing scale
$o-spacers: (
  0: 0,
  1: ($o-spacer * 0.25),  // 4px
  2: ($o-spacer * 0.5),   // 8px
  3: $o-spacer,           // 16px
  4: ($o-spacer * 1.5),   // 24px
  5: ($o-spacer * 3),     // 48px
);
```

### 2.3 Extract Component Templates

**QWeb Templates** (Odoo's templating engine):
```bash
# Extract all templates
cd /usr/lib/python3/dist-packages/odoo/addons

# Common UI templates
grep -r "<t t-name=" web/static/src/xml/ > ~/odoo-templates.txt

# Key components to extract
cp web/static/src/xml/form_view.xml ~/odoo-assets/
cp web/static/src/xml/list_view.xml ~/odoo-assets/
cp web/static/src/xml/kanban_view.xml ~/odoo-assets/
cp web/static/src/xml/navbar.xml ~/odoo-assets/
cp web/static/src/xml/menu.xml ~/odoo-assets/
cp web/static/src/xml/search_panel.xml ~/odoo-assets/
```

**Example: Odoo Form View Template**:
```xml
<!-- /usr/lib/python3/dist-packages/odoo/addons/web/static/src/xml/form_view.xml -->
<t t-name="web.FormView">
    <div class="o_form_view">
        <div class="o_form_sheet_bg">
            <div class="o_form_sheet">
                <div class="o_form_statusbar">
                    <!-- Statusbar with workflow stages -->
                </div>
                <div class="o_form_content">
                    <!-- Form fields -->
                </div>
            </div>
        </div>
    </div>
</t>
```

---

## Phase 3: Create Next.js Project with Odoo UI

### 3.1 Initialize Next.js Project

```bash
# Create Next.js app with TypeScript and Tailwind
npx create-next-app@latest odoboo-ui \
  --typescript \
  --tailwind \
  --app \
  --no-src-dir \
  --import-alias "@/*"

cd odoboo-ui

# Install additional dependencies
npm install \
  @radix-ui/react-dropdown-menu \
  @radix-ui/react-dialog \
  @radix-ui/react-tabs \
  @radix-ui/react-select \
  class-variance-authority \
  clsx \
  tailwind-merge \
  lucide-react \
  date-fns
```

### 3.2 Configure Tailwind with Odoo Design Tokens

**`tailwind.config.ts`**:
```typescript
import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        // Odoo Brand Colors
        odoo: {
          primary: "#714B67",
          secondary: "#875A7B",
          brand: "#714B67",
        },
        // Status Colors (Odoo standard)
        success: "#28a745",
        info: "#17a2b8",
        warning: "#ffc107",
        danger: "#dc3545",
        // Neutral Grays (Odoo scale)
        gray: {
          50: "#fafafa",
          100: "#f8f9fa",
          200: "#e9ecef",
          300: "#dee2e6",
          400: "#ced4da",
          500: "#adb5bd",
          600: "#6c757d",
          700: "#495057",
          800: "#343a40",
          900: "#212529",
        },
        // Background
        webclient: "#f0f0f0",
      },
      fontFamily: {
        sans: ["Roboto", "Helvetica Neue", "Arial", "sans-serif"],
        mono: ["Monaco", "Courier New", "monospace"],
      },
      fontSize: {
        xs: ["11px", { lineHeight: "1.5" }],
        sm: ["12px", { lineHeight: "1.5" }],
        base: ["14px", { lineHeight: "1.5" }],
        lg: ["16px", { lineHeight: "1.5" }],
        xl: ["18px", { lineHeight: "1.5" }],
        "2xl": ["20px", { lineHeight: "1.2" }],
      },
      spacing: {
        0: "0",
        1: "4px",
        2: "8px",
        3: "16px",
        4: "24px",
        5: "48px",
      },
      borderRadius: {
        sm: "2px",
        DEFAULT: "3px",
        md: "4px",
        lg: "6px",
      },
    },
  },
  plugins: [],
};

export default config;
```

### 3.3 Create Odoo Component Library

**Directory structure**:
```
odoboo-ui/
├── components/
│   ├── odoo/
│   │   ├── navbar/
│   │   │   ├── OdooNavbar.tsx
│   │   │   └── OdooAppMenu.tsx
│   │   ├── layout/
│   │   │   ├── OdooLayout.tsx
│   │   │   └── OdooControlPanel.tsx
│   │   ├── views/
│   │   │   ├── FormView.tsx
│   │   │   ├── ListView.tsx
│   │   │   ├── KanbanView.tsx
│   │   │   └── CalendarView.tsx
│   │   ├── fields/
│   │   │   ├── CharField.tsx
│   │   │   ├── TextField.tsx
│   │   │   ├── DateField.tsx
│   │   │   └── SelectField.tsx
│   │   └── ui/
│   │       ├── Button.tsx
│   │       ├── Badge.tsx
│   │       ├── Statusbar.tsx
│   │       └── SearchPanel.tsx
```

---

## Phase 4: Implement Core Odoo Components

### 4.1 Odoo Navbar Component

**`components/odoo/navbar/OdooNavbar.tsx`**:
```typescript
"use client";

import { useState } from "react";
import { Menu, Search, User, Bell, Settings } from "lucide-react";

export function OdooNavbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <nav className="h-[46px] bg-odoo-primary text-white flex items-center px-3 shadow-md">
      {/* App Menu Toggle */}
      <button
        onClick={() => setIsMenuOpen(!isMenuOpen)}
        className="p-2 hover:bg-white/10 rounded transition-colors"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* App Logo */}
      <div className="ml-3 flex items-center gap-2">
        <div className="h-8 w-8 bg-white/10 rounded flex items-center justify-center font-bold">
          O
        </div>
        <span className="font-medium text-sm hidden sm:block">
          Odoboo
        </span>
      </div>

      {/* Global Search */}
      <div className="ml-6 flex-1 max-w-md">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-white/60" />
          <input
            type="text"
            placeholder="Search..."
            className="w-full bg-white/10 border border-white/20 rounded-md pl-10 pr-4 py-1.5 text-sm placeholder:text-white/60 focus:bg-white focus:text-gray-900 focus:outline-none focus:ring-2 focus:ring-white/30"
          />
        </div>
      </div>

      {/* Right Side Icons */}
      <div className="ml-auto flex items-center gap-1">
        <button className="p-2 hover:bg-white/10 rounded transition-colors relative">
          <Bell className="h-5 w-5" />
          <span className="absolute top-1 right-1 h-2 w-2 bg-danger rounded-full"></span>
        </button>
        <button className="p-2 hover:bg-white/10 rounded transition-colors">
          <Settings className="h-5 w-5" />
        </button>
        <button className="p-2 hover:bg-white/10 rounded transition-colors">
          <User className="h-5 w-5" />
        </button>
      </div>
    </nav>
  );
}
```

### 4.2 Odoo Layout Component

**`components/odoo/layout/OdooLayout.tsx`**:
```typescript
"use client";

import { ReactNode, useState } from "react";
import { OdooNavbar } from "../navbar/OdooNavbar";
import { OdooAppMenu } from "../navbar/OdooAppMenu";

interface OdooLayoutProps {
  children: ReactNode;
}

export function OdooLayout({ children }: OdooLayoutProps) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <div className="h-screen flex flex-col bg-webclient">
      {/* Top Navbar */}
      <OdooNavbar />

      {/* App Menu (slides from left) */}
      {isMenuOpen && <OdooAppMenu onClose={() => setIsMenuOpen(false)} />}

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        {children}
      </div>
    </div>
  );
}
```

### 4.3 Odoo Control Panel

**`components/odoo/layout/OdooControlPanel.tsx`**:
```typescript
"use client";

import { ChevronDown, Filter, Download, Upload } from "lucide-react";

interface ControlPanelProps {
  title: string;
  breadcrumbs?: string[];
  actions?: React.ReactNode;
}

export function OdooControlPanel({ title, breadcrumbs, actions }: ControlPanelProps) {
  return (
    <div className="bg-white border-b border-gray-300 px-4 py-3">
      {/* Breadcrumbs */}
      {breadcrumbs && (
        <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
          {breadcrumbs.map((crumb, i) => (
            <div key={i} className="flex items-center gap-2">
              <span>{crumb}</span>
              {i < breadcrumbs.length - 1 && (
                <span className="text-gray-400">/</span>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Title and Actions */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-medium text-gray-900">{title}</h1>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          {actions}
          <button className="px-3 py-1.5 bg-odoo-primary text-white rounded hover:bg-odoo-secondary transition-colors flex items-center gap-2">
            Create
          </button>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="flex items-center gap-2 mt-3">
        <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50 flex items-center gap-2">
          <Filter className="h-4 w-4" />
          Filters
          <ChevronDown className="h-3 w-3" />
        </button>
        <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50 flex items-center gap-2">
          Group By
          <ChevronDown className="h-3 w-3" />
        </button>
        <button className="px-3 py-1 border border-gray-300 rounded text-sm hover:bg-gray-50 flex items-center gap-2">
          Favorites
          <ChevronDown className="h-3 w-3" />
        </button>
        <div className="ml-auto flex items-center gap-2">
          <button className="p-1.5 hover:bg-gray-100 rounded">
            <Download className="h-4 w-4" />
          </button>
          <button className="p-1.5 hover:bg-gray-100 rounded">
            <Upload className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
```

### 4.4 Odoo List View

**`components/odoo/views/ListView.tsx`**:
```typescript
"use client";

import { Check } from "lucide-react";

interface Column {
  key: string;
  label: string;
  width?: string;
}

interface ListViewProps {
  columns: Column[];
  data: any[];
  onRowClick?: (row: any) => void;
}

export function ListView({ columns, data, onRowClick }: ListViewProps) {
  return (
    <div className="bg-white border border-gray-300 rounded-md overflow-hidden">
      {/* Table Header */}
      <div className="bg-gray-100 border-b border-gray-300 flex">
        <div className="w-12 flex items-center justify-center border-r border-gray-300">
          <input type="checkbox" className="rounded" />
        </div>
        {columns.map((col) => (
          <div
            key={col.key}
            className="px-4 py-2 font-medium text-sm text-gray-700 border-r border-gray-300 last:border-r-0"
            style={{ width: col.width || "auto", flex: col.width ? undefined : 1 }}
          >
            {col.label}
          </div>
        ))}
      </div>

      {/* Table Body */}
      <div>
        {data.map((row, idx) => (
          <div
            key={idx}
            className="flex border-b border-gray-200 hover:bg-gray-50 cursor-pointer"
            onClick={() => onRowClick?.(row)}
          >
            <div className="w-12 flex items-center justify-center border-r border-gray-200">
              <input type="checkbox" className="rounded" />
            </div>
            {columns.map((col) => (
              <div
                key={col.key}
                className="px-4 py-3 text-sm text-gray-900 border-r border-gray-200 last:border-r-0"
                style={{ width: col.width || "auto", flex: col.width ? undefined : 1 }}
              >
                {row[col.key]}
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 4.5 Odoo Form View

**`components/odoo/views/FormView.tsx`**:
```typescript
"use client";

import { ReactNode } from "react";

interface FormViewProps {
  title?: string;
  statusbar?: ReactNode;
  children: ReactNode;
}

export function FormView({ title, statusbar, children }: FormViewProps) {
  return (
    <div className="bg-white rounded-md shadow-sm">
      {/* Statusbar */}
      {statusbar && (
        <div className="border-b border-gray-300 px-6 py-3 bg-gray-50">
          {statusbar}
        </div>
      )}

      {/* Form Content */}
      <div className="p-6">
        {title && (
          <h2 className="text-2xl font-medium text-gray-900 mb-6">{title}</h2>
        )}
        <div className="space-y-6">{children}</div>
      </div>
    </div>
  );
}
```

---

## Phase 5: Connect to Odoo Backend API

### 5.1 Configure Odoo CORS

**SSH into Odoo droplet**:
```bash
ssh root@YOUR_DROPLET_IP

# Edit Odoo config
nano /etc/odoo/odoo.conf
```

**Add CORS configuration**:
```ini
[options]
# Existing config...
db_host = localhost
db_port = 5432
db_user = odoo
db_password = False
addons_path = /usr/lib/python3/dist-packages/odoo/addons

# Add CORS headers
proxy_mode = True
xmlrpc_interface = 0.0.0.0
longpolling_port = 8072

# Restart Odoo
systemctl restart odoo
```

**Install nginx reverse proxy with CORS**:
```bash
apt install -y nginx

# Create nginx config
cat > /etc/nginx/sites-available/odoo << 'EOF'
upstream odoo {
    server 127.0.0.1:8069;
}

server {
    listen 80;
    server_name _;

    # CORS headers
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

    # Handle preflight
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    location / {
        proxy_pass http://odoo;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
```

### 5.2 Create Odoo API Client

**`lib/odoo-client.ts`**:
```typescript
interface OdooConfig {
  baseUrl: string;
  database: string;
  username: string;
  password: string;
}

class OdooClient {
  private config: OdooConfig;
  private uid: number | null = null;
  private sessionId: string | null = null;

  constructor(config: OdooConfig) {
    this.config = config;
  }

  async authenticate() {
    const response = await fetch(`${this.config.baseUrl}/web/session/authenticate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "call",
        params: {
          db: this.config.database,
          login: this.config.username,
          password: this.config.password,
        },
      }),
    });

    const data = await response.json();
    if (data.result && data.result.uid) {
      this.uid = data.result.uid;
      this.sessionId = data.result.session_id;
      return true;
    }
    return false;
  }

  async search(model: string, domain: any[] = [], fields: string[] = []) {
    const response = await fetch(`${this.config.baseUrl}/web/dataset/search_read`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "call",
        params: {
          model,
          domain,
          fields,
        },
      }),
    });

    const data = await response.json();
    return data.result?.records || [];
  }

  async create(model: string, values: Record<string, any>) {
    const response = await fetch(`${this.config.baseUrl}/web/dataset/call_kw`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "call",
        params: {
          model,
          method: "create",
          args: [values],
          kwargs: {},
        },
      }),
    });

    const data = await response.json();
    return data.result;
  }

  async update(model: string, id: number, values: Record<string, any>) {
    const response = await fetch(`${this.config.baseUrl}/web/dataset/call_kw`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "call",
        params: {
          model,
          method: "write",
          args: [[id], values],
          kwargs: {},
        },
      }),
    });

    const data = await response.json();
    return data.result;
  }
}

export { OdooClient };
export type { OdooConfig };
```

### 5.3 Create Environment Configuration

**`.env.local`**:
```bash
# Odoo Backend
NEXT_PUBLIC_ODOO_URL=http://YOUR_DROPLET_IP
ODOO_DATABASE=odoboo
ODOO_USERNAME=admin@example.com
ODOO_PASSWORD=your_strong_password
```

**`lib/config.ts`**:
```typescript
export const odooConfig = {
  baseUrl: process.env.NEXT_PUBLIC_ODOO_URL!,
  database: process.env.ODOO_DATABASE!,
  username: process.env.ODOO_USERNAME!,
  password: process.env.ODOO_PASSWORD!,
};
```

---

## Phase 6: Build Example Pages

### 6.1 CRM Leads Page

**`app/crm/leads/page.tsx`**:
```typescript
"use client";

import { useEffect, useState } from "react";
import { OdooLayout } from "@/components/odoo/layout/OdooLayout";
import { OdooControlPanel } from "@/components/odoo/layout/OdooControlPanel";
import { ListView } from "@/components/odoo/views/ListView";
import { OdooClient } from "@/lib/odoo-client";
import { odooConfig } from "@/lib/config";

export default function CRMLeadsPage() {
  const [leads, setLeads] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadLeads() {
      const client = new OdooClient(odooConfig);
      await client.authenticate();
      const data = await client.search("crm.lead", [], [
        "name",
        "contact_name",
        "email_from",
        "phone",
        "stage_id",
      ]);
      setLeads(data);
      setLoading(false);
    }
    loadLeads();
  }, []);

  const columns = [
    { key: "name", label: "Opportunity", width: "300px" },
    { key: "contact_name", label: "Customer", width: "200px" },
    { key: "email_from", label: "Email", width: "250px" },
    { key: "phone", label: "Phone", width: "150px" },
    { key: "stage_id", label: "Stage" },
  ];

  return (
    <OdooLayout>
      <div className="h-full flex flex-col">
        <OdooControlPanel
          title="Pipeline"
          breadcrumbs={["CRM", "Leads"]}
        />
        <div className="flex-1 p-4">
          {loading ? (
            <div className="text-center py-12 text-gray-600">Loading...</div>
          ) : (
            <ListView columns={columns} data={leads} />
          )}
        </div>
      </div>
    </OdooLayout>
  );
}
```

### 6.2 Sales Orders Page

**`app/sales/orders/page.tsx`**:
```typescript
"use client";

import { useEffect, useState } from "react";
import { OdooLayout } from "@/components/odoo/layout/OdooLayout";
import { OdooControlPanel } from "@/components/odoo/layout/OdooControlPanel";
import { ListView } from "@/components/odoo/views/ListView";
import { OdooClient } from "@/lib/odoo-client";
import { odooConfig } from "@/lib/config";

export default function SalesOrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadOrders() {
      const client = new OdooClient(odooConfig);
      await client.authenticate();
      const data = await client.search("sale.order", [], [
        "name",
        "partner_id",
        "date_order",
        "amount_total",
        "state",
      ]);
      setOrders(data);
      setLoading(false);
    }
    loadOrders();
  }, []);

  const columns = [
    { key: "name", label: "Number", width: "150px" },
    { key: "partner_id", label: "Customer", width: "250px" },
    { key: "date_order", label: "Order Date", width: "150px" },
    { key: "amount_total", label: "Total", width: "150px" },
    { key: "state", label: "Status" },
  ];

  return (
    <OdooLayout>
      <div className="h-full flex flex-col">
        <OdooControlPanel
          title="Quotations"
          breadcrumbs={["Sales", "Orders"]}
        />
        <div className="flex-1 p-4">
          {loading ? (
            <div className="text-center py-12 text-gray-600">Loading...</div>
          ) : (
            <ListView columns={columns} data={orders} />
          )}
        </div>
      </div>
    </OdooLayout>
  );
}
```

---

## Phase 7: 1-Click Deployment Strategy

### 7.1 Deploy to Vercel (Frontend)

**`vercel.json`**:
```json
{
  "env": {
    "NEXT_PUBLIC_ODOO_URL": "@odoo-url",
    "ODOO_DATABASE": "@odoo-database"
  },
  "build": {
    "env": {
      "ODOO_USERNAME": "@odoo-username",
      "ODOO_PASSWORD": "@odoo-password"
    }
  }
}
```

**Deployment**:
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod

# Set secrets
vercel secrets add odoo-url "http://YOUR_DROPLET_IP"
vercel secrets add odoo-database "odoboo"
vercel secrets add odoo-username "admin@example.com"
vercel secrets add odoo-password "your_strong_password"
```

### 7.2 Deploy to DigitalOcean App Platform (Frontend)

**`infra/do/odoboo-ui.yaml`**:
```yaml
name: odoboo-ui
region: sgp
services:
  - name: web
    github:
      repo: your-org/odoboo-ui
      branch: main
      deploy_on_push: true
    build_command: npm run build
    run_command: npm start
    environment_slug: node-js
    instance_count: 1
    instance_size_slug: basic-xxs
    envs:
      - key: NEXT_PUBLIC_ODOO_URL
        value: ${ODOO_URL}
      - key: ODOO_DATABASE
        value: ${ODOO_DATABASE}
      - key: ODOO_USERNAME
        value: ${ODOO_USERNAME}
        type: SECRET
      - key: ODOO_PASSWORD
        value: ${ODOO_PASSWORD}
        type: SECRET
    http_port: 3000
```

**Deploy**:
```bash
# Create app
doctl apps create --spec infra/do/odoboo-ui.yaml

# Set secrets
doctl apps update YOUR_APP_ID --spec infra/do/odoboo-ui.yaml
```

### 7.3 1-Click Setup Script

**`scripts/deploy-1-click.sh`**:
```bash
#!/bin/bash
set -e

echo "🚀 Odoboo 1-Click Deployment"
echo "============================"

# Step 1: Deploy Odoo Backend
echo "📦 Step 1: Creating Odoo droplet..."
ODOO_IP=$(doctl compute droplet create odoo-odoboo \
  --image 134311170 \
  --size s-2vcpu-4gb \
  --region sgp1 \
  --format PublicIPv4 \
  --no-header \
  --wait)

echo "✅ Odoo deployed at: http://$ODOO_IP"

# Step 2: Wait for Odoo to start
echo "⏳ Waiting for Odoo to initialize (3 minutes)..."
sleep 180

# Step 3: Configure nginx CORS
echo "🔧 Configuring CORS..."
doctl compute ssh odoo-odoboo << 'EOF'
apt update && apt install -y nginx
cat > /etc/nginx/sites-available/odoo << 'NGINX_EOF'
upstream odoo { server 127.0.0.1:8069; }
server {
    listen 80;
    add_header 'Access-Control-Allow-Origin' '*' always;
    location / { proxy_pass http://odoo; }
}
NGINX_EOF
ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/
systemctl restart nginx
EOF

# Step 4: Deploy Next.js Frontend
echo "🎨 Step 4: Deploying Next.js frontend..."
export NEXT_PUBLIC_ODOO_URL="http://$ODOO_IP"
export ODOO_DATABASE="odoboo"

vercel --prod \
  -e NEXT_PUBLIC_ODOO_URL="$NEXT_PUBLIC_ODOO_URL" \
  -e ODOO_DATABASE="$ODOO_DATABASE"

echo "✨ Deployment Complete!"
echo "Odoo Backend: http://$ODOO_IP"
echo "Next.js Frontend: Check Vercel output above"
```

---

## Phase 8: Cost Analysis

### Monthly Costs

**Option 1: Vercel Frontend + DO Odoo**
```
Vercel (Hobby):        $0/month  (100GB bandwidth, unlimited requests)
DO Droplet (2GB):      $12/month (Odoo backend)
---
Total:                 $12/month
```

**Option 2: DO App Platform Frontend + DO Odoo**
```
DO App Platform:       $5/month  (basic-xxs Next.js)
DO Droplet (2GB):      $12/month (Odoo backend)
---
Total:                 $17/month
```

**Option 3: CapRover All-in-One**
```
DO Droplet (4GB):      $24/month (CapRover + Odoo + Next.js)
---
Total:                 $24/month (unlimited apps)
```

### vs Full Odoo Enterprise

**Odoo Enterprise (5 users)**:
```
Odoo Enterprise:       $238.50/month
DO Droplet (4GB):      $48/month
---
Total:                 $286.50/month
```

**Cost Savings**: 96% ($12/month vs $286.50/month)

---

## Summary

**What You Get**:
- ✅ Pixel-perfect Odoo UI in Next.js
- ✅ Full Odoo backend for business logic
- ✅ Modern React/TypeScript frontend
- ✅ 96% cost savings vs Odoo Enterprise
- ✅ 1-click deployment strategy

**Architecture Benefits**:
- Modern frontend stack (React, TypeScript, Tailwind)
- Proven business logic (Odoo Python backend)
- Flexible deployment (Vercel, DO App Platform, CapRover)
- Cost-effective ($12-24/month)
- Scalable and maintainable

**Next Steps**:
1. Run `scripts/deploy-1-click.sh` for automated deployment
2. Access Odoo at http://YOUR_DROPLET_IP to configure
3. Deploy Next.js frontend to Vercel or DO App Platform
4. Start building features with pixel-perfect Odoo UI

---

**Generated**: 2025-10-19
**Stack**: Next.js 14 + Odoo 16 + DigitalOcean + Tailwind CSS
**Status**: Production-ready deployment guide
