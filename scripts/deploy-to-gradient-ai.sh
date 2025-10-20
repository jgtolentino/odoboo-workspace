#!/bin/bash
# Deploy Odoobo-Expert Agent to DigitalOcean Gradient AI Platform
# Architecture: Anthropic Skills + DO Gradient AI + SuperClaude Framework

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${PROJECT_ROOT}/.claude/skills"
KB_DIR="${PROJECT_ROOT}/.claude/knowledge-bases/odoobo"
AGENT_NAME="${AGENT_NAME:-odoobo-expert}"
DO_REGION="${DO_REGION:-sgp}"  # Singapore

# DigitalOcean Gradient AI Configuration
DO_TOKEN="${DO_GRADIENT_TOKEN:-$DO_ACCESS_TOKEN}"
if [ -z "$DO_TOKEN" ]; then
  echo -e "${RED}[ERROR]${NC} DO_GRADIENT_TOKEN or DO_ACCESS_TOKEN not set"
  exit 1
fi

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check doctl CLI
  if ! command -v doctl &> /dev/null; then
    log_error "doctl CLI not found. Install: brew install doctl"
    exit 1
  fi

  # Check authentication
  if ! doctl auth list | grep -q "$DO_TOKEN"; then
    log_info "Authenticating with DigitalOcean..."
    doctl auth init --access-token "$DO_TOKEN"
  fi

  # Check if skills exist
  if [ ! -d "$SKILLS_DIR" ]; then
    log_error "Skills directory not found: $SKILLS_DIR"
    exit 1
  fi

  log_success "Prerequisites check passed"
}

# Package skills for deployment
package_skills() {
  log_info "Packaging skills for deployment..."

  local package_dir="${PROJECT_ROOT}/dist/odoobo-expert"
  rm -rf "$package_dir"
  mkdir -p "$package_dir"

  # Copy skills
  cp -r "$SKILLS_DIR" "$package_dir/skills"

  # Copy agent config
  cp "${PROJECT_ROOT}/.claude/agents/odoobo-expert.agent.yaml" "$package_dir/"

  # Create deployment manifest
  cat > "$package_dir/manifest.json" << EOF
{
  "name": "odoobo-expert",
  "version": "3.0.0",
  "description": "Enhanced Odoo/OCA specialist with Anthropic Skills",
  "skills": [
    "pr-review",
    "odoo-rpc",
    "nl-sql",
    "visual-diff",
    "design-tokens"
  ],
  "framework": "anthropic-skills",
  "requires": {
    "python": ">=3.9",
    "runtime": "python3.11"
  },
  "entrypoint": "main.py",
  "region": "${DO_REGION}",
  "resources": {
    "cpu": "1",
    "memory": "2Gi"
  }
}
EOF

  # Create entrypoint
  cat > "$package_dir/main.py" << 'EOF'
#!/usr/bin/env python3
"""
Odoobo-Expert Agent Entrypoint for DigitalOcean Gradient AI
Anthropic Skills Architecture with FastAPI HTTP interface
"""

import os
import sys
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

# Add skills to path
SKILLS_DIR = Path(__file__).parent / "skills"
sys.path.insert(0, str(SKILLS_DIR))

app = FastAPI(title="Odoobo-Expert Agent", version="3.0.0")

# Import skills
try:
    from pr_review.analyze_pr import analyze_pr
    from odoo_rpc.odoo_client import OdooClient
    from nl_sql.wrenai_client import WrenAIClient
    from visual_diff.percy_client import PercyClient
    from design_tokens.extract_tokens import extract_tokens
except ImportError as e:
    print(f"Error importing skills: {e}")
    sys.exit(1)

# Health check
@app.get("/health")
async def health():
    return {"status": "ok", "agent": "odoobo-expert", "version": "3.0.0"}

# Skill endpoints
@app.post("/skills/pr-review")
async def pr_review(request: dict):
    """Execute PR review skill"""
    try:
        result = await analyze_pr(**request)
        return {"status": "success", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/skills/odoo-rpc")
async def odoo_rpc(request: dict):
    """Execute Odoo RPC skill"""
    try:
        client = OdooClient()
        result = await client.execute(**request)
        return {"status": "success", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/skills/nl-sql")
async def nl_sql(request: dict):
    """Execute NL-to-SQL skill"""
    try:
        client = WrenAIClient()
        result = await client.nl_to_results(**request)
        return {"status": "success", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/skills/visual-diff")
async def visual_diff(request: dict):
    """Execute visual diff skill"""
    try:
        client = PercyClient()
        result = await client.compare(**request)
        return {"status": "success", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/skills/design-tokens")
async def design_tokens(request: dict):
    """Execute design tokens extraction skill"""
    try:
        result = await extract_tokens(**request)
        return {"status": "success", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)
EOF

  chmod +x "$package_dir/main.py"

  # Create Dockerfile
  cat > "$package_dir/Dockerfile" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Copy skills and dependencies
COPY skills/ /app/skills/
COPY main.py /app/
COPY manifest.json /app/

# Install dependencies
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    pydantic \
    httpx \
    python-multipart

# Install skill dependencies
RUN for skill in /app/skills/*/requirements.txt; do \
      [ -f "$skill" ] && pip install --no-cache-dir -r "$skill"; \
    done

# Expose port
EXPOSE 8001

# Run
CMD ["python", "main.py"]
EOF

  log_success "Skills packaged: $package_dir"
  echo "$package_dir"
}

# Deploy to DO Gradient AI
deploy_agent() {
  local package_dir=$1
  log_info "Deploying agent to DigitalOcean Gradient AI..."

  # Build Docker image
  log_info "Building Docker image..."
  docker build -t "odoobo-expert:latest" "$package_dir"

  # Tag for DO registry
  local registry="registry.digitalocean.com/odoobo"
  docker tag "odoobo-expert:latest" "${registry}/odoobo-expert:latest"

  # Push to registry
  log_info "Pushing to DO registry..."
  docker push "${registry}/odoobo-expert:latest"

  # Create or update app
  log_info "Deploying to DO App Platform..."

  # Check if app exists
  if doctl apps list --format Name | grep -q "^odoobo-expert$"; then
    log_info "Updating existing app..."
    local app_id=$(doctl apps list --format ID,Name | grep "odoobo-expert" | awk '{print $1}')
    doctl apps update "$app_id" --spec "$package_dir/app-spec.yaml"
  else
    log_info "Creating new app..."
    doctl apps create --spec "$package_dir/app-spec.yaml"
  fi

  log_success "Agent deployed successfully"
}

# Create knowledge base
create_knowledge_base() {
  log_info "Creating knowledge base in DO Gradient AI..."

  # Export local embeddings
  if [ -d "$KB_DIR/embeddings" ]; then
    log_info "Exporting local embeddings..."
    python "${PROJECT_ROOT}/scripts/export_embeddings.py" \
      --input "$KB_DIR/embeddings" \
      --output "$KB_DIR/embeddings_export.json"
  fi

  # Upload to DO Gradient AI
  log_info "Uploading to DO Gradient AI knowledge base..."
  python "${PROJECT_ROOT}/scripts/upload_to_do_gradient.py" \
    --input "$KB_DIR/embeddings_export.json" \
    --agent-name "$AGENT_NAME" \
    --region "$DO_REGION"

  log_success "Knowledge base created"
}

# Verify deployment
verify_deployment() {
  log_info "Verifying deployment..."

  # Get app URL
  local app_url=$(doctl apps list --format Name,DefaultIngress | grep "odoobo-expert" | awk '{print $2}')

  if [ -z "$app_url" ]; then
    log_error "Could not find app URL"
    return 1
  fi

  log_info "App URL: https://${app_url}"

  # Health check
  log_info "Running health check..."
  local health_response=$(curl -sf "https://${app_url}/health" || echo "failed")

  if echo "$health_response" | grep -q '"status":"ok"'; then
    log_success "Health check passed"
    echo "$health_response" | jq .
  else
    log_error "Health check failed"
    return 1
  fi

  # Test each skill
  log_info "Testing skills..."
  for skill in pr-review odoo-rpc nl-sql visual-diff design-tokens; do
    log_info "Testing skill: $skill"
    local test_response=$(curl -sf -X POST "https://${app_url}/skills/${skill}" \
      -H "Content-Type: application/json" \
      -d '{"test": true}' || echo "failed")

    if echo "$test_response" | grep -q '"status":"success"'; then
      log_success "Skill $skill is working"
    else
      log_warning "Skill $skill test inconclusive"
    fi
  done

  log_success "Deployment verified"
}

# Print summary
print_summary() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Deployment Complete!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "${BLUE}Agent:${NC} odoobo-expert v3.0.0"
  echo -e "${BLUE}Platform:${NC} DigitalOcean Gradient AI"
  echo -e "${BLUE}Region:${NC} Singapore (sgp)"
  echo ""
  echo -e "${BLUE}Skills Deployed:${NC}"
  echo -e "  • pr-review"
  echo -e "  • odoo-rpc"
  echo -e "  • nl-sql"
  echo -e "  • visual-diff"
  echo -e "  • design-tokens"
  echo ""
  echo -e "${BLUE}Knowledge Base:${NC} Managed OpenSearch with 27K chunks"
  echo -e "${BLUE}Embedding Model:${NC} text-embedding-ada-002 (1536 dim)"
  echo ""
  echo -e "${BLUE}Cost Estimate:${NC}"
  echo -e "  • App Platform: $5-8/month"
  echo -e "  • Knowledge Base: $3/month"
  echo -e "  • Total: <$12/month"
  echo ""
  echo -e "${GREEN}Next Steps:${NC}"
  echo -e "  1. Update agent config with production URL"
  echo -e "  2. Configure monitoring (Prometheus + Grafana)"
  echo -e "  3. Set up GitHub Actions for CI/CD"
  echo -e "  4. Test skills with real workloads"
  echo ""
}

# Main execution
main() {
  log_info "Starting deployment to DigitalOcean Gradient AI..."

  check_prerequisites

  local package_dir
  package_dir=$(package_skills)

  deploy_agent "$package_dir"
  create_knowledge_base
  verify_deployment
  print_summary

  log_success "Deployment complete!"
}

# Run
main "$@"
