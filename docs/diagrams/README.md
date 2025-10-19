# Technical Architecture Diagrams

Professional Draw.io diagrams for OdoBoo Workspace technical documentation.

## 📊 Available Diagrams

### 1. System Architecture (`system-architecture.drawio`)
**Overview**: Complete system architecture with all layers and integrations

**Layers**:
- **Frontend Layer**: Vercel deployment, Next.js 15 App Router, React components, client libraries
- **Backend Layer**: Supabase PostgreSQL, RLS policies, database functions, triggers, pg_cron, Edge Functions
- **CI/CD Layer**: GitHub Actions pipeline, 5 jobs, triggers, secrets, notifications

**Components**:
- Vercel (Production Hosting)
- Next.js 15 App Router
- React Components (Apps Catalog, Notion Workspace, Task Manager)
- Supabase PostgreSQL (spdtwktxdalcfigzeqrz)
- Database tables (app_category, app, app_install, app_review, knowledge_pages, content_blocks, companies)
- RLS policies (company-scoped, user-based)
- Database functions (update_app_rating, increment_install_count, export/import)
- Triggers (auto-update ratings, auto-increment installs)
- pg_cron jobs (scheduled tasks)
- Supabase Edge Functions (Deno runtime)
- GitHub Actions (5-job CI/CD pipeline)
- GitHub Secrets (POSTGRES_URL, VERCEL_TOKEN, SUPABASE keys)

**Connections**:
- HTTPS connection pooler (Vercel → Supabase)
- Supabase Client SDK (Next.js → RLS)
- API calls (Components → Edge Functions)
- Database triggers and functions
- CI/CD deployment and migrations

**Use Cases**:
- Onboarding new developers
- System documentation
- Architecture reviews
- Stakeholder presentations

---

### 2. Database Schema ERD (`database-schema.drawio`)
**Overview**: Complete apps catalog database schema with relationships and constraints

**Tables**:
1. **app_category** (8 categories)
   - Primary key: id (BIGSERIAL)
   - Unique constraint: slug
   - Fields: name, description, icon, timestamps

2. **app** (10 sample apps)
   - Primary key: id (BIGSERIAL)
   - Foreign key: category_id → app_category
   - Unique constraint: slug
   - Fields: name, summary, description, icon, version, author, website, repository, license, pricing, flags, ratings, install_count

3. **app_install** (user installations)
   - Primary key: id (BIGSERIAL)
   - Foreign keys: app_id → app, company_id → companies
   - Unique constraint: (app_id, user_id, company_id)
   - Fields: user_id, installed_at, settings (JSONB), is_active

4. **app_review** (user reviews)
   - Primary key: id (BIGSERIAL)
   - Foreign key: app_id → app
   - Unique constraint: (app_id, user_id)
   - Fields: user_id, rating (1-5 CHECK), title, comment, timestamps

**Relationships**:
- app_category → app (1:N)
- app → app_install (1:N)
- app → app_review (1:N)

**Triggers**:
1. **update_app_rating()** - AFTER INSERT/UPDATE on app_review
   - Updates app.rating with AVG(review.rating)

2. **increment_install_count()** - AFTER INSERT on app_install
   - Increments app.install_count when is_active = TRUE

**Indexes**:
- idx_app_category ON app(category_id)
- idx_app_slug ON app(slug)
- idx_app_published ON app(is_published) WHERE is_published = TRUE
- idx_app_install_user ON app_install(user_id)

**Row Level Security**:
- app_category: Public read (SELECT)
- app: Public read for published apps
- app_install: User/company-scoped (CRUD with auth.uid() and ops.jwt_company_id())
- app_review: Public read, user-owned write

**Use Cases**:
- Database design documentation
- Migration planning
- RLS policy review
- Performance optimization

---

### 3. CI/CD Pipeline Flow (`cicd-pipeline.drawio`)
**Overview**: Complete GitHub Actions workflow with 5 jobs and dependencies

**Trigger Events**:
1. Push to main branch
2. Push to feature/** branches
3. Pull Request → main
4. Manual dispatch (workflow_dispatch)

**Job Pipeline**:

**Job 1: Database Migrations** (runs on main/dispatch only)
1. Checkout repository (actions/checkout@v4)
2. Install PostgreSQL client (apt-get)
3. Apply migrations (psql $POSTGRES_URL)
   - 005_apps_catalog.sql
   - 003_feature_inventory.sql
4. Verify database (table counts, health checks)
5. Create deployment summary

**Job 2: Frontend Build & Test** (runs on all triggers)
1. Checkout + Setup Node.js 20 (actions/setup-node@v4)
2. Install dependencies (npm ci)
3. Type checking (npx tsc --noEmit)
4. Linting (npm run lint)
5. Build application (npm run build)
   - Environment: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY

**Job 3: Deploy to Vercel** (depends on frontend-test)
1. Pull Vercel environment (vercel pull --prod)
2. Build artifacts (vercel build --prod)
3. Deploy to production (vercel deploy --prebuilt --prod)
   - Secrets: VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID

**Job 4: Post-Deployment Checks** (depends on deploy)
1. Health check (curl /apps → 200 OK)
2. Performance check (response time < 3 seconds)
3. Create health summary

**Job 5: Send Notifications** (depends on all, always runs)
1. Success notification (if deploy succeeded)
   - All checks passed
   - Production URL: https://v0-odoo-notion-workspace.vercel.app
2. Failure notification (if deploy failed)
   - Deployment status
   - Log references

**Dependencies**:
- Job 3 needs Job 2 (frontend-test)
- Job 4 needs Job 3 (deploy)
- Job 5 needs Jobs 1, 3, 4 (database, deploy, post-deploy)

**Use Cases**:
- DevOps documentation
- CI/CD troubleshooting
- Pipeline optimization
- Workflow training

---

## 🛠️ How to Use These Diagrams

### Opening in Draw.io Desktop
1. Download and install [draw.io desktop](https://github.com/jgraph/drawio-desktop/releases)
2. File → Open → Select `.drawio` file
3. Edit and save changes

### Opening in draw.io Web
1. Go to https://app.diagrams.net
2. File → Open from → Device
3. Select `.drawio` file
4. Edit online (no account required)

### Opening in VS Code
1. Install extension: `hediet.vscode-drawio`
2. Open `.drawio` file in VS Code
3. Edit inline with preview

### Exporting
**PNG/JPG/SVG** (for presentations):
```
File → Export as → PNG/JPEG/SVG
Resolution: 300 DPI (print quality)
Transparent background: ✓ (for PNG/SVG)
```

**PDF** (for documentation):
```
File → Export as → PDF
Include: All pages
Quality: High
```

**XML** (for version control):
```
Already in XML format (.drawio files are XML)
Commit directly to git
```

## 📁 File Organization

```
docs/diagrams/
├── README.md                      # This file
├── system-architecture.drawio     # Complete system overview
├── database-schema.drawio         # Apps catalog ERD
└── cicd-pipeline.drawio          # GitHub Actions workflow
```

## 🎨 Color Coding

**System Architecture**:
- 🔵 Blue (#dae8fc): Frontend Layer
- 🔴 Red (#f8cecc): Backend Layer
- 🟣 Purple (#e1d5e7): CI/CD Layer
- 🟡 Yellow (#fff2cc): Key infrastructure (Vercel, Supabase)
- 🟢 Green (#d5e8d4): Components and services

**Database Schema**:
- 🔵 Blue (#dae8fc): Categories table
- 🟡 Yellow (#fff2cc): Apps table (central)
- 🟢 Green (#d5e8d4): Installs table
- 🔴 Red (#f8cecc): Reviews table
- 🟣 Purple (#e1d5e7): Foreign keys and relationships

**CI/CD Pipeline**:
- 🟢 Green (#d5e8d4): Build and test steps
- 🔴 Red (#f8cecc): Database operations
- 🔵 Blue (#dae8fc): Frontend operations
- 🟣 Purple (#e1d5e7): Deployment steps
- ⚪ Gray (#f5f5f5): Notifications and reports

## 🔄 Updating Diagrams

When architecture changes:

1. **Open relevant diagram** in draw.io
2. **Update components** (add/remove/modify boxes)
3. **Update connections** (add/remove arrows)
4. **Update labels** (revise text descriptions)
5. **Export PNG** (for quick reference in docs)
6. **Commit changes** to git

Example commit message:
```
docs(diagrams): Update system architecture - add new Edge Function

- Added OCR processing Edge Function
- Updated data flow arrows
- Refreshed component versions
```

## 📚 Related Documentation

- **System Overview**: `docs/CURRENT_DEPLOYMENT_STATUS.md`
- **Database Migrations**: `supabase/migrations/`
- **CI/CD Workflows**: `.github/workflows/`
- **Deployment Guide**: `docs/NOTION_WORKSPACE_DEPLOYMENT.md`

---

**Last Updated**: 2025-10-19
**Maintained By**: Claude Code
**Draw.io Version**: 24.7.17
