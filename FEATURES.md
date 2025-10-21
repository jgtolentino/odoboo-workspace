# Feature Inventory

Comprehensive catalog of implemented, in-progress, and planned features for the Odoo workspace project.

## Legend

- ✅ **Implemented**: Production-ready and deployed
- 🔄 **In Progress**: Currently under development
- 📋 **Planned**: Scheduled for future implementation
- ⏸️ **On Hold**: Deprioritized, may resume later
- ❌ **Deprecated**: No longer supported or maintained

---

## Core Infrastructure (✅ Implemented)

### Development Environment

- ✅ Docker Compose setup for local Odoo 18 development
- ✅ PostgreSQL 15 database with persistent volumes
- ✅ Supabase integration (project: spdtwktxdalcfigzeqrz)
- ✅ VS Code workspace configuration with 27 recommended extensions
- ✅ Environment variable management via `~/.zshrc`

### Deployment & CI/CD

- ✅ DigitalOcean App Platform deployment automation
- ✅ GitHub Actions workflows for visual parity testing
- ✅ Database schema drift detection (daily cron)
- ✅ Docker Buildx for multi-platform image builds (AMD64)
- ✅ DigitalOcean Container Registry (DOCR) integration

### OCR & Document Processing

- ✅ FastAPI microservice with PaddleOCR-VL-900M
- ✅ OpenAI gpt-4o-mini enhancement for structured extraction
- ✅ DigitalOcean droplet deployment (188.166.237.231)
- ✅ Visual diff with SSIM/LPIPS comparison
- ✅ JSON diff for structured data changes
- ✅ Confidence scoring and auto-approval (≥85%)

### Database & Storage

- ✅ Supabase PostgreSQL with Row Level Security (RLS)
- ✅ Task queue system (`task_queue` table)
- ✅ Visual baseline storage (`visual_baseline` table)
- ✅ Migration management with `psql` and Supabase CLI
- ✅ Connection pooler for high concurrency (port 6543)

---

## VS Code Extension (🔄 In Progress)

### Implemented Commands

- ✅ `odoo.launch` - Launch Odoo server
- ✅ `odoo.rpcConsole` - Interactive JSON-RPC console
- ✅ `db.schemaGuard` - Database schema validation
- ✅ `qa.snapshot` - Visual regression baseline capture
- ✅ `test.impact` - Jest/Pytest impact analysis
- ✅ `platform.checkStatus` - Deployment status monitoring

### TreeView Providers

- ✅ Deployment Status TreeView - Real-time monitoring for Vercel, Supabase, GitHub Actions, DigitalOcean

### Pending Implementation (📋 Planned)

- 📋 Docker management commands (stop, restart, update module)
- 📋 Deployment commands (buildx AMD64, push to DOCR, verify image)
- 📋 Queue monitor TreeView with Supabase integration
- 📋 WebView-based interactive JSON-RPC console enhancement
- 📋 Auto-refresh deployment status (configurable interval)

---

## Odoo Modules (🔄 In Progress)

### Implemented Modules

- ✅ `hr_expense_ocr_audit` - OCR receipt processing with audit trail
  - PaddleOCR-VL integration
  - Visual diff with SSIM/LPIPS
  - JSON diff for structured data
  - Anomaly detection and confidence scoring
  - OCR dashboard with real-time metrics

- ✅ `web_dashboard_advanced` - Draxlr-style interactive dashboards
  - Drag-and-drop widget builder
  - SQL + ORM data sources
  - Chart.js integration
  - OCA-ready structure

### OCA Modules Installed (✅ Implemented)

- ✅ `web_timeline` - Universal timeline views for all models
- ✅ `auditlog` - Complete change tracking and audit trails
- ✅ `queue_job` - Background job processing with monitoring

### Pending Modules (📋 Planned)

- 📋 `mail_kanban_mentions` - @mention support in kanban cards
  - Email pattern detection in messages
  - Automatic activity creation for mentions
  - Notification system integration

- 📋 `compliance_calendar` - Deadline tracking with alerts
  - Compliance milestone management
  - Email/Slack notifications
  - Dashboard integration

- 📋 `devops_snapshot_console` - DevOps monitoring dashboard
  - Deployment status tracking
  - Build log aggregation
  - Performance metrics visualization

---

## Odoo-to-Next.js Bridge (📋 Planned)

### Architecture Strategy

- 📋 No "auto-convert" approach - expose Odoo via stable API
- 📋 OpenAPI specification generation from Odoo controllers
- 📋 TypeScript type generation with `openapi-typescript`
- 📋 React hooks generation with `orval` or `openapi-fetch`
- 📋 JSON-RPC helper for direct Odoo calls
- 📋 Supabase sync alternative architecture

### Components to Build

- 📋 OpenAPI generator script for Odoo controllers
- 📋 TypeScript client SDK generation pipeline
- 📋 React hooks with automatic type inference
- 📋 Next.js UI scaffolding templates
- 📋 Authentication integration (Odoo sessions ↔ Next.js)

---

## Task Bus & Orchestration (✅ Implemented)

### Task Routes

- ✅ `DEPLOY_WEB` - Web frontend deployment
- ✅ `DEPLOY_ADE` - OCR service deployment
- ✅ `DOCS_SYNC` - Documentation synchronization
- ✅ `CLIENT_OP` - Client operations
- ✅ `DB_OP` - Database operations
- ✅ `RUNBOT_SYNC` - Runbot synchronization
- ✅ `ODOO_BUILD` - Odoo build tasks
- ✅ `ODOO_INSTALL_TEST` - Module installation testing
- ✅ `ODOO_MIGRATE_MODULE` - Module migrations
- ✅ `ODOO_VISUAL_DIFF` - Visual regression testing
- ✅ `ODOO_PACKAGE_RELEASE` - Package releases

### RPC Functions

- ✅ `route_and_enqueue()` - Task routing and queue management
- ✅ `rpc_runbot_record()` - Runbot record creation
- ✅ `rpc_enqueue_odoo_visual()` - Visual diff task enqueuing

---

## Visual Regression Testing (✅ Implemented)

### Core Functionality

- ✅ Playwright-based screenshot capture (`scripts/snap.js`)
- ✅ SSIM-based comparison (`scripts/ssim.js`)
- ✅ Baseline storage in Supabase (`visual_baseline` table)
- ✅ Result storage with scores (`visual_result` table)
- ✅ GitHub Actions integration (`.github/workflows/visual-parity.yml`)

### Thresholds & Gates

- ✅ Mobile: SSIM ≥ 0.97 (375x812 viewport, iPhone 13)
- ✅ Desktop: SSIM ≥ 0.98 (1920x1080 viewport)
- ✅ PR blocking on threshold failures
- ✅ Baseline update workflow

---

## Documentation & Project Management (✅ Implemented)

### Spec-Kit Framework

- ✅ Product vision (`spec/00-product-vision.md`)
- ✅ OCR expense processing specification (`spec/01-ocr-expense-processing.md`)
- ✅ Architecture documentation (`plan/architecture.md`)
- ✅ Technology stack rationale (`plan/stack.md`)
- ✅ Deployment standards (`plan/deployment.md`)
- ✅ Constitution with 10 core principles

### Guides & Runbooks

- ✅ OCR service deployment guide
- ✅ Custom dashboard module guide
- ✅ Enterprise vs Community gap analysis
- ✅ Flutter mobile app guide
- ✅ Project management & alerts guide
- ✅ DigitalOcean integration guide
- ✅ Self-hosting guide (CapRover alternative)
- ✅ Next.js Odoo UI parity guide

### New Documentation (🔄 In Progress)

- 🔄 Changelog (CHANGELOG.md) - Keep a Changelog format
- 🔄 Feature inventory (FEATURES.md) - This document
- 📋 Task tracking integration in VS Code extension
- 📋 Odoo-to-Next.js bridge guide

### Knowledge Base & Spec-Kit Framework (✅ Implemented)

- ✅ Knowledge base architecture (`docs/KB_OVERVIEW.md`)
  - One-way directional sync from upstream sources
  - Chunk index with SHA-1 IDs for deduplication
  - Agent skill integration for doc-lookup
- ✅ Knowledge base operations runbook (`docs/KB_RUNBOOK.md`)
  - Upstream source refresh procedures
  - Chunk rebuild and maintenance
  - Search and retrieval workflows
- ✅ Documentation writing guide (`docs/DOCS_WRITING_GUIDE.md`)
  - Spec template (What & why)
  - Runbook template (How to operate)
  - ADR template (Architecture decisions)
- ✅ Deterministic spec compilation (`scripts/spec_compile.sh`)
  - Stable, sorted JSON output with jq
  - Git hash tracking for drift detection
  - CI workflow for build verification
- ✅ Auto PR review system (`.github/workflows/pr-review-odoobo.yml`)
  - odoobo-expert agent integration
  - Automatic code review on every PR
  - GitHub Actions workflow automation

### MCP Server for Spec Inventory (✅ Implemented)

- ✅ TypeScript MCP server (`mcp-servers/spec-inventory/`)
  - list_features tool with status/category filtering
  - search_specs tool for full-text search across docs
  - read_spec tool for complete spec file retrieval
  - get_feature_stats tool for implementation progress metrics
- ✅ Example spec: Knowledge base integration (`spec/03-knowledge-base-integration.md`)
  - 4-week implementation timeline
  - Complete architecture and workflow documentation
  - Security and licensing guardrails

---

## Mobile Applications (📋 Planned)

### Expo/React Native App

- 📋 Offline-first architecture with SQLite
- 📋 Native camera integration for receipt capture
- 📋 Sync with Supabase on connectivity
- 📋 Touch-optimized UI (44px minimum tap targets)
- 📋 Bandwidth-aware image compression (<2MB)

### Features

- 📋 Expense submission with OCR
- 📋 Task management
- 📋 Real-time collaboration
- 📋 Push notifications
- 📋 Biometric authentication

---

## API & Integration (📋 Planned)

### External Integrations

- 📋 Concur expense export
- 📋 Slack notifications
- 📋 Email alerts
- 📋 Webhook support for task bus events
- 📋 OAuth2 provider for third-party apps

### API Enhancements

- 📋 GraphQL layer over Supabase REST
- 📋 Rate limiting and throttling
- 📋 API versioning strategy
- 📋 OpenAPI documentation with Swagger UI

---

## Performance & Optimization (📋 Planned)

### Backend

- 📋 GPU acceleration for OCR (10x faster processing)
- 📋 Redis caching layer
- 📋 Database query optimization
- 📋 Connection pooling tuning
- 📋 CDN integration for static assets

### Frontend

- 📋 Code splitting and lazy loading
- 📋 Service worker for offline support
- 📋 Image optimization pipeline
- 📋 Bundle size reduction (<500KB initial)
- 📋 Core Web Vitals optimization (LCP <2.5s, FID <100ms, CLS <0.1)

---

## Security & Compliance (📋 Planned)

### Security Enhancements

- 📋 Two-factor authentication (2FA)
- 📋 Audit log retention policies
- 📋 Encryption at rest for sensitive data
- 📋 Penetration testing and vulnerability scanning
- 📋 OWASP compliance validation

### Compliance

- 📋 GDPR compliance tools (data export, deletion)
- 📋 SOC 2 audit preparation
- 📋 HIPAA compliance (if handling healthcare data)
- 📋 Data residency controls

---

## Analytics & Monitoring (📋 Planned)

### Observability

- 📋 Prometheus metrics export
- 📋 Grafana dashboards
- 📋 Application performance monitoring (APM)
- 📋 Error tracking with Sentry
- 📋 Log aggregation with Loki

### Business Analytics

- 📋 Expense analytics dashboard
- 📋 OCR accuracy tracking
- 📋 User engagement metrics
- 📋 Cost analysis and optimization reports

---

## Deprecated Features (❌)

### Azure Infrastructure

- ❌ Azure Container Registry (ACR) - Replaced by DigitalOcean Container Registry
- ❌ Azure Container Instances (ACI) - Replaced by DigitalOcean App Platform
- ❌ Azure Document Intelligence - Replaced by PaddleOCR-VL-900M
- ❌ Azure OpenAI - Replaced by direct OpenAI API (gpt-4o-mini)
- ❌ Azure Key Vault - Replaced by environment variables + Supabase Vault

### Other Deprecated

- ❌ Bruno executor - Deprecated executor service
- ❌ Notion API integration - Removed from architecture
- ❌ Local Docker for production - Replaced by DigitalOcean App Platform

---

## Success Metrics

### Performance Targets (✅ Implemented)

- ✅ OCR Processing: P95 <30s (receipt upload → fields filled)
- ✅ Auto-Approval Rate: ≥85% (confidence ≥0.85)
- ✅ Monthly Cost: <$20 USD (87% reduction from $100 Azure budget)

### Quality Targets (✅ Implemented)

- ✅ OCR Accuracy: ≥95% on vendor, amount, date
- ✅ Visual Parity: SSIM ≥0.97 (mobile), ≥0.98 (desktop)
- ✅ Database Schema Compliance: 100% (daily drift detection)

### Pending Targets (📋 Planned)

- 📋 Uptime: 99.9% (8.7 hours downtime/year)
- 📋 API Response Time: P95 <200ms
- 📋 Mobile TTI: <2.5s on 3G
- 📋 Test Coverage: ≥80% unit, ≥70% integration

---

## Roadmap Milestones

### P0 (MVP - Completed ✅)

- ✅ Single receipt OCR (vendor, amount, date, tax)
- ✅ Mobile photo upload with offline draft
- ✅ Confidence scoring and auto-approval (≥85%)
- ✅ Basic audit trail (who, when, result)
- ✅ DigitalOcean deployment (CPU mode)

### P1 (v1.0 - In Progress 🔄)

- 🔄 VS Code extension with Docker/deployment management
- 📋 Change detection (visual + JSON diff)
- 📋 Batch processing (50+ receipts)
- 📋 OCR dashboard with metrics
- 📋 Concur export integration
- 📋 Multi-language support (ES, FR, JA, ZH)

### P2 (v2.0 - Planned 📋)

- 📋 GPU acceleration (10x faster processing)
- 📋 Advanced analytics (fraud risk scoring)
- 📋 Handwritten receipt support (experimental)
- 📋 Vendor rate card auto-matching
- 📋 AI-powered category suggestions
- 📋 Mobile app (Expo/React Native)

---

## MCP Data Connectors (✅ Implemented)

### Native MCP Servers (Claude/Cursor)
- ✅ `mcp-spec-inventory` - TypeScript MCP server for spec YAML file management
  - Full CRUD operations (create, read, update, delete, move)
  - Filtering by status, priority, owner
  - Search across all spec fields
  - Automatic validation and reference checking

- ✅ `mcp-odoo` - Python MCP server for Odoo XML-RPC
  - search_read for any Odoo model
  - call_kw for custom methods
  - get_model_fields for schema introspection

- ✅ `supabase` - External MCP integration
  - Database operations (docs, database, account)
  - Edge Functions management
  - Storage and branching

### HTTP Gateway (ChatGPT Actions)
- ✅ `spec-inventory-http` - Express gateway exposing MCP tools as REST API
  - OpenAPI 3.1 specification
  - Bearer token authentication for writes
  - CORS enabled for GPT Actions
  - Health monitoring endpoint

### CI/CD Integration
- ✅ Spec validation workflow (`.github/workflows/spec-inventory.yml`)
  - Validates YAML format and required fields
  - Checks FEATURES.md references
  - Posts PR comments with spec summary
  - Generates spec-index.json artifact

- ✅ Health check workflow (`.github/workflows/connectors-health.yml`)
  - Runs every 30 minutes
  - Tests gateway endpoints
  - Monitors OpenAPI spec accessibility

### Example Specs Created
- ✅ FEAT-001: User Authentication System (P0, done)
- ✅ FEAT-002: Role-Based Access Control (P0, doing)
- ✅ FEAT-015: Real-time Collaboration Engine (P1, todo)
- ✅ FEAT-042: Extended OAuth2 Providers (P2, todo)
- ✅ FEAT-100: Mobile App Offline Sync (P1, paused)

For detailed MCP deployment instructions, see [`docs/MCP_DEPLOYMENT_GUIDE.md`](./docs/MCP_DEPLOYMENT_GUIDE.md).

---

**Last Updated**: 2025-10-20
**Next Review**: 2025-11-01
