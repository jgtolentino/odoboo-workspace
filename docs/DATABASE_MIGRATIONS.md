# Database Migration System

**Production-safe database migration system with CI/CD integration**

---

## 📋 Overview

This project uses a custom migration runner with:
- ✅ **Transaction safety** - Auto-rollback on failure
- ✅ **Migration tracking** - State tracking with checksums
- ✅ **Idempotency** - Safe to run multiple times
- ✅ **Dry-run mode** - Test before applying
- ✅ **CI/CD integration** - GitHub Actions workflows
- ✅ **Production safety** - Multiple confirmation layers

---

## 🗂️ File Structure

```
├── scripts/
│   ├── 00_migration_state_tracking.sql  # Migration tracking system (run first)
│   ├── 01_knowledge_workspace_schema.sql
│   ├── 02_hr_expense_schema.sql
│   ├── ...
│   └── run-migrations.js                # Migration runner
├── app/api/migrations/
│   └── route.ts                         # API endpoint (non-prod only)
└── .github/workflows/
    ├── db-staging.yml                   # Staging workflow
    └── db-prod.yml                      # Production workflow
```

---

## 🚀 Quick Start

### Development (Local)

```bash
# Install dependencies
npm install

# Set DATABASE_URL
export DATABASE_URL="postgresql://user:pass@localhost:5432/dbname"

# Dry-run to test
node scripts/run-migrations.js --dry-run

# Apply migrations
node scripts/run-migrations.js
```

### Staging Deployment

```bash
# Push to staging branch
git checkout staging
git merge main
git push origin staging

# Workflow runs automatically
# View: https://github.com/your-org/your-repo/actions
```

### Production Deployment

```bash
# Create version tag
git tag v1.0.0
git push origin v1.0.0

# Workflow runs automatically with:
# 1. Dry-run first (mandatory)
# 2. 30-second review window
# 3. Actual migration
# 4. Smoke tests
# 5. GitHub release creation
```

---

## 📝 Migration File Naming

Migrations are executed in alphabetical order:

```
00_migration_state_tracking.sql  ← MUST be first
01_knowledge_workspace_schema.sql
02_hr_expense_schema.sql
03_project_workspace_schema.sql
...
```

**Rules:**
- Prefix with 2-digit number
- Use descriptive names
- Use `.sql` extension
- Place in `scripts/` directory

---

## 🔒 Migration Safety Features

### 1. Checksum Validation

Every migration file is checksummed. If a migration file is modified after being applied, the system will detect it and prevent execution.

```sql
-- Stored in schema_migrations table
{
  "version": "01",
  "checksum": "a1b2c3d4e5f6...",
  "status": "completed"
}
```

**This prevents accidental data corruption from modified migrations.**

### 2. Transaction Safety

Each migration runs in a transaction:

```javascript
await client.query('BEGIN');
try {
  // Execute migration SQL
  await client.query(sql);
  await client.query('COMMIT');
} catch (error) {
  await client.query('ROLLBACK'); // Auto-rollback on failure
  throw error;
}
```

### 3. State Tracking

Migration state is tracked in `schema_migrations` table:

```sql
CREATE TABLE schema_migrations (
  version TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  checksum TEXT NOT NULL,
  execution_time_ms INTEGER,
  status TEXT NOT NULL, -- 'pending', 'running', 'completed', 'failed'
  error_message TEXT,
  applied_by TEXT
);
```

### 4. History Audit Trail

All executions are logged in `migration_history`:

```sql
CREATE TABLE migration_history (
  id UUID PRIMARY KEY,
  version TEXT NOT NULL,
  action TEXT NOT NULL, -- 'apply', 'rollback'
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  execution_time_ms INTEGER,
  status TEXT NOT NULL, -- 'success', 'failed'
  error_message TEXT,
  executed_by TEXT,
  environment TEXT -- 'staging', 'production', 'development'
);
```

---

## 🛠️ Migration Runner CLI

### Options

```bash
# Run all pending migrations
node scripts/run-migrations.js

# Dry-run (no changes)
node scripts/run-migrations.js --dry-run

# Run specific migration
node scripts/run-migrations.js --version=01

# Verbose output
node scripts/run-migrations.js --verbose

# Combine options
node scripts/run-migrations.js --dry-run --verbose
```

### Environment Variables

```bash
# Required
DATABASE_URL="postgresql://user:pass@host:5432/dbname"

# Optional
NODE_ENV="production"              # Enables production safety checks
GITHUB_ACTOR="username"            # Recorded in migration history
CONFIRM_PRODUCTION_MIGRATION=true  # Required for production
```

---

## 🌐 API Endpoint (Non-Production)

**Endpoint:** `POST /api/migrations`

**Security:**
- Requires `INTERNAL_ADMIN_TOKEN` in `Authorization` header
- Disabled in production (`NODE_ENV=production`)
- Use CI/CD workflows for production

### Usage

```bash
# Dry-run via API
curl -X POST https://your-app.com/api/migrations \
  -H "Authorization: Bearer $INTERNAL_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": true}'

# Apply migrations
curl -X POST https://your-app.com/api/migrations \
  -H "Authorization: Bearer $INTERNAL_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dryRun": false}'

# Check status
curl -X GET https://your-app.com/api/migrations \
  -H "Authorization: Bearer $INTERNAL_ADMIN_TOKEN"
```

---

## 🔄 CI/CD Workflows

### Staging Workflow (`db-staging.yml`)

**Trigger:** Push to `staging` branch

**Steps:**
1. Validate migration files exist
2. Run dry-run first (safety check)
3. Apply migrations
4. Verify migration status
5. Rollback instructions on failure

**GitHub Secrets Required:**
- `STAGING_DATABASE_URL`

### Production Workflow (`db-prod.yml`)

**Trigger:** Push tag `v*.*.*` (e.g., `v1.0.0`)

**Steps:**
1. Validate semantic version tag
2. Check database health
3. Create backup marker
4. **MANDATORY dry-run** on production
5. 30-second review window
6. Apply migrations (with confirmation)
7. Verify migration status
8. Run smoke tests
9. Create GitHub release
10. Rollback instructions on failure

**GitHub Secrets Required:**
- `PROD_DATABASE_URL`

**Manual Trigger:**
```yaml
# Requires typing "MIGRATE-PRODUCTION" exactly
# Defaults to dry-run mode for safety
```

---

## 📊 Monitoring & Status

### Check Migration Status

```bash
# Via CLI
node -e "
const { Client } = require('pg');
(async () => {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  const result = await client.query('SELECT * FROM get_migration_status()');
  console.table(result.rows);
  await client.end();
})();
"
```

### SQL Queries

```sql
-- Get overall status
SELECT * FROM get_migration_status();

-- View all migrations
SELECT * FROM migration_status_view;

-- Get recent history
SELECT * FROM migration_history
ORDER BY executed_at DESC
LIMIT 10;

-- Find failed migrations
SELECT * FROM schema_migrations
WHERE status = 'failed';

-- Check if specific migration applied
SELECT * FROM schema_migrations
WHERE version = '01';
```

---

## 🚨 Troubleshooting

### Migration Failed in CI/CD

1. **Check workflow logs:**
   - GitHub Actions → Failed workflow → View logs

2. **Check migration history:**
   ```sql
   SELECT * FROM migration_history
   WHERE status = 'failed'
   ORDER BY executed_at DESC
   LIMIT 1;
   ```

3. **Get error details:**
   ```sql
   SELECT version, error_message, execution_time_ms
   FROM schema_migrations
   WHERE status = 'failed';
   ```

4. **Fix the issue:**
   - Review error message
   - Fix migration SQL (create new migration, don't modify existing!)
   - Test locally with dry-run
   - Commit and push

### Checksum Mismatch Error

```
Migration 01 checksum mismatch!
File has been modified after being applied. This is unsafe.
```

**Cause:** Migration file was edited after being applied.

**Solutions:**

**Option A: Create new migration (recommended)**
```bash
# Create new migration to fix the issue
cp scripts/01_knowledge_workspace_schema.sql scripts/12_fix_knowledge_schema.sql
# Edit 12_fix_knowledge_schema.sql with corrections
git add scripts/12_fix_knowledge_schema.sql
git commit -m "fix: correct knowledge schema"
```

**Option B: Force re-apply (dangerous!)**
```sql
-- ONLY in development, NEVER in production
DELETE FROM schema_migrations WHERE version = '01';
DELETE FROM migration_history WHERE version = '01';
-- Then re-run migrations
```

### Production Migration Rollback

If production migration fails:

1. **Immediate actions:**
   ```bash
   # Check Supabase dashboard for automatic backups
   # Restore from pre-migration backup
   ```

2. **Via Supabase CLI:**
   ```bash
   supabase db pull
   # Review changes
   supabase db reset --linked
   ```

3. **Via pg_dump (if you have backups):**
   ```bash
   pg_restore -d your_database backup_file.dump
   ```

4. **Investigate failure:**
   - Check migration_history for error details
   - Review failed migration SQL
   - Test fix locally
   - Create hotfix migration

---

## ✅ Best Practices

### Writing Migrations

1. **Always use transactions**
   ```sql
   BEGIN;
   -- Your changes here
   COMMIT;
   ```

2. **Make migrations idempotent**
   ```sql
   -- Good
   CREATE TABLE IF NOT EXISTS users (...);

   -- Bad
   CREATE TABLE users (...);
   ```

3. **Add indexes in separate migrations**
   ```sql
   -- 01_create_table.sql
   CREATE TABLE users (...);

   -- 02_add_indexes.sql
   CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
   ```

4. **Document complex changes**
   ```sql
   -- Migration: Add user roles system
   -- Purpose: Replace simple admin boolean with flexible role system
   -- Breaking: Removes users.is_admin column
   ```

### Testing Migrations

1. **Always test locally first:**
   ```bash
   # Local database
   node scripts/run-migrations.js --dry-run
   node scripts/run-migrations.js
   ```

2. **Test on staging before production:**
   ```bash
   git checkout staging
   git merge main
   git push origin staging
   # Wait for CI to complete
   # Verify staging works
   ```

3. **Use dry-run in production:**
   ```bash
   # Automatic in CI/CD workflows
   # Or manually:
   DATABASE_URL=$PROD_URL node scripts/run-migrations.js --dry-run
   ```

### Version Control

```bash
# Good commit message
git commit -m "feat(db): add user roles system

- Add roles table
- Add user_roles junction table
- Migrate existing is_admin to roles
- Add RLS policies

Migration: 15_user_roles_system.sql"

# Bad commit message
git commit -m "update db"
```

---

## 🔐 Security Checklist

Before deploying to production:

- [ ] All migration files in `scripts/` directory
- [ ] Migration numbering is sequential
- [ ] `00_migration_state_tracking.sql` is first
- [ ] Tested locally with dry-run
- [ ] Tested on staging
- [ ] No secrets in migration files
- [ ] `PROD_DATABASE_URL` secret is set
- [ ] Backups are enabled (Supabase: automatic)
- [ ] Reviewed changes with team
- [ ] Created semantic version tag

---

## 📚 Additional Resources

- **PostgreSQL Transactions:** https://www.postgresql.org/docs/current/tutorial-transactions.html
- **Supabase Migrations:** https://supabase.com/docs/guides/database/migrations
- **GitHub Actions:** https://docs.github.com/en/actions

---

## 🆘 Support

If you encounter issues:

1. Check `migration_history` table for error details
2. Review workflow logs in GitHub Actions
3. Test migration locally with `--dry-run --verbose`
4. Check this documentation for similar issues

**Critical issues:** Immediately restore from backup and investigate offline.

---

**Created:** 2025-10-20
**Last Updated:** 2025-10-20
**Version:** 1.0.0
