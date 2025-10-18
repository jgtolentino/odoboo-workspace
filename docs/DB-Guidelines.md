# DB Guidelines

- Source of truth: migrations in git.
- RLS default ON. Service-role only on server routes.
- Policies pattern: owner scope, team scope, public-read for docs when needed.
- Never query service-role in the browser.
- Add covering indexes for FKs; idempotent creation.

## Migrations

- `supabase migration new <name>`
- Local test: `supabase db reset --seed`
- Staging: CI `db-staging.yml` pushes and regenerates types.
- Prod: tag `vX.Y.Z` triggers `db-prod.yml`.
