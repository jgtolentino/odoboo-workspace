#!/bin/bash

# rollback-deployment.sh - Rollback failed skill deployments
# Usage: ./scripts/rollback-deployment.sh [skill1,skill2,...] or ./scripts/rollback-deployment.sh (all failed)

set -e

# Configuration
WORKTREE_BASE="/tmp/odoobo-worktrees"
MAIN_REPO_DIR="$(pwd)"
STATUS_FILE="$MAIN_REPO_DIR/WORKTREE_STATUS.json"
LOG_DIR="$MAIN_REPO_DIR/logs/rollbacks"

echo "⏪ Rolling back skill deployments"
echo ""

# Step 1: Verify status file exists
if [ ! -f "$STATUS_FILE" ]; then
    echo "❌ Error: Status file not found: $STATUS_FILE"
    exit 1
fi

# Step 2: Determine skills to rollback
if [ -n "$1" ]; then
    IFS=',' read -ra ROLLBACK_SKILLS <<< "$1"
else
    # Get all failed skills from status file
    ROLLBACK_SKILLS=($(jq -r '.skills | to_entries[] | select(.value.status == "failed" or .value.deployment_status == "failed") | .key' "$STATUS_FILE"))
fi

if [ ${#ROLLBACK_SKILLS[@]} -eq 0 ]; then
    echo "ℹ️  No failed deployments to rollback"
    exit 0
fi

echo "📋 Skills to rollback: ${ROLLBACK_SKILLS[*]}"
echo ""

# Step 3: Create log directory
mkdir -p "$LOG_DIR"
ROLLBACK_ID="rollback-$(date +%Y%m%d-%H%M%S)"
ROLLBACK_LOG="$LOG_DIR/$ROLLBACK_ID.log"
echo "📝 Rollback ID: $ROLLBACK_ID"
echo "📄 Log file: $ROLLBACK_LOG"
echo ""

# Step 4: Rollback each skill
ROLLED_BACK=()
FAILED_ROLLBACK=()

for skill in "${ROLLBACK_SKILLS[@]}"; do
    echo "═══════════════════════════════════════════════════════════"
    echo "  Rolling back: $skill"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    APP_NAME="odoobo-skill-$skill"

    # Step 4.1: Get previous deployment
    echo "[$skill] 🔍 Finding previous deployment..." | tee -a "$ROLLBACK_LOG"

    if command -v doctl &> /dev/null; then
        APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "$APP_NAME" | awk '{print $1}' || echo "")

        if [ -z "$APP_ID" ]; then
            echo "[$skill] ⚠️  App not found on DigitalOcean: $APP_NAME" | tee -a "$ROLLBACK_LOG"
            FAILED_ROLLBACK+=("$skill")
            continue
        fi

        # Get deployment history
        DEPLOYMENTS=$(doctl apps list-deployments "$APP_ID" --format ID,Phase,CreatedAt --no-header | head -5)
        echo "[$skill] Recent deployments:" | tee -a "$ROLLBACK_LOG"
        echo "$DEPLOYMENTS" | tee -a "$ROLLBACK_LOG"

        # Get previous ACTIVE deployment
        PREV_DEPLOYMENT=$(echo "$DEPLOYMENTS" | grep "ACTIVE" | head -2 | tail -1 | awk '{print $1}')

        if [ -z "$PREV_DEPLOYMENT" ]; then
            echo "[$skill] ❌ No previous ACTIVE deployment found" | tee -a "$ROLLBACK_LOG"
            echo "[$skill]    Deleting app instead..." | tee -a "$ROLLBACK_LOG"

            read -p "    Delete app $APP_NAME? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if doctl apps delete "$APP_ID" --force 2>&1 | tee -a "$ROLLBACK_LOG"; then
                    echo "[$skill] ✅ App deleted" | tee -a "$ROLLBACK_LOG"
                    ROLLED_BACK+=("$skill")
                else
                    echo "[$skill] ❌ Failed to delete app" | tee -a "$ROLLBACK_LOG"
                    FAILED_ROLLBACK+=("$skill")
                fi
            else
                echo "[$skill] ⏭️  Skipped" | tee -a "$ROLLBACK_LOG"
                FAILED_ROLLBACK+=("$skill")
            fi
            continue
        fi

        # Step 4.2: Rollback to previous deployment
        echo "[$skill] ⏪ Rolling back to deployment: $PREV_DEPLOYMENT" | tee -a "$ROLLBACK_LOG"

        if doctl apps create-deployment "$APP_ID" --deployment-id "$PREV_DEPLOYMENT" 2>&1 | tee -a "$ROLLBACK_LOG"; then
            echo "[$skill] ✅ Rollback initiated" | tee -a "$ROLLBACK_LOG"

            # Wait for deployment to complete
            echo "[$skill] ⏳ Waiting for rollback to complete..." | tee -a "$ROLLBACK_LOG"
            sleep 30

            # Check deployment status
            APP_STATUS=$(doctl apps get "$APP_ID" --format ActiveDeployment.Phase --no-header 2>/dev/null || echo "UNKNOWN")

            if [ "$APP_STATUS" = "ACTIVE" ]; then
                echo "[$skill] ✅ Rollback successful" | tee -a "$ROLLBACK_LOG"
                ROLLED_BACK+=("$skill")

                # Update status file
                jq --arg skill "$skill" \
                   --arg status "rolled_back" \
                   --arg rolled_back_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                   '.skills[$skill].status = $status | .skills[$skill].rolled_back_at = $rolled_back_at' \
                   "$STATUS_FILE" > "$STATUS_FILE.tmp"
                mv "$STATUS_FILE.tmp" "$STATUS_FILE"
            else
                echo "[$skill] ❌ Rollback failed: Status is $APP_STATUS" | tee -a "$ROLLBACK_LOG"
                FAILED_ROLLBACK+=("$skill")
            fi
        else
            echo "[$skill] ❌ Failed to initiate rollback" | tee -a "$ROLLBACK_LOG"
            FAILED_ROLLBACK+=("$skill")
        fi
    else
        echo "[$skill] ❌ doctl not found" | tee -a "$ROLLBACK_LOG"
        echo "[$skill]    Install: brew install doctl" | tee -a "$ROLLBACK_LOG"
        FAILED_ROLLBACK+=("$skill")
    fi

    echo ""
done

# Step 5: Cleanup failed worktrees
if [ ${#ROLLED_BACK[@]} -gt 0 ]; then
    echo "🧹 Cleanup rolled back worktrees?"
    read -p "Remove rolled back worktrees? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for skill in "${ROLLED_BACK[@]}"; do
            WORKTREE_PATH="$WORKTREE_BASE/$skill"
            if [ -d "$WORKTREE_PATH" ]; then
                echo "  Removing: $skill"
                git worktree remove "$WORKTREE_PATH" --force
            fi

            # Delete remote branch
            BRANCH_NAME="skill/$skill"
            if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
                echo "  Deleting remote branch: $BRANCH_NAME"
                git push origin --delete "$BRANCH_NAME"
            fi
        done
        echo "✅ Worktrees and branches cleaned up"
    fi
    echo ""
fi

# Step 6: Display summary
echo "═══════════════════════════════════════════════════════════"
echo "  ⏪ Rollback Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 Rollback ID: $ROLLBACK_ID"
echo ""
echo "✅ Successfully rolled back (${#ROLLED_BACK[@]}):"
for skill in "${ROLLED_BACK[@]}"; do
    echo "  - $skill"
done

if [ ${#FAILED_ROLLBACK[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed to rollback (${#FAILED_ROLLBACK[@]}):"
    for skill in "${FAILED_ROLLBACK[@]}"; do
        echo "  - $skill"
    done
fi

echo ""
echo "📄 Rollback log: $ROLLBACK_LOG"
echo ""
echo "🔍 Next steps:"
echo "  1. Review failure logs: cat $LOG_DIR/deploy-*-<skill>.log"
echo "  2. Fix issues and redeploy: ./scripts/deploy-parallel.sh <skill>"
echo "  3. Monitor apps: doctl apps list"
echo ""

# Exit with error if any rollbacks failed
if [ ${#FAILED_ROLLBACK[@]} -gt 0 ]; then
    exit 1
fi
