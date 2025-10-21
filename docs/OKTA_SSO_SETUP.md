# Okta SSO Setup Guide

Complete guide to configure Okta SAML SSO for Odoo.

## Allowed Domains

Okta SSO is configured for:

- `@tbwa-smp.com`
- `@oomc.com`

For @gmail.com users, use Google OAuth or Magic Link instead.

## Prerequisites

- Okta administrator access
- Odoo instance with HTTPS enabled
- Domain: `https://your-odoo-domain.com`

## Setup Steps

### 1. Create SAML App in Okta

1. Log in to **Okta Admin Console**
2. Go to **Applications** > **Applications**
3. Click **Create App Integration**
4. Select **SAML 2.0**
5. Click **Next**

### 2. Configure General Settings

**App name**: Odoo SSO
**App logo**: Upload Odoo logo (optional)

### 3. Configure SAML Settings

**Single sign-on URL**:

```
https://your-odoo-domain.com/auth_saml/signin
```

**Audience URI (SP Entity ID)**:

```
https://your-odoo-domain.com
```

**Name ID format**: `EmailAddress`

**Application username**: `Email`

**Attribute Statements**:
| Name | Value |
|------|-------|
| email | user.email |
| firstName | user.firstName |
| lastName | user.lastName |
| name | user.displayName |

### 4. Assign Users in Okta

1. Go to **Assignments** tab
2. Click **Assign** > **Assign to People**
3. Select users from @tbwa-smp.com or @oomc.com
4. Click **Assign** and **Done**

### 5. Get Okta Metadata URL

1. Go to **Sign On** tab
2. Scroll to **SAML Signing Certificates**
3. Right-click **Metadata URL** and copy link

### 6. Configure Odoo

1. Log in to Odoo as administrator
2. Go to **Settings** > **Integrations** > **SAML Providers**
3. Edit **Okta SSO** provider
4. Paste the **Metadata URL** from Okta
5. Verify **SP Base URL** matches your Odoo domain
6. Click **Save**

### 7. Test SSO

1. Log out of Odoo
2. Click **Sign in with Okta**
3. Enter your @tbwa-smp.com or @oomc.com email
4. Complete Okta authentication
5. You should be logged in to Odoo

## User Auto-Creation

When a user signs in via Okta SSO:

- New Odoo user created automatically
- Email from SAML response
- Name from Okta profile
- Default **User** group assigned

## Security Features

- ✅ SAML 2.0 secure protocol
- ✅ Domain whitelist enforcement
- ✅ Automatic user provisioning
- ✅ Profile attribute sync
- ✅ Session management via Okta

## Troubleshooting

### "Email domain not allowed" Error

**Solution**: Okta SSO only works for @tbwa-smp.com and @oomc.com. Other domains should use different authentication methods.

### "SAML Response Invalid" Error

**Causes**:

- Metadata URL incorrect
- Certificate expired
- Time sync issue between Okta and Odoo

**Solution**: Re-download metadata from Okta and update in Odoo settings.

### User Not Created Automatically

**Checklist**:

- ✅ User assigned to Okta app
- ✅ Email attribute configured in Okta
- ✅ `auth_okta_saml` module installed in Odoo
- ✅ User email domain is @tbwa-smp.com or @oomc.com

### Redirect Loop

**Solution**:

- Clear browser cookies
- Check SP Base URL in Odoo matches exactly
- Verify Okta app's Single sign-on URL is correct

## Advanced Configuration

### Add More Domains

Edit `addons/auth_okta_saml/models/res_users.py`:

```python
ALLOWED_OKTA_DOMAINS = [
    'tbwa-smp.com',
    'oomc.com',
    'your-domain.com',  # Add here
]
```

### Sync Additional Attributes

Modify SAML attribute mapping in Okta:

| Odoo Field | Okta Attribute   |
| ---------- | ---------------- |
| phone      | user.mobilePhone |
| function   | user.title       |
| department | user.department  |

Then update `res_users.py` to map these fields.

### Group/Role Mapping

Configure group mapping in Okta to automatically assign Odoo groups based on Okta group membership.

## Authentication Summary

| Domain        | Method              | Access URL                  |
| ------------- | ------------------- | --------------------------- |
| @tbwa-smp.com | Okta SSO (Primary)  | `/auth_saml/signin/okta`    |
| @tbwa-smp.com | Magic Link (Backup) | `/auth/magic-link-form`     |
| @oomc.com     | Okta SSO (Primary)  | `/auth_saml/signin/okta`    |
| @oomc.com     | Magic Link (Backup) | `/auth/magic-link-form`     |
| @gmail.com    | Google OAuth        | `/auth_oauth/signin/google` |
| @gmail.com    | Magic Link          | `/auth/magic-link-form`     |

## Support

For issues or questions:

- Email: support@insightpulse.ai
- Admin: jgtolentino.rn@gmail.com
- Okta Admin: Contact your IT department
