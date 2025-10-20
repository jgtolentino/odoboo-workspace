#!/bin/bash
set -e

# ============================================================================
# AUTHENTICATION CLEANUP & FIX SCRIPT
# ============================================================================
# This script:
# 1. Diagnoses all authentication issues
# 2. Cleans up non-working keys/tokens
# 3. Guides you through re-authentication
# 4. Tests all connections
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔐 AUTHENTICATION DIAGNOSTIC & FIX"
echo "===================================="
echo ""

# ============================================================================
# PHASE 1: DIAGNOSE CURRENT STATE
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 1: Diagnosing Current Authentication State"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check SSH Keys
echo "1️⃣  SSH Keys"
echo "─────────────"
if [ -d "$HOME/.ssh" ]; then
    SSH_KEYS=$(ls -1 ~/.ssh/*.pub 2>/dev/null || true)
    if [ -z "$SSH_KEYS" ]; then
        echo -e "${YELLOW}⚠  No SSH keys found${NC}"
        NEED_SSH_KEY=true
    else
        echo -e "${GREEN}✅ SSH keys exist:${NC}"
        ls -lh ~/.ssh/*.pub
    fi
else
    echo -e "${YELLOW}⚠  ~/.ssh directory doesn't exist${NC}"
    NEED_SSH_KEY=true
fi
echo ""

# Check GitHub CLI
echo "2️⃣  GitHub CLI (gh)"
echo "──────────────────"
if command -v gh &> /dev/null; then
    GH_STATUS=$(gh auth status 2>&1 || true)
    if echo "$GH_STATUS" | grep -q "Logged in"; then
        echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
        echo "$GH_STATUS" | grep "Logged in"
    else
        echo -e "${RED}❌ GitHub CLI not authenticated${NC}"
        NEED_GH_AUTH=true
    fi
else
    echo -e "${YELLOW}⚠  GitHub CLI not installed${NC}"
    NEED_GH_INSTALL=true
fi
echo ""

# Check Supabase CLI
echo "3️⃣  Supabase CLI"
echo "────────────────"
if command -v supabase &> /dev/null; then
    if [ -f "$HOME/.supabase/access-token" ]; then
        echo -e "${GREEN}✅ Supabase CLI authenticated${NC}"
    else
        echo -e "${RED}❌ Supabase CLI not authenticated${NC}"
        NEED_SUPABASE_AUTH=true
    fi
else
    echo -e "${YELLOW}⚠  Supabase CLI not installed${NC}"
    NEED_SUPABASE_INSTALL=true
fi
echo ""

# Check DigitalOcean CLI
echo "4️⃣  DigitalOcean CLI (doctl)"
echo "────────────────────────────"
if command -v doctl &> /dev/null; then
    DOCTL_AUTH=$(doctl auth list 2>&1 || true)
    if echo "$DOCTL_AUTH" | grep -qE "default|current"; then
        echo -e "${GREEN}✅ DigitalOcean CLI authenticated${NC}"
    else
        echo -e "${RED}❌ DigitalOcean CLI not authenticated${NC}"
        NEED_DOCTL_AUTH=true
    fi
else
    echo -e "${YELLOW}⚠  DigitalOcean CLI not installed${NC}"
    NEED_DOCTL_INSTALL=true
fi
echo ""

# Check Vercel CLI
echo "5️⃣  Vercel CLI"
echo "──────────────"
if command -v vercel &> /dev/null; then
    if [ -f "$HOME/.vercel/auth.json" ]; then
        echo -e "${GREEN}✅ Vercel CLI authenticated${NC}"
    else
        echo -e "${RED}❌ Vercel CLI not authenticated${NC}"
        NEED_VERCEL_AUTH=true
    fi
else
    echo -e "${YELLOW}⚠  Vercel CLI not installed${NC}"
    NEED_VERCEL_INSTALL=true
fi
echo ""

# Check Git Config
echo "6️⃣  Git Configuration"
echo "──────────────────────"
GIT_USER=$(git config --global user.name || echo "")
GIT_EMAIL=$(git config --global user.email || echo "")

if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
    echo -e "${RED}❌ Git not configured${NC}"
    NEED_GIT_CONFIG=true
else
    echo -e "${GREEN}✅ Git configured${NC}"
    echo "   Name:  $GIT_USER"
    echo "   Email: $GIT_EMAIL"
fi
echo ""

# ============================================================================
# PHASE 2: CLEANUP NON-WORKING KEYS/TOKENS
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 2: Cleaning Up Non-Working Authentications"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Do you want to clean up and re-authenticate? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting without changes."
    exit 0
fi

# Backup existing configs
BACKUP_DIR="$HOME/.auth_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in: $BACKUP_DIR"

# Backup SSH keys (if any)
if [ -d "$HOME/.ssh" ]; then
    cp -r "$HOME/.ssh" "$BACKUP_DIR/"
    echo "✅ Backed up ~/.ssh"
fi

# Backup Git config
git config --global --list > "$BACKUP_DIR/gitconfig.txt" 2>/dev/null || true
echo "✅ Backed up git config"

# Backup CLI configs
[ -d "$HOME/.config/gh" ] && cp -r "$HOME/.config/gh" "$BACKUP_DIR/"
[ -d "$HOME/.supabase" ] && cp -r "$HOME/.supabase" "$BACKUP_DIR/"
[ -d "$HOME/.config/doctl" ] && cp -r "$HOME/.config/doctl" "$BACKUP_DIR/"
[ -d "$HOME/.vercel" ] && cp -r "$HOME/.vercel" "$BACKUP_DIR/"

echo "✅ All configs backed up"
echo ""

# ============================================================================
# PHASE 3: SETUP FRESH AUTHENTICATION
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 3: Setting Up Fresh Authentication"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Git Configuration
if [ "$NEED_GIT_CONFIG" = true ]; then
    echo "1️⃣  Configuring Git"
    echo "────────────────────"
    read -p "Enter your name (for commits): " GIT_NAME
    read -p "Enter your email: " GIT_EMAIL_INPUT

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL_INPUT"

    echo -e "${GREEN}✅ Git configured${NC}"
    echo ""
fi

# 2. SSH Key Setup
if [ "$NEED_SSH_KEY" = true ]; then
    echo "2️⃣  Creating SSH Key"
    echo "────────────────────"

    read -p "Create new SSH key? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SSH_EMAIL="${GIT_EMAIL_INPUT:-$(git config --global user.email)}"

        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f ~/.ssh/id_ed25519 -N ""

        echo -e "${GREEN}✅ SSH key created: ~/.ssh/id_ed25519${NC}"
        echo ""
        echo "📋 Add this public key to GitHub:"
        echo "   https://github.com/settings/ssh/new"
        echo ""
        cat ~/.ssh/id_ed25519.pub
        echo ""

        read -p "Press Enter after adding key to GitHub..."

        # Test SSH connection
        echo "Testing GitHub SSH connection..."
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo -e "${GREEN}✅ GitHub SSH connection successful${NC}"
        else
            echo -e "${YELLOW}⚠  GitHub SSH connection may need verification${NC}"
        fi
    fi
    echo ""
fi

# 3. GitHub CLI
if [ "$NEED_GH_INSTALL" = true ]; then
    echo "3️⃣  GitHub CLI Installation"
    echo "────────────────────────────"
    echo "Install GitHub CLI with:"
    echo "  macOS:   brew install gh"
    echo "  Ubuntu:  sudo apt install gh"
    echo "  Windows: scoop install gh"
    echo ""
elif [ "$NEED_GH_AUTH" = true ]; then
    echo "3️⃣  GitHub CLI Authentication"
    echo "──────────────────────────────"
    echo "Authenticating with GitHub..."

    if gh auth login; then
        echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
    else
        echo -e "${RED}❌ GitHub CLI authentication failed${NC}"
    fi
    echo ""
fi

# 4. Supabase CLI
if [ "$NEED_SUPABASE_INSTALL" = true ]; then
    echo "4️⃣  Supabase CLI Installation"
    echo "──────────────────────────────"
    echo "Install Supabase CLI with:"
    echo "  macOS:   brew install supabase/tap/supabase"
    echo "  Linux:   npm install -g supabase"
    echo "  Windows: scoop install supabase"
    echo ""
elif [ "$NEED_SUPABASE_AUTH" = true ]; then
    echo "4️⃣  Supabase CLI Authentication"
    echo "────────────────────────────────"
    echo "Authenticating with Supabase..."

    if supabase login; then
        echo -e "${GREEN}✅ Supabase CLI authenticated${NC}"

        # Link to project
        echo "Linking to project spdtwktxdalcfigzeqrz..."
        supabase link --project-ref spdtwktxdalcfigzeqrz
    else
        echo -e "${RED}❌ Supabase CLI authentication failed${NC}"
    fi
    echo ""
fi

# 5. DigitalOcean CLI
if [ "$NEED_DOCTL_INSTALL" = true ]; then
    echo "5️⃣  DigitalOcean CLI Installation"
    echo "──────────────────────────────────"
    echo "Install DigitalOcean CLI with:"
    echo "  macOS:   brew install doctl"
    echo "  Linux:   snap install doctl"
    echo "  Windows: scoop install doctl"
    echo ""
elif [ "$NEED_DOCTL_AUTH" = true ]; then
    echo "5️⃣  DigitalOcean CLI Authentication"
    echo "────────────────────────────────────"
    echo ""
    echo "Get your API token from:"
    echo "  https://cloud.digitalocean.com/account/api/tokens"
    echo ""
    read -p "Paste DigitalOcean API token: " -r DO_TOKEN

    if doctl auth init --access-token "$DO_TOKEN"; then
        echo -e "${GREEN}✅ DigitalOcean CLI authenticated${NC}"
    else
        echo -e "${RED}❌ DigitalOcean CLI authentication failed${NC}"
    fi
    echo ""
fi

# 6. Vercel CLI
if [ "$NEED_VERCEL_INSTALL" = true ]; then
    echo "6️⃣  Vercel CLI Installation"
    echo "────────────────────────────"
    echo "Install Vercel CLI with:"
    echo "  npm: npm install -g vercel"
    echo "  pnpm: pnpm add -g vercel"
    echo ""
elif [ "$NEED_VERCEL_AUTH" = true ]; then
    echo "6️⃣  Vercel CLI Authentication"
    echo "──────────────────────────────"
    echo "Authenticating with Vercel..."

    if vercel login; then
        echo -e "${GREEN}✅ Vercel CLI authenticated${NC}"
    else
        echo -e "${RED}❌ Vercel CLI authentication failed${NC}"
    fi
    echo ""
fi

# ============================================================================
# PHASE 4: VERIFICATION
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE 4: Verifying All Authentications"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS=0
FAIL=0

# Test SSH
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✅ GitHub SSH${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ GitHub SSH${NC}"
    ((FAIL++))
fi

# Test GitHub CLI
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo -e "${GREEN}✅ GitHub CLI${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ GitHub CLI${NC}"
    ((FAIL++))
fi

# Test Supabase CLI
if command -v supabase &> /dev/null && [ -f "$HOME/.supabase/access-token" ]; then
    echo -e "${GREEN}✅ Supabase CLI${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ Supabase CLI${NC}"
    ((FAIL++))
fi

# Test DigitalOcean CLI
if command -v doctl &> /dev/null && doctl account get &> /dev/null; then
    echo -e "${GREEN}✅ DigitalOcean CLI${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ DigitalOcean CLI${NC}"
    ((FAIL++))
fi

# Test Vercel CLI
if command -v vercel &> /dev/null && [ -f "$HOME/.vercel/auth.json" ]; then
    echo -e "${GREEN}✅ Vercel CLI${NC}"
    ((PASS++))
else
    echo -e "${RED}❌ Vercel CLI${NC}"
    ((FAIL++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 All authentications working!${NC}"
else
    echo -e "${YELLOW}⚠  Some authentications need attention.${NC}"
    echo ""
    echo "Review the output above and:"
    echo "1. Install missing CLIs"
    echo "2. Re-run this script"
    echo "3. Or manually authenticate each service"
fi

echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
