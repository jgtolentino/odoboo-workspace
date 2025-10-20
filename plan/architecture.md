# Technical Architecture

## Overview

odoboo-workspace implements an Odoo-inspired platform using modern web technologies with a focus on developer experience, AI automation, and cost efficiency.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
├──────────────────────────┬──────────────────────────────────┤
│   Web (Next.js/Vercel)   │   Mobile (Expo/React Native)     │
│   - Server Components    │   - Offline-first storage        │
│   - Route Handlers       │   - Native APIs (camera, files)  │
│   - Edge Functions       │   - Push notifications           │
└──────────────┬───────────┴──────────────┬───────────────────┘
               │                           │
               └───────────┐   ┌───────────┘
                           │   │
               ┌───────────▼───▼──────────────┐
               │   Supabase (Data Layer)      │
               ├──────────────────────────────┤
               │  - PostgreSQL (RLS-enabled)  │
               │  - PostgREST (Auto API)      │
               │  - Edge Functions (Deno)     │
               │  - Storage (S3-compatible)   │
               │  - Auth (JWT + RLS)          │
               │  - Realtime (WebSockets)     │
               └──────────────┬───────────────┘
                              │
               ┌──────────────▼───────────────┐
               │    Supporting Services        │
               ├──────────────────────────────┤
               │  - OCR Service (DigitalOcean)│
               │  - Task Bus (Supabase queue) │
               │  - AI Agents (Claude/Cline)  │
               │  - Stripe (Billing)          │
               └──────────────────────────────┘
```

## Data Architecture

### Database Design Principles

1. **Module-Based Schema Organization**
   - Each feature module (Knowledge, Projects, Expenses) has its own schema namespace
   - Shared tables (users, orgs, teams) live in `public` schema
   - Prevents cross-module coupling and enables independent evolution

2. **Row-Level Security (RLS) First**
   - Every table has RLS enabled by default
   - Policies enforce org/team-scoped access at database level
   - Service role bypasses RLS for admin operations only

3. **Audit Trail by Default**
   - All mutations logged to `work_queue` and `work_queue_comment`
   - Triggers capture created_by, updated_by, deleted_at
   - Enables full history reconstruction and compliance

### Key Schemas

**Public Schema** (Shared):
```sql
- users (id, email, role, org_id)
- orgs (id, name, stripe_customer_id)
- teams (id, org_id, name)
- app_category, app, app_install (catalog)
```

**Knowledge Schema**:
```sql
- knowledge_page (id, title, content, author_id, is_public)
- knowledge_tag (id, name)
- knowledge_page_tag (junction)
- knowledge_history (page_id, version, content, changed_by)
```

**Projects Schema**:
```sql
- project (id, name, org_id, team_id)
- task (id, project_id, title, assignee_id, status)
- task_assignment (user_id, task_id)
- kanban_column (id, project_id, name, position)
- timesheet (id, task_id, user_id, hours)
```

**Expenses Schema**:
```sql
- vendor_rate_card (id, vendor_name, org_id)
- rate_card_item (id, rate_card_id, category, unit_price)
- concur_mapping (vendor_id, concur_vendor_code)
- hr_expense (id, user_id, vendor_id, amount, receipt_url)
- export_queue (id, expense_ids[], status, concur_payload)
```

## Application Architecture

### Web Application (Next.js 14+)

**App Router Structure**:
```
app/
├── (auth)/          # Authentication routes
│   ├── login/
│   └── signup/
├── (dashboard)/     # Protected dashboard
│   ├── [workspace]/ # Workspace-scoped routes
│   │   ├── apps/    # App catalog
│   │   ├── projects/
│   │   ├── knowledge/
│   │   └── expenses/
│   └── settings/
└── api/             # Route handlers
    ├── webhooks/    # Stripe, Supabase triggers
    └── tasks/       # Task bus API
```

**Data Fetching Pattern**:
- Server Components fetch data directly from Supabase (via service role when needed)
- Client Components use `@supabase/ssr` for RLS-aware queries
- Real-time subscriptions via `supabase.channel().on('postgres_changes')`

**State Management**:
- URL state for navigation and filters (`useSearchParams`)
- React Context for user session and org context
- Zustand for UI state (modals, sidebars)
- No Redux - keep it simple

### Mobile Application (Expo + React Native)

**Architecture**:
```
mobile-app/
├── app/            # Expo Router (file-based)
│   ├── (tabs)/     # Bottom tab navigation
│   │   ├── projects.tsx
│   │   ├── knowledge.tsx
│   │   └── expenses.tsx
│   └── _layout.tsx
├── components/     # Shared UI components
├── hooks/          # Custom hooks (useSupabase, useOffline)
└── lib/
    ├── supabase.ts # Supabase client (anon key)
    └── offline.ts  # SQLite sync logic
```

**Offline-First Strategy**:
- SQLite local database via `expo-sqlite`
- Queue mutations when offline, sync when online
- Optimistic UI updates with conflict resolution
- Periodic background sync (every 15 minutes)

### OCR Microservice (FastAPI + PaddleOCR)

**Deployment**: DigitalOcean Droplet (Singapore, AMD64)

**Architecture**:
```
services/ocr-service/
├── app/
│   ├── main.py          # FastAPI app
│   ├── ocr_engine.py    # PaddleOCR-VL wrapper
│   ├── visual_diff.py   # SSIM/LPIPS comparison
│   └── audit_trail.py   # JSON diff + confidence scoring
├── Dockerfile           # Multi-stage build (2.1GB)
└── requirements.txt     # PyTorch, PaddleOCR, FastAPI
```

**API Contract**:
```
POST /v1/parse
Content-Type: multipart/form-data
Body: file (image/jpeg, image/png, application/pdf)

Response:
{
  "text": "extracted text",
  "confidence": 0.95,
  "fields": {
    "vendor": "Acme Corp",
    "amount": 142.50,
    "date": "2025-10-20"
  },
  "processing_time_ms": 2800
}
```

**Performance**:
- P95 processing time: <30 seconds
- Auto-approval threshold: confidence ≥ 0.85
- Concurrent requests: 2 workers (Uvicorn)
- Max file size: 10MB

## AI-Assisted Workflow

### Task Bus Architecture

**Components**:
1. **work_queue** table: Stores all enqueued tasks
2. **work_queue_comment** table: Real-time progress updates
3. **RPC Functions**: `route_and_enqueue()`, `claim_task()`
4. **Webhook**: Supabase → Vercel on INSERT to `work_queue`

**Task Lifecycle**:
```
1. User/Assistant creates task in work_queue
2. Supabase trigger fires webhook to Vercel
3. Vercel route handler notifies Cline (or routes to service)
4. Cline claims task, updates status to 'processing'
5. Cline executes (creates files, edits code)
6. Cline posts comments to work_queue_comment (real-time updates)
7. On completion, status → 'completed', creates PR for human review
8. Human reviews diff, approves/rejects
9. If rejected, status → 'failed', creates follow-up task
```

**Task Routes** (enum):
- `DEPLOY_WEB`: Vercel deployment
- `DEPLOY_ADE`: OCR service deployment
- `DOCS_SYNC`: Documentation updates
- `CLIENT_OP`: Frontend changes (Cline)
- `DB_OP`: Database migrations
- `RUNBOT_SYNC`: Odoo test runs
- `ODOO_BUILD`, `ODOO_INSTALL_TEST`, `ODOO_MIGRATE_MODULE`

### AI Agents

**Assistant (Claude/GPT-4)**:
- Plans multi-step tasks
- Breaks down requirements into actionable work
- Reviews diffs and validates changes
- Escalates to human when uncertain

**Cline (VS Code Extension)**:
- Executes frontend tasks from queue
- Creates/edits files autonomously
- Runs tests and linters
- Posts progress updates to task bus

## Security Architecture

### Row-Level Security (RLS) Policies

**Principle**: Every table has `created_by` and `org_id` columns

**Example Policy** (Knowledge Pages):
```sql
-- Enable RLS
ALTER TABLE knowledge_page ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read pages in their org
CREATE POLICY "org_read_pages" ON knowledge_page
  FOR SELECT USING (org_id = auth.jwt() ->> 'org_id');

-- Policy: Users can insert pages in their org
CREATE POLICY "org_insert_pages" ON knowledge_page
  FOR INSERT WITH CHECK (org_id = auth.jwt() ->> 'org_id');

-- Policy: Users can update their own pages
CREATE POLICY "user_update_own_pages" ON knowledge_page
  FOR UPDATE USING (created_by = auth.uid());
```

**CI Test**:
```typescript
// Fails CI if policy missing or misconfigured
test('RLS: users cannot read other orgs pages', async () => {
  const { data } = await supabase
    .from('knowledge_page')
    .select('*')
    .eq('org_id', 'other-org-id');

  expect(data).toEqual([]); // Must return empty
});
```

### Secrets Management

**Storage**:
- Supabase Vault for PII (credit cards, SSNs)
- Vercel Environment Variables for API keys (Stripe, OpenAI)
- Never in database or code

**Access Pattern**:
```typescript
// Correct: Use Supabase Vault
const { data } = await supabase
  .rpc('get_decrypted_secret', { secret_name: 'stripe_api_key' });

// Wrong: Never hardcode or store in DB
const apiKey = process.env.STRIPE_API_KEY; // OK for server-side only
```

## Deployment Architecture

### Infrastructure Stack

**Web Application**:
- **Platform**: Vercel (Serverless Functions, Edge Runtime)
- **Region**: Global Edge Network
- **Deployment**: Git push to `main` branch
- **Cost**: Free tier (hobby), $20/month (pro)

**Database**:
- **Platform**: Supabase PostgreSQL (AWS RDS)
- **Region**: us-east-1
- **Connection**: Pooler (port 6543) for high concurrency
- **Cost**: Free tier (500MB), $25/month (pro)

**OCR Service**:
- **Platform**: DigitalOcean Droplet
- **Specs**: 2vCPU, 4GB RAM, Singapore region
- **Deployment**: Docker Compose on droplet (AMD64 image)
- **TLS**: NGINX + Let's Encrypt (Certbot)
- **Cost**: $12/month (droplet) + $5/month (DOCR registry)

**CDN & Storage**:
- **Supabase Storage**: Receipt images, user uploads
- **Vercel CDN**: Static assets (JS, CSS, images)
- **Cost**: Included in Supabase/Vercel plans

### Deployment Pipeline

```
Developer → Git Push → GitHub Actions → Deploy

GitHub Actions:
1. Lint (ESLint, Prettier)
2. Type Check (TypeScript)
3. Test (Jest, Playwright)
4. RLS Policy Tests (Supabase)
5. Build (Next.js, Expo)
6. Deploy (Vercel, DigitalOcean)
7. Smoke Tests (Health checks)
8. Rollback if any step fails
```

**Deployment Checklist** (See [deployment.md](./deployment.md)):
- ✅ CI green (all tests pass)
- ✅ RLS policy tests pass
- ✅ Schema migrations applied (Supabase)
- ✅ Environment variables updated (Vercel)
- ✅ OCR service health check returns 200
- ✅ Visual parity tests pass (SSIM ≥0.97 mobile, ≥0.98 desktop)

## Performance Architecture

### Optimization Strategies

**1. Edge-First Rendering**:
- Next.js Server Components render at edge (Vercel Edge Runtime)
- Reduces Time to First Byte (TTFB) to <100ms
- Caches static pages with ISR (Incremental Static Regeneration)

**2. Database Query Optimization**:
- PostgREST enables direct DB access with <200ms p95
- Indexed foreign keys and frequently filtered columns
- Materialized views for complex aggregations (`app_category_counts`)

**3. Real-time Without Overhead**:
- Supabase Realtime uses WebSockets for presence and updates
- Only subscribe to specific table changes (not all)
- Automatic reconnection and backoff

**4. Mobile Performance**:
- Lazy load images with `expo-image`
- Virtual lists for long scrolling content (`@shopify/flash-list`)
- Offline-first reduces network dependency

### Monitoring

**Tools**:
- **Vercel Analytics**: Page load times, Web Vitals
- **Supabase Logs**: Query performance, error rates
- **Sentry**: Error tracking with stack traces
- **Logflare**: Centralized log aggregation

**Alerts**:
- p95 API latency >500ms → PagerDuty
- Error rate >1% → Slack #incidents
- RLS policy violations → Immediate escalation

## Scalability

### Current Limits (MVP)

- **Users**: 1,000 concurrent (Supabase free tier)
- **Requests**: 50,000/day (Vercel hobby)
- **Database**: 500MB storage (Supabase free tier)
- **OCR**: 2 concurrent requests (Uvicorn workers)

### Growth Path

**Phase 1** (100 users):
- No changes needed, stay on free tiers

**Phase 2** (1,000 users):
- Upgrade Supabase to Pro ($25/month, 8GB storage)
- Upgrade Vercel to Pro ($20/month, 100,000 requests)
- Scale OCR service to 4vCPU/8GB droplet ($24/month)

**Phase 3** (10,000 users):
- Add Supabase read replicas for reporting queries
- Enable Vercel Edge Middleware for auth caching
- Horizontal scale OCR service (load balancer + 3 droplets)
- Implement CDN for user uploads (DigitalOcean Spaces)

## References

- Product Vision: [/spec/00-product-vision.md](../spec/00-product-vision.md)
- Tech Stack Details: [/plan/stack.md](./stack.md)
- Deployment Guide: [/plan/deployment.md](./deployment.md)
