#!/bin/bash

# ============================================================================
# SECRET ROTATION QUICK START
# ============================================================================
# This script helps you rotate all exposed secrets quickly.
# Follow prompts and paste new values when requested.
# ============================================================================

set -e

echo "🔐 SECRET ROTATION ASSISTANT"
echo "============================"
echo ""
echo "This script will help you rotate ALL exposed secrets."
echo "Have these browser tabs ready:"
echo "  1. Supabase Dashboard (https://supabase.com/dashboard)"
echo "  2. DigitalOcean Dashboard (https://cloud.digitalocean.com)"
echo "  3. GitHub repository (for setting secrets)"
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
read -p "Paste NEW database password: " -r DB_PASSWORD
echo ""

# Construct connection strings
STAGING_DB_URL="postgresql://postgres.spdtwktxdalcfigzeqrz:${DB_PASSWORD}@aws-1-us-east-1.pooler.supabase.com:5432/postgres"
PROD_DB_URL="postgresql://postgres.spdtwktxdalcfigzeqrz:${DB_PASSWORD}@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

echo "✅ Database password saved (in memory only)"
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
read -p "Paste NEW service_role key: " -r SERVICE_ROLE_KEY
echo ""
echo "✅ Service role key saved"
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
read -p "Paste NEW anon key: " -r ANON_KEY
echo ""
echo "✅ Anon key saved"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Get Supabase Project URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Actions:"
echo "1. Same API page"
echo "2. Copy 'Project URL' (e.g., https://xxx.supabase.co)"
echo ""
read -p "Paste Supabase URL: " -r SUPABASE_URL
echo ""
echo "✅ Supabase URL saved"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Generate Internal Admin Token"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generating secure token..."
INTERNAL_ADMIN_TOKEN=$(openssl rand -base64 32)
echo "✅ Generated: $INTERNAL_ADMIN_TOKEN"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: DigitalOcean Token (Optional)"
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
    read -p "Paste DigitalOcean token: " -r DO_TOKEN
    echo ""
    echo "✅ DO token saved"
else
    DO_TOKEN="your_digitalocean_token_here"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7: Set GitHub Secrets"
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
    echo "Or set secrets manually at:"
    echo "https://github.com/jgtolentino/odoboo-workspace/settings/secrets/actions"
    echo ""
    echo "Use these values:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STAGING_DATABASE_URL:"
    echo "$STAGING_DB_URL"
    echo ""
    echo "PROD_DATABASE_URL:"
    echo "$PROD_DB_URL"
    echo ""
    echo "NEXT_PUBLIC_SUPABASE_URL:"
    echo "$SUPABASE_URL"
    echo ""
    echo "SUPABASE_SERVICE_ROLE_KEY:"
    echo "$SERVICE_ROLE_KEY"
    echo ""
    echo "NEXT_PUBLIC_SUPABASE_ANON_KEY:"
    echo "$ANON_KEY"
    echo ""
    echo "INTERNAL_ADMIN_TOKEN:"
    echo "$INTERNAL_ADMIN_TOKEN"
    echo ""
    echo "DO_ACCESS_TOKEN:"
    echo "$DO_TOKEN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    # Set secrets using gh CLI
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

    if [[ "$DO_TOKEN" != "your_digitalocean_token_here" ]]; then
        echo "Setting DO_ACCESS_TOKEN..."
        gh secret set DO_ACCESS_TOKEN -b "$DO_TOKEN"
    fi

    echo ""
    echo "✅ All GitHub secrets set!"
    echo ""

    # Verify secrets
    echo "Verifying secrets..."
    gh secret list
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 8: Create local .env file"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    read -p "Overwrite? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping .env creation. Update manually."
        echo ""
        echo "Values needed:"
        echo "  DATABASE_URL=$STAGING_DB_URL"
        echo "  NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL"
        echo "  SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY"
        echo "  NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY"
        echo "  INTERNAL_ADMIN_TOKEN=$INTERNAL_ADMIN_TOKEN"
        echo ""
    else
        cp .env.sample .env
        # Update .env with new values
        sed -i.bak "s|DATABASE_URL=.*|DATABASE_URL=$STAGING_DB_URL|" .env
        sed -i.bak "s|NEXT_PUBLIC_SUPABASE_URL=.*|NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL|" .env
        sed -i.bak "s|SUPABASE_SERVICE_ROLE_KEY=.*|SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY|" .env
        sed -i.bak "s|NEXT_PUBLIC_SUPABASE_ANON_KEY=.*|NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY|" .env
        sed -i.bak "s|INTERNAL_ADMIN_TOKEN=.*|INTERNAL_ADMIN_TOKEN=$INTERNAL_ADMIN_TOKEN|" .env
        if [[ "$DO_TOKEN" != "your_digitalocean_token_here" ]]; then
            sed -i.bak "s|DO_ACCESS_TOKEN=.*|DO_ACCESS_TOKEN=$DO_TOKEN|" .env
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
    if [[ "$DO_TOKEN" != "your_digitalocean_token_here" ]]; then
        sed -i.bak "s|DO_ACCESS_TOKEN=.*|DO_ACCESS_TOKEN=$DO_TOKEN|" .env
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
echo "  ✅ Set GitHub Secrets"
echo "  ✅ Created/updated local .env file"
echo ""
echo "📋 Next steps:"
echo "  1. Run git history cleanup:"
echo "     ./scripts/purge-secrets-from-history.sh"
echo ""
echo "  2. Initialize migration state tracking:"
echo "     psql \"\$STAGING_DATABASE_URL\" -f scripts/00_migration_state_tracking.sql"
echo "     psql \"\$PROD_DATABASE_URL\" -f scripts/00_migration_state_tracking.sql"
echo ""
echo "  3. Create Pull Request:"
echo "     Go to: https://github.com/jgtolentino/odoboo-workspace/compare"
echo "     Use PR_BODY.md as template"
echo ""
echo "  4. Test everything works:"
echo "     psql \"\$DATABASE_URL\" -c \"SELECT 1\""
echo ""
echo "🎉 Secret rotation complete! Proceed to git history cleanup."
echo ""
