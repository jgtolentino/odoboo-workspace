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
