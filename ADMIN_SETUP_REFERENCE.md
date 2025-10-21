# Admin Setup Quick Reference

**For**: Production Odoo deployment at `https://insightpulseai.net`

---

## Admin Account

- **Email**: `jgtolentino_rn@yahoo.com`
- **Database**: `insightpulse_prod`
- **Password**: Use the password from your password manager
  - **Format recommendation**: `<Word>_<Number>` (e.g., `Postgres_26`)
  - **Security**: Minimum 12 characters, mixed case recommended
  - **Storage**: Store in password manager under "Odoo Production Admin"

---

## First-Time Setup

### 1. Set Admin Password

**During Database Creation**:
```bash
docker exec -it odoo18 odoo -d insightpulse_prod \
  --without-demo=all \
  --stop-after-init

# When prompted:
# Email: jgtolentino_rn@yahoo.com
# Password: <your-secure-password>
# Language: English
# Country: United States
```

**Reset Existing Password**:
```bash
./scripts/reset_admin_password.sh

# Follow prompts:
# Database: insightpulse_prod
# Email: jgtolentino_rn@yahoo.com
# Password: <hidden-input>
```

### 2. Generate API Key

For CI/CD integration with SuperClaude:

```bash
# Login to Odoo
# Navigate to: Settings → Users & Companies → Users
# Select: jgtolentino_rn@yahoo.com
# Click: Edit → API Keys section → Generate API Key
# Copy immediately (shown only once)

# Set GitHub secret
gh secret set ODOO_API_KEY -b "<paste-api-key-here>"
```

### 3. Bootstrap SuperClaude System

```bash
export ODOO_URL="https://insightpulseai.net"
export ODOO_DB="insightpulse_prod"
export ODOO_ADMIN_EMAIL="jgtolentino_rn@yahoo.com"
export ODOO_API_KEY="<from-step-2>"
export REPO="jgtolentino/odoboo-workspace"

./scripts/bootstrap_superclaude.sh
```

This creates:
- CI/CD Pipeline project (8 stages)
- Custom fields (x_pr_number, x_build_status, x_env, etc.)
- #ci-updates Discuss channel
- GitHub secrets configuration

---

## Quick Commands

### Login to Odoo
```
URL: https://insightpulseai.net
Email: jgtolentino_rn@yahoo.com
Password: <from-password-manager>
```

### Reset Password
```bash
./scripts/reset_admin_password.sh
```

### Generate New API Key
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
admin = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')], limit=1)
new_key = admin._generate_api_key()
print(f"New API key: {new_key}")
print("⚠️  Copy immediately - shown only once!")
PY
```

### Verify Admin Access
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
admin = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')], limit=1)
print(f"User: {admin.name}")
print(f"Email: {admin.login}")
print(f"Active: {admin.active}")
print(f"Admin: {admin.has_group('base.group_system')}")
print(f"Groups: {', '.join(admin.groups_id.mapped('name'))}")
PY
```

---

## Security Checklist

Before going to production:

- [ ] Admin password set and stored in password manager
- [ ] Database master password set (via /web/database/manager)
- [ ] `dbfilter = ^insightpulse_prod$` in odoo.conf
- [ ] `list_db = False` in odoo.conf (hides database manager)
- [ ] API key generated and set in GitHub secrets
- [ ] Two-factor authentication enabled (Settings → Users → 2FA)
- [ ] OAuth configured for corporate SSO (see docs/ODOO_OAUTH_SETUP.md)
- [ ] Email notifications configured (Settings → Email → Outgoing Mail)
- [ ] SSL/TLS certificate valid (check https://insightpulseai.net)
- [ ] Backup automation configured (cron job for scripts/backup_odoo.sh)
- [ ] Staging database created (insightpulse_stage)

---

## Troubleshooting

### Can't login with admin credentials

**Check user exists**:
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
users = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')])
print(f"Found {len(users)} user(s)")
for u in users:
    print(f"  ID: {u.id}, Active: {u.active}, Name: {u.name}")
PY
```

**Reset password**:
```bash
./scripts/reset_admin_password.sh
```

### API key not working

**Check existing keys**:
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
admin = env['res.users'].search([('login','=','jgtolentino_rn@yahoo.com')], limit=1)
keys = env['res.users.apikeys'].search([('user_id','=',admin.id)])
print(f"Active API keys: {len(keys)}")
for key in keys:
    print(f"  Name: {key.name}, Created: {key.create_date}")
PY
```

**Generate new key**:
```bash
# Via UI: Settings → Users → API Keys → Generate
# Or via shell (see "Generate New API Key" above)
```

### Database locked / Can't access

**Check dbfilter**:
```bash
docker exec odoo18 cat /etc/odoo/odoo.conf | grep dbfilter
# Should show: dbfilter = ^insightpulse_prod$
```

**Unlock database manager** (temporarily):
```bash
# Edit odoo.conf
docker exec -it odoo18 bash
nano /etc/odoo/odoo.conf

# Change:
# list_db = False
# To:
# list_db = True

# Restart
docker restart odoo18

# After fixes, set back to False
```

---

## Related Documentation

- **Full production setup**: `docs/PRODUCTION_SETUP.md`
- **Credentials management**: `docs/CREDENTIALS.md`
- **SuperClaude bootstrap**: `scripts/bootstrap_superclaude.sh`
- **Smoke tests**: `docs/SUPERCLAUDE_SMOKE_TEST.md`
- **OAuth setup**: `docs/ODOO_OAUTH_SETUP.md`

---

**Last updated**: Auto-generated by bootstrap system
**Maintainer**: Admin (jgtolentino_rn@yahoo.com)
