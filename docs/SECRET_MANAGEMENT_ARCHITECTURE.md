# 🔐 Centralized Secret Management Architecture

**Purpose**: Unified secret management across all platforms with single source of truth

**Last Updated**: 2025-10-20

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     CENTRAL SECRET STORE (Source of Truth)              │
│                                                                          │
│  Option A: Supabase Edge Functions Secrets ← RECOMMENDED (already have) │
│  Option B: HashiCorp Vault                                              │
│  Option C: Doppler.com                                                   │
│  Option D: 1Password Connect                                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
                          ┌─────────┴─────────┐
                          │  Secret Sync CLI   │
                          │   (sync-secrets)   │
                          └─────────┬─────────┘
                                    ↓
        ┌───────────────────────────┼───────────────────────────┐
        ↓                           ↓                           ↓
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│   PRODUCTION  │         │  CI/CD        │         │  LOCAL DEV    │
├───────────────┤         ├───────────────┤         ├───────────────┤
│• Vercel       │         │• GitHub       │         │• .env         │
│• DO App       │         │  Actions      │         │• .zshrc       │
│• Supabase     │         │• GitLab CI    │         │• Docker       │
│  Edge Fns     │         │               │         │  Compose      │
└───────────────┘         └───────────────┘         └───────────────┘
```

---

## 🏗️ Recommended: Supabase Edge Functions as Source of Truth

**Why?**
- ✅ Already using Supabase
- ✅ Free tier available
- ✅ Built-in encryption
- ✅ Accessible via CLI and API
- ✅ Version controlled
- ✅ Access control built-in

**Supabase Secrets Features:**
```bash
# Set secrets for Edge Functions
supabase secrets set SECRET_NAME=value

# List all secrets
supabase secrets list

# Sync secrets from .env file
supabase secrets set --env-file .env.production

# Get secret value (for sync scripts)
supabase secrets get SECRET_NAME
```

**Dashboard:** https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/functions/secrets

---

## 📦 Secret Categories & Distribution

### 1. **Database Secrets** (Supabase PostgreSQL)

| Secret | Supabase Edge Fn | GitHub | Vercel | Local .env | .zshrc |
|--------|-----------------|--------|--------|------------|--------|
| `DATABASE_URL` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `POSTGRES_PASSWORD` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `STAGING_DATABASE_URL` | ✅ | ✅ | ❌ | ✅ | ❌ |
| `PROD_DATABASE_URL` | ✅ | ✅ | ✅ | ❌ | ❌ |

### 2. **API Keys** (Supabase Auth)

| Secret | Supabase Edge Fn | GitHub | Vercel | Local .env | .zshrc |
|--------|-----------------|--------|--------|------------|--------|
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `NEXT_PUBLIC_SUPABASE_URL` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `SUPABASE_JWT_SECRET` | ✅ | ❌ | ✅ | ❌ | ❌ |

### 3. **Infrastructure** (DigitalOcean)

| Secret | Supabase Edge Fn | GitHub | Vercel | Local .env | .zshrc |
|--------|-----------------|--------|--------|------------|--------|
| `DO_ACCESS_TOKEN` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `DO_SPACES_ACCESS_KEY` | ✅ | ❌ | ✅ | ✅ | ❌ |
| `DO_SPACES_SECRET_KEY` | ✅ | ❌ | ✅ | ✅ | ❌ |

### 4. **Application Secrets**

| Secret | Supabase Edge Fn | GitHub | Vercel | Local .env | .zshrc |
|--------|-----------------|--------|--------|------------|--------|
| `INTERNAL_ADMIN_TOKEN` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `NEXTAUTH_SECRET` | ✅ | ❌ | ✅ | ✅ | ❌ |
| `STRIPE_SECRET_KEY` | ✅ | ❌ | ✅ | ❌ | ❌ |

### 5. **Developer Tools** (Local only)

| Secret | Supabase Edge Fn | GitHub | Vercel | Local .env | .zshrc |
|--------|-----------------|--------|--------|------------|--------|
| `GITHUB_TOKEN` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `SUPABASE_ACCESS_TOKEN` | ❌ | ❌ | ❌ | ❌ | ✅ |
| `VERCEL_TOKEN` | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 🔄 Secret Sync Workflow

### **Setup (One-Time)**

```bash
# 1. Install dependencies
brew install supabase/tap/supabase
brew install gh
brew install vercel

# 2. Authenticate with all platforms
supabase login
gh auth login
vercel login

# 3. Set up central secret store
./scripts/secrets/setup-central-store.sh

# 4. Initial sync from existing secrets
./scripts/secrets/sync-secrets.sh --init
```

### **Daily Usage**

```bash
# Update a secret everywhere
./scripts/secrets/update-secret.sh DATABASE_URL "new-value"

# Sync all secrets (after rotation)
./scripts/secrets/sync-secrets.sh --all

# Pull latest secrets to local
./scripts/secrets/pull-secrets.sh
```

### **Rotation**

```bash
# Rotate a specific secret across ALL platforms
./scripts/secrets/rotate-secret.sh DATABASE_URL

# This will:
# 1. Prompt for new value
# 2. Update Supabase Edge Functions
# 3. Sync to GitHub Secrets
# 4. Sync to Vercel
# 5. Update local .env
# 6. Test connections
# 7. Create audit log
```

---

## 🛠️ Implementation Plan

### **Phase 1: Central Store Setup**

**Option A: Supabase Edge Functions** (Recommended)

```bash
# scripts/secrets/setup-supabase-secrets.sh

#!/bin/bash
set -e

echo "Setting up Supabase as central secret store..."

# Login to Supabase
supabase login

# Link to project
supabase link --project-ref spdtwktxdalcfigzeqrz

# Import secrets from .env.sample
supabase secrets set --env-file .env.production

# Verify
supabase secrets list

echo "✅ Supabase secrets configured!"
```

**Option B: HashiCorp Vault** (Enterprise)

```bash
# Docker Compose for local Vault
services:
  vault:
    image: vault:latest
    ports:
      - "8200:8200"
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: root
    cap_add:
      - IPC_LOCK
```

**Option C: Doppler** (SaaS)

```bash
# Install Doppler CLI
brew install dopplerhq/cli/doppler

# Login
doppler login

# Setup project
doppler setup --project odoboo-workspace --config production
```

---

### **Phase 2: Sync Scripts**

Create unified CLI tool: `scripts/secrets/sync-secrets.sh`

```bash
#!/bin/bash
# Central secret management CLI

COMMAND=$1
SECRET_NAME=$2
SECRET_VALUE=$3

case $COMMAND in
  pull)
    # Pull from Supabase to local
    ./scripts/secrets/pull-from-supabase.sh
    ;;

  push)
    # Push from local to all platforms
    ./scripts/secrets/push-to-all.sh
    ;;

  update)
    # Update specific secret everywhere
    ./scripts/secrets/update-secret.sh "$SECRET_NAME" "$SECRET_VALUE"
    ;;

  rotate)
    # Interactive rotation
    ./scripts/secrets/rotate-secret.sh "$SECRET_NAME"
    ;;

  sync)
    # Sync Supabase → all platforms
    ./scripts/secrets/sync-to-github.sh
    ./scripts/secrets/sync-to-vercel.sh
    ./scripts/secrets/sync-to-local.sh
    ;;

  verify)
    # Test all connections
    ./scripts/secrets/verify-secrets.sh
    ;;

  *)
    echo "Usage: sync-secrets.sh {pull|push|update|rotate|sync|verify}"
    exit 1
    ;;
esac
```

---

### **Phase 3: Platform Integrations**

#### **A. GitHub Secrets**

```bash
# scripts/secrets/sync-to-github.sh

#!/bin/bash
set -e

echo "Syncing secrets to GitHub Actions..."

# Get secrets from Supabase
SECRETS=$(supabase secrets list --format json)

# Parse and set each secret
echo "$SECRETS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
  # Filter: only sync CI/CD secrets
  if [[ $key =~ ^(DATABASE_URL|SUPABASE_|GITHUB_|INTERNAL_) ]]; then
    echo "Setting $key..."
    gh secret set "$key" -b "$value" -R jgtolentino/odoboo-workspace
  fi
done

echo "✅ GitHub Secrets synced!"
```

#### **B. Vercel Environment Variables**

```bash
# scripts/secrets/sync-to-vercel.sh

#!/bin/bash
set -e

echo "Syncing secrets to Vercel..."

PROJECT_ID="your-vercel-project-id"

# Get secrets from Supabase
SECRETS=$(supabase secrets list --format json)

# Parse and set each secret
echo "$SECRETS" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
  # Filter: only sync production secrets
  if [[ $key =~ ^(NEXT_PUBLIC_|DATABASE_URL|SUPABASE_) ]]; then
    echo "Setting $key in Vercel production..."

    # Remove old value
    vercel env rm "$key" production --yes 2>/dev/null || true

    # Add new value
    echo "$value" | vercel env add "$key" production
  fi
done

echo "✅ Vercel secrets synced!"
```

#### **C. Docker Secrets**

```bash
# scripts/secrets/sync-to-docker.sh

#!/bin/bash
set -e

echo "Syncing secrets to Docker..."

# Create .env file for Docker Compose
supabase secrets list --format dotenv > .env.docker

# Create Docker secrets (for Swarm mode)
cat .env.docker | while IFS='=' read -r key value; do
  if [[ $key =~ ^(DATABASE_URL|ODOO_|POSTGRES_) ]]; then
    echo "$value" | docker secret create "${key,,}" - 2>/dev/null || \
      docker secret rm "${key,,}" && echo "$value" | docker secret create "${key,,}" -
  fi
done

echo "✅ Docker secrets synced!"
```

#### **D. Local .zshrc**

```bash
# scripts/secrets/sync-to-zshrc.sh

#!/bin/bash
set -e

echo "Syncing developer secrets to .zshrc..."

ZSHRC="$HOME/.zshrc"
MARKER="# === ODOBOO SECRETS (managed by sync-secrets) ==="

# Remove old section
sed -i.bak "/$MARKER/,/# === END ODOBOO SECRETS ===/d" "$ZSHRC"

# Add new section
cat >> "$ZSHRC" << 'EOF'
# === ODOBOO SECRETS (managed by sync-secrets) ===
# DO NOT EDIT MANUALLY - Use sync-secrets.sh to update

# Developer Tokens (CLI access)
export SUPABASE_ACCESS_TOKEN="your-supabase-token"
export GITHUB_TOKEN="your-github-token"
export VERCEL_TOKEN="your-vercel-token"
export DO_ACCESS_TOKEN="your-do-token"

# Helper aliases
alias odoboo-pull="cd ~/odoboo-workspace && ./scripts/secrets/pull-secrets.sh"
alias odoboo-sync="cd ~/odoboo-workspace && ./scripts/secrets/sync-secrets.sh sync"
alias odoboo-db="psql \$DATABASE_URL"

# === END ODOBOO SECRETS ===
EOF

echo "✅ .zshrc updated! Run: source ~/.zshrc"
```

---

## 🔒 Security Best Practices

### **1. Secret Hierarchy**

```bash
# Least privileged access
LOCAL_DEV:    Can read all secrets (for development)
GITHUB_CI:    Can read CI/CD secrets only
VERCEL_PROD:  Can read production secrets only
EDGE_FN:      Can read function-specific secrets only
```

### **2. Encryption at Rest**

```bash
# All secrets encrypted in Supabase
# - AES-256 encryption
# - Encrypted in PostgreSQL
# - TLS in transit

# For local .env (optional):
brew install git-crypt
git-crypt init
echo ".env" >> .gitattributes
git-crypt add-gpg-user your@email.com
```

### **3. Audit Logging**

```bash
# scripts/secrets/audit-log.sh

LOG_FILE="$HOME/.odoboo/secret-audit.log"

log_secret_access() {
  local action=$1
  local secret=$2
  local user=${USER}
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "$timestamp|$user|$action|$secret" >> "$LOG_FILE"
}

# Usage in sync scripts:
log_secret_access "ROTATED" "DATABASE_URL"
log_secret_access "SYNCED_TO_GITHUB" "SUPABASE_SERVICE_ROLE_KEY"
```

### **4. Secret Rotation Schedule**

```yaml
# .github/workflows/secret-rotation-reminder.yml
name: Secret Rotation Reminder

on:
  schedule:
    - cron: '0 0 1 */3 *'  # Every 3 months

jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
      - name: Create issue
        run: |
          gh issue create \
            --title "🔐 Quarterly Secret Rotation Due" \
            --body "Time to rotate all secrets. Run: ./scripts/secrets/rotate-all.sh"
```

---

## 📋 Quick Reference

### **Common Commands**

```bash
# Pull latest secrets from Supabase to local
./scripts/secrets/pull-secrets.sh

# Update a secret everywhere
./scripts/secrets/update-secret.sh DATABASE_URL "new-value"

# Rotate a secret (interactive)
./scripts/secrets/rotate-secret.sh SUPABASE_SERVICE_ROLE_KEY

# Sync Supabase → all platforms
./scripts/secrets/sync-secrets.sh sync

# Verify all connections work
./scripts/secrets/verify-secrets.sh

# View audit log
tail -f ~/.odoboo/secret-audit.log
```

### **Platform-Specific**

```bash
# Supabase Edge Functions
supabase secrets list
supabase secrets set SECRET_NAME=value
supabase secrets get SECRET_NAME

# GitHub Actions
gh secret list
gh secret set SECRET_NAME -b "value"
gh secret remove SECRET_NAME

# Vercel
vercel env ls
vercel env add SECRET_NAME production
vercel env rm SECRET_NAME production

# Docker
docker secret ls
echo "value" | docker secret create secret_name -
docker secret inspect secret_name
```

---

## 🚀 Getting Started

### **Step 1: Setup**

```bash
# Clone and navigate
cd /path/to/odoboo-workspace

# Make scripts executable
chmod +x scripts/secrets/*.sh

# Setup Supabase as central store
./scripts/secrets/setup-supabase-secrets.sh
```

### **Step 2: Initial Sync**

```bash
# Import existing secrets to Supabase
supabase secrets set --env-file .env.production

# Verify
supabase secrets list

# Sync to all platforms
./scripts/secrets/sync-secrets.sh --init
```

### **Step 3: Verify**

```bash
# Test all connections
./scripts/secrets/verify-secrets.sh

# Expected output:
# ✅ Database connection: OK
# ✅ Supabase API: OK
# ✅ GitHub CLI: OK
# ✅ Vercel CLI: OK
# ✅ Docker: OK
```

---

## 📚 Next Steps

1. **Implement scripts** in `scripts/secrets/` directory
2. **Test sync workflow** in staging
3. **Document team onboarding** (how to pull secrets)
4. **Setup rotation reminders** (quarterly)
5. **Monitor audit logs** for suspicious activity

---

**Document Version**: 1.0
**Last Updated**: 2025-10-20
**Maintained By**: DevOps Team
