# Technology Stack

## Overview

odoboo-workspace technology choices prioritize open-source foundations, cost efficiency, and developer productivity. This document explains **why** we chose each technology and **why we rejected** common alternatives.

## Frontend Stack

### Web Application: Next.js 14+

**Choice**: Next.js App Router with React Server Components

**Why Next.js**:
- **Server Components**: Reduce client bundle size by 40-60%, improve TTI
- **Edge Runtime**: Deploy serverless functions globally, <100ms TTFB
- **Zero Config**: TypeScript, fast refresh, image optimization out-of-the-box
- **Vercel Integration**: Seamless deployment with preview URLs and analytics
- **Ecosystem**: Largest React framework community, extensive plugin ecosystem

**Why NOT Alternatives**:
- ❌ **Remix**: Smaller ecosystem, less mature edge runtime support
- ❌ **SvelteKit**: Learning curve for React developers, smaller talent pool
- ❌ **Nuxt**: Vue.js lock-in, we prefer React ecosystem alignment
- ❌ **Create React App**: Deprecated, no SSR/SSG, poor performance

**Constraints**:
- Next.js 14.0.0+ (App Router required)
- React 18+ (Server Components dependency)
- Node.js 18+ (edge runtime compatibility)

### Mobile Application: Expo + React Native

**Choice**: Expo managed workflow with EAS Build

**Why Expo**:
- **Code Sharing**: 95% shared codebase between iOS, Android, and web
- **OTA Updates**: Deploy fixes without app store review (critical for MVP iteration)
- **Native Modules**: Access camera, file system, offline storage via expo-modules
- **EAS Build**: Cloud build service, no need for Mac/Xcode for development
- **Developer Experience**: Fast refresh, TypeScript support, excellent debugging

**Why NOT Alternatives**:
- ❌ **Flutter**: Dart language, no web support parity, smaller ecosystem
- ❌ **Ionic**: WebView performance, not truly native
- ❌ **Native iOS/Android**: 2x development cost, no code sharing
- ❌ **React Native CLI**: Complex native build setup, slower iteration

**Constraints**:
- Expo SDK 49+ (React Native 0.72+)
- React Native 0.72+ (performance improvements)
- expo-sqlite for offline-first storage
- @shopify/flash-list for high-performance lists

### UI Framework: Tailwind CSS v4

**Choice**: Tailwind CSS with utility-first design system

**Why Tailwind**:
- **Utility-First**: Faster development, no CSS naming debates
- **Purge**: Removes unused styles, <10KB final CSS
- **Customization**: Design tokens via tailwind.config.js
- **Mobile-First**: Responsive design by default
- **TypeScript Integration**: Type-safe theme values

**Why NOT Alternatives**:
- ❌ **CSS Modules**: More boilerplate, slower iteration
- ❌ **Styled Components**: Runtime overhead, larger bundle size
- ❌ **Material UI**: Opinionated design, hard to customize, large bundle
- ❌ **Chakra UI**: Good but heavier than Tailwind for our use case

**Constraints**:
- Tailwind CSS v4.0+ (performance improvements)
- PostCSS 8+ (build tool requirement)

## Backend Stack

### Database: Supabase (PostgreSQL + PostgREST)

**Choice**: Supabase managed PostgreSQL with auto-generated REST API

**Why Supabase**:
- **PostgreSQL**: Battle-tested RDBMS, ACID compliance, advanced features
- **Auto REST API**: PostgREST generates API from schema, zero backend code
- **Row-Level Security (RLS)**: Database-enforced authorization, zero trust architecture
- **Real-time**: WebSocket subscriptions for live updates
- **Edge Functions**: Deno runtime for serverless API routes
- **Storage**: S3-compatible object storage with RLS integration
- **Cost**: Free tier (500MB), $25/month pro tier vs. $100+ AWS equivalent

**Why NOT Alternatives**:
- ❌ **Firebase**: NoSQL lock-in, expensive at scale, vendor lock-in
- ❌ **AWS Amplify**: Complex setup, costly, poor DX compared to Supabase
- ❌ **PlanetScale**: MySQL (we need PostgreSQL features), limited free tier
- ❌ **Hasura**: Requires separate PostgreSQL, more moving parts
- ❌ **Raw PostgreSQL + Express**: 10x more code to write and maintain

**Constraints**:
- PostgreSQL 15+ (improved performance, better JSON support)
- PostgREST 11+ (Supabase compatibility)
- Connection pooler (port 6543) for high concurrency (>100 connections)

### Authentication: Supabase Auth

**Choice**: Supabase Auth with JWT + RLS integration

**Why Supabase Auth**:
- **Zero Backend Code**: Built-in providers (email, OAuth)
- **JWT Integration**: Tokens contain org_id, user_id for RLS policies
- **Session Management**: Automatic refresh, secure cookie storage
- **Multi-Factor Auth**: Optional 2FA for enterprise security
- **Cost**: Included in Supabase tier, no separate auth service

**Why NOT Alternatives**:
- ❌ **Auth0**: $25/month minimum, 7,000 active users limit
- ❌ **Clerk**: $25/month minimum, overkill for MVP
- ❌ **NextAuth**: DIY approach, more code to maintain
- ❌ **Firebase Auth**: Vendor lock-in, costly at scale

**Constraints**:
- @supabase/auth-helpers-nextjs for Next.js integration
- @supabase/auth-helpers-react-native for mobile

### API Layer: PostgREST + Supabase Edge Functions

**Choice**: Hybrid approach - PostgREST for CRUD, Edge Functions for custom logic

**Why Hybrid**:
- **PostgREST**: Auto-generated REST API, <200ms p95 latency, zero maintenance
- **Edge Functions**: Deno runtime, TypeScript, global deployment, custom business logic
- **Cost**: PostgREST included, Edge Functions free tier (500K requests/month)
- **Developer Experience**: No backend framework boilerplate

**Why NOT Alternatives**:
- ❌ **Express.js**: 5-10x more code, requires hosting, slower iteration
- ❌ **NestJS**: Overkill for MVP, steep learning curve
- ❌ **tRPC**: Good but requires separate backend, more setup
- ❌ **GraphQL**: Overcomplicated for CRUD, slower query performance

**Constraints**:
- Deno 1.37+ (Edge Functions runtime)
- TypeScript 5+ (type safety)

## Infrastructure Stack

### Deployment: Vercel + DigitalOcean

**Choice**: Vercel for web frontend, DigitalOcean for microservices

**Why Vercel**:
- **Zero Config**: Git push → deploy, automatic preview URLs
- **Edge Network**: Global CDN, <100ms TTFB worldwide
- **Serverless Functions**: Auto-scaling, pay-per-use
- **Cost**: Free tier (hobby), $20/month pro tier
- **Analytics**: Built-in Web Vitals monitoring

**Why DigitalOcean**:
- **Droplets**: Predictable pricing, full control, $12/month for OCR service
- **Container Registry**: Free registry, private Docker images
- **Simplicity**: No AWS complexity, straightforward networking
- **Cost**: $17/month total (droplet + registry + spaces)

**Why NOT Alternatives**:
- ❌ **AWS**: Overcomplicated, expensive, steep learning curve
- ❌ **Azure**: Vendor lock-in, costly, poor DX
- ❌ **Netlify**: Good for static sites, limited backend capabilities
- ❌ **Railway/Render**: Less mature, uncertain long-term pricing

**Constraints**:
- Node.js 18+ (Vercel Edge Runtime)
- Docker 24+ (DigitalOcean image compatibility)

### CI/CD: GitHub Actions

**Choice**: GitHub Actions for all automation

**Why GitHub Actions**:
- **Native Integration**: Same platform as git repository
- **Free Tier**: 2,000 minutes/month for private repos
- **Marketplace**: Extensive action library (Vercel, Supabase, DigitalOcean)
- **Matrix Builds**: Test multiple Node versions in parallel
- **Secrets Management**: Secure environment variables

**Why NOT Alternatives**:
- ❌ **CircleCI**: Separate platform, more complex setup
- ❌ **GitLab CI**: Would require migrating from GitHub
- ❌ **Jenkins**: Self-hosted overhead, complex configuration
- ❌ **Vercel CI**: Limited to build/deploy, no custom workflows

**Constraints**:
- GitHub Actions v3+ (workflow syntax)
- Node.js 18+ (test environment)

### Monitoring: Vercel Analytics + Supabase Logs + Sentry

**Choice**: Multi-tool observability stack

**Why This Stack**:
- **Vercel Analytics**: Web Vitals, page performance, free with deployment
- **Supabase Logs**: Database query performance, error rates, included in tier
- **Sentry**: Error tracking with stack traces, 5K events/month free
- **Logflare**: Centralized log aggregation, Supabase integration

**Why NOT Alternatives**:
- ❌ **Datadog**: $15/host/month minimum, overkill for MVP
- ❌ **New Relic**: Complex pricing, steep learning curve
- ❌ **Grafana + Prometheus**: Self-hosted overhead, complex setup

**Constraints**:
- @vercel/analytics for Web Vitals collection
- @sentry/nextjs for error tracking
- Sentry 7+ (performance monitoring)

## OCR Microservice Stack

### OCR Engine: PaddleOCR-VL

**Choice**: PaddleOCR-VL-900M model

**Why PaddleOCR-VL**:
- **Accuracy**: 95%+ confidence on receipts, invoices, documents
- **Multilingual**: English, Chinese, Japanese, Korean, European languages
- **Open Source**: Apache 2.0 license, no vendor lock-in
- **Cost**: Free (self-hosted), vs. $1,000-$4,000/month for Azure Document Intelligence
- **Performance**: P95 <30 seconds on DigitalOcean 2vCPU/4GB
- **Structured Output**: JSON extraction with confidence scores

**Why NOT Alternatives**:
- ❌ **Azure Document Intelligence**: $1-4/page, vendor lock-in, overkill cost
- ❌ **Google Cloud Vision**: $1.50/1K images, adds up quickly
- ❌ **AWS Textract**: $1.50/page for tables, expensive at scale
- ❌ **Tesseract**: Lower accuracy (70-80%), no structured output
- ❌ **EasyOCR**: Slower than PaddleOCR, less accurate on receipts

**Constraints**:
- Python 3.10+ (PaddleOCR dependency)
- PyTorch 2.0+ (model runtime)
- CUDA 11.8+ (GPU acceleration, optional)

### OCR API: FastAPI

**Choice**: FastAPI for OCR microservice REST API

**Why FastAPI**:
- **Performance**: Async I/O, 2-3x faster than Flask
- **Type Safety**: Pydantic validation, automatic OpenAPI docs
- **Developer Experience**: Auto-generated Swagger UI, easy testing
- **Python Ecosystem**: Native integration with PaddleOCR, PyTorch
- **Deployment**: Simple Docker containerization

**Why NOT Alternatives**:
- ❌ **Flask**: Synchronous, slower, no native async support
- ❌ **Django**: Overkill for single-purpose microservice
- ❌ **Express.js**: Would require Python ↔ Node.js bridge for PaddleOCR

**Constraints**:
- FastAPI 0.104+ (latest features)
- Uvicorn 0.24+ (ASGI server)
- Pydantic 2.0+ (validation)

## Development Tools

### Package Manager: npm

**Choice**: npm (default Node.js package manager)

**Why npm**:
- **Default**: Comes with Node.js, zero setup
- **Workspaces**: Monorepo support for packages/db, packages/ui
- **Lock File**: package-lock.json for reproducible builds
- **Registry**: Largest JavaScript package ecosystem

**Why NOT Alternatives**:
- ❌ **Yarn**: Extra dependency, marginal benefits
- ❌ **pnpm**: Good but adds complexity for team onboarding
- ❌ **Bun**: Too new, ecosystem compatibility issues

**Constraints**:
- npm 9+ (workspaces support)
- Node.js 18+ (npm compatibility)

### Code Quality: ESLint + Prettier + TypeScript

**Choice**: Standard linting and formatting stack

**Why This Stack**:
- **ESLint**: Catches bugs, enforces conventions, Next.js preset
- **Prettier**: Consistent formatting, zero config debates
- **TypeScript**: Type safety, catches 60% of bugs before runtime
- **Husky**: Pre-commit hooks, prevents bad commits

**Why NOT Alternatives**:
- ❌ **JSHint/JSLint**: Older, less powerful than ESLint
- ❌ **StandardJS**: Opinionated, no semicolons (team preference)
- ❌ **Biome**: Too new, ecosystem not mature

**Constraints**:
- TypeScript 5+ (latest features)
- ESLint 8+ (Next.js compatibility)
- Prettier 3+ (performance improvements)

### Testing: Jest + Playwright

**Choice**: Jest for unit/integration, Playwright for E2E

**Why Jest**:
- **Speed**: Parallel test execution, watch mode
- **Snapshot Testing**: Component regression testing
- **Coverage**: Built-in code coverage reports
- **React Integration**: @testing-library/react compatibility

**Why Playwright**:
- **Multi-Browser**: Chrome, Firefox, Safari with one API
- **Reliability**: Auto-wait, no flaky tests
- **Debugging**: Time-travel debugging, screenshot/video capture
- **Mobile Testing**: Device emulation, touch gestures

**Why NOT Alternatives**:
- ❌ **Mocha/Chai**: More boilerplate, slower than Jest
- ❌ **Cypress**: Slower than Playwright, single-browser focus
- ❌ **Puppeteer**: Chrome-only, less reliable than Playwright
- ❌ **Selenium**: Slow, flaky, outdated architecture

**Constraints**:
- Jest 29+ (latest performance improvements)
- Playwright 1.40+ (latest features)
- @testing-library/react 14+ (React 18 support)

## Version Constraints Summary

```json
{
  "engines": {
    "node": ">=18.17.0",
    "npm": ">=9.0.0"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "tailwindcss": "^4.0.0",
    "@supabase/supabase-js": "^2.38.0",
    "expo": "^49.0.0"
  },
  "devDependencies": {
    "typescript": "^5.2.0",
    "eslint": "^8.51.0",
    "prettier": "^3.0.0",
    "jest": "^29.7.0",
    "playwright": "^1.40.0"
  }
}
```

## References

- Product Vision: [/spec/00-product-vision.md](../spec/00-product-vision.md)
- Technical Architecture: [/plan/architecture.md](./architecture.md)
- Constitution: [/constitution.md](../constitution.md)
