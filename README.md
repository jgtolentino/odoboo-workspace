# OdoBoo Workspace - Enterprise Notion-like Platform

[![Odoo Version](https://img.shields.io/badge/Odoo-18.0-875A7B.svg)](https://www.odoo.com/)
[![OCA](https://img.shields.io/badge/OCA-Certified-green.svg)](https://odoo-community.org/)
[![DigitalOcean](https://img.shields.io/badge/Deploy-DigitalOcean-0080FF.svg)](https://www.digitalocean.com/)
[![Supabase](https://img.shields.io/badge/Database-Supabase-3ECF8E.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-LGPL--3.0-blue.svg)](LICENSE)

## 🚀 Overview

OdoBoo Workspace transforms **Odoo 18.0** into a powerful **Notion-like collaborative workspace** with enterprise features using OCA community modules. Built for teams who need project management, document collaboration, real-time sync, and email notifications.

## ✨ Key Features

- 📝 **Notion-like Pages** - Hierarchical documents with rich text editing
- 📊 **Inline Databases** - Multiple views (List, Kanban, Calendar, Gantt)
- 📋 **Project Management** - Sprint planning, dependencies, milestones
- 🔄 **Real-time Sync** - Bi-directional sync with Supabase PostgreSQL
- 📧 **Email Notifications** - Multi-provider support (SendGrid, AWS SES, SMTP)
- 🔔 **In-App Alerts** - Announcements and notifications (OCA)
- 🔐 **Enterprise Security** - Role-based access control (RBAC)
- 🌐 **API-First** - RESTful & JSON-RPC APIs
- 🐳 **Docker Ready** - One-command deployment

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENT LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│  Web Browser  │  Mobile App  │  API Clients  │  Webhooks        │
└────────┬──────────────┬───────────────┬────────────────┬─────────┘
         │              │               │                │
         ├──────────────┴───────────────┴────────────────┤
         │           Nginx Reverse Proxy (SSL)           │
         │               Port 80/443                      │
         └──────────────────┬────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────────────┐
│                   APPLICATION LAYER                            │
├────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Odoo 18.0 Application Server                │ │
│  │                  Port 8069, 8072                          │ │
│  ├──────────────────────────────────────────────────────────┤ │
│  │  Core Modules        OCA Modules       Custom Modules    │ │
│  │  • project           • web_responsive  • supabase_sync   │ │
│  │  • documents         • mail_gateway    • notion_workspace│ │
│  │  • knowledge         • announcement    • email_notify    │ │
│  │  • calendar          • dms             •                 │ │
│  │  • crm              • project_timeline •                 │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────┬────────────────────┬────────────────┬───────────────┬─┘
         │                    │                │               │
         ├────────────────────┴────────────────┴───────────────┤
         │               Odoo Cron Workers (Background Jobs)    │
         │                   Max 2 Threads                      │
         └──────────────────┬────────────────┬────────────────┬┘
                            │                │                │
┌───────────────────────────┴────────────────┴────────────────┴──┐
│                      DATA LAYER                                 │
├────────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │  PostgreSQL   │  │   Supabase DB    │  │  Redis Cache    │ │
│  │   (Local)     │  │   (Cloud Sync)   │  │   Port 6379     │ │
│  │   Port 5432   │  │   Real-time      │  │   Sessions      │ │
│  │   Internal    │  │   Row-Level      │  │   Queue         │ │
│  │   Odoo Data   │  │   Security       │  │                 │ │
│  └───────────────┘  └──────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────────────┐
│                   STORAGE & SERVICES LAYER                      │
├────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌───────────────┐  ┌─────────────────┐ │
│  │  MinIO / DO      │  │  Email        │  │  Monitoring     │ │
│  │  Spaces          │  │  Providers    │  │  (Optional)     │ │
│  │  File Storage    │  │  • SendGrid   │  │  • Prometheus   │ │
│  │  S3-compatible   │  │  • AWS SES    │  │  • Grafana      │ │
│  │                  │  │  • SMTP       │  │                 │ │
│  └──────────────────┘  └───────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
odoboo-workspace/
│
├── 📂 addons/                          # Custom Odoo Modules
│   └── 📦 supabase_sync/               # ✅ Supabase Integration
│       ├── __manifest__.py             # Module definition
│       ├── __init__.py                 # Module initializer
│       ├── models/                     # Business logic
│       │   ├── __init__.py
│       │   ├── supabase_sync.py        # Main sync controller
│       │   ├── res_partner.py          # Customer sync
│       │   ├── project_project.py      # Project sync
│       │   └── project_task.py         # Task sync
│       ├── views/                      # UI definitions
│       │   └── supabase_config_views.xml
│       ├── security/                   # Access control
│       │   └── ir.model.access.csv
│       └── data/                       # Initial data
│           └── cron_jobs.xml           # Scheduled jobs
│
├── 📂 oca/                             # OCA Community Modules (auto-downloaded)
│   ├── social/                         # ✅ Email & Communication
│   │   ├── mail_gateway/               # Email gateway
│   │   ├── mail_notification_with_history/
│   │   └── mail_tracking/              # Email tracking
│   ├── server-ux/                      # ✅ UX Enhancements
│   │   ├── announcement/               # System announcements
│   │   ├── base_user_role/             # Role-based access
│   │   └── date_range/                 # Date range filters
│   ├── web/                            # ✅ Web Interface
│   │   ├── web_responsive/             # Mobile responsive
│   │   ├── web_editor_enhanced/        # Rich text editor
│   │   └── web_notify/                 # Browser notifications
│   ├── project/                        # ✅ Project Management
│   │   ├── project_timeline/           # Gantt charts
│   │   ├── project_milestone/          # Milestones
│   │   └── project_task_dependency/    # Task dependencies
│   └── dms/                            # ✅ Document Management
│       └── dms/                        # Document system
│
├── 📂 config/                          # Configuration Files
│   ├── odoo.conf                       # Local development config
│   ├── odoo.supabase.conf              # Supabase cloud config
│   └── nginx.conf                      # Reverse proxy config
│
├── 📂 docker/                          # Docker Configuration
│   └── Dockerfile                      # Odoo + OCA image build
│
├── 📂 scripts/                         # Automation Scripts
│   ├── setup.sh                        # ✅ Initial project setup
│   ├── deploy.sh                       # 🚧 Deploy to DigitalOcean
│   ├── download_oca_modules.sh         # ✅ OCA module installer
│   ├── init_supabase_db.sh             # ✅ Supabase DB init
│   └── sql/                            # Database Scripts
│       └── init_supabase.sql           # 🚧 Supabase schema
│
├── 📂 .github/                         # GitHub Actions CI/CD
│   └── workflows/
│       ├── deploy.yml                  # 🚧 Deployment pipeline
│       └── test.yml                    # 🚧 Automated testing
│
├── 📂 docs/                            # Documentation
│   ├── QUICK_START.md                  # 🚧 Getting started guide
│   ├── CONTRIBUTING.md                 # 🚧 Contribution guide
│   └── DEPLOYMENT.md                   # 🚧 Deployment guide
│
├── 📄 docker-compose.yml               # ✅ Local development
├── 📄 docker-compose.supabase.yml      # ✅ Supabase-connected setup
├── 📄 docker-compose.production.yml    # ✅ Production deployment
├── 📄 .env.example                     # 🚧 Environment template
├── 📄 .env.production                  # ✅ Production env (gitignored)
├── 📄 .gitignore                       # ✅ Git ignore patterns
├── 📄 package.json                     # 🚧 NPM scripts
├── 📄 LICENSE                          # LGPL-3.0 license
└── 📄 README.md                        # ✅ This file

Legend: ✅ Implemented | 🚧 Planned | 📦 Module | 📂 Directory | 📄 File
```

## 🛠 Tech Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Core** | Odoo | 18.0 | ERP/CRM platform |
| **Community** | OCA Modules | Latest | Enterprise features |
| **Database** | PostgreSQL | 15 | Local Odoo database |
| **Cloud DB** | Supabase | Latest | Real-time sync & storage |
| **Cache** | Redis | 7.x | Session & queue management |
| **Storage** | MinIO / DO Spaces | Latest | File storage (S3-compatible) |
| **Proxy** | Nginx | Alpine | Reverse proxy & SSL |
| **Container** | Docker | 20.10+ | Containerization |
| **Orchestration** | Docker Compose | 2.0+ | Multi-container management |
| **Deployment** | DigitalOcean | App Platform | Cloud hosting |
| **CI/CD** | GitHub Actions | Latest | Automated deployment |
| **Email** | SendGrid/AWS SES | Latest | Email delivery |
| **Monitoring** | Grafana/Prometheus | Optional | Performance monitoring |

## 📦 Quick Start

### Prerequisites

- Docker 20.10+ & Docker Compose 2.0+
- Git
- (Optional) DigitalOcean account for production
- (Optional) Supabase account for real-time sync

### 🐳 Local Development (5 minutes)

```bash
# 1. Clone repository
git clone https://github.com/jgtolentino/odoboo-workspace.git
cd odoboo-workspace

# 2. Setup environment
cp .env.example .env
# Edit .env with your credentials (optional for local dev)

# 3. Download OCA modules (already done if oca/ folder exists)
cd oca && ls -la

# 4. Start services
docker-compose up -d

# 5. Wait for startup (30-60 seconds)
docker-compose logs -f odoo

# 6. Access Odoo
open http://localhost:8069

# Default credentials: admin / admin
# Create database: odoo_workspace
```

### 🚀 Production Deployment to DigitalOcean

```bash
# 1. Install doctl CLI
brew install doctl  # macOS
# or snap install doctl  # Linux

# 2. Authenticate
doctl auth init

# 3. Configure environment
cp .env.production .env
# Edit with your Supabase & DO credentials

# 4. Deploy (coming soon)
./scripts/deploy.sh digitalocean
```

## 🔧 Configuration

### Environment Variables (.env)

```env
# === SUPABASE CONFIGURATION ===
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
POSTGRES_PASSWORD=your_postgres_password

# === ODOO CONFIGURATION ===
ADMIN_PASSWORD=secure_admin_password
DB_NAME=odoo_workspace
DB_USER=odoo
DB_PASSWORD=odoo_password

# === DIGITALOCEAN (Production) ===
DO_ACCESS_TOKEN=your_do_token
DO_SPACES_KEY=your_spaces_key
DO_SPACES_SECRET=your_spaces_secret

# === EMAIL CONFIGURATION ===
EMAIL_PROVIDER=sendgrid  # or smtp, aws_ses
SENDGRID_API_KEY=your_sendgrid_key
```

## 📚 Installed Modules

### OCA Community Modules

| Module | Description | Category |
|--------|-------------|----------|
| `mail_gateway` | Multi-provider email gateway | Communication |
| `mail_notification_with_history` | Email notification tracking | Communication |
| `announcement` | System-wide announcements & alerts | Notifications |
| `web_responsive` | Mobile-responsive UI | Interface |
| `web_editor_enhanced` | Rich text editor improvements | Content |
| `project_timeline` | Gantt charts for projects | Project Mgmt |
| `project_milestone` | Milestone tracking | Project Mgmt |
| `dms` | Document management system | Documents |

### Custom Modules

| Module | Description | Status |
|--------|-------------|--------|
| `supabase_sync` | Real-time bi-directional Supabase sync | ✅ Active |
| `notion_workspace` | Notion-like hierarchical pages | 🚧 Planned |
| `email_notifications` | Multi-provider email system | 🚧 Planned |

## 🧪 Testing

```bash
# Run all tests
docker-compose exec odoo pytest

# Run specific module tests
docker-compose exec odoo pytest addons/supabase_sync/tests/

# Code quality
docker-compose exec odoo flake8 addons/
```

## 📊 API Documentation

### JSON-RPC API (Odoo Native)

```bash
# Authenticate
curl -X POST http://localhost:8069/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "params": {"db": "odoo_workspace", "login": "admin", "password": "admin"}}'

# Get projects
curl -X POST http://localhost:8069/web/dataset/call_kw \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "params": {"model": "project.project", "method": "search_read"}}'
```

## 📝 License

LGPL-3.0 - See [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [Odoo Community Association (OCA)](https://odoo-community.org/)
- [DigitalOcean](https://www.digitalocean.com/)
- [Supabase](https://supabase.com/)

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/jgtolentino/odoboo-workspace/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/jgtolentino/odoboo-workspace/discussions)
- 📧 **Email**: support@odoboo.com

---
**Built with ❤️ for enterprise teams**
