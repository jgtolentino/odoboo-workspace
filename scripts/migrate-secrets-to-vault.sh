#!/bin/bash
# Migrate Secrets to Supabase Vault
# Comprehensive secret management setup for AI agent-driven development

set -e

echo "🔐 Migrating Secrets to Supabase Vault"
echo "========================================"

# Configuration
PROJECT_REF="${SUPABASE_PROJECT_REF:-spdtwktxdalcfigzeqrz}"
DB_URL="${SUPABASE_URL}/rest/v1"
SERVICE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"

# Validate environment
if [ -z "$SERVICE_KEY" ]; then
  echo "❌ Error: SUPABASE_SERVICE_ROLE_KEY not set"
  exit 1
fi

# Function to store secret in Supabase Vault
store_secret() {
  local name=$1
  local value=$2
  local description=$3

  echo "📝 Storing secret: $name"

  # Use Supabase SQL to insert into vault
  psql "postgresql://postgres.spdtwktxdalcfigzeqrz:${SUPABASE_DB_PASSWORD}@aws-0-us-east-1.pooler.supabase.com:6543/postgres" <<EOF
SELECT vault.create_secret(
  '${value}',
  '${name}',
  '${description}'
);
EOF

  if [ $? -eq 0 ]; then
    echo "✅ Stored: $name"
  else
    echo "⚠️  Failed to store: $name (may already exist)"
  fi
}

# Function to update Supabase secret (for Edge Functions)
update_supabase_secret() {
  local name=$1
  local value=$2

  echo "📝 Updating Supabase secret: $name"
  supabase secrets set "$name=$value" --project-ref "$PROJECT_REF"
}

echo ""
echo "🔄 Step 1: Migrate Core Secrets to Vault"
echo "----------------------------------------"

# GitHub Token
if [ -n "$GITHUB_TOKEN" ]; then
  store_secret "github_token" "$GITHUB_TOKEN" "GitHub Personal Access Token for AI agents"
  update_supabase_secret "GITHUB_TOKEN" "$GITHUB_TOKEN"
fi

# Plugin Bearer Token
if [ -n "$PLUGIN_BEARER_TOKEN" ]; then
  store_secret "plugin_bearer_token" "$PLUGIN_BEARER_TOKEN" "Bearer token for ChatGPT plugin authentication"
  update_supabase_secret "PLUGIN_BEARER_TOKEN" "$PLUGIN_BEARER_TOKEN"
fi

# OCR Space API Key
if [ -n "$OCR_SPACE_API_KEY" ]; then
  store_secret "ocr_space_api_key" "$OCR_SPACE_API_KEY" "OCR.space API key for document processing"
  update_supabase_secret "OCR_SPACE_API_KEY" "$OCR_SPACE_API_KEY"
fi

# Supabase Access Token
if [ -n "$SUPABASE_ACCESS_TOKEN" ]; then
  store_secret "supabase_access_token" "$SUPABASE_ACCESS_TOKEN" "Supabase Management API access token"
fi

# Supabase Service Role Key
if [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  store_secret "supabase_service_role_key" "$SUPABASE_SERVICE_ROLE_KEY" "Supabase service role key (full access)"
  update_supabase_secret "SUPABASE_SERVICE_ROLE_KEY" "$SUPABASE_SERVICE_ROLE_KEY"
fi

# Supabase Anon Key
if [ -n "$SUPABASE_ANON_KEY" ]; then
  store_secret "supabase_anon_key" "$SUPABASE_ANON_KEY" "Supabase anonymous key (public access)"
  update_supabase_secret "SUPABASE_ANON_KEY" "$SUPABASE_ANON_KEY"
fi

# Supabase URL
if [ -n "$SUPABASE_URL" ]; then
  store_secret "supabase_url" "$SUPABASE_URL" "Supabase project URL"
  update_supabase_secret "SUPABASE_URL" "$SUPABASE_URL"
fi

# Digital Ocean Access Token
if [ -n "$DO_ACCESS_TOKEN" ]; then
  store_secret "do_access_token" "$DO_ACCESS_TOKEN" "DigitalOcean API access token"
  update_supabase_secret "DO_ACCESS_TOKEN" "$DO_ACCESS_TOKEN"
fi

# OpenAI API Key (if exists)
if [ -n "$OPENAI_API_KEY" ]; then
  store_secret "openai_api_key" "$OPENAI_API_KEY" "OpenAI API key for AI completions"
  update_supabase_secret "OPENAI_API_KEY" "$OPENAI_API_KEY"
fi

# Anthropic API Key (if exists)
if [ -n "$ANTHROPIC_API_KEY" ]; then
  store_secret "anthropic_api_key" "$ANTHROPIC_API_KEY" "Anthropic API key for Claude AI"
  update_supabase_secret "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"
fi

echo ""
echo "🔄 Step 2: Generate Rotation Schedule"
echo "--------------------------------------"

cat > /tmp/secret-rotation-schedule.md <<EOF
# Secret Rotation Schedule

Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Rotation Frequencies

| Secret | Frequency | Last Rotated | Next Rotation |
|--------|-----------|--------------|---------------|
| github_token | 90 days | $(date +"%Y-%m-%d") | $(date -v+90d +"%Y-%m-%d") |
| plugin_bearer_token | 90 days | $(date +"%Y-%m-%d") | $(date -v+90d +"%Y-%m-%d") |
| ocr_space_api_key | 180 days | $(date +"%Y-%m-%d") | $(date -v+180d +"%Y-%m-%d") |
| supabase_access_token | 90 days | $(date +"%Y-%m-%d") | $(date -v+90d +"%Y-%m-%d") |
| do_access_token | 90 days | $(date +"%Y-%m-%d") | $(date -v+90d +"%Y-%m-%d") |
| openai_api_key | Manual | - | On compromise |
| anthropic_api_key | Manual | - | On compromise |

## Rotation Process

1. Generate new secret value
2. Update Vault: \`SELECT public.rotate_secret('secret_name', 'new_value');\`
3. Update Supabase secrets: \`supabase secrets set SECRET_NAME=new_value\`
4. Restart affected services
5. Verify functionality
6. Revoke old secret

## Emergency Rotation

If a secret is compromised:
\`\`\`bash
# 1. Immediately rotate in Vault
psql "\$POSTGRES_URL" -c "SELECT public.rotate_secret('secret_name', 'emergency_value');"

# 2. Update Supabase
supabase secrets set SECRET_NAME=emergency_value --project-ref $PROJECT_REF

# 3. Restart services
supabase functions deploy chatgpt-plugin --project-ref $PROJECT_REF

# 4. Audit access logs
psql "\$POSTGRES_URL" -c "SELECT * FROM public.secret_access_log WHERE secret_name = 'secret_name' ORDER BY created_at DESC LIMIT 50;"
\`\`\`
EOF

echo "✅ Rotation schedule created: /tmp/secret-rotation-schedule.md"

echo ""
echo "🔄 Step 3: Configure AI Agent Access"
echo "-------------------------------------"

# Create AI agent configuration file
cat > /Users/tbwa/Documents/GitHub/odoboo-workspace-temp/.ai-agent-config.yaml <<EOF
# AI Agent Configuration for Secure Secret Access
# This file configures how AI agents (Claude, ChatGPT) access secrets

version: "1.0"

secret_management:
  provider: "supabase-vault"
  project_ref: "$PROJECT_REF"

  # Access patterns
  access:
    claude_desktop:
      method: "mcp"
      secrets: ["github_token", "supabase_service_role_key"]

    chatgpt_plugin:
      method: "edge_function"
      secrets: ["github_token", "plugin_bearer_token"]

    automation:
      method: "service_account"
      secrets: ["all"]

  # Security policies
  security:
    audit_logging: true
    rotation_enabled: true
    access_control: "role_based"

  # Rotation policies
  rotation:
    auto_rotate: false
    notify_before_expiry: true
    expiry_notification_days: 7

# AI Agent Workflows
workflows:
  github_operations:
    secrets_required: ["github_token"]
    audit_level: "detailed"

  database_operations:
    secrets_required: ["supabase_service_role_key"]
    audit_level: "detailed"

  deployment_operations:
    secrets_required: ["github_token", "do_access_token", "supabase_access_token"]
    audit_level: "comprehensive"

# Monitoring
monitoring:
  alert_on_failed_access: true
  alert_on_rotation_needed: true
  audit_retention_days: 90
EOF

echo "✅ AI agent config created: .ai-agent-config.yaml"

echo ""
echo "✅ Migration Complete!"
echo "===================="
echo ""
echo "📊 Summary:"
echo "  - Secrets stored in Supabase Vault ✅"
echo "  - Supabase Edge Function secrets updated ✅"
echo "  - Rotation schedule generated ✅"
echo "  - AI agent configuration created ✅"
echo ""
echo "📝 Next Steps:"
echo "  1. Apply vault migration: supabase db push"
echo "  2. Review rotation schedule: cat /tmp/secret-rotation-schedule.md"
echo "  3. Configure AI agents to use Vault"
echo "  4. Test secret access from Edge Functions"
echo ""
echo "🔐 Security Recommendations:"
echo "  - Remove secrets from ~/.zshrc after migration"
echo "  - Enable 2FA on all service accounts"
echo "  - Set up secret rotation reminders"
echo "  - Review audit logs regularly"
