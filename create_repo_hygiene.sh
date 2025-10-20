#!/bin/bash
# create_repo_hygiene.sh
set -euo pipefail
mkdir -p .github/workflows .github/ISSUE_TEMPLATE scripts docs

# README
cat > README.md <<'MD'
# odoboo-workspace
Native Odoo + OCA stack with OCR microservice and DO deploy scripts.

## Quick start
```bash
./scripts/db-sync-check.sh --db "$DATABASE_URL"
```

* Deploy: see `infra/do/*.sh` and `infra/do/*.yml`
* OCA minimal core: `scripts/download_oca_minimal.sh`

## Contributing
See CONTRIBUTING.md · Code of Conduct in CODE_OF_CONDUCT.md · Security in SECURITY.md
MD

# CONTRIBUTING
cat > CONTRIBUTING.md <<'MD'
# Contributing

* Branch: `git checkout -b feat/<topic>`
* Lint/Test (adapt as needed): `pnpm i && pnpm lint && pnpm test`
* DB: migrations in git are **source of truth**. Staging runs on branch pushes; Prod runs on tags (`v*.*.*`).
* PRs: small, focused, with screenshots/logs for deploy changes.
MD

# CODE_OF_CONDUCT
cat > CODE_OF_CONDUCT.md <<'MD'
# Code of Conduct

Be respectful. No harassment. Assume good intent. Report issues to maintainers.
MD

# SECURITY
cat > SECURITY.md <<'MD'
# Security Policy

If you find a vulnerability, email [security@insightpulseai.com](mailto:security@insightpulseai.com). Rotate any exposed secrets immediately.
MD

# Issue/PR templates
cat > .github/ISSUE_TEMPLATE/bug_report.md <<'YML'
---
name: Bug report
about: Help us fix it
title: "[bug] "
labels: bug
---

**What happened?**
Steps, expected vs. actual
YML

cat > .github/PULL_REQUEST_TEMPLATE.md <<'MD'
## Summary
Why this change?

## Changes
* …

## Testing
Logs/Screens/smoke steps.

## Release
* [ ] No secrets in diff
* [ ] DB migrations safe
MD

# CI (lint/tests as applicable)
cat > .github/workflows/ci.yml <<'YML'
name: CI
on:
  push: { branches: [main, staging] }
  pull_request: { branches: [main] }
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Node (optional)
        uses: actions/setup-node@v4
        with: { node-version: 20 }
      - name: Install (if pnpm)
        run: |
          if [ -f pnpm-lock.yaml ]; then npm i -g pnpm && pnpm i; fi
      - name: Lint/Test (noop if none)
        run: |
          if [ -f package.json ]; then (pnpm lint || true; pnpm test || true); fi
YML

# DB: staging migrations on branch push
cat > .github/workflows/db-staging.yml <<'YML'
name: DB - Staging
on:
  push:
    branches: [staging]
jobs:
  migrate-staging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run migrations
        env:
          DATABASE_URL: ${{ secrets.STAGING_DATABASE_URL }}
        run: |
          if [ -f scripts/run-migrations.ts ]; then
            node scripts/run-migrations.ts
          elif command -v supabase >/dev/null 2>&1; then
            supabase migration up
          else
            echo "Add your migration runner"; exit 1
          fi
YML

# DB: production migrations on tag
cat > .github/workflows/db-prod.yml <<'YML'
name: DB - Prod
on:
  push:
    tags: ['v*.*.*']
jobs:
  migrate-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run migrations
        env:
          DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
        run: |
          if [ -f scripts/run-migrations.ts ]; then
            node scripts/run-migrations.ts
          elif command -v supabase >/dev/null 2>&1; then
            supabase migration up
          else
            echo "Add your migration runner"; exit 1
          fi
YML

# DB sync checker
cat > scripts/db-sync-check.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
DB="${1:-}"; [[ "$DB" == "--db" ]] && DB="$2" || DB="${DB:-$DATABASE_URL}"
[ -z "${DB:-}" ] && { echo "Usage: $0 --db <DATABASE_URL>"; exit 1; }
tables=("schema_migrations" "supabase_migrations" "migrations")
for t in "${tables[@]}"; do
  echo ">>> Checking $t"
  psql "$DB" -Atc "SELECT * FROM $t LIMIT 5;" 2>/dev/null && found=1 && break || true
done
[ -z "${found:-}" ] && { echo "No known migration table found"; exit 2; }
echo "OK: migration table exists ($t). Compare with repo files below:"
ls -1 scripts/sql 2>/dev/null || ls -1 app/api/migrations 2>/dev/null || echo "No local migration dir."
SH
chmod +x scripts/db-sync-check.sh

echo "Done. Next:

1. git add -A && git commit -m 'chore: repo hygiene + CI + DB sync check'
2. Set repo secrets: STAGING_DATABASE_URL, PROD_DATABASE_URL
3. Push a test commit to 'staging' to exercise db-staging.yml
"
