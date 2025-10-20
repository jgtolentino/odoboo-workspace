# Implementation Tasks

Work breakdown organized by milestone. Each task includes acceptance criteria and estimated effort.

## Quick Reference

- **P0 (MVP)**: Weeks 1-4 → Core functionality, single-user prototype
- **P1 (v1.0)**: Weeks 5-8 → Multi-user, production-ready
- **P2 (v2.0)**: Weeks 9-12 → Advanced features, enterprise scale

**Status Key**: ⏳ Pending | 🔄 In Progress | ✅ Completed | ❌ Blocked

---

## P0: MVP (Weeks 1-4)

**Goal**: Single-user prototype with core functionality (Knowledge, Projects, Expenses with OCR)

### Database & Infrastructure

**TASK-001**: Database Schema Setup
- **Description**: Create core tables (users, orgs, teams, knowledge_page, project, task, expense)
- **Dependencies**: None
- **Acceptance Criteria**:
  - All tables have RLS policies enabled
  - Migration scripts in `packages/db/sql/`
  - Schema documentation generated
  - CI drift detection passes
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-002**: Supabase Configuration
- **Description**: Setup Supabase project, configure auth, storage policies
- **Dependencies**: TASK-001
- **Acceptance Criteria**:
  - Email auth + OAuth (Google, GitHub) working
  - Storage buckets with RLS policies
  - Edge Functions deployed
  - Connection pooler configured (port 6543)
- **Effort**: 2 days
- **Status**: ⏳ Pending

**TASK-003**: DigitalOcean OCR Service Deployment
- **Description**: Deploy PaddleOCR service to DigitalOcean droplet
- **Dependencies**: None
- **Acceptance Criteria**:
  - AMD64 Docker image built and pushed to DOCR
  - Droplet deployed (s-2vcpu-4gb, Singapore)
  - NGINX + TLS configured (ocr.insightpulseai.net)
  - Health check returns 200 OK
  - `/v1/parse` endpoint returns OCR results in <30s
- **Effort**: 2 days
- **Status**: 🔄 In Progress (AMD64 build issue)

**TASK-004**: CI/CD Pipeline Setup
- **Description**: GitHub Actions workflows for lint, test, db-staging, db-prod
- **Dependencies**: TASK-001, TASK-002
- **Acceptance Criteria**:
  - CI runs on every PR
  - Database migrations auto-apply on merge to main
  - Visual parity tests run on UI changes
  - All workflows pass
- **Effort**: 2 days
- **Status**: ⏳ Pending

### Web Frontend (Next.js)

**TASK-005**: Next.js Project Setup
- **Description**: Create Next.js 14+ app with App Router, Tailwind CSS v4, TypeScript
- **Dependencies**: TASK-002
- **Acceptance Criteria**:
  - Project initialized with Turbopack
  - Tailwind CSS configured with design tokens
  - Supabase client configured
  - Auth flow works (login, signup, logout)
  - TTI <2.5s on homepage
- **Effort**: 2 days
- **Status**: ⏳ Pending

**TASK-006**: Apps Catalog Page
- **Description**: `/apps` page with Knowledge, Projects, Expenses cards
- **Dependencies**: TASK-005
- **Acceptance Criteria**:
  - Grid layout with 3 app cards
  - Each card links to app page
  - Responsive (mobile, tablet, desktop)
  - TTI <2.5s (p75)
- **Effort**: 1 day
- **Status**: ⏳ Pending

**TASK-007**: Knowledge App (Notion-style Pages)
- **Description**: Create, edit, view knowledge pages with rich formatting
- **Dependencies**: TASK-005
- **Acceptance Criteria**:
  - Create page with title + markdown content
  - Edit page with inline editor (TipTap or Lexical)
  - Tag pages and filter by tag
  - Search pages by title/content
  - Presence indicators (who's viewing)
  - CRUD p95 <200ms via PostgREST
- **Effort**: 5 days
- **Status**: ⏳ Pending

**TASK-008**: Projects App (Kanban + Tasks)
- **Description**: Project list, kanban board, task management
- **Dependencies**: TASK-005
- **Acceptance Criteria**:
  - Create project with name + description
  - Kanban board with drag-and-drop columns
  - Create tasks with assignee, due date, priority
  - Drag tasks between columns
  - Mobile-responsive kanban
- **Effort**: 5 days
- **Status**: ⏳ Pending

**TASK-009**: Expenses App (OCR Integration)
- **Description**: Upload receipt, OCR extraction, expense list
- **Dependencies**: TASK-003, TASK-005
- **Acceptance Criteria**:
  - Upload receipt image (JPEG, PNG, PDF)
  - OCR extracts vendor, amount, date, tax (≥95% accuracy)
  - Display confidence score
  - Edit OCR-extracted fields
  - Expense list with filters
  - Auto-approval if confidence ≥85%
- **Effort**: 5 days
- **Status**: ⏳ Pending

### Mobile App (Expo)

**TASK-010**: Expo Project Setup
- **Description**: Create Expo app with React Native, offline SQLite
- **Dependencies**: TASK-002
- **Acceptance Criteria**:
  - Expo SDK 49+ initialized
  - Supabase client configured
  - SQLite for offline drafts
  - Auth flow works (login, signup)
  - App runs on iOS + Android simulators
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-011**: Mobile Expenses (Photo Capture)
- **Description**: Snap photo → OCR → create expense
- **Dependencies**: TASK-003, TASK-010
- **Acceptance Criteria**:
  - Open camera with single tap
  - Snap photo → save locally in SQLite
  - Sync to Supabase when online
  - OCR processing triggered on sync
  - Fields auto-filled in ≤10 seconds
- **Effort**: 4 days
- **Status**: ⏳ Pending

### Testing & Quality

**TASK-012**: Unit Tests (≥80% Coverage)
- **Description**: Jest unit tests for all components and utilities
- **Dependencies**: TASK-005, TASK-007, TASK-008, TASK-009
- **Acceptance Criteria**:
  - ≥80% unit test coverage
  - All critical paths tested
  - Tests pass in CI
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-013**: E2E Tests (Playwright)
- **Description**: End-to-end tests for critical user journeys
- **Dependencies**: TASK-005, TASK-007, TASK-008, TASK-009
- **Acceptance Criteria**:
  - Test: Create knowledge page → edit → save
  - Test: Create project → add task → move to done
  - Test: Upload receipt → OCR → create expense
  - All tests pass in CI
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-014**: Visual Parity Tests
- **Description**: SSIM-based screenshot comparison vs. baseline
- **Dependencies**: TASK-005, TASK-007, TASK-008, TASK-009
- **Acceptance Criteria**:
  - Baseline screenshots captured
  - SSIM ≥0.97 (mobile), ≥0.98 (desktop)
  - Tests run on every PR touching UI
  - Failing tests block merge
- **Effort**: 2 days
- **Status**: ⏳ Pending

---

## P1: v1.0 (Weeks 5-8)

**Goal**: Multi-user, production-ready with advanced features

### Multi-User & Collaboration

**TASK-101**: Organization Management
- **Description**: Create org, invite users, assign roles
- **Dependencies**: TASK-001, TASK-005
- **Acceptance Criteria**:
  - Owner creates org → generates invite link
  - Users join org via link
  - Assign roles: Owner, Admin, Member
  - RLS policies enforce org isolation
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-102**: Real-time Collaboration
- **Description**: Presence indicators, live cursors, real-time updates
- **Dependencies**: TASK-007, TASK-101
- **Acceptance Criteria**:
  - Show who's viewing a page (avatars in header)
  - Live cursor positions for co-editors
  - Real-time updates via Supabase Realtime
  - Conflict resolution (last-write-wins)
- **Effort**: 4 days
- **Status**: ⏳ Pending

**TASK-103**: Team Management
- **Description**: Create teams, assign members, team-specific projects
- **Dependencies**: TASK-101
- **Acceptance Criteria**:
  - Create team with name + members
  - Assign projects to teams
  - Team-specific dashboards
  - RLS policies enforce team isolation
- **Effort**: 2 days
- **Status**: ⏳ Pending

### Advanced Expenses

**TASK-104**: OCR Change Detection
- **Description**: Visual + JSON diff if receipt replaced after submission
- **Dependencies**: TASK-009, TASK-003
- **Acceptance Criteria**:
  - Store original OCR payload on first extraction
  - If receipt replaced, compute SSIM + JSON diff
  - Alert if SSIM <0.95 or JSON changes detected
  - Show side-by-side comparison in UI
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-105**: Batch OCR Processing
- **Description**: Upload ZIP → process all receipts in parallel
- **Dependencies**: TASK-009, TASK-003
- **Acceptance Criteria**:
  - Upload ZIP with 50+ images
  - Queue all images for OCR processing
  - Show progress (X/Y completed)
  - Results displayed in expense list
  - Processing time: ≤5 minutes for 50 receipts
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-106**: Expense Dashboard
- **Description**: OCR metrics, confidence distribution, auto-approval rate
- **Dependencies**: TASK-009
- **Acceptance Criteria**:
  - Chart: Confidence score distribution
  - Metric: Auto-approval rate (%)
  - Metric: Average processing time
  - Metric: Error rate (<5%)
  - Filterable by date range, team, employee
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-107**: Concur Export
- **Description**: Export expenses to Concur CSV format
- **Dependencies**: TASK-009
- **Acceptance Criteria**:
  - Button: "Export to Concur"
  - CSV matches Concur field mapping
  - Include vendor, amount, date, tax, category
  - Download CSV file
- **Effort**: 2 days
- **Status**: ⏳ Pending

### Performance & Scalability

**TASK-108**: Performance Optimization
- **Description**: Code splitting, image optimization, lazy loading
- **Dependencies**: TASK-005, TASK-007, TASK-008, TASK-009
- **Acceptance Criteria**:
  - TTI <2.5s on all pages (p75)
  - Bundle size <500KB initial load
  - Images lazy-loaded and optimized
  - Code splitting by route
  - Lighthouse score ≥90 (performance)
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-109**: Database Indexing
- **Description**: Add indexes to high-traffic queries
- **Dependencies**: TASK-001
- **Acceptance Criteria**:
  - Indexes on: user_id, org_id, team_id, created_at
  - Query performance: CRUD p95 <200ms
  - EXPLAIN ANALYZE shows index usage
  - No full table scans on large tables
- **Effort**: 1 day
- **Status**: ⏳ Pending

**TASK-110**: Caching Strategy
- **Description**: Cache OCR results, user sessions, static assets
- **Dependencies**: TASK-009
- **Acceptance Criteria**:
  - OCR results cached by image hash (90-day TTL)
  - User sessions cached (Redis or Supabase)
  - Static assets cached with CDN (Vercel Edge)
  - Cache hit rate ≥70%
- **Effort**: 2 days
- **Status**: ⏳ Pending

### Monitoring & Observability

**TASK-111**: Logging & Monitoring
- **Description**: Structured logs, error tracking, performance monitoring
- **Dependencies**: TASK-002, TASK-005
- **Acceptance Criteria**:
  - Vercel Analytics for Web Vitals
  - Sentry for error tracking
  - Supabase Logs for database queries
  - Logflare for centralized logs
  - Alerts for error rate >1%, p95 >500ms
- **Effort**: 2 days
- **Status**: ⏳ Pending

**TASK-112**: Uptime Monitoring
- **Description**: Health checks for web, OCR service, database
- **Dependencies**: TASK-003, TASK-005
- **Acceptance Criteria**:
  - Cron job checks /health every 5 minutes
  - Alert if 2 consecutive failures
  - PagerDuty integration for critical alerts
  - Status page for uptime history
- **Effort**: 1 day
- **Status**: ⏳ Pending

---

## P2: v2.0 (Weeks 9-12)

**Goal**: Enterprise-scale features, advanced AI, mobile parity

### Advanced Features

**TASK-201**: GPU OCR Acceleration
- **Description**: Upgrade OCR service to GPU droplet for 10x speedup
- **Dependencies**: TASK-003
- **Acceptance Criteria**:
  - GPU droplet deployed (g-2vcpu-8gb-nvidia-tesla-t4)
  - OCR processing time: P95 <3s (vs. 30s on CPU)
  - GPU utilization ≥70%
  - Cost: $30-50/month
- **Effort**: 2 days
- **Status**: ⏳ Pending

**TASK-202**: Multi-Language OCR
- **Description**: Support Spanish, French, Japanese, Chinese receipts
- **Dependencies**: TASK-003
- **Acceptance Criteria**:
  - Detect receipt language automatically
  - Extract fields in detected language
  - Translate to English for Concur export
  - Accuracy ≥90% on non-English receipts
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-203**: AI Category Suggestions
- **Description**: AI-powered expense category suggestions based on vendor
- **Dependencies**: TASK-009
- **Acceptance Criteria**:
  - Suggest category based on vendor name
  - Learn from user corrections
  - Accuracy ≥85% after 50 expenses
  - Fallback to manual selection if confidence <70%
- **Effort**: 4 days
- **Status**: ⏳ Pending

**TASK-204**: Vendor Rate Card Matching
- **Description**: Fuzzy match vendors to rate card database
- **Dependencies**: TASK-009
- **Acceptance Criteria**:
  - Upload vendor rate card CSV
  - Fuzzy match vendor names (0.8 threshold)
  - Auto-apply rate card pricing
  - Flag expenses above rate card max
  - Dashboard for rate card compliance
- **Effort**: 4 days
- **Status**: ⏳ Pending

**TASK-205**: Advanced Analytics
- **Description**: Expense trends, spending by category, team spending comparison
- **Dependencies**: TASK-009, TASK-101
- **Acceptance Criteria**:
  - Chart: Monthly expense trends
  - Chart: Spending by category (pie chart)
  - Chart: Team spending comparison (bar chart)
  - Export charts as PNG or CSV
  - Filterable by date range, team, category
- **Effort**: 3 days
- **Status**: ⏳ Pending

### Mobile Parity

**TASK-206**: Mobile Knowledge App
- **Description**: View and edit knowledge pages on mobile
- **Dependencies**: TASK-010, TASK-007
- **Acceptance Criteria**:
  - List all knowledge pages
  - View page content (markdown rendered)
  - Edit page with mobile-optimized editor
  - Offline drafts sync when online
  - Search pages by title/content
- **Effort**: 4 days
- **Status**: ⏳ Pending

**TASK-207**: Mobile Projects App
- **Description**: View and manage projects on mobile
- **Dependencies**: TASK-010, TASK-008
- **Acceptance Criteria**:
  - List all projects
  - View project kanban board
  - Create/edit tasks
  - Drag-and-drop tasks (mobile gestures)
  - Offline task creation
- **Effort**: 4 days
- **Status**: ⏳ Pending

### Enterprise Scale

**TASK-208**: SSO Integration
- **Description**: SAML 2.0 SSO for enterprise customers
- **Dependencies**: TASK-002
- **Acceptance Criteria**:
  - Configure SAML IdP (Okta, Azure AD)
  - Users log in via SSO
  - Automatic user provisioning
  - Role mapping from IdP
- **Effort**: 5 days
- **Status**: ⏳ Pending

**TASK-209**: Audit Logs
- **Description**: Comprehensive audit trail for all user actions
- **Dependencies**: TASK-001
- **Acceptance Criteria**:
  - Log all CRUD operations (who, what, when)
  - Searchable audit log UI
  - Export audit logs to CSV
  - Retention: 1 year
- **Effort**: 3 days
- **Status**: ⏳ Pending

**TASK-210**: Advanced RLS Policies
- **Description**: Fine-grained access control (project-level, document-level)
- **Dependencies**: TASK-001, TASK-101
- **Acceptance Criteria**:
  - Document-level sharing (public, org, team, private)
  - Project-level access control
  - RLS policies enforce sharing settings
  - Zero data leaks (CI tests verify)
- **Effort**: 4 days
- **Status**: ⏳ Pending

---

## Task Effort Summary

| Milestone | Total Tasks | Total Effort | Target Completion |
|-----------|-------------|--------------|-------------------|
| P0 (MVP) | 14 tasks | ~43 days | Week 4 |
| P1 (v1.0) | 12 tasks | ~32 days | Week 8 |
| P2 (v2.0) | 10 tasks | ~40 days | Week 12 |
| **Total** | **36 tasks** | **~115 days** | **12 weeks** |

**Assumptions**:
- 2 developers working in parallel
- Each developer: 5 days/week
- Parallelizable tasks executed concurrently
- Contingency: 20% buffer for unknown unknowns

---

## References

- [Product Vision](../spec/00-product-vision.md) - User journeys and success criteria
- [Technical Architecture](../plan/architecture.md) - System design and data models
- [Deployment Standards](../plan/deployment.md) - CI/CD and deployment procedures
- [Constitution](../constitution.md) - Non-negotiable project principles
