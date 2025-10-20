# 🔄 Database Migration Rollback Playbook

**Purpose**: Emergency procedures for rolling back failed or problematic database migrations.

**Scope**: Next.js/Supabase database ONLY (NOT Odoo database)

**Last Updated**: 2025-10-20

---

## 🚨 When to Rollback

Execute rollback procedures when:

- ✅ Migration caused data corruption or loss
- ✅ Application is broken after migration
- ✅ Migration took longer than expected and caused downtime
- ✅ Migration applied to wrong database
- ✅ Critical bug discovered in migration SQL

**DO NOT rollback if**:
- ❌ Migration completed successfully but app has unrelated bug
- ❌ Migration is still in progress (wait for timeout or failure)
- ❌ Minor performance issues (investigate first)

---

## 🔍 Pre-Rollback Checklist

Before executing rollback, verify:

1. **Confirm migration status**:
```bash
# Check current migration state
DATABASE_URL="$PROD_DATABASE_URL" node scripts/run-migrations.js --status

# Or query directly:
psql "$PROD_DATABASE_URL" -c "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 10;"
```

2. **Identify target version**:
```bash
# List all migrations
psql "$PROD_DATABASE_URL" -c "SELECT version, name, status, applied_at FROM schema_migrations ORDER BY version DESC;"

# Find the last known-good version (before the problem)
```

3. **Verify backup exists**:
```bash
# Check if pre-deployment snapshot exists (DigitalOcean)
doctl compute snapshot list

# Or verify Supabase automatic backup
# Supabase: Dashboard → Database → Backups
```

4. **Stop application traffic** (if possible):
```bash
# Prevent new data from being written during rollback
# Option A: Enable maintenance mode
# Option B: Scale down application replicas
# Option C: Redirect traffic to staging
```

---

## 🛠️ Rollback Methods

### Method 1: Automated Rollback (Recommended)

**Best for**: Single migration rollback, transaction-safe migrations

```bash
# Dry-run first (simulates rollback)
DATABASE_URL="$PROD_DATABASE_URL" \
  node scripts/run-migrations.js \
  --rollback \
  --to 2025_10_20_120001 \
  --dry-run \
  --verbose

# If dry-run looks good, execute rollback
DATABASE_URL="$PROD_DATABASE_URL" \
  node scripts/run-migrations.js \
  --rollback \
  --to 2025_10_20_120001 \
  --verbose
```

**What this does**:
1. Validates target version exists and was previously applied
2. Checks if rollback script exists (`down.sql` or `rollback.sql`)
3. Executes rollback SQL in a transaction
4. Updates `schema_migrations` table
5. Logs rollback in `migration_history` table

**Limitations**:
- Only works if migration has a rollback script
- May not reverse all data changes (e.g., deleted rows)

---

### Method 2: Manual SQL Rollback

**Best for**: Custom rollback logic, data recovery

```bash
# 1. Connect to database
psql "$PROD_DATABASE_URL"

# 2. Begin transaction (safety!)
BEGIN;

# 3. Execute reverse operations manually
-- Example: Drop table that was created
DROP TABLE IF EXISTS new_feature_table;

-- Example: Restore old column
ALTER TABLE users DROP COLUMN new_field;

-- Example: Revert data changes
UPDATE users SET status = 'active' WHERE status = 'migrated';

# 4. Update migration status
UPDATE schema_migrations
SET status = 'rolled_back'
WHERE version = '2025_10_20_150000';

INSERT INTO migration_history (version, operation, status, executed_by, executed_at)
VALUES ('2025_10_20_150000', 'rollback', 'completed', 'admin', NOW());

# 5. Verify changes look correct
SELECT * FROM schema_migrations WHERE version = '2025_10_20_150000';

# 6. Commit (or ROLLBACK if something looks wrong)
COMMIT;
```

---

### Method 3: Database Restore from Backup

**Best for**: Catastrophic failures, multiple failed migrations, data corruption

#### Option A: Supabase Point-in-Time Recovery

```bash
# 1. Go to Supabase Dashboard
# https://supabase.com/dashboard/project/<your-project>/database/backups

# 2. Select "Point in Time Recovery"
# - Choose timestamp before migration (e.g., 30 minutes ago)
# - Restore to new database or overwrite current

# 3. Wait for restore (usually 5-15 minutes)

# 4. Verify restored data
psql "$PROD_DATABASE_URL" -c "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 5;"

# 5. Update application to use restored database
```

#### Option B: DigitalOcean Droplet Snapshot Restore

```bash
# 1. List available snapshots
doctl compute snapshot list

# 2. Restore from snapshot (this recreates the droplet)
doctl compute droplet create restored-db \
  --image <snapshot-id> \
  --size s-2vcpu-4gb \
  --region sgp1 \
  --wait

# 3. Get new droplet IP
doctl compute droplet get <droplet-id> --format PublicIPv4

# 4. Update DNS and application config to point to new IP
```

#### Option C: Custom pg_dump Restore

```bash
# 1. Find backup file (should be created pre-deployment)
ls -lh backups/

# 2. Restore from backup
psql "$PROD_DATABASE_URL" < backups/prod-pre-migration-2025-10-20.sql

# 3. Verify restoration
psql "$PROD_DATABASE_URL" -c "SELECT COUNT(*) FROM schema_migrations;"
```

---

## 📋 Step-by-Step Rollback Procedure

### Production Rollback (Full Procedure)

**Estimated Time**: 15-30 minutes

**Prerequisites**:
- Database backup exists
- Rollback SQL script ready (or manual SQL prepared)
- Team notified (if applicable)

#### Step 1: Assess Situation (5 minutes)

```bash
# Check migration status
DATABASE_URL="$PROD_DATABASE_URL" node scripts/run-migrations.js --status

# Check application health
curl -f https://insightpulseai.net/api/health || echo "App is DOWN"

# Check logs for errors
# (Application logs, database logs, etc.)
```

#### Step 2: Create Emergency Backup (2 minutes)

```bash
# Quick pg_dump backup before rollback
pg_dump "$PROD_DATABASE_URL" | gzip > backups/emergency-pre-rollback-$(date +%F-%H%M%S).sql.gz

# Or create DigitalOcean snapshot (if using droplet)
doctl compute droplet-action snapshot <droplet-id> \
  --snapshot-name "emergency-pre-rollback-$(date +%F-%H%M%S)" \
  --wait
```

#### Step 3: Enable Maintenance Mode (1 minute)

```bash
# Option A: Set environment variable
# MAINTENANCE_MODE=true

# Option B: Update application config
# Redirect users to maintenance page

# Option C: Scale down to 0 replicas (Kubernetes/DO App Platform)
```

#### Step 4: Execute Rollback (5-10 minutes)

**Choose ONE method from above:**

- **Automated**: `node scripts/run-migrations.js --rollback --to <version>`
- **Manual SQL**: Custom SQL in transaction
- **Restore**: Point-in-time recovery or snapshot restore

#### Step 5: Verify Rollback (5 minutes)

```bash
# 1. Check migration status
psql "$PROD_DATABASE_URL" -c "SELECT * FROM schema_migrations WHERE status = 'rolled_back';"

# 2. Verify critical tables/data
psql "$PROD_DATABASE_URL" -c "SELECT COUNT(*) FROM users;"
psql "$PROD_DATABASE_URL" -c "SELECT COUNT(*) FROM projects;"

# 3. Run smoke tests
./scripts/smoke-tests.sh

# 4. Check application health
curl -f https://insightpulseai.net/api/health
```

#### Step 6: Restart Application (2 minutes)

```bash
# Disable maintenance mode
# MAINTENANCE_MODE=false

# Or restart application
# kubectl rollout restart deployment/app
# doctl apps create-deployment <app-id>
```

#### Step 7: Monitor (10 minutes)

```bash
# Watch application logs
tail -f /var/log/app.log

# Monitor error rates
# Check Sentry, New Relic, or application monitoring

# Watch database connections
psql "$PROD_DATABASE_URL" -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'postgres';"

# Check user reports
# Monitor support channels, social media, etc.
```

#### Step 8: Post-Rollback Analysis (Next Day)

```bash
# 1. Document what went wrong
# - Create incident report
# - Identify root cause
# - Document lessons learned

# 2. Fix migration SQL
# - Update migration file
# - Add rollback script if missing
# - Add validation checks

# 3. Test migration in staging
DATABASE_URL="$STAGING_DATABASE_URL" node scripts/run-migrations.js

# 4. Schedule re-deployment (after fixes)
```

---

## 🔧 Rollback Scenarios & Solutions

### Scenario 1: Migration Failed Halfway

**Symptoms**: Migration status = 'failed', some changes applied, some not

**Solution**:
```bash
# If migration was in a transaction, it auto-rolled back
# Just mark it as failed and investigate
psql "$PROD_DATABASE_URL" -c "
  UPDATE schema_migrations
  SET status = 'failed', error_message = 'Manual investigation required'
  WHERE version = '2025_10_20_150000';
"

# Fix the migration SQL
# Re-run with fixes:
DATABASE_URL="$PROD_DATABASE_URL" node scripts/run-migrations.js
```

---

### Scenario 2: Migration Succeeded but App Broken

**Symptoms**: Migration status = 'completed', app throws errors

**Solution**:
```bash
# Option A: Rollback migration
DATABASE_URL="$PROD_DATABASE_URL" \
  node scripts/run-migrations.js \
  --rollback \
  --to <previous-version>

# Option B: Deploy application hotfix (if migration is correct)
git revert <bad-commit>
git push origin main

# Option C: Roll forward with new migration to fix issues
# Create new migration that fixes the problem
```

---

### Scenario 3: Wrong Database Targeted

**Symptoms**: Migration applied to production instead of staging (or vice versa)

**Solution**:
```bash
# 1. Immediately rollback on wrong database
DATABASE_URL="$WRONG_DATABASE_URL" \
  node scripts/run-migrations.js \
  --rollback \
  --to <last-good-version>

# 2. Verify correct database is clean
DATABASE_URL="$CORRECT_DATABASE_URL" \
  node scripts/run-migrations.js \
  --status

# 3. Apply to correct database
DATABASE_URL="$CORRECT_DATABASE_URL" \
  node scripts/run-migrations.js

# 4. Update environment variables to prevent recurrence
# Check .env, CI/CD secrets, etc.
```

---

### Scenario 4: Data Loss After Migration

**Symptoms**: Rows deleted, columns dropped, data corrupted

**Solution**:
```bash
# Option A: Restore from backup (fastest)
# See Method 3 above

# Option B: Reconstruct data from audit logs
psql "$PROD_DATABASE_URL" -c "
  SELECT * FROM migration_history
  WHERE version = '2025_10_20_150000';
"

# Option C: Request users to re-enter data (last resort)
```

---

## 🚀 Quick Reference Commands

### Check Migration Status
```bash
DATABASE_URL="$PROD_DATABASE_URL" node scripts/run-migrations.js --status
```

### Rollback Last Migration
```bash
DATABASE_URL="$PROD_DATABASE_URL" \
  node scripts/run-migrations.js \
  --rollback \
  --to <previous-version>
```

### Rollback with Dry-Run
```bash
DATABASE_URL="$PROD_DATABASE_URL" \
  node scripts/run-migrations.js \
  --rollback \
  --to <version> \
  --dry-run
```

### Manual SQL Rollback
```bash
psql "$PROD_DATABASE_URL" << 'SQL'
BEGIN;
-- Your rollback SQL here
UPDATE schema_migrations SET status = 'rolled_back' WHERE version = 'X';
COMMIT;
SQL
```

### View Migration History
```bash
psql "$PROD_DATABASE_URL" -c "
  SELECT * FROM migration_history
  WHERE version = '2025_10_20_150000'
  ORDER BY executed_at DESC;
"
```

### Create Emergency Backup
```bash
pg_dump "$PROD_DATABASE_URL" | gzip > backups/emergency-$(date +%F-%H%M%S).sql.gz
```

---

## 📞 Escalation Contacts

**During Rollback**:
1. **Database Team**: database-team@company.com
2. **DevOps Lead**: devops-lead@company.com
3. **Engineering Manager**: eng-manager@company.com

**After-Hours**:
1. On-call engineer: +1-XXX-XXX-XXXX
2. PagerDuty incident: https://company.pagerduty.com

---

## 🛡️ Prevention Best Practices

**To minimize rollback needs**:

1. **Always dry-run first**:
   ```bash
   node scripts/run-migrations.js --dry-run
   ```

2. **Test in staging**:
   ```bash
   DATABASE_URL="$STAGING_DATABASE_URL" node scripts/run-migrations.js
   ```

3. **Create rollback scripts**:
   - Every migration should have a `down.sql` or rollback method
   - Test rollback in staging too!

4. **Backup before production**:
   ```bash
   pg_dump "$PROD_DATABASE_URL" > backups/pre-migration-$(date +%F).sql
   ```

5. **Use feature flags**:
   - Deploy code changes behind feature flags
   - Enable after migration succeeds

6. **Monitor closely**:
   - Watch logs during migration
   - Check error rates in APM tools
   - Have rollback command ready to execute

7. **Schedule during low-traffic**:
   - Minimize user impact
   - Easier to rollback if needed

---

## 📚 Related Documentation

- [Database Migrations Guide](./DATABASE_MIGRATIONS.md)
- [Infrastructure Mismatch Report](./INFRA_DEPLOY_MISMATCH_REPORT.md)
- [Deployment Guide](./DEPLOYMENT_READY.md)

---

**Document Version**: 1.0
**Last Reviewed**: 2025-10-20
**Review Frequency**: After each incident or quarterly
