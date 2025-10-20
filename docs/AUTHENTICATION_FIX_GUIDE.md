# 🔐 Authentication Fix Guide

**Purpose**: Resolve all SSH and token authentication issues across platforms

**Last Updated**: 2025-10-20

---

## 🚨 Quick Fix (Run This First)

```bash
# One command to diagnose and fix everything
./scripts/fix-all-auth.sh
```

This script will:
- ✅ Diagnose all authentication issues
- ✅ Clean up broken keys/tokens
- ✅ Guide you through re-authentication
- ✅ Test all connections
- ✅ Create backup of existing configs

---

## 🔍 Manual Diagnosis

### Check SSH Keys

```bash
# List SSH keys
ls -la ~/.ssh/

# Should see:
# id_ed25519       (private key)
# id_ed25519.pub   (public key)
```

### Check GitHub Authentication

```bash
# Test SSH connection
ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated"

# Check GitHub CLI
gh auth status
# Expected: "Logged in to github.com as username"
```

### Check Supabase Authentication

```bash
# Check if authenticated
ls ~/.supabase/access-token

# Test connection
supabase projects list
```

### Check DigitalOcean Authentication

```bash
# Check auth list
doctl auth list

# Test connection
doctl account get
```

### Check Vercel Authentication

```bash
# Check if authenticated
ls ~/.vercel/auth.json

# Test connection
vercel whoami
```

---

## 🛠️ Manual Fixes

### 1. Fix GitHub SSH

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub:
# https://github.com/settings/ssh/new
# Paste the public key
```

**Test:**
```bash
ssh -T git@github.com
```

---

### 2. Fix GitHub CLI

```bash
# Logout (if needed)
gh auth logout

# Login (interactive)
gh auth login

# Choose:
# - GitHub.com
# - HTTPS or SSH
# - Authenticate with browser or token
```

**Test:**
```bash
gh auth status
gh repo list
```

---

### 3. Fix Supabase CLI

```bash
# Install (if not installed)
brew install supabase/tap/supabase  # macOS
# or
npm install -g supabase  # Linux/Windows

# Logout (if needed)
rm ~/.supabase/access-token

# Login (opens browser)
supabase login

# Link to project
supabase link --project-ref spdtwktxdalcfigzeqrz
```

**Test:**
```bash
supabase projects list
supabase secrets list
```

---

### 4. Fix DigitalOcean CLI

```bash
# Install (if not installed)
brew install doctl  # macOS
# or
snap install doctl  # Linux

# Get API token from:
# https://cloud.digitalocean.com/account/api/tokens

# Authenticate
doctl auth init
# Paste token when prompted

# Or non-interactive:
doctl auth init --access-token YOUR_TOKEN
```

**Test:**
```bash
doctl account get
doctl droplet list
```

---

### 5. Fix Vercel CLI

```bash
# Install (if not installed)
npm install -g vercel

# Logout (if needed)
vercel logout

# Login (opens browser)
vercel login
```

**Test:**
```bash
vercel whoami
vercel env ls
```

---

## 🧹 Clean Up Broken Keys

### Remove Old SSH Keys

```bash
# Backup first
cp -r ~/.ssh ~/.ssh.backup

# Remove specific key
rm ~/.ssh/old_key
rm ~/.ssh/old_key.pub

# Remove from SSH agent
ssh-add -D  # Remove all
ssh-add -d ~/.ssh/specific_key  # Remove specific
```

### Remove from GitHub

1. Go to https://github.com/settings/keys
2. Find broken/old keys
3. Click "Delete"

### Remove from DigitalOcean

1. Go to https://cloud.digitalocean.com/account/security
2. Find old SSH keys
3. Click "Delete"

---

## 🔄 Token Rotation (After Cleanup)

After fixing authentication, rotate all tokens:

```bash
# Use the rotation script
./ROTATION_QUICK_START.sh

# Or manually:
# 1. GitHub: https://github.com/settings/tokens
# 2. Supabase: https://supabase.com/dashboard/account/tokens
# 3. DigitalOcean: https://cloud.digitalocean.com/account/api/tokens
# 4. Vercel: https://vercel.com/account/tokens
```

---

## 📋 Common Issues & Solutions

### Issue: "Permission denied (publickey)"

**Cause**: SSH key not added to GitHub or SSH agent not running

**Fix**:
```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key
ssh-add ~/.ssh/id_ed25519

# Verify
ssh -T git@github.com
```

---

### Issue: "Could not resolve hostname github.com"

**Cause**: Network/DNS issue

**Fix**:
```bash
# Test DNS
ping github.com

# Try HTTPS instead of SSH
git remote set-url origin https://github.com/username/repo.git
```

---

### Issue: "gh: command not found"

**Cause**: GitHub CLI not installed

**Fix**:
```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Windows
scoop install gh
```

---

### Issue: "Supabase CLI: Unauthorized"

**Cause**: Not logged in or token expired

**Fix**:
```bash
# Re-login
rm ~/.supabase/access-token
supabase login
```

---

### Issue: "doctl: Unable to authenticate"

**Cause**: Invalid or expired API token

**Fix**:
```bash
# Get new token from:
# https://cloud.digitalocean.com/account/api/tokens

# Re-authenticate
doctl auth init --access-token NEW_TOKEN

# Verify
doctl account get
```

---

## ✅ Verification Checklist

After fixing all authentication:

```bash
# Run verification
./scripts/verify-all-auth.sh

# Or manually test each:

# 1. Git
git fetch
# Should work without password

# 2. GitHub SSH
ssh -T git@github.com
# Should show: "successfully authenticated"

# 3. GitHub CLI
gh repo list
# Should list your repos

# 4. Supabase
supabase projects list
# Should list your projects

# 5. DigitalOcean
doctl account get
# Should show account info

# 6. Vercel
vercel whoami
# Should show your username

# 7. Docker (if using)
docker login registry.digitalocean.com
# Should succeed
```

---

## 🔒 Security Best Practices

### 1. Use SSH Keys (Not Passwords)

```bash
# Generate strong key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Use different keys for different services (optional)
ssh-keygen -t ed25519 -C "github" -f ~/.ssh/id_github
ssh-keygen -t ed25519 -C "digitalocean" -f ~/.ssh/id_digitalocean
```

### 2. Rotate Tokens Regularly

```bash
# Quarterly rotation
# - GitHub tokens: every 90 days
# - DigitalOcean tokens: every 90 days
# - Supabase tokens: every 90 days

# Set calendar reminder
```

### 3. Use Token Expiration

When creating tokens:
- ✅ Set expiration (30-90 days)
- ✅ Use minimum required scopes
- ✅ Create separate tokens for different purposes
- ✅ Document token purpose

### 4. Audit Access

```bash
# Review GitHub SSH keys
# https://github.com/settings/keys

# Review GitHub tokens
# https://github.com/settings/tokens

# Review DigitalOcean tokens
# https://cloud.digitalocean.com/account/api/tokens

# Review Supabase tokens
# https://supabase.com/dashboard/account/tokens
```

---

## 📚 Related Documentation

- [Secret Rotation Checklist](../SECRET_ROTATION_CHECKLIST.md)
- [Secret Management Architecture](./SECRET_MANAGEMENT_ARCHITECTURE.md)
- [GitHub Secrets Setup](./GITHUB_SECRETS_SETUP.md)

---

## 🆘 Still Having Issues?

If authentication issues persist:

1. **Check .ssh/config**:
   ```bash
   cat ~/.ssh/config
   # Should have proper host configurations
   ```

2. **Check git config**:
   ```bash
   git config --list --show-origin
   # Verify user.name and user.email are set
   ```

3. **Check environment variables**:
   ```bash
   env | grep -E "GITHUB|SUPABASE|VERCEL|DO_"
   # Should show CLI tokens
   ```

4. **Check file permissions**:
   ```bash
   # SSH directory should be 700
   chmod 700 ~/.ssh

   # Private keys should be 600
   chmod 600 ~/.ssh/id_*

   # Public keys should be 644
   chmod 644 ~/.ssh/*.pub
   ```

5. **Run the fix script again**:
   ```bash
   ./scripts/fix-all-auth.sh
   ```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-20
**Next Review**: After each authentication rotation
