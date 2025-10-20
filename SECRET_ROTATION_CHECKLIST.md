# 🔐 Secret Rotation Checklist

**Date**: 2025-10-20
**Reason**: Exposed credentials in git history
**Urgency**: 🔴 CRITICAL - Execute immediately

---

## 📋 Exposed Secrets to Rotate

Based on the infrastructure analysis, these secrets were exposed:

| Secret | Location | Severity | Status |
|--------|----------|----------|--------|
| Supabase PostgreSQL password | `.env.production`, `docker-compose.supabase.yml` | 🔴 Critical | ⏳ To rotate |
| Supabase service_role_key | `.env.production` | 🔴 Critical | ⏳ To rotate |
| Supabase JWT secret | `.env.production` | 🔴 Critical | ⏳ To rotate |
| Supabase anon key | `.env.production` | 🟡 High | ⏳ To rotate |
| Odoo admin password | `.env.production`, `config/odoo.local.conf` | 🟡 High | ⏳ To rotate |
| DigitalOcean token | `.env.production` | 🟡 High | ℹ️ Placeholder (not set) |

---

## 🚀 Rotation Procedures

### 1️⃣ Supabase Database Password

**Current exposed value**: `SHWYXDMFAwXI1drT`

#### Steps:

1. **Go to Supabase Dashboard**:
   ```
   https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/settings/database
   ```

2. **Reset Database Password**:
   - Scroll to "Database password" section
   - Click "Reset database password"
   - Copy the NEW password immediately (it won't be shown again)
   - Save it securely (password manager recommended)

3. **Update connection strings**:
   ```bash
   # Old format (EXPOSED):
   postgresql://postgres.spdtwktxdalcfigzeqrz:SHWYXDMFAwXI1drT@aws-1-us-east-1.pooler.supabase.com:5432/postgres

   # New format (use NEW password):
   postgresql://postgres.spdtwktxdalcfigzeqrz:NEW_PASSWORD_HERE@aws-1-us-east-1.pooler.supabase.com:5432/postgres
   ```

4. **Update in GitHub Secrets**:
   ```bash
   # Update DATABASE_URL
   gh secret set STAGING_DATABASE_URL -b "postgresql://postgres.spdtwktxdalcfigzeqrz:NEW_PASSWORD@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

   gh secret set PROD_DATABASE_URL -b "postgresql://postgres.spdtwktxdalcfigzeqrz:NEW_PASSWORD@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

   gh secret set POSTGRES_PASSWORD -b "NEW_PASSWORD"
   ```

5. **Update local .env** (create from .env.sample):
   ```bash
   cp .env.sample .env
   nano .env  # Add NEW password to POSTGRES_PASSWORD
   ```

6. **Test connection**:
   ```bash
   psql "postgresql://postgres.spdtwktxdalcfigzeqrz:NEW_PASSWORD@aws-1-us-east-1.pooler.supabase.com:5432/postgres" -c "SELECT 1"
   ```

✅ **Mark complete**: [ ]

---

### 2️⃣ Supabase Service Role Key

**Current exposed value**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHR3a3R4ZGFsY2ZpZ3plcXJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0NDAzNSwiZXhwIjoyMDc2MjIwMDM1fQ.Rhdi18B5EuUeaSGfdB4rqZ6UoPSrJ9IbzkN_YboyvhU`

#### Steps:

1. **Go to Supabase API Settings**:
   ```
   https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/settings/api
   ```

2. **Rotate Service Role Key**:
   - Scroll to "Project API keys" section
   - Find "service_role" key (secret, server-side only)
   - Click "Reveal" to see current value
   - Click "Roll" or "Regenerate" button
   - Copy NEW key immediately
   - Save securely

3. **Update in GitHub Secrets**:
   ```bash
   gh secret set SUPABASE_SERVICE_ROLE_KEY -b "NEW_SERVICE_ROLE_KEY_HERE"
   ```

4. **Update local .env**:
   ```bash
   nano .env  # Add NEW service_role_key to SUPABASE_SERVICE_ROLE_KEY
   ```

5. **Test with API call**:
   ```bash
   curl "https://spdtwktxdalcfigzeqrz.supabase.co/rest/v1/" \
     -H "apikey: NEW_SERVICE_ROLE_KEY" \
     -H "Authorization: Bearer NEW_SERVICE_ROLE_KEY"
   ```

✅ **Mark complete**: [ ]

---

### 3️⃣ Supabase JWT Secret

**Current exposed value**: `UCrAMrC47YUN4pILFRKm1JD1JAUN2GXNYzariivwVUKzMUcEKRMR5w+dYcndM3ijn45Z6I7txvtQ0yyrB5EWng==`

#### Steps:

⚠️ **WARNING**: Rotating JWT secret invalidates ALL existing user sessions!

1. **Go to Supabase API Settings**:
   ```
   https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/settings/api
   ```

2. **Find JWT Secret**:
   - Scroll to "JWT Settings" section
   - Current secret is shown

3. **Generate NEW JWT Secret**:
   ```bash
   # Generate new 64-byte secret
   openssl rand -base64 64
   ```

4. **Contact Supabase Support** (if rotation needed):
   - JWT secret rotation requires Supabase support intervention
   - File ticket: https://supabase.com/dashboard/support/new
   - Provide new secret and request rotation
   - **OR** accept current secret is exposed and monitor for abuse

5. **Alternative: Create NEW Supabase Project** (recommended for production):
   - Create fresh project with new JWT secret
   - Migrate data using pg_dump/restore
   - Update all connection strings

✅ **Mark complete**: [ ] (or skip if keeping current secret)

---

### 4️⃣ Supabase Anonymous Key

**Current exposed value**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHR3a3R4ZGFsY2ZpZ3plcXJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NDQwMzUsImV4cCI6MjA3NjIyMDAzNX0.IHBJ0cNTMKJvRozljqaEqWph_gC0zlW2Td5Xl_GENs4`

#### Steps:

ℹ️ **Note**: Anon key is meant to be public (client-side), but good practice to rotate.

1. **Same process as Service Role Key** (see #2 above)

2. **Update in GitHub Secrets**:
   ```bash
   gh secret set NEXT_PUBLIC_SUPABASE_ANON_KEY -b "NEW_ANON_KEY_HERE"
   ```

3. **Update local .env**:
   ```bash
   nano .env  # Add NEW anon key to NEXT_PUBLIC_SUPABASE_ANON_KEY
   ```

✅ **Mark complete**: [ ]

---

### 5️⃣ Odoo Admin Password

**Current exposed values**:
- `.env.production`: `admin` (weak!)
- `config/odoo.local.conf`: `n94h-nf3x-22pv`

#### Steps:

1. **Generate strong password**:
   ```bash
   # Generate 32-character password
   openssl rand -base64 32
   # Example output: K8sN3mP9qR7tY2wE5uI8oL1aS4dF6gH9jK0zX3cV5bN7mQ2
   ```

2. **Update Odoo admin password** (if Odoo instance is running):
   ```bash
   # Connect to Odoo database
   docker exec -it odoo18 odoo shell -d odoboo_local

   # In Odoo shell, change admin password:
   env['res.users'].browse(2).write({'password': 'NEW_STRONG_PASSWORD_HERE'})
   env.cr.commit()
   exit()
   ```

3. **Update config files**:
   ```bash
   # Update config/odoo.local.conf (or use environment variable)
   # Change admin_passwd = n94h-nf3x-22pv
   # To:    admin_passwd = NEW_STRONG_PASSWORD
   ```

4. **Update .env**:
   ```bash
   nano .env  # Set ODOO_ADMIN_PASSWORD=NEW_STRONG_PASSWORD
   ```

5. **Test login**:
   - Go to http://localhost:8069/web/database/manager
   - Enter NEW admin password
   - Verify access

✅ **Mark complete**: [ ]

---

### 6️⃣ DigitalOcean API Token

**Current status**: Placeholder (`your_digitalocean_token_here`) - not exposed

#### Steps (if you have an existing token to rotate):

1. **Go to DigitalOcean API Tokens**:
   ```
   https://cloud.digitalocean.com/account/api/tokens
   ```

2. **Revoke old token** (if exists):
   - Find old token in list
   - Click "..." → "Delete"
   - Confirm deletion

3. **Create NEW token**:
   - Click "Generate New Token"
   - Name: `GitHub Actions - odoboo-workspace - 2025-10-20`
   - Scopes: ✅ Read + ✅ Write
   - Expiration: Set reminder for 90 days
   - Click "Generate Token"
   - Copy token IMMEDIATELY (won't be shown again)

4. **Update in GitHub Secrets**:
   ```bash
   gh secret set DO_ACCESS_TOKEN -b "dop_v1_NEW_TOKEN_HERE"
   ```

5. **Update local .env**:
   ```bash
   nano .env  # Set DO_ACCESS_TOKEN=dop_v1_NEW_TOKEN_HERE
   ```

6. **Test token**:
   ```bash
   doctl auth init --access-token "dop_v1_NEW_TOKEN_HERE"
   doctl account get
   ```

✅ **Mark complete**: [ ]

---

### 7️⃣ Generate NEW Internal Admin Token

**Purpose**: Authentication for migration API endpoint

This is a NEW secret (not previously exposed), but required for the migration system.

#### Steps:

1. **Generate secure token**:
   ```bash
   openssl rand -base64 32
   # Example output: xP9mK2qL5wN8eR3tY7uO1iA4sD6fG0hJ9kZ3vC5bN7mQ2
   ```

2. **Set in GitHub Secrets**:
   ```bash
   gh secret set INTERNAL_ADMIN_TOKEN -b "$(openssl rand -base64 32)"
   ```

3. **Update local .env**:
   ```bash
   nano .env  # Set INTERNAL_ADMIN_TOKEN=xP9mK2qL5wN8eR3tY7uO1iA4sD6fG0hJ9kZ3vC5bN7mQ2
   ```

4. **Test migration API**:
   ```bash
   # After app is running:
   curl -X POST http://localhost:3000/api/migrations \
     -H "Authorization: Bearer xP9mK2qL5wN8eR3tY7uO1iA4sD6fG0hJ9kZ3vC5bN7mQ2" \
     -H "Content-Type: application/json" \
     -d '{"dry_run": true}'
   ```

✅ **Mark complete**: [ ]

---

## 📝 Post-Rotation Verification

After rotating ALL secrets, verify everything works:

### ✅ Checklist

- [ ] **Database connection works**:
  ```bash
  psql "$DATABASE_URL" -c "SELECT version();"
  ```

- [ ] **Supabase API works**:
  ```bash
  curl "https://spdtwktxdalcfigzeqrz.supabase.co/rest/v1/" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
  ```

- [ ] **Odoo admin login works**:
  - Visit http://localhost:8069
  - Login as admin with NEW password

- [ ] **DigitalOcean CLI works**:
  ```bash
  doctl account get
  ```

- [ ] **GitHub Secrets are set**:
  ```bash
  gh secret list
  # Should show:
  # STAGING_DATABASE_URL
  # PROD_DATABASE_URL
  # SUPABASE_SERVICE_ROLE_KEY
  # NEXT_PUBLIC_SUPABASE_ANON_KEY
  # INTERNAL_ADMIN_TOKEN
  # DO_ACCESS_TOKEN
  ```

- [ ] **Local .env is configured**:
  ```bash
  grep -E "DATABASE_URL|SUPABASE_SERVICE_ROLE_KEY|ODOO_ADMIN_PASSWORD|DO_ACCESS_TOKEN|INTERNAL_ADMIN_TOKEN" .env
  # Should show all NEW values (not placeholders)
  ```

- [ ] **Old secrets are documented** (for audit trail):
  ```bash
  # Create incident report documenting:
  # - Which secrets were exposed
  # - When rotation occurred
  # - Who performed rotation
  # - Verification that old secrets are revoked
  ```

---

## 🚨 Emergency Contacts

If you encounter issues during rotation:

- **Supabase Support**: https://supabase.com/dashboard/support/new
- **DigitalOcean Support**: https://cloud.digitalocean.com/support
- **GitHub Support**: https://support.github.com

---

## 📅 Rotation Schedule (Future)

Set reminders to rotate secrets regularly:

| Secret | Rotation Frequency | Next Rotation |
|--------|-------------------|---------------|
| Database passwords | Quarterly | 2026-01-20 |
| Supabase keys | Quarterly | 2026-01-20 |
| API tokens | Quarterly | 2026-01-20 |
| Admin passwords | Quarterly | 2026-01-20 |
| DO tokens | Yearly | 2026-10-20 |

Use calendar reminders or tools like:
- 1Password Watchtower
- LastPass Security Challenge
- Bitwarden Vault Health Reports

---

## ✅ Final Steps

After completing rotation:

1. **Update this checklist** with completion status
2. **Test all applications** with new secrets
3. **Document rotation** in password manager
4. **Proceed with git history cleanup**:
   ```bash
   ./scripts/purge-secrets-from-history.sh
   ```
5. **Force push cleaned history**:
   ```bash
   git push origin --force --all
   git push origin --force --tags
   ```

---

**Rotation completed by**: _______________
**Date**: _______________
**Time**: _______________
**Verified by**: _______________
