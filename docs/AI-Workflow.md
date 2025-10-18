# AI-Assisted Development Workflow

## Task Bus

- Assistant enqueues work → `work_queue(PENDING)`.
- Cline claims via RPC `claim_task(worker)`.
- Cline posts progress to `work_queue_comment`.
- Completion sets `DONE` with result JSON.

## Prompt Contract (stored in prompt_json)

```json
{
  "goal": "...",
  "acceptance": ["..."],
  "files": ["..."],
  "guards": ["..."],
  "verify": ["..."]
}
```

## Roles

- **Assistant**: author PRDs, migrations, policies, specs, enqueues tasks.
- **Cline**: implements frontend-only tasks per contract.
- **Senior Backend**: migrations, RLS, Edge Functions, Stripe.
- **Senior Web**: Next.js pages, components, tests, perf.
- **Senior Mobile**: Expo screens, offline drafts, sync.

## Done Criteria

- Acceptance met.
- RLS tests pass.
- `pnpm build`, `pnpm test`, `pnpm lint` clean.
- Types regenerated when schema changes.
