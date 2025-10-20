#!/usr/bin/env bash
#
# SuperClaude Orchestration Bootstrap
# ====================================
# One-shot setup for Odoo-as-Slack + Kanban CI/CD board
#
# Prerequisites:
# - gh CLI logged in (gh auth status)
# - Docker access to Odoo container (docker ps | grep odoo)
# - Odoo admin API key generated
#
# Usage:
#   export ODOO_URL="https://insightpulseai.net"
#   export ODOO_DB="odoboo_prod"
#   export ODOO_ADMIN_EMAIL="admin@insightpulseai.net"
#   export ODOO_API_KEY="<your-api-key>"
#   export REPO="jgtolentino/odoboo-workspace"
#   export ODOO_CONTAINER="odoo18"  # optional, defaults to odoo18
#   ./scripts/bootstrap_superclaude.sh
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

# --- 0) Validate Prerequisites ---
info "Validating prerequisites..."

# Check required env vars
required_vars=(ODOO_URL ODOO_DB ODOO_ADMIN_EMAIL ODOO_API_KEY REPO)
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        error "Missing required environment variable: $var"
    fi
done

# Set defaults
ODOO_CONTAINER="${ODOO_CONTAINER:-odoo18}"

# Verify gh CLI
if ! command -v gh &> /dev/null; then
    error "gh CLI not found. Install from: https://cli.github.com/"
fi

if ! gh auth status &> /dev/null; then
    error "gh CLI not authenticated. Run: gh auth login"
fi

# Verify Docker access
if ! docker ps &> /dev/null; then
    error "Docker not accessible. Check permissions."
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${ODOO_CONTAINER}$"; then
    error "Odoo container '${ODOO_CONTAINER}' not running. Check with: docker ps"
fi

success "Prerequisites validated"
echo ""

# --- 1) Set GitHub Secrets ---
info "Setting GitHub secrets for SuperClaude workflows..."

secrets=(
    "ODOO_URL:$ODOO_URL"
    "ODOO_DATABASE:$ODOO_DB"
    "ODOO_USER:$ODOO_ADMIN_EMAIL"
    "ODOO_API_KEY:$ODOO_API_KEY"
)

for secret in "${secrets[@]}"; do
    name="${secret%%:*}"
    value="${secret#*:}"

    if gh secret set "$name" -b "$value" --repo "$REPO" &> /dev/null; then
        success "Set GitHub secret: $name"
    else
        error "Failed to set GitHub secret: $name"
    fi
done

# Check for optional secrets (warn if missing)
optional_secrets=(DO_ACCESS_TOKEN OPENAI_API_KEY ANTHROPIC_API_KEY MCP_ADMIN_TOKEN)
for secret in "${optional_secrets[@]}"; do
    if ! gh secret list --repo "$REPO" 2>/dev/null | grep -q "^${secret}"; then
        warn "Optional secret not set: $secret (may be needed for full functionality)"
    fi
done

success "GitHub secrets configured"
echo ""

# --- 2) Provision Odoo Project + Fields + Discuss Channel ---
info "Provisioning Odoo CI/CD Pipeline project..."

# Create temporary Python script for Odoo shell
cat > /tmp/odoo_bootstrap.py <<'PYEOF'
import sys

env = env.sudo()

# === 1) Create Project ===
proj = env['project.project'].search([('name', '=', 'CI/CD Pipeline')], limit=1)
if not proj:
    proj = env['project.project'].create({
        'name': 'CI/CD Pipeline',
        'privacy_visibility': 'followers',
        'description': 'Automated CI/CD task tracking (SuperClaude orchestration)',
    })
    print(f"Created project: CI/CD Pipeline (ID: {proj.id})")
else:
    print(f"Found existing project: CI/CD Pipeline (ID: {proj.id})")

# === 2) Create Stages ===
stages = [
    'Backlog',
    'Spec Review',
    'In PR',
    'CI Green',
    'Staging ✅',
    'Ready for Prod',
    'Deployed',
    'Blocked'
]

TaskType = env['project.task.type']
for stage_name in stages:
    existing = TaskType.search([
        ('name', '=', stage_name),
        ('project_ids', 'in', proj.id)
    ], limit=1)

    if not existing:
        TaskType.create({
            'name': stage_name,
            'project_ids': [(4, proj.id)],
            'fold': stage_name in ['Deployed', 'Blocked'],
        })
        print(f"  Created stage: {stage_name}")
    else:
        print(f"  Found stage: {stage_name}")

# === 3) Add Custom Fields ===
IrModelFields = env['ir.model.fields']
task_model_id = env['ir.model']._get_id('project.task')

def add_custom_field(field_name, field_desc, field_type, **kwargs):
    """Add custom field if it doesn't exist"""
    existing = IrModelFields.search([
        ('model', '=', 'project.task'),
        ('name', '=', field_name)
    ], limit=1)

    if not existing:
        vals = {
            'name': field_name,
            'model_id': task_model_id,
            'field_description': field_desc,
            'ttype': field_type,
            'store': True,
        }
        vals.update(kwargs)
        IrModelFields.create(vals)
        print(f"  Created field: {field_name} ({field_type})")
    else:
        print(f"  Found field: {field_name}")

# Integer field for PR number
add_custom_field('x_pr_number', 'PR Number', 'integer')

# Char fields
add_custom_field('x_pr_url', 'PR URL', 'char', size=512)
add_custom_field('x_repo', 'Repository', 'char', size=256)
add_custom_field('x_commit_sha', 'Commit SHA', 'char', size=64)
add_custom_field('x_author', 'Author', 'char', size=128)
add_custom_field('x_deploy_url', 'Deploy URL', 'char', size=512)

# Selection fields
add_custom_field('x_build_status', 'Build Status', 'selection',
                 selection="[('queued','Queued'),('running','Running'),('passed','Passed'),('failed','Failed')]")

add_custom_field('x_env', 'Environment', 'selection',
                 selection="[('preview','Preview'),('staging','Staging'),('prod','Production')]")

# Text field for agent notes
add_custom_field('x_agent_notes', 'Agent Notes', 'text')

# === 4) Create Discuss Channel ===
DiscussChannel = env['discuss.channel']
channel = DiscussChannel.search([('name', '=', 'ci-updates')], limit=1)

if not channel:
    channel = DiscussChannel.create({
        'name': 'ci-updates',
        'channel_type': 'channel',
        'public': 'public',
        'description': 'SuperClaude CI/CD notifications (Your Own Slack)',
    })
    print(f"Created Discuss channel: #ci-updates (ID: {channel.id})")
else:
    print(f"Found Discuss channel: #ci-updates (ID: {channel.id})")

# === 5) Post Welcome Message ===
if channel:
    welcome_msg = """
<h3>🤖 SuperClaude CI/CD System Ready</h3>
<p>This channel receives automated updates from:</p>
<ul>
<li>PR reviews (OCA compliance, spec validation)</li>
<li>Security scans (secret detection, CVE checks)</li>
<li>Test results (lint, unit, integration)</li>
<li>Deployment events (staging → production)</li>
</ul>
<p><strong>Kanban Board:</strong> <a href="/web#action=project.action_view_task&amp;model=project.task&amp;view_type=kanban">CI/CD Pipeline Project</a></p>
"""

    channel.message_post(
        body=welcome_msg,
        message_type='comment',
        subtype_xmlid='mail.mt_comment',
    )
    print("Posted welcome message to #ci-updates")

print("\n✅ Odoo provisioning complete")
print(f"Project ID: {proj.id}")
print(f"Channel ID: {channel.id}")
print(f"Custom fields: 9 added")
print(f"Stages: {len(stages)} configured")

PYEOF

# Execute provisioning script
info "Running Odoo shell script..."
if docker exec -i "$ODOO_CONTAINER" odoo shell -d "$ODOO_DB" < /tmp/odoo_bootstrap.py; then
    success "Odoo project, fields, and channel provisioned"
else
    error "Odoo provisioning failed. Check container logs: docker logs $ODOO_CONTAINER --tail 50"
fi

# Cleanup
rm -f /tmp/odoo_bootstrap.py
echo ""

# --- 3) Verify Installation ---
info "Verifying installation..."

# Check if workflows exist
workflow_file=".github/workflows/superclaude-pr.yml"
if [[ -f "$workflow_file" ]]; then
    success "Found SuperClaude PR workflow: $workflow_file"
else
    warn "SuperClaude PR workflow not found at: $workflow_file"
    warn "You may need to create this workflow. See: docs/SUPERCLAUDE_ORCHESTRATION.md"
fi

# Check if sync script exists
sync_script="scripts/odoo_kanban_sync.py"
if [[ -f "$sync_script" ]] && [[ -x "$sync_script" ]]; then
    success "Found Odoo Kanban sync script: $sync_script"
else
    warn "Odoo Kanban sync script not found or not executable: $sync_script"
fi

# Check if agent configs exist
agent_dir=".claude/agents"
if [[ -d "$agent_dir" ]]; then
    agent_count=$(find "$agent_dir" -name "*.agent.yaml" | wc -l)
    success "Found $agent_count agent configuration(s) in $agent_dir"
else
    warn "Agent configuration directory not found: $agent_dir"
fi

echo ""

# --- 4) Summary & Next Steps ---
cat <<EOF
${GREEN}╔════════════════════════════════════════════════════════════════╗
║  ✅ SuperClaude Orchestration Bootstrap Complete               ║
╚════════════════════════════════════════════════════════════════╝${NC}

${BLUE}📋 What was configured:${NC}
  • GitHub Secrets: ODOO_URL, ODOO_DATABASE, ODOO_USER, ODOO_API_KEY
  • Odoo Project: "CI/CD Pipeline" with 8 stages
  • Custom Fields: x_pr_number, x_pr_url, x_build_status, x_env (+ 5 more)
  • Discuss Channel: #ci-updates (Your Own Slack)

${BLUE}🧪 Quick Smoke Test:${NC}
  1. Create a test PR:
     ${YELLOW}git checkout -b test/superclaude
     echo "\$(date) smoke" >> SUPERCLAUDE_SMOKE.md
     git add SUPERCLAUDE_SMOKE.md
     git commit -m "chore: superclaude smoke test"
     git push -u origin HEAD${NC}

  2. Watch GitHub Actions:
     ${YELLOW}https://github.com/${REPO}/actions${NC}

  3. Check Odoo:
     ${YELLOW}${ODOO_URL}/web#action=project.action_view_task${NC}
     → Look for task in "In PR" stage

     ${YELLOW}${ODOO_URL}/web#action=mail.action_discuss${NC}
     → Check #ci-updates for PR notification

${BLUE}🔧 Troubleshooting:${NC}
  • GitHub Actions failing → Check secrets in repo settings
  • No Odoo updates → Verify API key has Project + Discuss permissions
  • Container issues → Check: ${YELLOW}docker logs ${ODOO_CONTAINER} --tail 50${NC}

${BLUE}📚 Documentation:${NC}
  • Full guide: docs/SUPERCLAUDE_ORCHESTRATION.md
  • Agent configs: .claude/agents/*.agent.yaml
  • MCP servers: mcp/servers.json

${GREEN}Your CI/CD is now orchestrated by SuperClaude with parallel agents! 🚀${NC}
EOF
