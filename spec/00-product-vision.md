# Product Vision — Odoo-Style Platform

## What Success Looks Like

Users can manage their complete business operations through an intuitive, mobile-first platform that combines the power of Odoo Enterprise with the simplicity of modern SaaS applications.

## User Journeys

### Journey 1: Knowledge Worker Managing Documentation

**As a** team member
**I want to** create, organize, and collaborate on documentation in real-time
**So that** my team stays aligned and knowledge is never lost

**Success Criteria**:
- Create pages with rich formatting in <5 seconds
- Real-time collaboration with presence indicators
- Find any document via tags/search in <2 seconds
- Access full history and restore previous versions
- Public/private sharing with granular permissions

### Journey 2: Project Manager Coordinating Work

**As a** project manager
**I want to** visualize and manage team workload across multiple projects
**So that** deadlines are met and resources are optimally allocated

**Success Criteria**:
- Create projects and tasks with drag-and-drop kanban in <10 seconds
- Assign tasks with real-time notifications
- See team availability and workload at a glance
- Track time spent on tasks automatically
- Mobile-first interface for on-the-go updates

### Journey 3: Finance Team Processing Expenses

**As a** finance administrator
**I want to** automate expense categorization and vendor rate card management
**So that** expense reports are accurate and Concur export is seamless

**Success Criteria**:
- Upload receipt → auto-extract data via OCR in <30 seconds
- Map vendors to rate cards with fuzzy matching
- Export to Concur with zero manual data entry
- Track approval workflows with audit trail
- Mobile app for employees to submit expenses instantly

### Journey 4: Organization Owner Managing Growth

**As an** organization owner
**I want to** control billing, user access, and installed apps centrally
**So that** costs are predictable and security is maintained

**Success Criteria**:
- Add/remove users with immediate RLS enforcement
- Install/uninstall apps from catalog without downtime
- View usage metrics and billing forecasts
- Enforce row-level security policies automatically
- Stripe billing integration with per-seat pricing

### Journey 5: AI Assistant Automating Workflows

**As an** AI assistant
**I want to** plan, enqueue, and execute tasks via task bus
**So that** development work is automated while remaining auditable

**Success Criteria**:
- Parse user requirements into actionable tasks
- Enqueue tasks with dependencies and priorities
- Execute frontend/backend tasks autonomously
- Provide real-time progress updates via comments
- Enable rollback if changes fail validation

## Experience Principles

### Instant Gratification

**What this means**: Every user action feels immediate and responsive

- Time to Interactive (TTI) <2.5s on /apps and project pages (p75)
- CRUD operations <200ms via PostgREST (p95)
- Real-time updates with presence indicators
- Optimistic UI updates before server confirmation

### Mobile-First Design

**What this means**: Full functionality on mobile devices without compromise

- Touch-optimized UI components (44px minimum tap targets)
- Offline-first drafts for Knowledge and Projects
- Native mobile apps (iOS/Android) via Expo
- Responsive design (mobile → tablet → desktop)

### Zero Data Loss

**What this means**: User data is protected with enterprise-grade security

- Row-Level Security (RLS) on all tables
- Zero public data leaks (blocked by CI tests)
- Complete audit trail via task bus
- 99.9% availability target (8.7 hours downtime/year)

### Transparent AI

**What this means**: AI assistance is visible, auditable, and reversible

- Task bus shows all AI-generated work
- Human review required before merging
- Full diff visibility for all changes
- One-click rollback capability

### Predictable Costs

**What this means**: No surprise bills or hidden fees

- <$20/month infrastructure target
- Per-seat Stripe subscription pricing
- Clear usage metrics and forecasting
- No vendor lock-in (portable to other providers)

## What We're NOT Building (MVP Scope)

To maintain focus and ship quickly, the MVP explicitly excludes:

- **Studio-like schema editor**: Users cannot create custom fields or tables via UI
- **Advanced accounting**: No GL, AP/AR, or financial reporting beyond expenses
- **On-premise connectors**: No SAP, Oracle, or legacy system integrations
- **Multi-language UI**: English only for MVP (i18n infrastructure deferred)
- **Custom workflows**: No visual workflow builder (hardcoded workflows only)

## Success Metrics (How We Measure)

### Performance

- **Page Load**: TTI <2.5s on /apps and /[ws]/projects (p75)
- **API Speed**: CRUD p95 <200ms via PostgREST
- **Task Bus**: >95% SLA (enqueue→claim <10s)

### Security

- **Zero Data Leaks**: RLS policy tests block deployment if failed
- **Audit Trail**: 100% coverage for all mutations
- **Uptime**: 99.9% availability (Vercel + Supabase)

### User Adoption

- **Mobile Usage**: ≥40% of sessions on mobile devices
- **Daily Active Users**: ≥70% of paid seats active daily
- **Task Completion**: ≥90% of created tasks completed within SLA

### AI Effectiveness

- **Task Success**: ≥85% of enqueued tasks complete without errors
- **Review Time**: <10 minutes median time for human review
- **Rollback Rate**: <5% of merged AI work requires rollback

## Risks and Mitigation

### Risk 1: Feature Drift vs Odoo Parity

**Mitigation**: Track via Module Matrix comparing OCA modules to our features. Block MVP if <70% parity achieved.

### Risk 2: RLS Misconfiguration Leading to Data Leaks

**Mitigation**: CI blocks merge if RLS policy tests fail. Manual security audit before production launch.

### Risk 3: AI-Generated Code Quality

**Mitigation**: Human review required for all merges. Automated linting and testing on enqueued tasks.

### Risk 4: Cost Overruns Due to Supabase/Vercel Usage

**Mitigation**: Monitor daily spend. Alert if >$1/day average. Implement caching and CDN for static assets.

## Roadmap Milestones

### P0 (MVP - Week 1-4)

- **Apps Catalog**: Browse and install OCA-inspired modules
- **Knowledge**: Pages, tags, history, real-time collaboration
- **Task Bus + Comms**: AI task queueing with human review
- **Projects**: Kanban, assignments, presence indicators
- **RLS Gates**: CI tests for row-level security

### P1 (v1.0 - Week 5-8)

- **Expenses + Rate Cards**: OCR extraction, vendor mappings, Concur export
- **Stripe Billing**: Subscription management, per-seat pricing
- **Org/Teams RLS**: Multi-tenant security with team-scoped data

### P2 (v2.0 - Week 9-12)

- **Mobile Apps**: Native iOS/Android via Expo
- **Offline Drafts**: Sync Knowledge/Projects when online
- **Performance Optimization**: Sub-1s load times, CDN integration

## References

- Technical Implementation: [/plan/architecture.md](../plan/architecture.md)
- Deployment Strategy: [/plan/deployment.md](../plan/deployment.md)
- Task Breakdown: [/tasks/01-setup-platform.md](../tasks/01-setup-platform.md)
