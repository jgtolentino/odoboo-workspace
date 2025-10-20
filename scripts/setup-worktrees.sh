#!/bin/bash

# setup-worktrees.sh - Create 5 parallel git worktrees for skill development
# Usage: ./scripts/setup-worktrees.sh

set -e

# Configuration
WORKTREE_BASE="/tmp/odoobo-worktrees"
MAIN_REPO_DIR="$(pwd)"
SKILLS=(
  "pr-review"
  "odoo-rpc"
  "nl-sql"
  "visual-diff"
  "design-tokens"
)

echo "🌳 Setting up parallel git worktrees for skill deployment"
echo "Base directory: $WORKTREE_BASE"
echo "Main repository: $MAIN_REPO_DIR"
echo ""

# Step 1: Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Step 2: Ensure we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Warning: Not on main branch (currently on $CURRENT_BRANCH)"
    read -p "Switch to main branch? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout main
        git pull origin main
    else
        echo "❌ Aborted: Must be on main branch"
        exit 1
    fi
fi

# Step 3: Clean up existing worktrees
echo "🧹 Cleaning up existing worktrees..."
if [ -d "$WORKTREE_BASE" ]; then
    for skill in "${SKILLS[@]}"; do
        WORKTREE_PATH="$WORKTREE_BASE/$skill"
        if [ -d "$WORKTREE_PATH" ]; then
            echo "  Removing existing worktree: $skill"
            git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
        fi
    done
    rm -rf "$WORKTREE_BASE"
fi

# Step 4: Create base directory
echo "📁 Creating base directory..."
mkdir -p "$WORKTREE_BASE"

# Step 5: Create worktrees for each skill
echo ""
echo "🔀 Creating 5 parallel worktrees..."
for skill in "${SKILLS[@]}"; do
    BRANCH_NAME="skill/$skill"
    WORKTREE_PATH="$WORKTREE_BASE/$skill"

    echo ""
    echo "  Processing: $skill"
    echo "  Branch: $BRANCH_NAME"
    echo "  Path: $WORKTREE_PATH"

    # Delete branch if exists (locally and remotely)
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "    Deleting existing local branch..."
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
    fi

    if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
        echo "    Deleting existing remote branch..."
        git push origin --delete "$BRANCH_NAME" 2>/dev/null || true
    fi

    # Create new branch from main
    echo "    Creating fresh branch from main..."
    git checkout -b "$BRANCH_NAME"
    git checkout main

    # Create worktree
    echo "    Creating worktree..."
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"

    # Create skill-specific directory structure
    echo "    Setting up directory structure..."
    mkdir -p "$WORKTREE_PATH/services/agent-service/skills/$skill"
    mkdir -p "$WORKTREE_PATH/infra/do-gradient/$skill"
    mkdir -p "$WORKTREE_PATH/docs/skills/$skill"

    # Create skill manifest
    cat > "$WORKTREE_PATH/services/agent-service/skills/$skill/manifest.json" << EOF
{
  "skill_id": "$skill",
  "version": "1.0.0",
  "status": "development",
  "worktree": "$WORKTREE_PATH",
  "branch": "$BRANCH_NAME",
  "deployment": {
    "platform": "digitalocean-gradient-ai",
    "endpoint": "https://{skill-id}.agents.do-ai.run",
    "health_check": "/health"
  },
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "dependencies": [],
  "tools": []
}
EOF

    # Create README
    cat > "$WORKTREE_PATH/services/agent-service/skills/$skill/README.md" << EOF
# Skill: $skill

**Status**: Development
**Branch**: $BRANCH_NAME
**Worktree**: $WORKTREE_PATH

## Description

AI skill for the odoobo-expert agent system.

## Development

\`\`\`bash
# Navigate to worktree
cd $WORKTREE_PATH

# Make changes
# ...

# Commit and push
git add .
git commit -m "feat: implement $skill skill"
git push origin $BRANCH_NAME
\`\`\`

## Deployment

\`\`\`bash
# Deploy to DigitalOcean Gradient AI
cd $MAIN_REPO_DIR
./scripts/deploy-parallel.sh $skill
\`\`\`

## Testing

\`\`\`bash
# Run skill tests
cd $WORKTREE_PATH
pytest services/agent-service/skills/$skill/tests/
\`\`\`
EOF

    echo "    ✅ Worktree ready: $skill"
done

# Step 6: Create status tracking file in main repo
echo ""
echo "📊 Creating status tracking file..."
cat > "$MAIN_REPO_DIR/WORKTREE_STATUS.json" << EOF
{
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "base_directory": "$WORKTREE_BASE",
  "main_repository": "$MAIN_REPO_DIR",
  "skills": {
    "pr-review": {
      "branch": "skill/pr-review",
      "worktree": "$WORKTREE_BASE/pr-review",
      "status": "ready",
      "deployment_status": "pending"
    },
    "odoo-rpc": {
      "branch": "skill/odoo-rpc",
      "worktree": "$WORKTREE_BASE/odoo-rpc",
      "status": "ready",
      "deployment_status": "pending"
    },
    "nl-sql": {
      "branch": "skill/nl-sql",
      "worktree": "$WORKTREE_BASE/nl-sql",
      "status": "ready",
      "deployment_status": "pending"
    },
    "visual-diff": {
      "branch": "skill/visual-diff",
      "worktree": "$WORKTREE_BASE/visual-diff",
      "status": "ready",
      "deployment_status": "pending"
    },
    "design-tokens": {
      "branch": "skill/design-tokens",
      "worktree": "$WORKTREE_BASE/design-tokens",
      "status": "ready",
      "deployment_status": "pending"
    }
  }
}
EOF

# Step 7: Display summary
echo ""
echo "✅ Git worktree setup complete!"
echo ""
echo "📋 Worktree Summary:"
git worktree list
echo ""
echo "📊 Status file: $MAIN_REPO_DIR/WORKTREE_STATUS.json"
echo ""
echo "🚀 Next Steps:"
echo "  1. Deploy skills in parallel: ./scripts/deploy-parallel.sh"
echo "  2. Monitor deployments: ./scripts/monitor-deployments.sh"
echo "  3. Merge completed skills: ./scripts/merge-skills.sh"
echo ""
echo "🔍 Inspect individual worktrees:"
for skill in "${SKILLS[@]}"; do
    echo "  cd $WORKTREE_BASE/$skill"
done
echo ""
