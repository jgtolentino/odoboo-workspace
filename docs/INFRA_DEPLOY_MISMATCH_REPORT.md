# 🔍 Infrastructure & Deployment Mismatch Report

**Date**: 2025-10-20
**Project**: Odoboo Workspace (Odoo 18 + Next.js + Supabase)
**Status**: ⚠️ Critical Misalignments Identified

---

## 🎯 Executive Summary

This project has a **dual-architecture** system with **significant misalignments** between:

1. **Odoo 18 ERP** (Python/PostgreSQL) - Enterprise Resource Planning
2. **Next.js Web App** (TypeScript/Supabase) - Modern web interface

**Key Finding**: The newly added database migration system is designed for **Next.js/Supabase only** and does NOT apply to the Odoo database schema. This creates confusion about which database is being migrated.

---

## 🏗️ Architecture Overview

### Dual Database Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ODOBOO WORKSPACE                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────┐          ┌────────────────────┐     │
│  │   ODOO 18 ERP      │          │   NEXT.JS APP      │     │
│  │   (Python)         │          │   (TypeScript)     │     │
│  ├────────────────────┤          ├────────────────────┤     │
│  │ PostgreSQL DB      │          │ Supabase DB        │     │
│  │ (Local/Supabase)   │          │ (PostgreSQL)       │     │
│  │                    │          │                    │     │
│  │ Schemas:           │          │ Schemas:           │     │
│  │ - odoboo_local     │          │ - schema_migrations│     │
│  │ - odoo_workspace   │          │ - migration_history│     │
│  │ - odoo_production  │          │ - knowledge_pages  │     │
│  │                    │          │ - hr_expenses      │     │
│  │ Modules:           │          │ - project_tasks    │     │
│  │ - hr_expense_ocr   │          │ - invoices         │     │
│  │ - web_dashboard    │          │ - vendors          │     │
│  │ - 90+ OCA modules  │          │ - analytics        │     │
│  └────────────────────┘          └────────────────────┘     │
│           ↓                               ↓                 │
│  Port: 8069 (web)                Database URL:              │
│  Port: 8072 (longpolling)        spdtwktxdalcfigzeqrz      │
└─────────────────────────────────────────────────────────────┘
```

---

## ❌ Critical Misalignments

### 1. Database Migration System Confusion

**Problem**: The newly created migration system (`scripts/run-migrations.js`, `00_migration_state_tracking.sql`) is designed for **Supabase (Next.js side)** but the codebase is primarily **Odoo-focused**.

| Component | Intended For | Actually Needed For |
|-----------|--------------|---------------------|
| `scripts/run-migrations.js` | Supabase PostgreSQL | ✅ Next.js app |
| `scripts/*.sql` migrations | Supabase schemas | ✅ Next.js app |
| `.github/workflows/db-*.yml` | Supabase DATABASE_URL | ✅ Next.js app |
| Odoo modules | Odoo PostgreSQL | ❌ Not covered by migration system |

**Impact**:
- ⚠️ Odoo database changes (modules, customizations) are NOT managed by the migration runner
- ⚠️ Confusion about which database `DATABASE_URL` points to
- ⚠️ Two separate deployment workflows needed

**Recommendation**:
```bash
# Clearly separate the two systems:

# For Odoo database (use Odoo's module upgrade system):
docker exec odoo18 odoo -d odoboo_local -u hr_expense_ocr_audit,web_dashboard_advanced

# For Next.js/Supabase database (use migration runner):
DATABASE_URL=$SUPABASE_URL node scripts/run-migrations.js
```

---

### 2. Docker Compose File Proliferation

**Problem**: 5 different `docker-compose.yml` files with overlapping but inconsistent configurations.

| File | Purpose | Status | Issues |
|------|---------|--------|--------|
| `docker-compose.yml` | Base configuration | 🟡 Unclear | No database service defined |
| `docker-compose.local.yml` | Local dev (Odoo + local PostgreSQL) | ✅ Working | Uses `db:5432` |
| `docker-compose.supabase.yml` | Odoo + Supabase PostgreSQL | 🟡 Partial | Only Odoo service, no db service |
| `docker-compose.production.yml` | Production config | ❌ Unknown | Not reviewed |
| `docker-compose.simple.yml` | Simplified setup | ❌ Unknown | Not reviewed |

**docker-compose.local.yml** (Working):
```yaml
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: odoo  # ⚠️ Insecure for production
    ports:
      - "5432:5432"  # ⚠️ Exposes PostgreSQL externally

  odoo:
    image: odoo:18.0
    depends_on:
      - db
    environment:
      HOST: db  # Points to local PostgreSQL
      USER: odoo
      PASSWORD: odoo
```

**docker-compose.supabase.yml** (Partial):
```yaml
services:
  odoo:
    image: odoo:18.0
    environment:
      # ⚠️ Hardcoded Supabase credentials
      HOST: aws-1-us-east-1.pooler.supabase.com
      USER: postgres.spdtwktxdalcfigzeqrz
      PASSWORD: SHWYXDMFAwXI1drT  # ⚠️ EXPOSED SECRET
      DB_SSLMODE: require
```

**Issues**:
- ❌ Supabase credentials **hardcoded** in `docker-compose.supabase.yml`
- ❌ No database service in `docker-compose.supabase.yml` (Odoo points to external Supabase)
- ❌ PostgreSQL exposed on port 5432 in local setup (security risk)
- ❌ Unclear which compose file is canonical

**Recommendation**:
```bash
# Consolidate to 2 files with environment variable injection:

# 1. docker-compose.yml (base - no secrets)
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  odoo:
    environment:
      HOST: ${DB_HOST}
      USER: ${DB_USER}
      PASSWORD: ${DB_PASSWORD}

# 2. docker-compose.override.yml (for local dev only, gitignored)
# Contains local overrides

# Use .env file for secrets (gitignored)
```

---

### 3. Environment Variable Chaos

**Problem**: Environment variables are spread across multiple files with inconsistent naming and missing values.

#### File: `.env.example` (Template)

```bash
# Odoo Configuration
DB_HOST=db
DB_NAME=odoo_workspace
DB_USER=odoo
DB_PASSWORD=SecureOdooPassword123!

# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# DigitalOcean
DO_DROPLET_IP=your.droplet.ip.address
DOMAIN=odoboo.yourdomain.com
```

**Status**: ✅ Good template, but not used

#### File: `.env.production` (Actual)

```bash
# Supabase (REAL credentials - ⚠️ SHOULD BE GITIGNORED!)
NEXT_PUBLIC_SUPABASE_URL=https://spdtwktxdalcfigzeqrz.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
POSTGRES_PASSWORD=SHWYXDMFAwXI1drT  # ⚠️ EXPOSED SECRET

# Odoo
ODOO_ADMIN_PASSWORD=admin  # ⚠️ Weak password
ODOO_DATABASE_NAME=odoo_production

# DigitalOcean (not configured)
DO_ACCESS_TOKEN=your_digitalocean_token_here  # ⚠️ Placeholder
```

**Critical Issues**:
- ❌ **SECURITY**: `.env.production` contains **real secrets** and may be committed to git
- ❌ **SECURITY**: Supabase credentials exposed (JWT, passwords)
- ❌ Missing environment variables for migration runner (`DATABASE_URL`)
- ❌ Inconsistent naming: `DB_HOST` vs `POSTGRES_HOST`
- ❌ DigitalOcean placeholders not filled in

**Comparison Matrix**:

| Variable | .env.example | .env.production | docker-compose.local.yml | docker-compose.supabase.yml | Used By |
|----------|--------------|-----------------|--------------------------|----------------------------|---------|
| `DATABASE_URL` | ❌ Missing | ❌ Missing | ❌ Missing | ❌ Missing | Migration runner |
| `DB_HOST` | ✅ db | ❌ Missing | ✅ db | ❌ (hardcoded in env) | Odoo |
| `POSTGRES_HOST` | ✅ db.*.supabase.co | ✅ db.*.supabase.co | ❌ Missing | ❌ Missing | Next.js |
| `NEXT_PUBLIC_SUPABASE_URL` | ❌ Placeholder | ✅ Real | ❌ Missing | ❌ Missing | Next.js |
| `SUPABASE_SERVICE_ROLE_KEY` | ❌ Placeholder | ✅ Real (⚠️) | ❌ Missing | ❌ Missing | Next.js |
| `ODOO_ADMIN_PASSWORD` | ✅ Template | ✅ admin (⚠️) | ❌ Missing | ❌ Missing | Odoo |
| `DO_DROPLET_IP` | ❌ Placeholder | ❌ Placeholder | ❌ Missing | ❌ Missing | Deployment |

**Recommendation**:
```bash
# 1. Create .env (gitignored) from .env.example
cp .env.example .env

# 2. Add missing variables to .env.example:
DATABASE_URL=postgresql://user:pass@host:5432/dbname  # For migration runner
STAGING_DATABASE_URL=postgresql://user:pass@host:5432/staging_db
PROD_DATABASE_URL=postgresql://user:pass@host:5432/prod_db

# 3. Add .env.production to .gitignore (URGENT!)
echo ".env.production" >> .gitignore
git rm --cached .env.production
git commit -m "security: remove exposed credentials"

# 4. Rotate ALL exposed secrets:
# - Supabase: Regenerate service_role_key
# - Odoo: Change admin password
# - PostgreSQL: Change database passwords
```

---

### 4. Deployment Target Confusion

**Problem**: Multiple deployment strategies with unclear relationships.

#### Current Deployment Landscape:

| Service | Deployment Target | Status | Port | Domain |
|---------|------------------|--------|------|--------|
| Odoo 18 | Local Docker | ✅ Working | 8069 | localhost:8069 |
| Odoo 18 | DigitalOcean Droplet | 🟡 Partial | 8069 | insightpulseai.net:8069 (?) |
| Odoo 18 | Supabase PostgreSQL | 🟡 Experimental | 8069 | N/A |
| Next.js App | Unknown | ❌ Not deployed | N/A | N/A |
| OCR Service | DigitalOcean Droplet | ✅ Ready | 8000 | 188.166.237.231:8000 |
| PostgreSQL (Odoo) | Local Docker | ✅ Working | 5432 | localhost:5432 |
| PostgreSQL (Supabase) | Supabase Cloud | ✅ Working | 5432 | aws-1-us-east-1.pooler.supabase.com |

#### Deployment Scripts Analysis:

**`infra/do/deploy-droplet.sh`**:
- ✅ Creates DigitalOcean droplet in Singapore (sgp1)
- ✅ Deploys OCR service
- ❌ Does NOT deploy Odoo
- Size: s-2vcpu-4gb ($24/month)

**`infra/do/DEPLOY_PRODUCTION.sh`**:
- ✅ Production-ready OCR deployment
- ✅ Immutable tags (:prod, :sha-<gitsha>)
- ✅ Firewall hardening (port 8000 internal only)
- ✅ Snapshot automation
- ❌ Odoo deployment not included

**Missing**:
- ❌ No Odoo production deployment script
- ❌ No Next.js app deployment script
- ❌ No database backup/restore for Odoo PostgreSQL
- ❌ No staging environment for Odoo

**Recommendation**:
```bash
# Create separate deployment scripts for each service:

infra/do/
├── deploy-ocr-service.sh        # ✅ Exists (DEPLOY_PRODUCTION.sh)
├── deploy-odoo.sh               # ❌ Missing - CREATE THIS
├── deploy-nextjs-app.sh         # ❌ Missing - CREATE THIS
├── deploy-full-stack.sh         # ❌ Missing - Orchestrates all 3
└── teardown.sh                  # ❌ Missing - Clean shutdown
```

---

### 5. Database Schema Mismatch

**Problem**: Odoo schemas and Supabase schemas are stored in the same PostgreSQL instance but serve different purposes.

#### When using Supabase PostgreSQL for BOTH:

```sql
-- SUPABASE POSTGRESQL DATABASE CONTENTS:

-- Odoo Schemas (managed by Odoo modules):
odoo_production (database)
├── public (schema)
│   ├── res_users
│   ├── res_partner
│   ├── hr_expense
│   ├── project_task
│   ├── ir_module_module
│   └── ... (300+ Odoo tables)

-- Next.js Schemas (managed by migration runner):
postgres (database)  ← ⚠️ Different database!
├── public (schema)
│   ├── schema_migrations      ← Created by 00_migration_state_tracking.sql
│   ├── migration_history      ← Created by 00_migration_state_tracking.sql
│   ├── knowledge_pages        ← Created by 01_knowledge_workspace_schema.sql
│   ├── hr_expenses            ← Created by 02_hr_expense_schema.sql
│   ├── project_tasks          ← Created by 03_project_workspace_schema.sql
│   └── ... (Next.js app tables)
```

**Issues**:
- ❌ Odoo uses `odoo_production` database
- ❌ Next.js uses `postgres` database (default)
- ❌ Migration runner targets Next.js schemas, NOT Odoo
- ❌ **Duplicate table names** (`hr_expenses` in both Odoo and Next.js) with different schemas
- ❌ No synchronization between Odoo data and Next.js data

**Example Conflict**:

```sql
-- Odoo table structure:
odoo_production.public.hr_expense (
  id serial PRIMARY KEY,
  employee_id integer,
  product_id integer,
  name text,
  unit_amount numeric,
  -- Odoo-specific fields
  create_uid integer,
  write_uid integer,
  create_date timestamp,
  write_date timestamp
)

-- Next.js table structure (from 02_hr_expense_schema.sql):
postgres.public.hr_expenses (
  id uuid PRIMARY KEY,
  user_id uuid,
  amount numeric,
  title text,
  receipt_url text,
  -- Next.js-specific fields
  created_at timestamptz,
  updated_at timestamptz,
  ocr_confidence numeric,
  visual_diff_score numeric
)
```

**Impact**:
- Data is NOT shared between Odoo and Next.js
- Users would need to manually sync data
- Migration runner does NOT affect Odoo database

**Recommendation**:

**Option A**: Keep databases separate (RECOMMENDED)
```yaml
services:
  odoo-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: odoo_production
    ports:
      - "5433:5432"  # Different port to avoid conflict

  # Next.js uses Supabase PostgreSQL (separate instance)
```

**Option B**: Use same Supabase PostgreSQL but different databases
```bash
# Odoo connects to:
DATABASE_NAME=odoo_production

# Next.js connects to:
DATABASE_NAME=postgres

# Migration runner targets Next.js database:
DATABASE_URL=postgresql://postgres.spdtwktxdalcfigzeqrz:pass@supabase.com:5432/postgres

# Odoo connects to separate database:
DB_NAME=odoo_production
```

**Option C**: Build integration layer (COMPLEX)
```javascript
// services/odoo-sync/
// Sync Odoo hr_expense → Next.js hr_expenses via API
// Use Odoo XML-RPC or REST API to fetch data
// Insert into Supabase via migration or API
```

---

### 6. Missing Odoo Deployment Strategy

**Problem**: Odoo deployment is not documented or automated.

**Current State**:
- ✅ Local development works (`docker-compose.local.yml`)
- 🟡 Supabase connection works (`docker-compose.supabase.yml`)
- ❌ Production deployment undefined

**What's Missing**:

1. **Odoo Production Deployment Script**:
```bash
# infra/do/deploy-odoo.sh (DOES NOT EXIST)

#!/bin/bash
# Deploy Odoo 18 to DigitalOcean droplet with:
# - NGINX reverse proxy
# - SSL/TLS certificate
# - Supabase PostgreSQL backend
# - OCA modules mounted
# - Firewall configuration
# - Health checks
# - Backup automation
```

2. **Odoo Module Upgrade Automation**:
```bash
# No CI/CD for Odoo module upgrades
# Manual process:
docker exec odoo18 odoo -d odoboo_local -u module_name
```

3. **Odoo Data Backup/Restore**:
```bash
# No automated backup for Odoo PostgreSQL
# Supabase has automatic backups, but:
# - Only for Next.js schemas
# - Odoo schemas need separate backup strategy
```

**Recommendation**:
```bash
# Create comprehensive Odoo deployment:

1. Create infra/do/deploy-odoo.sh:
   - Provision DigitalOcean droplet
   - Install Docker + Docker Compose
   - Deploy NGINX + Certbot (SSL)
   - Deploy Odoo container
   - Configure Supabase connection
   - Mount OCA modules
   - Run health checks

2. Create .github/workflows/odoo-deploy.yml:
   - Trigger: Push to main branch (Odoo files changed)
   - Build custom Odoo Docker image with modules
   - Push to DigitalOcean Container Registry
   - Deploy to droplet
   - Run module upgrades
   - Health checks

3. Create scripts/backup-odoo-db.sh:
   - pg_dump odoo_production database
   - Upload to DigitalOcean Spaces or Supabase Storage
   - Scheduled via cron (daily)
```

---

### 7. Secrets Management Vulnerabilities

**Problem**: Secrets are exposed in multiple locations.

**Exposed Secrets**:

| Secret | Location | Severity | Status |
|--------|----------|----------|--------|
| Supabase PostgreSQL password | `.env.production` | 🔴 Critical | ⚠️ May be committed |
| Supabase service_role_key | `.env.production` | 🔴 Critical | ⚠️ May be committed |
| Supabase JWT secret | `.env.production` | 🔴 Critical | ⚠️ May be committed |
| PostgreSQL password | `docker-compose.supabase.yml` | 🔴 Critical | ✅ Committed (hardcoded) |
| Odoo admin password | `.env.production` | 🟡 High | Weak ("admin") |
| Odoo admin password | `config/odoo.local.conf` | 🟡 High | Weak ("n94h-nf3x-22pv") |
| DigitalOcean token | `.env.production` | 🟡 High | Placeholder (not set) |

**Verification**:
```bash
# Check if .env.production is tracked by git:
git ls-files | grep .env.production

# If output exists, secrets are EXPOSED in git history!
```

**Immediate Actions Required**:
```bash
# 1. Remove from git (if committed):
git rm --cached .env.production
git commit -m "security: remove exposed credentials"

# 2. Add to .gitignore:
echo ".env.production" >> .gitignore
echo ".env" >> .gitignore
echo "config/*.conf" >> .gitignore

# 3. Rotate ALL exposed secrets:
# - Supabase Dashboard → Settings → API → Reset service_role_key
# - Change Odoo admin password
# - Change PostgreSQL passwords
# - Regenerate JWT secret

# 4. Use environment variables or secrets management:
# - GitHub Secrets for CI/CD
# - DigitalOcean App Platform environment variables
# - Doppler, AWS Secrets Manager, or HashiCorp Vault for production
```

**Recommendation**:
```bash
# Use GitHub Secrets for CI/CD:
# .github/workflows/db-staging.yml
env:
  DATABASE_URL: ${{ secrets.STAGING_DATABASE_URL }}

# .github/workflows/db-prod.yml
env:
  DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
  CONFIRM_PRODUCTION_MIGRATION: true

# Local development uses .env (gitignored)
# Production uses environment variables (not in git)
```

---

## 🎯 Reconciliation Plan

### Phase 1: Security (URGENT - Do First)

```bash
# 1. Rotate all exposed secrets
# 2. Remove .env.production from git
# 3. Update .gitignore
# 4. Remove hardcoded credentials from docker-compose.supabase.yml

Timeline: 1 hour
Priority: 🔴 Critical
```

### Phase 2: Clarify Architecture (HIGH)

```bash
# 1. Document which database each service uses:
#    - Odoo → Separate PostgreSQL (local or Supabase database: odoo_production)
#    - Next.js → Supabase PostgreSQL (database: postgres)
#    - Migration runner → Next.js database ONLY

# 2. Update README with clear architecture diagram

# 3. Rename migration workflows to be explicit:
#    .github/workflows/db-staging.yml → nextjs-db-staging.yml
#    .github/workflows/db-prod.yml → nextjs-db-prod.yml

Timeline: 2 hours
Priority: 🟡 High
```

### Phase 3: Consolidate Docker Compose Files (MEDIUM)

```bash
# 1. Merge to 2 files:
#    - docker-compose.yml (base, no secrets)
#    - docker-compose.override.yml (local dev, gitignored)

# 2. Use .env for all configuration

# 3. Document usage in README

Timeline: 3 hours
Priority: 🟢 Medium
```

### Phase 4: Create Odoo Deployment Automation (MEDIUM)

```bash
# 1. Create infra/do/deploy-odoo.sh
# 2. Create .github/workflows/odoo-deploy.yml
# 3. Create backup/restore scripts

Timeline: 1 day
Priority: 🟢 Medium
```

### Phase 5: Environment Variable Standardization (LOW)

```bash
# 1. Create comprehensive .env.example with ALL variables
# 2. Document each variable in README
# 3. Validate environment variables in startup scripts

Timeline: 2 hours
Priority: 🔵 Low
```

---

## 📊 Comparison Matrix

### Odoo vs Next.js Feature Comparison

| Feature | Odoo 18 | Next.js App | Integration Status |
|---------|---------|-------------|-------------------|
| User Authentication | ✅ res.users | ✅ Supabase Auth | ❌ Not integrated |
| HR Expense Management | ✅ hr.expense module | ✅ hr_expenses table | ❌ Not integrated |
| Project Management | ✅ project.task | ✅ project_tasks table | ❌ Not integrated |
| Knowledge Base | ✅ document.page (OCA) | ✅ knowledge_pages table | ❌ Not integrated |
| File Storage | ✅ ir.attachment | ✅ Supabase Storage | ❌ Not integrated |
| OCR Processing | ✅ hr_expense_ocr_audit | ✅ OCR service API | 🟡 Partial (via API) |
| Dashboards | ✅ web_dashboard_advanced | ✅ Analytics schema | ❌ Not integrated |
| Mobile Access | ✅ PWA (web_pwa_oca) | ❌ Not implemented | ❌ Not integrated |
| API Access | ✅ XML-RPC / REST | ✅ Supabase REST API | ❌ Not integrated |
| Database Migrations | ❌ Module upgrades | ✅ Migration runner | N/A (separate DBs) |

---

## ✅ Recommended Actions

### Immediate (This Week)

1. **🔴 SECURITY**: Rotate all exposed secrets
2. **🔴 SECURITY**: Remove `.env.production` from git
3. **🔴 SECURITY**: Update `.gitignore` and `docker-compose.supabase.yml`
4. **🟡 DOCS**: Add architecture diagram to README clarifying dual-database setup
5. **🟡 DOCS**: Update migration docs to clearly state "Next.js/Supabase ONLY"

### Short-term (Next 2 Weeks)

6. **🟢 INFRA**: Consolidate docker-compose files to 2 files
7. **🟢 INFRA**: Create `.env.example` with all required variables
8. **🟢 DEPLOY**: Create `infra/do/deploy-odoo.sh` deployment script
9. **🟢 DEPLOY**: Create Odoo backup/restore automation

### Medium-term (Next Month)

10. **🔵 INTEGRATION**: Build Odoo ↔ Next.js sync service (if needed)
11. **🔵 INTEGRATION**: Unified authentication (Supabase Auth + Odoo session)
12. **🔵 DEPLOY**: Create full-stack deployment orchestration script
13. **🔵 MONITORING**: Add health checks and monitoring for all services

---

## 📚 Reference

### Current File Structure

```
odoboo-workspace/
├── .env.example              # ✅ Template (not used)
├── .env.production           # ⚠️ Real secrets (exposed!)
├── docker-compose.yml        # 🟡 Base (unclear)
├── docker-compose.local.yml  # ✅ Local Odoo + PostgreSQL
├── docker-compose.supabase.yml # ⚠️ Odoo + Supabase (hardcoded secrets)
├── docker-compose.production.yml # ❌ Unknown
├── docker-compose.simple.yml # ❌ Unknown
├── config/
│   ├── odoo.conf
│   ├── odoo.local.conf       # ✅ Local Odoo config
│   └── odoo.supabase.conf    # 🟡 Supabase Odoo config
├── infra/do/
│   ├── deploy-droplet.sh     # ✅ OCR service deployment
│   ├── DEPLOY_PRODUCTION.sh  # ✅ Production OCR deployment
│   ├── DEPLOY_WITH_TLS.sh    # ✅ TLS setup
│   └── deploy-odoo.sh        # ❌ Missing
├── scripts/
│   ├── 00_migration_state_tracking.sql # For Next.js DB
│   ├── 01_knowledge_workspace_schema.sql # For Next.js DB
│   ├── 02_hr_expense_schema.sql # For Next.js DB
│   ├── ...
│   └── run-migrations.js     # For Next.js DB (NOT Odoo)
├── .github/workflows/
│   ├── db-staging.yml        # Next.js DB migrations
│   └── db-prod.yml           # Next.js DB migrations
├── app/                      # Next.js application
│   ├── api/migrations/       # Next.js migration API
│   └── ...
└── addons/                   # Odoo custom modules
    ├── hr_expense_ocr_audit/
    └── web_dashboard_advanced/
```

### Database URL Mapping

```bash
# Next.js App Database (Supabase):
DATABASE_URL="postgresql://postgres.spdtwktxdalcfigzeqrz:SHWYXDMFAwXI1drT@aws-1-us-east-1.pooler.supabase.com:5432/postgres"
# Used by: Migration runner, Next.js API routes

# Odoo Database (Local):
DB_HOST=db
DB_PORT=5432
DB_USER=odoo
DB_PASSWORD=odoo
DB_NAME=odoboo_local
# Used by: Odoo container (docker-compose.local.yml)

# Odoo Database (Supabase - separate database):
DB_HOST=aws-1-us-east-1.pooler.supabase.com
DB_PORT=5432
DB_USER=postgres.spdtwktxdalcfigzeqrz
DB_PASSWORD=SHWYXDMFAwXI1drT
DB_NAME=odoo_production  # ⚠️ Different database than Next.js!
# Used by: Odoo container (docker-compose.supabase.yml)
```

---

**Report Generated**: 2025-10-20
**Next Review**: After Phase 1 completion (security fixes)
**Status**: 🔴 Action Required
