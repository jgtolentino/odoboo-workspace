#!/bin/bash

# ============================================================================
# SECRET ROTATION QUICK START (SECURE VERSION)
# ============================================================================
# This script helps you rotate all exposed secrets quickly and securely.
# NEVER prints secrets to console - follows security best practices.
# ============================================================================

set -e

echo "🔐 SECRET ROTATION ASSISTANT (SECURE)"
echo "======================================"
echo ""
echo "This script will help you rotate ALL exposed secrets."
echo "Have these browser tabs ready:"
echo "  1. Supabase Dashboard (https://supabase.com/dashboard)"
echo "  2. DigitalOcean Dashboard (https://cloud.digitalocean.com)"
echo "  3. OpenAI Platform (https://platform.openai.com/api-keys)"
echo "  4. GitHub repository (for setting secrets)"
echo ""

read -p "Ready to proceed? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Run this script when ready."
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Rotate Supabase Database Password"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Actions:"
echo "1. Go to: https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/settings/database"
echo "2. Click 'Reset database password'"
echo "3. Copy the NEW password"
echo ""
read -sp "Paste NEW database password (hidden): " DB_PASSWORD
echo ""
echo ""

# Construct connection strings
STAGING_DB_URL="postgresql://postgres.spdtwktxdalcfigzeqrz:${DB_PASSWORD}@aws-1-us-east-1.pooler.supabase.com:5432/postgres"
PROD_DB_URL="postgresql://postgres.spdtwktxdalcfigzeqrz:${DB_PASSWORD}@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

echo "✅ Database password saved (in memory only - not displayed)"
echo ""

# Test connection
echo "🔍 Testing database connection..."
if psql "$STAGING_DB_URL" -c "SELECT 1" > /dev/null 2>&1; then
    echo "✅ Database connection successful!"
else
    echo "❌ Database connection failed! Check password and try again."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Rotate Supabase Service Role Key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Actions:"
echo "1. Go to: https://supabase.com/dashboard/project/spdtwktxdalcfigzeqrz/settings/api"
echo "2. Find 'service_role' key"
echo "3. Click 'Roll' or 'Regenerate'"
echo "4. Copy NEW service_role key"
echo ""
read -sp "Paste NEW service_role key (hidden): " SERVICE_ROLE_KEY
echo ""
echo ""
echo "✅ Service role key saved (not displayed)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Rotate Supabase Anon Key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Actions:"
echo "1. Same page as above"
echo "2. Find 'anon' key (public)"
echo "3. Click 'Roll' or 'Regenerate'"
echo "4. Copy NEW anon key"
echo ""
read -sp "Paste NEW anon key (hidden): " ANON_KEY
echo ""
echo ""
echo "✅ Anon key saved (not displayed)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Get Supabase Project URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Actions:"
echo "1. Same API page"
echo "2. Copy 'Project URL' (e.g., https://xxx.supabase.co)"
echo ""
read -p "Paste Supabase URL: " SUPABASE_URL
echo ""
echo "✅ Supabase URL saved: $SUPABASE_URL"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Generate Internal Admin Token"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generating secure token..."
INTERNAL_ADMIN_TOKEN=$(openssl rand -base64 32)
echo "✅ Generated new INTERNAL_ADMIN_TOKEN (32 bytes, not displayed)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Generate MCP Admin Token"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generating MCP admin token..."
MCP_ADMIN_TOKEN=$(openssl rand -base64 32)
echo "✅ Generated new MCP_ADMIN_TOKEN (32 bytes, not displayed)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7: DigitalOcean Token (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Do you want to set DigitalOcean token? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📋 Actions:"
    echo "1. Go to: https://cloud.digitalocean.com/account/api/tokens"
    echo "2. Click 'Generate New Token'"
    echo "3. Name: 'GitHub Actions - odoboo-workspace'"
    echo "4. Scopes: Read + Write"
    echo "5. Copy token"
    echo ""
    read -sp "Paste DigitalOcean token (hidden): " DO_TOKEN
    echo ""
    echo ""
    echo "✅ DO token saved (not displayed)"
else
    DO_TOKEN=""
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 8: OpenAI API Key (Optional but recommended)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Do you want to set OpenAI API key? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📋 Actions:"
    echo "1. Go to: https://platform.openai.com/api-keys"
    echo "2. Click 'Create new secret key'"
    echo "3. Name: 'odoboo-workspace-github'"
    echo "4. Copy key (starts with sk-proj-)"
    echo ""
    read -sp "Paste OpenAI API key (hidden): " OPENAI_API_KEY
    echo ""
    echo ""
    echo "✅ OpenAI API key saved (not displayed)"
else
    OPENAI_API_KEY=""
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 9: Set GitHub Secrets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Setting GitHub repository secrets..."
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI (gh) not found!"
    echo ""
    echo "Install with: brew install gh"
    echo ""
    echo "Then run this script again, OR set secrets manually at:"
    echo "https://github.com/jgtolentino/odoboo-workspace/settings/secrets/actions"
    echo ""
    echo "⚠️  SECURITY WARNING:"
    echo "For manual setup, use the values you entered above."
    echo "NEVER copy/paste secrets from console output!"
    echo ""
    echo "Required secrets to set manually:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  - STAGING_DATABASE_URL"
    echo "  - PROD_DATABASE_URL"
    echo "  - NEXT_PUBLIC_SUPABASE_URL"
    echo "  - SUPABASE_SERVICE_ROLE_KEY"
    echo "  - NEXT_PUBLIC_SUPABASE_ANON_KEY"
    echo "  - INTERNAL_ADMIN_TOKEN"
    echo "  - MCP_ADMIN_TOKEN"
    echo "  - DO_ACCESS_TOKEN (if you set it)"
    echo "  - OPENAI_API_KEY (if you set it)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "See OPENAI_SETUP.md and docs/GITHUB_SECRETS_SETUP.md for help."
    echo ""
    exit 0
else
    # Set secrets using gh CLI (secure - values never echo'd)
    echo "Setting STAGING_DATABASE_URL..."
    gh secret set STAGING_DATABASE_URL -b "$STAGING_DB_URL"

    echo "Setting PROD_DATABASE_URL..."
    gh secret set PROD_DATABASE_URL -b "$PROD_DB_URL"

    echo "Setting NEXT_PUBLIC_SUPABASE_URL..."
    gh secret set NEXT_PUBLIC_SUPABASE_URL -b "$SUPABASE_URL"

    echo "Setting SUPABASE_SERVICE_ROLE_KEY..."
    gh secret set SUPABASE_SERVICE_ROLE_KEY -b "$SERVICE_ROLE_KEY"

    echo "Setting NEXT_PUBLIC_SUPABASE_ANON_KEY..."
    gh secret set NEXT_PUBLIC_SUPABASE_ANON_KEY -b "$ANON_KEY"

    echo "Setting INTERNAL_ADMIN_TOKEN..."
    gh secret set INTERNAL_ADMIN_TOKEN -b "$INTERNAL_ADMIN_TOKEN"

    echo "Setting MCP_ADMIN_TOKEN..."
    gh secret set MCP_ADMIN_TOKEN -b "$MCP_ADMIN_TOKEN"

    if [ -n "$DO_TOKEN" ]; then
        echo "Setting DO_ACCESS_TOKEN..."
        gh secret set DO_ACCESS_TOKEN -b "$DO_TOKEN"
    fi

    if [ -n "$OPENAI_API_KEY" ]; then
        echo "Setting OPENAI_API_KEY..."
        gh secret set OPENAI_API_KEY -b "$OPENAI_API_KEY"
    fi

    echo ""
    echo "✅ All GitHub secrets set!"
    echo ""

    # Verify secrets (only shows names, not values)
    echo "Verifying secrets (listing names only)..."
    gh secret list
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 10: Create local .env file"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    read -p "Overwrite? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping .env creation. Update manually if needed."
        echo ""
    else
        cp .env.sample .env
        # Update .env with new values
        sed -i.bak "s|DATABASE_URL=.*|DATABASE_URL=$STAGING_DB_URL|" .env
        sed -i.bak "s|NEXT_PUBLIC_SUPABASE_URL=.*|NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL|" .env
        sed -i.bak "s|SUPABASE_SERVICE_ROLE_KEY=.*|SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
        sed -i.bak "s|NEXT_PUBLIC_SUPABASE_ANON_KEY=.*|NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY|" .env
        sed -i.bak "s|INTERNAL_ADMIN_TOKEN=.*|INTERNAL_ADMIN_TOKEN=$INTERNAL_ADMIN_TOKEN|" .env
        sed -i.bak "s|MCP_ADMIN_TOKEN=.*|MCP_ADMIN_TOKEN=$MCP_ADMIN_TOKEN|" .env
        if [ -n "$DO_TOKEN" ]; then
            sed -i.bak "s|DO_ACCESS_TOKEN=.*|DO_ACCESS_TOKEN=$DO_TOKEN|" .env
        fi
        if [ -n "$OPENAI_API_KEY" ]; then
            sed -i.bak "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$OPENAI_API_KEY|" .env
        fi
        rm .env.bak
        echo "✅ .env file updated!"
    fi
else
    cp .env.sample .env
    # Update .env with new values (same sed commands as above)
    sed -i.bak "s|DATABASE_URL=.*|DATABASE_URL=$STAGING_DB_URL|" .env
    sed -i.bak "s|NEXT_PUBLIC_SUPABASE_URL=.*|NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL|" .env
    sed -i.bak "s|SUPABASE_SERVICE_ROLE_KEY=.*|SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
    sed -i.bak "s|NEXT_PUBLIC_SUPABASE_ANON_KEY=.*|NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY|" .env
    sed -i.bak "s|INTERNAL_ADMIN_TOKEN=.*|INTERNAL_ADMIN_TOKEN=$INTERNAL_ADMIN_TOKEN|" .env
    sed -i.bak "s|MCP_ADMIN_TOKEN=.*|MCP_ADMIN_TOKEN=$MCP_ADMIN_TOKEN|" .env
    if [ -n "$DO_TOKEN" ]; then
        sed -i.bak "s|DO_ACCESS_TOKEN=.*|DO_ACCESS_TOKEN=$DO_TOKEN|" .env
    fi
    if [ -n "$OPENAI_API_KEY" ]; then
        sed -i.bak "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$OPENAI_API_KEY|" .env
    fi
    rm .env.bak
    echo "✅ .env file created!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ROTATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was done:"
echo "  ✅ Rotated Supabase database password"
echo "  ✅ Rotated Supabase service_role key"
echo "  ✅ Rotated Supabase anon key"
echo "  ✅ Generated internal admin token"
echo "  ✅ Generated MCP admin token"
echo "  ✅ Set GitHub Secrets (all secrets secured)"
echo "  ✅ Created/updated local .env file"
echo ""
echo "🔐 SECURITY: All secrets were handled securely (never printed to console)"
echo ""
echo "📋 Next steps:"
echo "  1. Run git history cleanup (if secrets were previously committed):"
echo "     ./scripts/purge-secrets-from-history.sh"
echo ""
echo "  2. Initialize migration state tracking:"
echo "     psql \"\$STAGING_DATABASE_URL\" -f scripts/00_migration_state_tracking.sql"
echo "     psql \"\$PROD_DATABASE_URL\" -f scripts/00_migration_state_tracking.sql"
echo ""
echo "  3. Test everything works:"
echo "     psql \"\$DATABASE_URL\" -c \"SELECT 1\""
echo ""
echo "  4. Review security documentation:"
echo "     - OPENAI_SETUP.md (OpenAI API setup)"
echo "     - docs/GITHUB_SECRETS_SETUP.md (All secrets)"
echo "     - docs/SECRET_MANAGEMENT_ARCHITECTURE.md (Architecture)"
echo ""
echo "🎉 Secret rotation complete!"
echo ""
