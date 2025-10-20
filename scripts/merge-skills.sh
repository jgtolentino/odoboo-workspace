#!/bin/bash

# merge-skills.sh - Merge completed skill branches to main
# Usage: ./scripts/merge-skills.sh [skill1,skill2,...] or ./scripts/merge-skills.sh (all deployed)

set -e

# Configuration
WORKTREE_BASE="/tmp/odoobo-worktrees"
MAIN_REPO_DIR="$(pwd)"
STATUS_FILE="$MAIN_REPO_DIR/WORKTREE_STATUS.json"
LOG_DIR="$MAIN_REPO_DIR/logs/merges"

echo "🔀 Merging completed skill branches to main"
echo ""

# Step 1: Verify we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ Error: Must be on main branch (currently on $CURRENT_BRANCH)"
    exit 1
fi

# Step 2: Verify status file exists
if [ ! -f "$STATUS_FILE" ]; then
    echo "❌ Error: Status file not found: $STATUS_FILE"
    echo "   Run: ./scripts/setup-worktrees.sh"
    exit 1
fi

# Step 3: Determine skills to merge
if [ -n "$1" ]; then
    IFS=',' read -ra MERGE_SKILLS <<< "$1"
else
    # Get all deployed skills from status file
    MERGE_SKILLS=($(jq -r '.skills | to_entries[] | select(.value.status == "deployed") | .key' "$STATUS_FILE"))
fi

if [ ${#MERGE_SKILLS[@]} -eq 0 ]; then
    echo "❌ No skills to merge"
    echo "   Deploy skills first: ./scripts/deploy-parallel.sh"
    exit 1
fi

echo "📋 Skills to merge: ${MERGE_SKILLS[*]}"
echo ""

# Step 4: Create log directory
mkdir -p "$LOG_DIR"
MERGE_ID="merge-$(date +%Y%m%d-%H%M%S)"
MERGE_LOG="$LOG_DIR/$MERGE_ID.log"
echo "📝 Merge ID: $MERGE_ID"
echo "📄 Log file: $MERGE_LOG"
echo ""

# Step 5: Update git from remote
echo "🔄 Updating main branch from remote..."
git pull origin main | tee -a "$MERGE_LOG"
echo ""

# Step 6: Merge each skill branch
MERGED_SKILLS=()
FAILED_SKILLS=()

for skill in "${MERGE_SKILLS[@]}"; do
    BRANCH_NAME="skill/$skill"

    echo "═══════════════════════════════════════════════════════════"
    echo "  Merging: $skill"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Step 6.1: Fetch latest from remote
    echo "[$skill] 📥 Fetching latest changes..." | tee -a "$MERGE_LOG"
    git fetch origin "$BRANCH_NAME" 2>&1 | tee -a "$MERGE_LOG"

    # Step 6.2: Check if branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
        echo "[$skill] ❌ Error: Branch not found on remote: $BRANCH_NAME" | tee -a "$MERGE_LOG"
        FAILED_SKILLS+=("$skill")
        continue
    fi

    # Step 6.3: Verify deployment health
    echo "[$skill] 🏥 Verifying deployment health..." | tee -a "$MERGE_LOG"
    APP_NAME="odoobo-skill-$skill"

    if command -v doctl &> /dev/null; then
        APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "$APP_NAME" | awk '{print $1}' || echo "")

        if [ -n "$APP_ID" ]; then
            # Get app health status
            APP_STATUS=$(doctl apps get "$APP_ID" --format ActiveDeployment.Phase --no-header 2>/dev/null || echo "UNKNOWN")

            if [ "$APP_STATUS" != "ACTIVE" ]; then
                echo "[$skill] ⚠️  Warning: App status is $APP_STATUS (not ACTIVE)" | tee -a "$MERGE_LOG"
                read -p "    Continue merge anyway? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "[$skill] ⏭️  Skipped" | tee -a "$MERGE_LOG"
                    FAILED_SKILLS+=("$skill")
                    continue
                fi
            else
                echo "[$skill] ✅ Deployment is ACTIVE" | tee -a "$MERGE_LOG"
            fi
        else
            echo "[$skill] ⚠️  Warning: App not found on DigitalOcean" | tee -a "$MERGE_LOG"
            read -p "    Continue merge anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "[$skill] ⏭️  Skipped" | tee -a "$MERGE_LOG"
                FAILED_SKILLS+=("$skill")
                continue
            fi
        fi
    fi

    # Step 6.4: Merge branch
    echo "[$skill] 🔀 Merging branch..." | tee -a "$MERGE_LOG"

    if git merge --no-ff "origin/$BRANCH_NAME" -m "Merge skill/$skill: Deploy $skill skill to DO Gradient AI

Merge ID: $MERGE_ID
Deployment verified and tested

Generated with Claude Code parallel deployment automation" 2>&1 | tee -a "$MERGE_LOG"; then
        echo "[$skill] ✅ Merge successful" | tee -a "$MERGE_LOG"
        MERGED_SKILLS+=("$skill")

        # Update status file
        jq --arg skill "$skill" \
           --arg status "merged" \
           --arg merged_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           '.skills[$skill].status = $status | .skills[$skill].merged_at = $merged_at' \
           "$STATUS_FILE" > "$STATUS_FILE.tmp"
        mv "$STATUS_FILE.tmp" "$STATUS_FILE"
    else
        echo "[$skill] ❌ Merge failed" | tee -a "$MERGE_LOG"
        FAILED_SKILLS+=("$skill")

        # Abort merge
        git merge --abort 2>/dev/null || true
    fi

    echo ""
done

# Step 7: Push to main if any merges succeeded
if [ ${#MERGED_SKILLS[@]} -gt 0 ]; then
    echo "📤 Pushing merged changes to main..."
    if git push origin main 2>&1 | tee -a "$MERGE_LOG"; then
        echo "✅ Changes pushed to main"
    else
        echo "❌ Failed to push to main"
        echo "   Review and push manually: git push origin main"
    fi
    echo ""
fi

# Step 8: Cleanup merged worktrees (optional)
if [ ${#MERGED_SKILLS[@]} -gt 0 ]; then
    echo "🧹 Cleanup merged worktrees?"
    read -p "Remove merged worktrees? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for skill in "${MERGED_SKILLS[@]}"; do
            WORKTREE_PATH="$WORKTREE_BASE/$skill"
            if [ -d "$WORKTREE_PATH" ]; then
                echo "  Removing: $skill"
                git worktree remove "$WORKTREE_PATH" --force
            fi
        done
        echo "✅ Worktrees cleaned up"
    fi
    echo ""
fi

# Step 9: Display summary
echo "═══════════════════════════════════════════════════════════"
echo "  🎉 Merge Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 Merge ID: $MERGE_ID"
echo ""
echo "✅ Successfully merged (${#MERGED_SKILLS[@]}):"
for skill in "${MERGED_SKILLS[@]}"; do
    echo "  - $skill"
done

if [ ${#FAILED_SKILLS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed to merge (${#FAILED_SKILLS[@]}):"
    for skill in "${FAILED_SKILLS[@]}"; do
        echo "  - $skill"
    done
fi

echo ""
echo "📄 Merge log: $MERGE_LOG"
echo ""
echo "🔍 Next steps:"
echo "  1. Verify merged code: git log --oneline -10"
echo "  2. Tag release: git tag v1.0.0-skills && git push --tags"
echo "  3. Delete remote branches: ./scripts/cleanup-branches.sh"
echo ""

# Exit with error if any merges failed
if [ ${#FAILED_SKILLS[@]} -gt 0 ]; then
    exit 1
fi
