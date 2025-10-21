# Credentials Management

**CRITICAL**: This file contains credential *locations* and *procedures*, NOT actual passwords.
Store all actual credentials in a password manager (1Password, Bitwarden, etc.).

---

## Production Odoo Admin Account

### Primary Admin User
- **Email**: `jgtolentino_rn@yahoo.com`
- **Role**: Super Administrator
- **Database**: `insightpulse_prod`
- **Password**: Stored in password manager under "Odoo Production Admin"
  - **DO NOT commit actual password to git**
  - Use strong password (minimum 12 characters, mixed case, numbers, symbols)
  - Example format: `<uppercase><lowercase><numbers><symbols>_<number>`

### Setting Admin Password

**Option 1: During Database Creation** (recommended for new databases)
```bash
# When creating database, set admin password interactively
docker exec -it odoo18 odoo -d insightpulse_prod \
  --without-demo=all \
  --stop-after-init
# Prompts for: Email, Password, Language, Country
```

**Option 2: Reset Existing Admin Password**

Use the secure script:
```bash
./scripts/reset_admin_password.sh
```

This script will:
1. Prompt for database name (default: `insightpulse_prod`)
2. Prompt for admin email (default: `jgtolentino_rn@yahoo.com`)
3. Prompt for new password (hidden input, never displayed)
4. Hash password using Odoo's algorithm
5. Update database securely

**Option 3: Via Odoo Shell** (manual)
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
import sys

# Prompt for new password (hidden input in production)
# For script, pass via environment variable
new_password = input("Enter new admin password: ")

env = env.sudo()
admin_email = 'jgtolentino_rn@yahoo.com'

# Find admin user
admin_user = env['res.users'].search([('login', '=', admin_email)], limit=1)

if not admin_user:
    print(f"ERROR: User {admin_email} not found")
    sys.exit(1)

# Update password (Odoo auto-hashes)
admin_user.password = new_password

print(f"✅ Password updated for {admin_email}")
print("⚠️  Clear shell history: history -c")
PY
```

---

## API Keys

### Odoo API Key (for CI/CD)

**Purpose**: Allows GitHub Actions to update Odoo Kanban + Discuss

**Generation**:
1. Login as admin: `https://insightpulseai.net`
2. Navigate to: **Settings → Users & Companies → Users**
3. Select user: `jgtolentino_rn@yahoo.com`
4. Click **Edit**
5. Scroll to **API Keys** section
6. Click **Generate API Key**
7. Copy immediately (shown only once)
8. Store in:
   - Password manager: "Odoo API Key (Production)"
   - GitHub Secrets: `ODOO_API_KEY`

**Set GitHub Secret**:
```bash
# From password manager, copy API key
gh secret set ODOO_API_KEY -b "<paste-from-password-manager>"

# Verify
gh secret list | grep ODOO_API_KEY
```

**Revoke/Rotate**:
```bash
# Via Odoo UI: Settings → Users → API Keys → Delete
# Then generate new key and update GitHub secrets

# Or via shell:
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
admin = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')], limit=1)

# Revoke all existing keys
env['res.users.apikeys'].search([('user_id','=',admin.id)]).unlink()

# Generate new key
new_key = admin._generate_api_key()
print(f"New API key: {new_key}")
print("⚠️  Copy this immediately - shown only once!")
PY
```

### OpenAI API Key

**Purpose**: OCR enhancement, AI features

**Generation**: https://platform.openai.com/api-keys

**Storage**:
- Password manager: "OpenAI API Key (Production)"
- GitHub Secrets: `OPENAI_API_KEY`
- Odoo config (if needed): `ir.config_parameter` → `openai.api_key`

**Set GitHub Secret**:
```bash
gh secret set OPENAI_API_KEY -b "sk-proj-<your-key-here>"
```

### MCP Admin Token

**Purpose**: Write operations via MCP HTTP gateway

**Generation**:
```bash
# Generate secure random token
openssl rand -base64 32
# Example: xK9mP2vR7wQ8nL4jF6hT5yU3oI1eA0sD
```

**Storage**:
- Password manager: "MCP Admin Token"
- GitHub Secrets: `MCP_ADMIN_TOKEN`
- Environment variable: `MCP_ADMIN_TOKEN`

**Set GitHub Secret**:
```bash
MCP_TOKEN=$(openssl rand -base64 32)
gh secret set MCP_ADMIN_TOKEN -b "$MCP_TOKEN"

# Also add to .env (for local development)
echo "MCP_ADMIN_TOKEN=$MCP_TOKEN" >> .env
```

---

## Database Credentials

### PostgreSQL Connection String

**Format**:
```
postgresql://[user]:[password]@[host]:[port]/[database]
```

**Production**:
- Host: `aws-1-us-east-1.pooler.supabase.com`
- Port: `6543`
- User: `postgres.spdtwktxdalcfigzeqrz`
- Database: `insightpulse_prod`
- Password: Stored in password manager under "Supabase PostgreSQL Password"

**Storage**:
- Password manager: Full connection string
- GitHub Secrets: `PRODUCTION_DATABASE_URL`
- `.env` (local): `DATABASE_URL`

**Set GitHub Secret**:
```bash
# Never type password in plain text - copy from password manager
gh secret set PRODUCTION_DATABASE_URL -b "postgresql://user:password@host:port/db"
```

### Staging Database

Same credentials as production, but database name: `insightpulse_stage`

```bash
gh secret set STAGING_DATABASE_URL -b "postgresql://user:password@host:port/insightpulse_stage"
```

---

## OAuth Credentials

### Google OAuth (for Corporate SSO)

**Setup**: See `docs/ODOO_OAUTH_SETUP.md`

**Credentials**:
- **Client ID**: Stored in password manager under "Google OAuth Client ID"
- **Client Secret**: Stored in password manager under "Google OAuth Client Secret"

**Storage in Odoo**:
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
provider = env['auth.oauth.provider'].search([('name','=','Google (OMC/TBWA)')], limit=1)

if provider:
    # Update credentials (paste from password manager)
    provider.write({
        'client_id': '<paste-from-password-manager>',
        'client_secret': '<paste-from-password-manager>',
    })
    print("✅ OAuth credentials updated")
PY
```

**Allowed Domains**:
- `omc.com`
- `tbwa-smp.com`

---

## DigitalOcean Credentials

### Personal Access Token

**Purpose**: Deploy OCR service, manage droplets

**Generation**: https://cloud.digitalocean.com/account/api/tokens

**Storage**:
- Password manager: "DigitalOcean Access Token"
- GitHub Secrets: `DO_ACCESS_TOKEN`
- Local: `doctl auth init`

**Set GitHub Secret**:
```bash
gh secret set DO_ACCESS_TOKEN -b "<paste-from-password-manager>"
```

### Registry Access

**Purpose**: Push/pull Docker images from DigitalOcean Container Registry

**Setup**:
```bash
# Login (uses DO_ACCESS_TOKEN)
doctl registry login

# Credentials stored in: ~/.docker/config.json
# For GitHub Actions, use DO_ACCESS_TOKEN secret
```

---

## SSH Keys

### Droplet Access

**Purpose**: Deploy to DigitalOcean droplets via SSH

**Key Location**: `~/.ssh/id_ed25519`

**Public Key** (safe to share):
```bash
cat ~/.ssh/id_ed25519.pub
# Add to DigitalOcean → Settings → Security → SSH Keys
```

**Private Key** (NEVER share):
- Stored securely on local machine
- Encrypted with passphrase
- NOT committed to git
- NOT stored in password manager (too large)

**Add to DigitalOcean**:
```bash
# Upload public key
doctl compute ssh-key create "macbook-pro" --public-key "$(cat ~/.ssh/id_ed25519.pub)"

# Or via web UI:
# https://cloud.digitalocean.com/account/security → Add SSH Key
```

---

## Security Best Practices

### Password Requirements
1. **Minimum length**: 12 characters
2. **Complexity**: Mixed case + numbers + symbols
3. **Uniqueness**: Different password for each service
4. **Rotation**: Change every 90 days
5. **Storage**: Use password manager (1Password, Bitwarden)

### Secret Management Rules
1. ✅ **DO**: Store in password manager
2. ✅ **DO**: Use GitHub Secrets for CI/CD
3. ✅ **DO**: Use environment variables for local dev
4. ✅ **DO**: Rotate regularly (quarterly)
5. ❌ **DON'T**: Commit to git
6. ❌ **DON'T**: Share in Slack/email
7. ❌ **DON'T**: Store in plain text files
8. ❌ **DON'T**: Echo to console/logs

### Emergency Access
If admin password is lost:

**Option 1: Odoo Web Interface** (if email works)
- Navigate to login page
- Click "Reset Password"
- Check email for reset link

**Option 2: Database Shell** (requires server access)
```bash
# Reset admin password via PostgreSQL
docker exec -i postgres psql -U odoo -d insightpulse_prod <<SQL
UPDATE res_users
SET password = crypt('NewTemporaryPassword123!', gen_salt('bf'))
WHERE login = 'jgtolentino_rn@yahoo.com';
SQL

# Login with temporary password, then change via UI
```

**Option 3: Docker Shell** (last resort)
```bash
docker exec -it odoo18 odoo shell -d insightpulse_prod
>>> env = env.sudo()
>>> admin = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')], limit=1)
>>> admin.password = 'NewTemporaryPassword123!'
>>> print("Password reset successful")
```

---

## Credential Rotation Schedule

| Credential | Rotation Frequency | Last Rotated | Next Rotation |
|------------|-------------------|--------------|---------------|
| Admin Password | 90 days | - | - |
| Odoo API Key | 180 days | - | - |
| OpenAI API Key | Annually | - | - |
| MCP Admin Token | 180 days | - | - |
| Database Password | 90 days | - | - |
| DO Access Token | 180 days | - | - |
| OAuth Client Secret | Annually | - | - |

**Automated Rotation**:
Use `scripts/ROTATION_QUICK_START_SECURE.sh` for guided rotation process.

---

## Audit Log

Track all credential changes:

```bash
# View recent credential updates
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()

# Check API key generation
api_keys = env['res.users.apikeys'].search([], order='create_date desc', limit=10)
for key in api_keys:
    print(f"{key.create_date}: {key.user_id.name} - {key.name}")

# Check password changes (if auditlog module installed)
if 'auditlog.log' in env:
    password_changes = env['auditlog.log'].search([
        ('model_id.model', '=', 'res.users'),
        ('method', '=', 'write'),
        ('field', '=', 'password')
    ], order='create_date desc', limit=10)

    for log in password_changes:
        print(f"{log.create_date}: {log.user_id.name} changed password for {log.res_id}")
PY
```

---

**Remember**: Credentials are the keys to your kingdom. Treat them with utmost security!
