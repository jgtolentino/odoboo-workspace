# Odoo OAuth Setup for Corporate Domains

**Domains Allowed**: `@omc.com`, `@tbwa-smp.com`

This guide sets up Google OAuth for Odoo with strict domain restrictions, ensuring only corporate email addresses can access the system.

---

## Quick Setup (5 Minutes)

### 1. Google Cloud OAuth Configuration

**Create OAuth Client** (Google Cloud Console):

1. Go to: https://console.cloud.google.com/apis/credentials
2. Create credentials → OAuth 2.0 Client ID
3. Application type: **Web application**
4. Name: `Odoo Production (insightpulseai.net)`

**Authorized redirect URIs** (Required):
```
https://insightpulseai.net/auth_oauth/signin
https://staging.insightpulseai.net/auth_oauth/signin
http://localhost:8069/auth_oauth/signin
```

**Authorized JavaScript origins** (Optional, if you have SPA):
```
https://insightpulseai.net
```

**OAuth consent screen**:
- User type: **External** (or **Internal** if project is in OMC Workspace)
- Authorized domains: `insightpulseai.net`
- Scopes: `openid`, `email`, `profile`
- **Publish the app** (move from Testing to Production)

**Save**:
- Client ID: `123456789-abc...apps.googleusercontent.com`
- Client Secret: `GOCSPX-...`

---

### 2. Configure Odoo OAuth Provider

#### Option A: Via Odoo UI

1. **Install OAuth module**:
   - Settings → General Settings → Integrations
   - Check "OAuth Authentication" → Save

2. **Configure Google provider**:
   - Settings → Users & Companies → OAuth Providers
   - Click "Google" (or create new)
   - Fill in:
     - **Name**: Google (OMC/TBWA)
     - **Client ID**: `<YOUR_CLIENT_ID>`
     - **Client Secret**: `<YOUR_CLIENT_SECRET>`
     - **Enabled**: ✅
     - **Auth endpoint**: `https://accounts.google.com/o/oauth2/v2/auth?hd=omc.com`
     - **Validation endpoint**: `https://oauth2.googleapis.com/tokeninfo`
     - **Data endpoint**: `https://openidconnect.googleapis.com/v1/userinfo`
     - **Scope**: `openid email profile`
     - **Body**: (leave empty)

3. **Save**

#### Option B: Via CLI (Faster)

Run this script:

```bash
docker exec -it odoo18 odoo shell -d odoboo_prod <<'PY'
# Allowed email domains
ALLOWED_DOMAINS = ['omc.com', 'tbwa-smp.com']

# OAuth provider configuration
provider_vals = {
    'name': 'Google (OMC/TBWA)',
    'enabled': True,
    'client_id': '<YOUR_GOOGLE_CLIENT_ID>',
    'client_secret': '<YOUR_GOOGLE_CLIENT_SECRET>',
    'auth_endpoint': 'https://accounts.google.com/o/oauth2/v2/auth?hd=omc.com',
    'validation_endpoint': 'https://oauth2.googleapis.com/tokeninfo',
    'data_endpoint': 'https://openidconnect.googleapis.com/v1/userinfo',
    'scope': 'openid email profile',
}

# Get or create provider
provider = env['auth.oauth.provider'].search([('name', 'ilike', 'Google')], limit=1)

if provider:
    provider.write(provider_vals)
    print(f"✅ Updated OAuth provider: {provider.name}")
else:
    provider = env['auth.oauth.provider'].create(provider_vals)
    print(f"✅ Created OAuth provider: {provider.name}")

# Set allowed email domains (for enforcement module)
env['ir.config_parameter'].sudo().set_param(
    'auth.allowed_email_domains',
    ','.join(ALLOWED_DOMAINS)
)
print(f"✅ Allowed email domains: {', '.join(ALLOWED_DOMAINS)}")

env.cr.commit()
PY
```

---

## Domain Restriction Enforcement

To **hard-enforce** domain restrictions (prevent non-corporate emails), install a custom module.

### Custom Module: `auth_domain_guard`

**File**: `addons/auth_domain_guard/__manifest__.py`

```python
{
    'name': 'OAuth Domain Guard',
    'version': '18.0.1.0.0',
    'category': 'Authentication',
    'summary': 'Restrict OAuth logins to allowed email domains',
    'description': """
        Enforces email domain allowlist for OAuth authentication.
        Only users from allowed domains can sign in.
    """,
    'author': 'InsightPulseAI',
    'depends': ['auth_oauth'],
    'data': [
        'data/config_parameters.xml',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
```

**File**: `addons/auth_domain_guard/controllers/main.py`

```python
# -*- coding: utf-8 -*-
from odoo import http
from odoo.http import request
from odoo.addons.auth_oauth.controllers.main import OAuthLogin
from werkzeug.exceptions import Forbidden
import logging

_logger = logging.getLogger(__name__)


class DomainGuardOAuthLogin(OAuthLogin):
    """
    OAuth login controller with email domain restriction.

    Only allows sign-in from pre-approved corporate email domains.
    """

    def _get_allowed_domains(self):
        """Get allowed email domains from system parameters"""
        ICP = request.env['ir.config_parameter'].sudo()
        domains_str = ICP.get_param('auth.allowed_email_domains', 'omc.com,tbwa-smp.com')

        # Parse and clean domains
        domains = [d.strip().lower() for d in domains_str.split(',') if d.strip()]

        if not domains:
            _logger.warning("No allowed email domains configured!")

        return domains

    def _is_email_allowed(self, email):
        """Check if email domain is in allowlist"""
        if not email:
            return False

        email = email.lower().strip()
        allowed_domains = self._get_allowed_domains()

        for domain in allowed_domains:
            if email.endswith(f'@{domain}'):
                return True

        return False

    def _signup_from_oauth(self, provider, validation, params):
        """
        Override OAuth signup to enforce domain restrictions.

        Raises Forbidden if email domain is not in allowlist.
        """
        email = validation.get('email', '').lower().strip()

        if not self._is_email_allowed(email):
            allowed_domains = self._get_allowed_domains()
            _logger.warning(
                f"OAuth login rejected: {email} not in allowed domains "
                f"({', '.join(allowed_domains)})"
            )

            raise Forbidden(
                f"Access denied. Only users from authorized domains "
                f"({', '.join(allowed_domains)}) can sign in."
            )

        _logger.info(f"OAuth login allowed: {email}")

        return super()._signup_from_oauth(provider, validation, params)

    def _signin(self, *args, **kwargs):
        """
        Override signin to also check domain on existing users.
        """
        # Call parent signin
        result = super()._signin(*args, **kwargs)

        # Additional check for existing users
        user = request.env.user
        if user and user.login and not self._is_email_allowed(user.login):
            _logger.warning(f"Existing user with disallowed domain: {user.login}")
            # Don't block existing users, just log (for migration period)

        return result
```

**File**: `addons/auth_domain_guard/data/config_parameters.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="1">
        <!-- Default allowed email domains -->
        <record id="auth_allowed_email_domains" model="ir.config_parameter">
            <field name="key">auth.allowed_email_domains</field>
            <field name="value">omc.com,tbwa-smp.com</field>
        </record>
    </data>
</odoo>
```

**File**: `addons/auth_domain_guard/__init__.py`

```python
# -*- coding: utf-8 -*-
from . import controllers
```

**File**: `addons/auth_domain_guard/controllers/__init__.py`

```python
# -*- coding: utf-8 -*-
from . import main
```

---

### Install the Module

```bash
# Copy module to addons directory
docker cp addons/auth_domain_guard odoo18:/mnt/extra-addons/

# Install module
docker exec -it odoo18 odoo -d odoboo_prod -i auth_domain_guard --stop-after-init

# Restart Odoo
docker-compose restart odoo
```

Or via UI:
1. Apps → Update Apps List
2. Search: "OAuth Domain Guard"
3. Install

---

## User Management

### Add Khalil Veracruz

#### Via UI:
1. Settings → Users & Companies → Users
2. Create
3. Fill:
   - Name: `Khalil Veracruz`
   - Email: `khalil.veracruz@tbwa-smp.com`
   - Access Rights: (select groups)
4. Save

#### Via CLI:
```bash
docker exec -it odoo18 odoo shell -d odoboo_prod <<'PY'
# Create user
user = env['res.users'].create({
    'name': 'Khalil Veracruz',
    'login': 'khalil.veracruz@tbwa-smp.com',
    'email': 'khalil.veracruz@tbwa-smp.com',
    'groups_id': [(6, 0, [
        env.ref('base.group_user').id,  # Employee
        env.ref('base.group_portal').id,  # Portal (if external)
    ])],
})

print(f"✅ Created user: {user.name} ({user.login})")
env.cr.commit()
PY
```

### Auto-provision users

If you want **automatic user creation** on first OAuth login:

Settings → General Settings → Integrations → OAuth:
- ✅ **Allow users to sign up**
- Default user template: (select a template user)

**Security**: Only users from allowed domains can sign up (enforced by module).

---

## Nginx/Proxy Configuration

Ensure your Nginx passes the correct headers for OAuth callbacks:

```nginx
location / {
    proxy_pass http://odoo18:8069;

    # Required for OAuth
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;

    # Timeouts
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
}
```

---

## Testing

### 1. Test OAuth Login

1. Go to: https://insightpulseai.net/web/login
2. Click "Sign in with Google (OMC/TBWA)"
3. Select Google account

**Expected**:
- ✅ `khalil.veracruz@tbwa-smp.com` → Login succeeds
- ✅ `user@omc.com` → Login succeeds
- ❌ `user@gmail.com` → Forbidden (403)

### 2. Test via cURL

```bash
# Check login page loads
curl -I https://insightpulseai.net/web/login

# Check OAuth endpoint exists
curl -I https://insightpulseai.net/auth_oauth/signin

# Both should return 200 or 303
```

### 3. Check Logs

```bash
# Watch Odoo logs during OAuth attempt
docker logs -f odoo18 | grep -i oauth

# Look for:
# - "OAuth login allowed: khalil.veracruz@tbwa-smp.com"
# - "OAuth login rejected: user@gmail.com not in allowed domains"
```

---

## Corporate SSO Alternative (Okta/Azure AD)

If OMC uses corporate SSO (Okta/Azure AD) instead of Google:

### 1. Install OCA OIDC Module

```bash
# Download OCA auth_oidc
git clone -b 18.0 --depth 1 https://github.com/OCA/server-auth.git oca-server-auth
docker cp oca-server-auth/auth_oidc odoo18:/mnt/extra-addons/

# Install
docker exec -it odoo18 odoo -d odoboo_prod -i auth_oidc --stop-after-init
docker-compose restart odoo
```

### 2. Configure OIDC Provider

Get from OMC IT:
- Discovery URL (e.g., `https://login.microsoftonline.com/<tenant>/v2.0/.well-known/openid-configuration`)
- Client ID
- Client Secret

Settings → Users & Companies → OIDC Providers:
- **Name**: Omnicom SSO
- **Discovery URL**: `<from IT>`
- **Client ID**: `<from IT>`
- **Client Secret**: `<from IT>`
- **Scope**: `openid email profile`
- **Redirect URI**: `https://insightpulseai.net/auth_oauth/signin`

**Domain guard module** works the same (enforces `@omc.com`).

---

## Allowed Domains Management

### View Current Allowed Domains

```bash
docker exec -it odoo18 odoo shell -d odoboo_prod <<'PY'
domains = env['ir.config_parameter'].sudo().get_param('auth.allowed_email_domains')
print(f"Allowed domains: {domains}")
PY
```

### Update Allowed Domains

```bash
docker exec -it odoo18 odoo shell -d odoboo_prod <<'PY'
ALLOWED = ['omc.com', 'tbwa-smp.com', 'example.com']  # Add/remove as needed

env['ir.config_parameter'].sudo().set_param(
    'auth.allowed_email_domains',
    ','.join(ALLOWED)
)
print(f"✅ Updated allowed domains: {', '.join(ALLOWED)}")
env.cr.commit()
PY
```

---

## Security Checklist

- [ ] Google OAuth client created with correct redirect URIs
- [ ] OAuth consent screen published (not in Testing mode)
- [ ] Odoo OAuth provider configured with correct Client ID/Secret
- [ ] `auth_domain_guard` module installed
- [ ] Allowed domains configured: `omc.com`, `tbwa-smp.com`
- [ ] Nginx proxy headers configured correctly
- [ ] SSL certificate valid for `insightpulseai.net`
- [ ] Test login with corporate email (should work)
- [ ] Test login with personal email (should fail)
- [ ] Khalil Veracruz user created

---

## Troubleshooting

### Error: "OAuth provider not found"

**Fix**: Install `auth_oauth` module:
```bash
docker exec -it odoo18 odoo -d odoboo_prod -i auth_oauth --stop-after-init
```

### Error: "redirect_uri_mismatch"

**Fix**: Ensure redirect URI in Google Cloud Console **exactly matches**:
```
https://insightpulseai.net/auth_oauth/signin
```

### Error: "Access denied" for allowed domain

**Fix**: Check allowed domains configuration:
```bash
docker exec -it odoo18 odoo shell -d odoboo_prod <<'PY'
domains = env['ir.config_parameter'].sudo().get_param('auth.allowed_email_domains')
print(f"Current: {domains}")

# Update if needed
env['ir.config_parameter'].sudo().set_param(
    'auth.allowed_email_domains',
    'omc.com,tbwa-smp.com'
)
env.cr.commit()
PY
```

### Login redirects to wrong URL

**Fix**: Check `web.base.url` system parameter:
```bash
docker exec -it odoo18 odoo shell -d odoboo_prod <<'PY'
env['ir.config_parameter'].sudo().set_param('web.base.url', 'https://insightpulseai.net')
env.cr.commit()
PY
```

---

## Quick Reference

**Google OAuth Setup**:
- Redirect URI: `https://insightpulseai.net/auth_oauth/signin`
- Auth endpoint: `https://accounts.google.com/o/oauth2/v2/auth?hd=omc.com`
- Token endpoint: `https://oauth2.googleapis.com/tokeninfo`
- Userinfo endpoint: `https://openidconnect.googleapis.com/v1/userinfo`
- Scopes: `openid email profile`

**Allowed Domains**: `omc.com`, `tbwa-smp.com`

**Test Login**: https://insightpulseai.net/web/login

**Logs**: `docker logs -f odoo18`

---

## Next Steps

1. **Set up Google OAuth** (see Quick Setup above)
2. **Install `auth_domain_guard`** module
3. **Test with Khalil's email**: `khalil.veracruz@tbwa-smp.com`
4. **Add more OMC users** as needed
5. **(Optional)** Switch to corporate SSO if required by IT

---

**Related Documentation**:
- [Odoo Authentication](https://www.odoo.com/documentation/18.0/administration/authentication.html)
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)
- [OCA auth_oidc](https://github.com/OCA/server-auth/tree/18.0/auth_oidc)
