# Product Requirements Document — Odoo-Style Platform (Vercel + Supabase)

## Objective

Deliver Odoo Enterprise-class capabilities using:

- OCA/Odoo concepts for IA/UX.
- Next.js (Web), Expo (Mobile), Supabase (DB/Auth/Storage/Functions), Vercel (hosting).
- AI-assisted development via Assistant + Cline + Task Bus.

## Users & Roles

- **Owner**: billing, plans, org settings.
- **Admin**: workspaces, apps, users, policies.
- **Member**: uses apps (knowledge, projects, expenses).
- **Vendor**: limited access to rate cards/docs.
- **Assistant**: plans, enqueues tasks, reviews diffs.
- **Cline**: executes frontend tasks from queue.

## In Scope (MVP → v1)

1. **Apps Catalog**: browse/install modules.
2. **Knowledge**: pages, tags, history, public/private, realtime comments.
3. **Projects**: projects, tasks, kanban, assignments, presence.
4. **Expenses & Vendors**: rate cards, mappings, export queue (Concur-ready).
5. **Comms Hub**: task bus + comments thread, DB→Vercel webhook.
6. **Auth & RLS**: row-level security across modules.
7. **Billing (v1)**: Stripe subscriptions, seat limits.

## Out of Scope (MVP)

- Studio-like schema editor, advanced accounting, on-prem connectors.

## Success Metrics

- TTI < 2.5s on /apps and /[ws]/projects (p75).
- CRUD p95 < 200ms via PostgREST.
- > 95% task queue SLA (enqueue→claim < 10s).
- Zero public data leaks under RLS tests.

## Data Model (Supabase)

- Catalog: `app_category`, `app`, `app_install`, view `app_category_counts`.
- Knowledge: `knowledge_*` (page, tag, history, junctions).
- Projects: `project`, `task`, `task_assignment`, `kanban_column`, `timesheet` (added by migration).
- Expenses: `vendor_rate_card`, `rate_card_item`, `concur_mapping`, `hr_expense`, `export_queue*`.
- Comms/AI: `work_queue`, `work_queue_comment`, RPC `claim_task`, webhook trigger to Vercel.

## Security

- RLS enabled on all public tables (owners/team-scope).
- Service-role only for admin/edge paths.
- Vault for any PII/keys when introduced.

## Non-Functional

- Availability: 99.9% target (Vercel + Supabase managed).
- Observability: Logflare drain + app logs; error budget 1%.

## Milestones

- **P0**: Catalog, Knowledge, Task Bus + Comms, Projects (kanban), RLS gates.
- **P1**: Expenses + Rate Cards, Stripe billing, org/teams RLS.
- **P2**: Mobile app read/write for Knowledge/Projects, offline drafts.

## Risks

- Feature drift vs Odoo parity → track via Module Matrix.
- RLS misconfig → block on policy tests in CI.
