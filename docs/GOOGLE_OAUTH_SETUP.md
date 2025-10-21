# Google OAuth Setup Guide

This guide explains how to configure Google OAuth authentication for your Odoo instance.

## Allowed Email Domains

The following email domains are allowed for automatic user creation:

- `@tbwa-smp.com`
- `@oomc.com`
- `@gmail.com`

## Setup Steps

### 1. Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. Choose **Web application**
6. Add authorized redirect URIs:
   ```
   https://your-odoo-domain.com/auth_oauth/signin
   ```
7. Copy the **Client ID** and **Client Secret**

### 2. Configure Odoo

1. Log in to Odoo as administrator
2. Go to **Settings** > **Integrations** > **OAuth Authentication**
3. Edit the **Google** provider
4. Paste your **Client ID**
5. Save changes

### 3. Test Authentication

1. Log out of Odoo
2. Click **Sign in with Google** on the login page
3. Select your Google account
4. Grant permissions
5. You should be logged in to Odoo automatically

## User Auto-Creation

When a user from an allowed domain signs in with Google OAuth:

- A new Odoo user is automatically created
- Default permissions: **User** group
- Profile information is synced from Google

## Security Features

- ✅ Domain whitelist enforcement
- ✅ OAuth 2.0 secure flow
- ✅ Automatic token refresh
- ✅ Profile picture sync
- ✅ Email verification via Google

## Troubleshooting

### "Email domain not allowed" Error

**Solution**: Ensure your email ends with @tbwa-smp.com, @oomc.com, or @gmail.com

### "Redirect URI mismatch" Error

**Solution**: Verify the redirect URI in Google Console matches your Odoo domain exactly

### User Not Created Automatically

**Solution**: Check that the `auth_google_oauth` module is installed and enabled

## Additional Configuration

### Add More Allowed Domains

Edit `addons/auth_google_oauth/models/res_users.py`:

```python
ALLOWED_GOOGLE_DOMAINS = [
    'tbwa-smp.com',
    'oomc.com',
    'gmail.com',
    'your-domain.com',  # Add your domain here
]
```

### Change Default User Permissions

Edit the `_generate_signup_values` method in `res_users.py` to assign different groups.

## Support

For issues or questions:

- Email: support@insightpulse.ai
- Admin: jgtolentino.rn@gmail.com
