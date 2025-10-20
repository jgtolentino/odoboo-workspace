# odoboo-workspace Constitution

## Purpose

This constitution establishes the non-negotiable principles that govern the odoboo-workspace project - an Odoo Enterprise-class platform built on modern open-source infrastructure.

## Core Principles

### 1. User Privacy and Security First

**Non-Negotiable**: User data must be protected with enterprise-grade security.

- Row-Level Security (RLS) enabled on all public tables
- Zero tolerance for data leaks - block deployment if RLS tests fail
- Service-role keys restricted to admin/edge paths only
- PII and secrets stored in vault, never in code or environment variables
- 99.9% availability target (Vercel + Supabase managed infrastructure)

### 2. Open Source Foundation

**Non-Negotiable**: Build on open-source tools and contribute back to the community.

- OCA (Odoo Community Association) modules as reference implementation
- Native Odoo concepts for IA/UX patterns
- Open-source deployment scripts and documentation
- Transparent architecture and decision-making

### 3. Evidence-Based Development

**Non-Negotiable**: All architectural decisions must be backed by measurable criteria.

- Performance: TTI < 2.5s (p75), CRUD < 200ms (p95)
- Reliability: >95% task queue SLA (enqueue→claim < 10s)
- Quality: Error budget 1%, observability via Logflare + app logs
- Validation: CI must pass before merge, including RLS policy tests

### 4. AI-Assisted Workflow

**Non-Negotiable**: Leverage AI for productivity while maintaining human oversight.

- AI agents (Assistant, Cline) plan and execute tasks via task bus
- Human review required for all AI-generated code changes
- Task bus provides auditability and rollback capability
- Specifications drive implementation, not the reverse

### 5. Deployment Simplicity

**Non-Negotiable**: Production deployment must be reproducible and automated.

- Infrastructure as Code for all deployments
- DigitalOcean + Supabase primary stack
- Automated TLS, firewall, and security hardening
- Immutable image tags (`:sha-<gitsha>`) for rollback capability
- One-command deployment scripts

### 6. Mobile-First Experience

**Non-Negotiable**: All features must work seamlessly on mobile devices.

- Responsive design (mobile, tablet, desktop)
- Expo mobile app for iOS/Android
- Offline-first drafts for Knowledge and Projects
- Touch-optimized UI components

### 7. Modular Architecture

**Non-Negotiable**: Features must be composable and independently deployable.

- Apps Catalog for browsing and installing modules
- Clean separation between modules (Knowledge, Projects, Expenses)
- Database schema organized by module
- API-first design for inter-module communication

### 8. Financial Sustainability

**Non-Negotiable**: Project must be cost-effective to operate.

- <$20/month infrastructure cost target
- Stripe subscription model for revenue
- Seat-based pricing aligned with usage
- No vendor lock-in - portability across providers

### 9. Observability by Default

**Non-Negotiable**: All system behavior must be transparent and debuggable.

- Comprehensive logging (app logs, DB logs, build logs)
- Error tracking with actionable context
- Performance monitoring with p50/p95/p99 metrics
- Task bus provides complete audit trail

### 10. Documentation as Specification

**Non-Negotiable**: Documentation must be executable - specifications drive code, not the reverse.

- Spec-Kit compliance: Specify → Plan → Tasks workflow
- User journey focused specifications
- Technical plans separate from user specifications
- Task breakdowns with clear acceptance criteria
- No implementation without specification

## Enforcement

These principles are enforced through:

- **CI/CD Pipeline**: Automated tests for RLS, performance, security
- **Code Review**: Human review required for all changes
- **Deployment Gates**: Production blocked if quality gates fail
- **Constitution Updates**: Require project-wide consensus

## Version

**v1.0** - Initial constitution (2025-10-20)

## References

- Product Requirements: [spec/00-product-vision.md](spec/00-product-vision.md)
- Technical Architecture: [plan/architecture.md](plan/architecture.md)
- Deployment Standards: [plan/deployment.md](plan/deployment.md)
