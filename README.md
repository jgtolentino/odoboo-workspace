# odoboo-workspace

**Odoo Enterprise-class platform** built on modern open-source infrastructure with AI-assisted workflows, mobile-first design, and automated expense processing.

## What We're Building

- **Apps Catalog** - Browse and install modular business apps (Knowledge, Projects, Expenses)
- **Real-time Collaboration** - Notion-style docs with presence indicators and live updates
- **Mobile-First** - Native iOS/Android apps with offline-first drafts
- **AI-Assisted Workflows** - Task bus orchestration with Claude/GPT-4 integration
- **OCR Expense Processing** - 95%+ accuracy receipt extraction with auto-approval (≥85%)

**Success Metrics**: TTI <2.5s (p75) | CRUD p95 <200ms | >95% task queue SLA | 99.9% uptime

## Documentation Structure

Following [GitHub Spec-Kit](https://github.com/github/spec-kit) framework:

### 📋 [Specifications](./spec/) (User Journeys)
- [**Product Vision**](./spec/00-product-vision.md) - User journeys, experience principles, success metrics
- [**Constitution**](./constitution.md) - Non-negotiable project principles

### 🏗️ [Technical Plans](./plan/) (Architecture & Implementation)
- [**Architecture**](./plan/architecture.md) - System design, data models, security architecture
- [**Technology Stack**](./plan/stack.md) - Technology choices and rationale (Next.js, Supabase, Expo, PaddleOCR)
- [**Deployment Standards**](./plan/deployment.md) - CI/CD pipeline, rollback procedures, monitoring

### ✅ [Tasks](./tasks/) (Work Breakdown)
- Implementation tasks organized by milestone (P0, P1, P2)

## Quick Start

### Prerequisites
- Node.js 18+, npm 9+
- Docker (for local OCR service testing)
- Supabase CLI (optional, for local database)

### Development Setup
```bash
# Install dependencies
npm install

# Setup environment variables
cp .env.example .env.local
# Edit .env.local with your Supabase credentials

# Start development server
npm run dev

# Run tests
npm test

# Database sync check
./scripts/db-sync-check.sh --db "$DATABASE_URL"
```

### Deployment
- **Web Frontend**: Push to `main` → Vercel auto-deploys
- **OCR Service**: `./infra/do/DEPLOY_WITH_TLS.sh` (DigitalOcean)
- **Database**: `psql "$POSTGRES_URL" -f packages/db/sql/*.sql`

See [Deployment Standards](./plan/deployment.md) for detailed procedures.

## Technology Stack

- **Frontend**: Next.js 14+ (App Router), React 18, Tailwind CSS v4
- **Mobile**: Expo 49+ (React Native), offline-first with SQLite
- **Backend**: Supabase (PostgreSQL + PostgREST + Edge Functions)
- **OCR**: PaddleOCR-VL-900M + FastAPI (DigitalOcean droplet)
- **Deployment**: Vercel (web), DigitalOcean (OCR), GitHub Actions (CI/CD)
- **Cost**: <$20/month infrastructure (87% reduction from $100 Azure budget)

See [Technology Stack](./plan/stack.md) for detailed rationale.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines.

**Code of Conduct**: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
**Security Policy**: [SECURITY.md](./SECURITY.md)

## Project Principles

1. **User Privacy and Security First** - RLS enabled on all tables, zero data leaks
2. **Open Source Foundation** - OCA modules as reference implementation
3. **Evidence-Based Development** - Performance metrics, quality gates, validation
4. **AI-Assisted Workflow** - Task bus with human review for all AI changes
5. **Deployment Simplicity** - Infrastructure as Code, immutable image tags
6. **Mobile-First Experience** - Responsive design, offline-first capabilities
7. **Modular Architecture** - Apps Catalog, clean module separation
8. **Financial Sustainability** - <$20/month cost target
9. **Observability by Default** - Comprehensive logging and monitoring
10. **Documentation as Specification** - Spec-Kit compliance (Specify → Plan → Tasks)

See [Constitution](./constitution.md) for full principles.

## License

[MIT](./LICENSE) (or specify your license)
