# 🔐 GitHub Secrets Setup Guide

**Purpose**: Configure GitHub repository secrets for CI/CD workflows and secure deployments.

**Repository**: jgtolentino/odoboo-workspace

**Last Updated**: 2025-10-20

---

## 📋 Overview

GitHub Secrets allow you to store sensitive information (API keys, passwords, tokens) securely for use in GitHub Actions workflows without exposing them in code.

**Path to configure**: GitHub.com → Your Repo → Settings → Secrets and variables → Actions

---

## 🔑 Required Secrets

### 1. Database Connection Secrets

#### `STAGING_DATABASE_URL`

**Purpose**: Supabase PostgreSQL connection string for staging environment

**Format**:
```
postgresql://postgres.your-staging-ref:staging-password@aws-0-region.pooler.supabase.com:5432/postgres
```

**How to get**:
1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your **staging project**
3. Click Settings → Database
4. Find "Connection string" section
5. Select "URI" tab
6. Copy the connection string (use Transaction mode, not Session)
7. Replace `[YOUR-PASSWORD]` with actual database password

**Used by**:
- `.github/workflows/db-staging.yml`
- Triggered on push to `staging` branch

**Example**:
```
postgresql://postgres.spdtwktxdalcfigzeqrz:SHWYXDMFAwXI1drT@aws-1-us-east-1.pooler.supabase.com:5432/postgres
```

---

#### `PROD_DATABASE_URL`

**Purpose**: Supabase PostgreSQL connection string for production environment

**Format**: Same as `STAGING_DATABASE_URL` but for production project

**How to get**:
1. Go to Supabase Dashboard
2. Select your **production project** (different from staging)
3. Settings → Database → Connection string → URI
4. Copy and replace password placeholder

**Used by**:
- `.github/workflows/db-prod.yml`
- Triggered on version tags (e.g., `v1.0.0`)

**⚠️ CRITICAL**: This should point to your PRODUCTION database. Triple-check before saving!

---

### 2. Supabase API Secrets

#### `NEXT_PUBLIC_SUPABASE_URL`

**Purpose**: Supabase project URL (safe for client-side)

**Format**:
```
https://your-project-ref.supabase.co
```

**How to get**:
1. Supabase Dashboard → Settings → API
2. Copy "Project URL"

**Used by**:
- Next.js application builds
- Client-side Supabase connections

**Note**: This is NOT secret (it's public), but stored as secret for consistency.

---

#### `SUPABASE_SERVICE_ROLE_KEY`

**Purpose**: Server-side Supabase key with full admin access

**Format**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHR3a3R4ZGFsY2ZpZ3plcXJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0NDAzNSwiZXhwIjoyMDc2MjIwMDM1fQ.your_signature_here
```

**How to get**:
1. Supabase Dashboard → Settings → API
2. Find "Service Role" key
3. Click "Reveal" and copy

**Used by**:
- Server-side API routes
- Admin operations
- Database migrations (if using Supabase REST API)

**⚠️ SECURITY**: Keep this secret! It bypasses Row Level Security (RLS).

---

### 3. Migration API Authentication

#### `INTERNAL_ADMIN_TOKEN`

**Purpose**: Authentication token for migration API endpoint

**Format**: Any secure random string (min 32 characters)

**How to generate**:
```bash
# Option 1: OpenSSL
openssl rand -base64 32

# Option 2: Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# Option 3: Manual
# Use password generator with 32+ characters
```

**Used by**:
- `app/api/migrations/route.ts`
- Prevents unauthorized access to migration endpoint

**Example**:
```
k8sN3mP9qR7tY2wE5uI8oL1aS4dF6gH9jK0zX3cV5bN7mQ2
```

---

### 4. DigitalOcean Secrets

#### `DO_ACCESS_TOKEN`

**Purpose**: DigitalOcean API token for droplet management

**Format**:
```
dop_v1_1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab
```

**How to get**:
1. Go to DigitalOcean Control Panel
2. Click API in left sidebar
3. Click "Generate New Token"
4. Name: "GitHub Actions - odoboo-workspace"
5. Scopes: Read + Write
6. Expiration: No expiry (or set reminder to rotate)
7. Click "Generate Token"
8. Copy immediately (won't be shown again)

**Used by**:
- Droplet deployment scripts
- Container registry authentication
- Infrastructure automation

**⚠️ SECURITY**: This token has full access to your DigitalOcean account!

---

## 🎯 Optional Secrets

### 5. Feature Flags & Overrides

#### `ROLLBACK_ALLOWED`

**Purpose**: Enable rollback functionality in workflows

**Format**: `true` or `false`

**Default**: `false` (rollback disabled for safety)

**Used by**:
- `.github/workflows/db-prod.yml`
- Allows automated rollback on failure

**Recommendation**: Keep `false` in production, require manual rollback.

---

#### `CONFIRM_PRODUCTION_MIGRATION`

**Purpose**: Bypass manual confirmation for production migrations

**Format**: `true` or `false`

**Default**: Requires manual confirmation

**Used by**:
- `.github/workflows/db-prod.yml`
- Skips 30-second review window

**⚠️ WARNING**: Only use for fully automated deployments with extensive testing!

---

## 📝 Step-by-Step Setup Instructions

### Setting Up Secrets (GitHub Web UI)

1. **Navigate to repository**:
   - Go to https://github.com/jgtolentino/odoboo-workspace

2. **Open Settings**:
   - Click "Settings" tab (top menu)
   - If you don't see Settings, you need admin access

3. **Go to Secrets section**:
   - In left sidebar, click "Secrets and variables"
   - Click "Actions"

4. **Add each secret**:
   - Click "New repository secret"
   - Enter secret name (e.g., `STAGING_DATABASE_URL`)
   - Paste secret value
   - Click "Add secret"

5. **Repeat for all required secrets**

---

### Setting Up Secrets (GitHub CLI)

```bash
# Install GitHub CLI (if not installed)
brew install gh

# Authenticate
gh auth login

# Navigate to repository
cd /path/to/odoboo-workspace

# Set secrets
gh secret set STAGING_DATABASE_URL -b "postgresql://postgres.staging:password@aws-0-region.pooler.supabase.com:5432/postgres"
gh secret set PROD_DATABASE_URL -b "postgresql://postgres.prod:password@aws-0-region.pooler.supabase.com:5432/postgres"
gh secret set NEXT_PUBLIC_SUPABASE_URL -b "https://your-project.supabase.co"
gh secret set SUPABASE_SERVICE_ROLE_KEY -b "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
gh secret set INTERNAL_ADMIN_TOKEN -b "$(openssl rand -base64 32)"
gh secret set DO_ACCESS_TOKEN -b "dop_v1_your_token_here"

# Verify secrets are set
gh secret list
```

---

## ✅ Verification Checklist

After setting up secrets, verify they work:

### 1. List Secrets

```bash
gh secret list
```

**Expected output**:
```
STAGING_DATABASE_URL      Updated 2025-10-20
PROD_DATABASE_URL         Updated 2025-10-20
NEXT_PUBLIC_SUPABASE_URL  Updated 2025-10-20
SUPABASE_SERVICE_ROLE_KEY Updated 2025-10-20
INTERNAL_ADMIN_TOKEN      Updated 2025-10-20
DO_ACCESS_TOKEN           Updated 2025-10-20
```

### 2. Test Staging Workflow

```bash
# Push to staging branch to trigger workflow
git checkout staging
git push origin staging

# Monitor workflow
gh run list --workflow=db-staging.yml
gh run view <run-id> --log
```

**Expected**: Workflow runs successfully, migrations applied to staging DB.

### 3. Test Production Workflow (Dry-Run)

```bash
# Create version tag to trigger prod workflow
git tag v0.0.1-test
git push origin v0.0.1-test

# Monitor workflow
gh run list --workflow=db-prod.yml
gh run view <run-id> --log
```

**Expected**: Workflow runs dry-run, waits for approval, then applies (or skips if dry-run only).

### 4. Test Migration API (Local)

```bash
# Set environment variable locally
export INTERNAL_ADMIN_TOKEN="your_token_from_github_secrets"

# Test API endpoint
curl -X POST http://localhost:3000/api/migrations \
  -H "Authorization: Bearer $INTERNAL_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dry_run": true}'
```

**Expected**: API returns migration status, not "Unauthorized".

---

## 🔄 Rotation Schedule

**Best Practice**: Rotate secrets regularly to minimize risk.

| Secret | Rotation Frequency | Complexity |
|--------|-------------------|------------|
| Database URLs | When passwords change | High (requires DB password rotation) |
| Supabase Keys | Quarterly or on breach | Medium (regenerate in Supabase dashboard) |
| `INTERNAL_ADMIN_TOKEN` | Quarterly | Low (generate new random string) |
| `DO_ACCESS_TOKEN` | Yearly or on breach | Medium (generate new token in DO panel) |

### Rotation Procedure

1. **Generate new secret** (Supabase, DigitalOcean, etc.)
2. **Update GitHub Secret** (Settings → Secrets → Edit)
3. **Deploy applications** with new secret
4. **Verify** new secret works in production
5. **Revoke old secret** at provider (Supabase, DigitalOcean)
6. **Document rotation** in password manager or wiki

---

## 🚨 Troubleshooting

### Secret Not Available in Workflow

**Symptom**: Workflow log shows `${{ secrets.SECRET_NAME }}` is empty

**Solutions**:
1. Verify secret name matches exactly (case-sensitive)
2. Check secret is set at repository level (not organization level)
3. Ensure workflow is triggered from allowed branch
4. Re-save secret (sometimes helps with sync issues)

---

### Database Connection Fails

**Symptom**: `psql: error: connection to server ... failed`

**Solutions**:
1. Verify `DATABASE_URL` format is correct
2. Check database password is correct
3. Ensure Supabase project is not paused
4. Verify database allows connections from GitHub Actions IPs
5. Test connection locally:
   ```bash
   psql "$STAGING_DATABASE_URL" -c "SELECT 1"
   ```

---

### Unauthorized API Access

**Symptom**: Migration API returns 401 Unauthorized

**Solutions**:
1. Verify `INTERNAL_ADMIN_TOKEN` is set in GitHub Secrets
2. Check token is passed correctly in workflow:
   ```yaml
   env:
     INTERNAL_ADMIN_TOKEN: ${{ secrets.INTERNAL_ADMIN_TOKEN }}
   ```
3. Ensure API route is reading token from environment:
   ```typescript
   const token = process.env.INTERNAL_ADMIN_TOKEN
   ```

---

## 📚 Related Documentation

- [Database Migrations Guide](./DATABASE_MIGRATIONS.md)
- [Rollback Playbook](./ROLLBACK_PLAYBOOK.md)
- [Infrastructure Mismatch Report](./INFRA_DEPLOY_MISMATCH_REPORT.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Supabase Database Settings](https://supabase.com/docs/guides/database)

---

## 🔗 Quick Links

- **GitHub Secrets Settings**: https://github.com/jgtolentino/odoboo-workspace/settings/secrets/actions
- **Supabase Dashboard**: https://supabase.com/dashboard
- **DigitalOcean API Tokens**: https://cloud.digitalocean.com/account/api/tokens
- **GitHub Actions Runs**: https://github.com/jgtolentino/odoboo-workspace/actions

---

**Document Version**: 1.0
**Last Reviewed**: 2025-10-20
**Next Review**: After secret rotation or incident
