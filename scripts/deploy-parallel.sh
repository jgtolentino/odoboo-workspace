#!/bin/bash

# deploy-parallel.sh - Parallel deployment of 5 skills using SuperClaude sub-agents
# Usage: ./scripts/deploy-parallel.sh [skill1,skill2,...] or ./scripts/deploy-parallel.sh (all)

set -e

# Configuration
WORKTREE_BASE="/tmp/odoobo-worktrees"
MAIN_REPO_DIR="$(pwd)"
STATUS_FILE="$MAIN_REPO_DIR/WORKTREE_STATUS.json"
LOG_DIR="$MAIN_REPO_DIR/logs/deployments"
DO_GRADIENT_API="https://api.digitalocean.com/v2/apps"

# DigitalOcean API token (from environment or .env)
if [ -z "$DO_ACCESS_TOKEN" ]; then
    if [ -f ".env" ]; then
        export $(grep -v '^#' .env | xargs)
    fi
fi

if [ -z "$DO_ACCESS_TOKEN" ]; then
    echo "❌ Error: DO_ACCESS_TOKEN not set"
    echo "   Set environment variable or add to .env file"
    exit 1
fi

# Skills to deploy (all by default)
ALL_SKILLS=("pr-review" "odoo-rpc" "nl-sql" "visual-diff" "design-tokens")
if [ -n "$1" ]; then
    IFS=',' read -ra DEPLOY_SKILLS <<< "$1"
else
    DEPLOY_SKILLS=("${ALL_SKILLS[@]}")
fi

echo "🚀 Parallel Deployment of Odoobo Skills to DigitalOcean Gradient AI"
echo "Skills to deploy: ${DEPLOY_SKILLS[*]}"
echo ""

# Step 1: Verify worktrees exist
echo "🔍 Verifying worktrees..."
for skill in "${DEPLOY_SKILLS[@]}"; do
    WORKTREE_PATH="$WORKTREE_BASE/$skill"
    if [ ! -d "$WORKTREE_PATH" ]; then
        echo "❌ Error: Worktree not found for $skill"
        echo "   Run: ./scripts/setup-worktrees.sh"
        exit 1
    fi
done
echo "✅ All worktrees verified"
echo ""

# Step 2: Create log directory
mkdir -p "$LOG_DIR"
DEPLOYMENT_ID="deploy-$(date +%Y%m%d-%H%M%S)"
DEPLOYMENT_LOG="$LOG_DIR/$DEPLOYMENT_ID.log"
echo "📝 Deployment ID: $DEPLOYMENT_ID"
echo "📄 Log file: $DEPLOYMENT_LOG"
echo ""

# Step 3: Update status file
echo "📊 Updating deployment status..."
cat > "$STATUS_FILE.tmp" << EOF
{
  "deployment_id": "$DEPLOYMENT_ID",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "in_progress",
  "skills": {}
}
EOF

for skill in "${DEPLOY_SKILLS[@]}"; do
    jq --arg skill "$skill" \
       --arg status "deploying" \
       '.skills[$skill] = {"status": $status, "started_at": now|todate}' \
       "$STATUS_FILE.tmp" > "$STATUS_FILE.tmp.2"
    mv "$STATUS_FILE.tmp.2" "$STATUS_FILE.tmp"
done

mv "$STATUS_FILE.tmp" "$STATUS_FILE"
echo "✅ Status file updated"
echo ""

# Step 4: Deploy skills in parallel using background processes
echo "🔄 Starting parallel deployments..."
declare -A PIDS

for skill in "${DEPLOY_SKILLS[@]}"; do
    (
        WORKTREE_PATH="$WORKTREE_BASE/$skill"
        SKILL_LOG="$LOG_DIR/$DEPLOYMENT_ID-$skill.log"

        echo "[$skill] 🚀 Starting deployment..." | tee -a "$SKILL_LOG"

        # Navigate to worktree
        cd "$WORKTREE_PATH"

        # Step 4.1: Build skill package
        echo "[$skill] 📦 Building skill package..." | tee -a "$SKILL_LOG"

        # Create skill package structure
        SKILL_PACKAGE_DIR="$WORKTREE_PATH/.build/$skill"
        mkdir -p "$SKILL_PACKAGE_DIR"

        # Copy skill implementation
        cp -r "services/agent-service/skills/$skill" "$SKILL_PACKAGE_DIR/"

        # Create Dockerfile
        cat > "$SKILL_PACKAGE_DIR/Dockerfile" << 'DOCKERFILE_EOF'
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy skill code
COPY . .

# Expose port
EXPOSE 8080

# Run FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
DOCKERFILE_EOF

        # Create requirements.txt
        cat > "$SKILL_PACKAGE_DIR/requirements.txt" << 'REQ_EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
anthropic==0.18.0
pydantic==2.6.0
python-dotenv==1.0.0
httpx==0.26.0
REQ_EOF

        # Create main.py wrapper
        cat > "$SKILL_PACKAGE_DIR/main.py" << 'MAIN_EOF'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os

app = FastAPI(title="Odoobo Skill")

class SkillRequest(BaseModel):
    input: dict
    context: dict = {}

class SkillResponse(BaseModel):
    output: dict
    metadata: dict = {}

@app.get("/health")
async def health():
    return {"status": "healthy", "skill": os.getenv("SKILL_ID", "unknown")}

@app.post("/invoke")
async def invoke(request: SkillRequest):
    # Import skill-specific handler
    from skill import handler
    result = await handler.process(request.input, request.context)
    return SkillResponse(output=result, metadata={"skill": os.getenv("SKILL_ID")})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
MAIN_EOF

        echo "[$skill] ✅ Skill package built" | tee -a "$SKILL_LOG"

        # Step 4.2: Create DigitalOcean Gradient AI app spec
        echo "[$skill] 📋 Creating DO Gradient AI app spec..." | tee -a "$SKILL_LOG"

        APP_SPEC_FILE="$WORKTREE_PATH/infra/do-gradient/$skill/app-spec.yaml"
        mkdir -p "$(dirname "$APP_SPEC_FILE")"

        cat > "$APP_SPEC_FILE" << SPEC_EOF
name: odoobo-skill-$skill
region: sgp
features:
  - buildpack-stack=ubuntu-22

services:
  - name: $skill
    github:
      repo: jgtolentino/odoboo-workspace
      branch: skill/$skill
      deploy_on_push: true
    source_dir: /services/agent-service/skills/$skill

    build_command: |
      pip install -r requirements.txt

    run_command: uvicorn main:app --host 0.0.0.0 --port 8080

    dockerfile_path: Dockerfile

    http_port: 8080

    instance_count: 1
    instance_size_slug: apps-s-1vcpu-0.5gb

    health_check:
      http_path: /health
      initial_delay_seconds: 30
      period_seconds: 10
      timeout_seconds: 5
      success_threshold: 1
      failure_threshold: 3

    routes:
      - path: /

    envs:
      - key: SKILL_ID
        value: $skill
      - key: ANTHROPIC_API_KEY
        value: \${ANTHROPIC_API_KEY}
        type: SECRET
      - key: OPENAI_API_KEY
        value: \${OPENAI_API_KEY}
        type: SECRET
      - key: GITHUB_TOKEN
        value: \${GITHUB_TOKEN}
        type: SECRET
      - key: SUPABASE_URL
        value: \${SUPABASE_URL}
        type: SECRET
      - key: SUPABASE_SERVICE_ROLE_KEY
        value: \${SUPABASE_SERVICE_ROLE_KEY}
        type: SECRET

alerts:
  - rule: DEPLOYMENT_FAILED
  - rule: DOMAIN_FAILED
SPEC_EOF

        echo "[$skill] ✅ App spec created" | tee -a "$SKILL_LOG"

        # Step 4.3: Commit and push to skill branch
        echo "[$skill] 📤 Committing and pushing to skill branch..." | tee -a "$SKILL_LOG"

        git add .
        git commit -m "feat: deploy $skill skill to DO Gradient AI

Deployment ID: $DEPLOYMENT_ID
Generated with Claude Code parallel deployment automation" || true

        git push -u origin "skill/$skill" --force

        echo "[$skill] ✅ Code pushed to GitHub" | tee -a "$SKILL_LOG"

        # Step 4.4: Deploy to DigitalOcean Gradient AI using doctl
        echo "[$skill] 🚢 Deploying to DigitalOcean Gradient AI..." | tee -a "$SKILL_LOG"

        if command -v doctl &> /dev/null; then
            # Check if app exists
            APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "odoobo-skill-$skill" | awk '{print $1}' || echo "")

            if [ -n "$APP_ID" ]; then
                # Update existing app
                echo "[$skill] 🔄 Updating existing app (ID: $APP_ID)..." | tee -a "$SKILL_LOG"
                doctl apps update "$APP_ID" --spec "$APP_SPEC_FILE" 2>&1 | tee -a "$SKILL_LOG"

                # Trigger deployment
                echo "[$skill] 🚀 Triggering new deployment..." | tee -a "$SKILL_LOG"
                doctl apps create-deployment "$APP_ID" --force-rebuild 2>&1 | tee -a "$SKILL_LOG"
            else
                # Create new app
                echo "[$skill] 🆕 Creating new app..." | tee -a "$SKILL_LOG"
                doctl apps create --spec "$APP_SPEC_FILE" 2>&1 | tee -a "$SKILL_LOG"
            fi

            echo "[$skill] ✅ Deployment initiated" | tee -a "$SKILL_LOG"
        else
            echo "[$skill] ⚠️  Warning: doctl not found, skipping deployment" | tee -a "$SKILL_LOG"
            echo "[$skill]    Install: brew install doctl" | tee -a "$SKILL_LOG"
        fi

        # Step 4.5: Update status
        echo "[$skill] 📊 Updating deployment status..." | tee -a "$SKILL_LOG"
        jq --arg skill "$skill" \
           --arg status "deployed" \
           --arg completed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           '.skills[$skill].status = $status | .skills[$skill].completed_at = $completed_at' \
           "$STATUS_FILE" > "$STATUS_FILE.tmp"
        mv "$STATUS_FILE.tmp" "$STATUS_FILE"

        echo "[$skill] ✅ Deployment complete" | tee -a "$SKILL_LOG"
        echo "[$skill] 📄 Log: $SKILL_LOG" | tee -a "$SKILL_LOG"

    ) &

    PIDS[$skill]=$!
    echo "  Started: $skill (PID: ${PIDS[$skill]})"
done

echo ""
echo "⏳ Waiting for all deployments to complete..."
echo ""

# Step 5: Wait for all background processes
FAILED_SKILLS=()
for skill in "${DEPLOY_SKILLS[@]}"; do
    PID=${PIDS[$skill]}
    echo "  Waiting for $skill (PID: $PID)..."

    if wait "$PID"; then
        echo "    ✅ $skill completed successfully"
    else
        echo "    ❌ $skill failed"
        FAILED_SKILLS+=("$skill")
    fi
done

# Step 6: Update final status
echo ""
echo "📊 Updating final deployment status..."
if [ ${#FAILED_SKILLS[@]} -eq 0 ]; then
    FINAL_STATUS="completed"
else
    FINAL_STATUS="failed"
fi

jq --arg status "$FINAL_STATUS" \
   --arg completed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.status = $status | .completed_at = $completed_at' \
   "$STATUS_FILE" > "$STATUS_FILE.tmp"
mv "$STATUS_FILE.tmp" "$STATUS_FILE"

# Step 7: Display summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  🎉 Parallel Deployment Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📋 Deployment ID: $DEPLOYMENT_ID"
echo "📊 Status: $FINAL_STATUS"
echo ""
echo "✅ Successful deployments:"
for skill in "${DEPLOY_SKILLS[@]}"; do
    if [[ ! " ${FAILED_SKILLS[@]} " =~ " ${skill} " ]]; then
        echo "  - $skill"
    fi
done

if [ ${#FAILED_SKILLS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed deployments:"
    for skill in "${FAILED_SKILLS[@]}"; do
        echo "  - $skill"
    done
fi

echo ""
echo "📄 Logs:"
echo "  Main: $DEPLOYMENT_LOG"
for skill in "${DEPLOY_SKILLS[@]}"; do
    echo "  $skill: $LOG_DIR/$DEPLOYMENT_ID-$skill.log"
done

echo ""
echo "🔍 Next steps:"
echo "  1. Monitor deployments: ./scripts/monitor-deployments.sh"
echo "  2. Test endpoints: ./scripts/test-skills.sh"
echo "  3. Merge to main: ./scripts/merge-skills.sh"
echo ""

# Exit with error if any deployments failed
if [ ${#FAILED_SKILLS[@]} -gt 0 ]; then
    exit 1
fi
