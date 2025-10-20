# Parallel Deployment Automation - Odoobo Skills

Comprehensive guide for deploying 5 AI skills in parallel using git worktrees and DigitalOcean Gradient AI.

## Overview

**Architecture**: Git worktrees + Parallel deployment + DO Gradient AI + GitHub Actions CI/CD

**Skills**:

1. **pr-review** - Automated PR code review with multi-framework support
2. **odoo-rpc** - Odoo RPC integration and API wrapper
3. **nl-sql** - Natural language to SQL query generation
4. **visual-diff** - Visual parity testing with SSIM/LPIPS
5. **design-tokens** - Design token extraction from websites

**Performance**:

- **Parallel Execution**: 5 skills deployed concurrently
- **Deployment Time**: ~5-10 minutes (vs 25-50 minutes sequential)
- **Zero-Downtime**: Rolling deployments with health checks
- **Auto-Rollback**: Failed deployments automatically rolled back

**Cost**:

- **Per Skill**: $5-8/month (DO App Platform basic-xxs)
- **Total**: $25-40/month for 5 skills
- **API Usage**: Variable based on traffic (~$10-20/month)

## Prerequisites

### Required Tools

```bash
# Install DigitalOcean CLI
brew install doctl

# Authenticate with DigitalOcean
doctl auth init

# Verify authentication
doctl account get
```

### Required Secrets

```bash
# Add to GitHub repository secrets
DO_ACCESS_TOKEN=dop_v1_...
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GITHUB_TOKEN=github_pat_...
SUPABASE_URL=https://...supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
```

### Environment Setup

```bash
# Clone repository
git clone https://github.com/jgtolentino/odoboo-workspace.git
cd odoboo-workspace

# Install dependencies (if testing locally)
pip install -r services/agent-service/requirements.txt

# Verify git status
git status
git branch
```

## Quick Start

### 1. Setup Worktrees (One-Time)

```bash
# Create 5 parallel worktrees for skill development
./scripts/setup-worktrees.sh

# Verify worktrees created
git worktree list

# Inspect worktree structure
ls -la /tmp/odoobo-worktrees/

# Check status file
cat WORKTREE_STATUS.json
```

**What This Does**:

- Creates 5 branches: `skill/pr-review`, `skill/odoo-rpc`, `skill/nl-sql`, `skill/visual-diff`, `skill/design-tokens`
- Sets up isolated worktrees in `/tmp/odoobo-worktrees/`
- Generates skill manifests and README files
- Creates status tracking file

### 2. Deploy Skills in Parallel

```bash
# Deploy all skills (5 concurrent deployments)
./scripts/deploy-parallel.sh

# Deploy specific skills
./scripts/deploy-parallel.sh pr-review,nl-sql

# View deployment logs
tail -f logs/deployments/deploy-*.log
```

**What This Does**:

- Builds skill packages in parallel
- Creates DO Gradient AI app specs
- Commits and pushes to skill branches
- Triggers deployments to DigitalOcean
- Monitors deployment status
- Updates status file

### 3. Monitor Deployments

```bash
# Real-time monitoring (refreshes every 10s)
./scripts/monitor-deployments.sh

# Custom refresh interval (5s)
./scripts/monitor-deployments.sh 5

# Check all health endpoints
doctl apps list
```

**Dashboard Shows**:

- Deployment status (ACTIVE, PENDING, ERROR)
- Health check results
- App URLs
- Summary counts

### 4. Test Deployed Skills

```bash
# Test all skills
./scripts/test-skills.sh

# Test specific skills
./scripts/test-skills.sh pr-review,visual-diff

# View test results
cat logs/tests/test-*.log
```

**Test Suite Includes**:

1. Health check (HTTP 200 response)
2. Response time (<5000ms)
3. Skill metadata validation
4. Error handling (404/405)
5. Documentation availability (/docs)

### 5. Merge to Main

```bash
# Merge all deployed skills
./scripts/merge-skills.sh

# Merge specific skills
./scripts/merge-skills.sh pr-review,nl-sql

# View merge logs
cat logs/merges/merge-*.log
```

**Safety Checks**:

- Verifies deployment is ACTIVE before merge
- Creates merge commit with deployment metadata
- Updates status file
- Optional worktree cleanup

### 6. Rollback Failed Deployments

```bash
# Rollback all failed deployments
./scripts/rollback-deployment.sh

# Rollback specific skills
./scripts/rollback-deployment.sh pr-review

# View rollback logs
cat logs/rollbacks/rollback-*.log
```

**Rollback Actions**:

- Finds previous ACTIVE deployment
- Triggers rollback deployment
- Monitors rollback status
- Cleans up failed worktrees

## GitHub Actions CI/CD

### Automated Deployment Workflow

**Trigger Conditions**:

1. **Push to skill branches**: `skill/**`
2. **Pull request to main**: Affecting `services/agent-service/skills/**`
3. **Manual trigger**: With custom skill selection

**Workflow Steps**:

1. **Detect Changes**: Identify modified skills
2. **Validate Skills**: Lint, test, structure validation
3. **Build Skills**: Docker image build and test
4. **Deploy to DO**: Parallel deployment to DigitalOcean
5. **Verify Health**: Health checks and smoke tests
6. **Notify**: Deployment report and artifacts

**Usage**:

```bash
# Trigger manual deployment via GitHub UI
# Actions -> Deploy Skills (Parallel) -> Run workflow

# Or via GitHub CLI
gh workflow run deploy-skills-parallel.yml -f skills=pr-review,nl-sql

# Force rebuild all skills
gh workflow run deploy-skills-parallel.yml -f force_rebuild=true
```

**Monitoring**:

```bash
# View workflow runs
gh run list --workflow=deploy-skills-parallel.yml

# View specific run
gh run view <run-id>

# Download deployment artifacts
gh run download <run-id>
```

## Worktree Management

### Worktree Structure

```
/tmp/odoobo-worktrees/
├── pr-review/                    # Isolated git worktree
│   ├── services/agent-service/skills/pr-review/
│   │   ├── manifest.json
│   │   ├── README.md
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── tests/
│   └── infra/do-gradient/pr-review/
│       └── app-spec.yaml
├── odoo-rpc/
├── nl-sql/
├── visual-diff/
└── design-tokens/
```

### Working in Worktrees

```bash
# Navigate to worktree
cd /tmp/odoobo-worktrees/pr-review

# Make changes
vim services/agent-service/skills/pr-review/main.py

# Commit and push
git add .
git commit -m "feat: enhance PR review skill"
git push origin skill/pr-review

# Deployment triggers automatically via GitHub Actions
```

### Worktree Commands

```bash
# List all worktrees
git worktree list

# Remove specific worktree
git worktree remove /tmp/odoobo-worktrees/pr-review

# Prune deleted worktrees
git worktree prune

# Move worktree
git worktree move /tmp/odoobo-worktrees/pr-review /tmp/new-location
```

## DigitalOcean Gradient AI Configuration

### App Spec Format

```yaml
name: odoobo-skill-pr-review
region: sgp

services:
  - name: pr-review
    github:
      repo: jgtolentino/odoboo-workspace
      branch: skill/pr-review
      deploy_on_push: true
    source_dir: /services/agent-service/skills/pr-review

    build_command: |
      pip install -r requirements.txt

    run_command: uvicorn main:app --host 0.0.0.0 --port 8080

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
        value: pr-review
      - key: ANTHROPIC_API_KEY
        value: ${ANTHROPIC_API_KEY}
        type: SECRET
```

### App Management

```bash
# List all apps
doctl apps list

# Get specific app details
doctl apps get <app-id>

# View deployment history
doctl apps list-deployments <app-id>

# View logs
doctl apps logs <app-id> --type=deploy
doctl apps logs <app-id> --type=run --follow

# Update app spec
doctl apps update <app-id> --spec infra/do-gradient/pr-review/app-spec.yaml

# Trigger new deployment
doctl apps create-deployment <app-id>

# Delete app
doctl apps delete <app-id>
```

### Scaling Configuration

```bash
# Horizontal scaling (instance count)
doctl apps update <app-id> --spec <(cat infra/do-gradient/pr-review/app-spec.yaml | \
  yq e '.services[0].instance_count = 3' -)

# Vertical scaling (instance size)
doctl apps update <app-id> --spec <(cat infra/do-gradient/pr-review/app-spec.yaml | \
  yq e '.services[0].instance_size_slug = "apps-s-2vcpu-4gb"' -)
```

## Skill Development Workflow

### 1. Create New Skill

```bash
# Setup worktree for new skill
./scripts/setup-worktrees.sh

# Navigate to skill worktree
cd /tmp/odoobo-worktrees/new-skill

# Implement skill
mkdir -p services/agent-service/skills/new-skill
cat > services/agent-service/skills/new-skill/main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI(title="New Skill")

@app.get("/health")
async def health():
    return {"status": "healthy", "skill": "new-skill"}

@app.post("/invoke")
async def invoke(data: dict):
    # Skill logic here
    return {"result": "success"}
EOF

# Create requirements.txt
cat > services/agent-service/skills/new-skill/requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.6.0
EOF

# Commit and push
git add .
git commit -m "feat: add new-skill implementation"
git push origin skill/new-skill
```

### 2. Test Locally

```bash
# Run skill locally
cd services/agent-service/skills/new-skill
uvicorn main:app --reload --port 8080

# Test health endpoint
curl http://localhost:8080/health

# Test skill invocation
curl -X POST http://localhost:8080/invoke \
  -H "Content-Type: application/json" \
  -d '{"input": "test data"}'
```

### 3. Deploy to Staging

```bash
# Deploy skill to staging
./scripts/deploy-parallel.sh new-skill

# Monitor deployment
./scripts/monitor-deployments.sh

# Test deployed skill
./scripts/test-skills.sh new-skill
```

### 4. Production Release

```bash
# Merge to main after validation
./scripts/merge-skills.sh new-skill

# Tag release
git tag v1.0.0-new-skill
git push --tags

# Cleanup worktree
git worktree remove /tmp/odoobo-worktrees/new-skill
```

## Troubleshooting

### Deployment Failures

**Symptom**: Deployment stuck in PENDING or ERROR state

**Solution**:

```bash
# Check deployment logs
doctl apps logs <app-id> --type=deploy

# Common issues:
# 1. Build failure -> Check requirements.txt dependencies
# 2. Port mismatch -> Ensure http_port matches app port (8080)
# 3. Health check failure -> Verify /health endpoint responds HTTP 200
# 4. Environment variables -> Check secrets are set correctly

# Rollback to previous version
./scripts/rollback-deployment.sh <skill-name>

# Or manual rollback
doctl apps list-deployments <app-id>
doctl apps create-deployment <app-id> --deployment-id <previous-deployment-id>
```

### Health Check Failures

**Symptom**: App deployed but health checks fail

**Solution**:

```bash
# Test health endpoint directly
APP_URL=$(doctl apps get <app-id> --format DefaultIngress --no-header)
curl -v https://$APP_URL/health

# Check app logs
doctl apps logs <app-id> --type=run --follow

# Common issues:
# 1. Wrong health path -> Update app-spec.yaml health_check.http_path
# 2. Slow startup -> Increase health_check.initial_delay_seconds
# 3. Port binding -> Ensure app listens on 0.0.0.0:8080
```

### Merge Conflicts

**Symptom**: Merge fails with conflicts

**Solution**:

```bash
# Abort failed merge
git merge --abort

# Rebase skill branch on main
cd /tmp/odoobo-worktrees/<skill>
git fetch origin main
git rebase origin/main

# Resolve conflicts
git status
# Edit conflicting files
git add <resolved-files>
git rebase --continue

# Push rebased branch
git push origin skill/<skill> --force

# Retry merge
cd <main-repo>
./scripts/merge-skills.sh <skill>
```

### Worktree Issues

**Symptom**: Worktree creation fails or corrupt

**Solution**:

```bash
# Remove corrupt worktree
git worktree remove /tmp/odoobo-worktrees/<skill> --force

# Prune worktree references
git worktree prune

# Recreate worktree
./scripts/setup-worktrees.sh

# Or manually
git worktree add /tmp/odoobo-worktrees/<skill> skill/<skill>
```

### GitHub Actions Failures

**Symptom**: CI/CD workflow fails

**Solution**:

```bash
# View workflow run details
gh run view <run-id>

# Check job logs
gh run view <run-id> --log

# Common issues:
# 1. Missing secrets -> Add to repository settings
# 2. doctl auth failure -> Verify DO_ACCESS_TOKEN is valid
# 3. Build timeout -> Increase workflow timeout or optimize build
# 4. Test failures -> Fix tests before deployment

# Re-run failed workflow
gh run rerun <run-id>
```

## Performance Optimization

### Parallel Execution

- **5 concurrent deployments**: 80% time reduction vs sequential
- **Background processes**: Non-blocking deployment monitoring
- **GitHub Actions matrix**: Parallel validation and build

### Build Optimization

```bash
# Use Docker layer caching
# Add to app-spec.yaml
build_command: |
  pip install --no-cache-dir -r requirements.txt

# Or use Docker buildx with cache
docker buildx build --cache-from=type=registry,ref=<image> .
```

### Resource Allocation

```bash
# Instance sizes (monthly cost)
apps-s-1vcpu-0.5gb  # $5/month  - Development
apps-s-1vcpu-1gb    # $7/month  - Production light
apps-s-2vcpu-4gb    # $25/month - Production heavy

# Auto-scaling (horizontal)
instance_count: 1-5  # Scale based on load
```

### Health Check Tuning

```yaml
health_check:
  initial_delay_seconds: 30 # Increase for slow startup
  period_seconds: 10 # Decrease for faster detection
  timeout_seconds: 5 # Increase for slow responses
  success_threshold: 1 # Min successful checks
  failure_threshold: 3 # Max failed checks before restart
```

## Security Best Practices

### Secret Management

```bash
# Store secrets in GitHub Secrets, not code
# Access via environment variables only

# Rotate secrets regularly
doctl apps update <app-id> --spec <updated-spec-with-new-secrets>

# Use least-privilege API keys
# - Read-only database credentials for analytics
# - Fine-grained GitHub tokens with minimum scopes
```

### Access Control

```bash
# Restrict app access to specific IPs (optional)
# Add to app-spec.yaml
ingress:
  rules:
    - component:
        name: pr-review
      match:
        path:
          prefix: /
      cors:
        allow_origins:
          - https://yourdomain.com

# Enable HTTPS only
# DO App Platform enforces HTTPS by default
```

### Monitoring & Alerts

```bash
# Setup alerts for deployments
# Already configured in app-spec.yaml
alerts:
  - rule: DEPLOYMENT_FAILED
  - rule: DOMAIN_FAILED

# Add custom alerts via DO dashboard
# - CPU usage > 80%
# - Memory usage > 90%
# - Response time > 5s
```

## Cost Management

### Monthly Cost Breakdown

```
Per Skill (basic-xxs, 1 instance):
- DO App Platform: $5/month
- API Usage (Anthropic): ~$2-5/month (varies by traffic)
- Total per skill: $7-10/month

Total for 5 Skills:
- Infrastructure: $25/month
- API Usage: ~$10-25/month (varies by traffic)
- Total: $35-50/month

Compared to:
- Azure previous setup: $100+/month
- DO Droplet (previous): $21-38/month (higher maintenance)
```

### Cost Optimization Tips

```bash
# 1. Use development environment for testing
# - Smaller instance sizes
# - Lower resource limits

# 2. Implement caching
# - Redis for frequent queries
# - CDN for static assets

# 3. Scale down during off-hours
# - Use DO API to adjust instance_count

# 4. Monitor API usage
# - Set token limits per request
# - Implement rate limiting

# 5. Consolidate low-traffic skills
# - Merge into single service if usage is low
```

## Maintenance

### Daily Tasks

```bash
# Monitor deployment health
./scripts/monitor-deployments.sh

# Check for failed deployments
./scripts/rollback-deployment.sh

# Review logs for errors
doctl apps logs <app-id> --type=run | grep ERROR
```

### Weekly Tasks

```bash
# Review cost and usage
doctl monitoring alert-policy list

# Update dependencies
# For each skill worktree:
cd /tmp/odoobo-worktrees/<skill>
pip list --outdated
# Update requirements.txt and redeploy

# Cleanup old deployments
doctl apps list-deployments <app-id> | tail -n +6  # Keep last 5
```

### Monthly Tasks

```bash
# Security updates
# Update base images and dependencies
# Test thoroughly before deploying

# Performance review
# Analyze response times and resource usage
# Optimize bottlenecks

# Cost review
# Analyze usage patterns
# Adjust instance sizes and counts

# Backup configuration
tar -czf backup-$(date +%Y%m%d).tar.gz \
  infra/do-gradient/ \
  services/agent-service/skills/ \
  scripts/
```

## Support & Resources

### Documentation

- **Main README**: [services/README.md](../services/README.md)
- **Agent Service**: [services/agent-service/README.md](../services/agent-service/README.md)
- **Deployment Guide**: [services/DEPLOYMENT.md](../services/DEPLOYMENT.md)

### External Resources

- **DigitalOcean App Platform**: https://docs.digitalocean.com/products/app-platform/
- **doctl CLI**: https://docs.digitalocean.com/reference/doctl/
- **GitHub Actions**: https://docs.github.com/en/actions

### Getting Help

- **Issues**: https://github.com/jgtolentino/odoboo-workspace/issues
- **Discussions**: https://github.com/jgtolentino/odoboo-workspace/discussions
- **DO Support**: https://www.digitalocean.com/support/

## Appendix

### Script Reference

| Script                   | Purpose                         | Usage                                         |
| ------------------------ | ------------------------------- | --------------------------------------------- |
| `setup-worktrees.sh`     | Create 5 parallel worktrees     | `./scripts/setup-worktrees.sh`                |
| `deploy-parallel.sh`     | Deploy skills in parallel       | `./scripts/deploy-parallel.sh [skills]`       |
| `merge-skills.sh`        | Merge completed skills to main  | `./scripts/merge-skills.sh [skills]`          |
| `rollback-deployment.sh` | Rollback failed deployments     | `./scripts/rollback-deployment.sh [skills]`   |
| `monitor-deployments.sh` | Real-time deployment monitoring | `./scripts/monitor-deployments.sh [interval]` |
| `test-skills.sh`         | Comprehensive skill testing     | `./scripts/test-skills.sh [skills]`           |

### Environment Variables

| Variable                    | Purpose                         | Required |
| --------------------------- | ------------------------------- | -------- |
| `DO_ACCESS_TOKEN`           | DigitalOcean API authentication | Yes      |
| `ANTHROPIC_API_KEY`         | Claude API access               | Yes      |
| `OPENAI_API_KEY`            | OpenAI API access               | Yes      |
| `GITHUB_TOKEN`              | GitHub API access (PR review)   | Optional |
| `SUPABASE_URL`              | Supabase project URL            | Optional |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase admin access           | Optional |

### Deployment Timeline

| Phase               | Duration     | Actions                             |
| ------------------- | ------------ | ----------------------------------- |
| **Worktree Setup**  | ~30s         | Create 5 branches and worktrees     |
| **Parallel Build**  | ~2-3min      | Build 5 skill packages concurrently |
| **Parallel Deploy** | ~3-5min      | Deploy to DO App Platform           |
| **Health Checks**   | ~1-2min      | Verify all deployments              |
| **Total**           | **~5-10min** | Full parallel deployment cycle      |

Compare to sequential: ~25-50 minutes (5-10 min per skill × 5 skills)

---

**Generated with Claude Code parallel deployment automation**
**Last Updated**: 2025-10-21
