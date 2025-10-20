# Quick Start: Parallel Skill Deployment

**5-minute guide to deploy 5 skills in parallel**

## Prerequisites Checklist

```bash
# 1. Install doctl
brew install doctl

# 2. Authenticate
doctl auth init

# 3. Add GitHub Secrets (via UI or CLI)
# DO_ACCESS_TOKEN, ANTHROPIC_API_KEY, OPENAI_API_KEY, GITHUB_TOKEN
```

## Deployment in 5 Commands

```bash
# 1. Setup worktrees (one-time, ~30s)
./scripts/setup-worktrees.sh

# 2. Deploy all skills in parallel (~5-10 min)
./scripts/deploy-parallel.sh

# 3. Monitor deployment (real-time dashboard)
./scripts/monitor-deployments.sh

# 4. Test all endpoints (~1 min)
./scripts/test-skills.sh

# 5. Merge to main when ready
./scripts/merge-skills.sh
```

## Visual Status Check

```bash
# One-line status check
doctl apps list | grep "odoobo-skill-"

# Detailed health check
for skill in pr-review odoo-rpc nl-sql visual-diff design-tokens; do
  echo -n "$skill: "
  curl -sf "https://odoobo-skill-$skill-{app-id}.ondigitalocean.app/health" || echo "FAIL"
done
```

## Common Operations

### Deploy Single Skill

```bash
./scripts/deploy-parallel.sh pr-review
```

### Rollback Failed Deployment

```bash
./scripts/rollback-deployment.sh pr-review
```

### Update Existing Skill

```bash
cd /tmp/odoobo-worktrees/pr-review
# Make changes
git add . && git commit -m "fix: update logic"
git push origin skill/pr-review
# Auto-deploys via GitHub Actions
```

### Monitor Live

```bash
# Dashboard (refreshes every 10s)
./scripts/monitor-deployments.sh

# Manual check
doctl apps list --format Spec.Name,ActiveDeployment.Phase
```

## Troubleshooting Quick Fixes

### Deployment Stuck

```bash
# Check logs
doctl apps logs <app-id> --type=deploy

# Rollback
./scripts/rollback-deployment.sh <skill>
```

### Health Check Fails

```bash
# Get app URL
APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "odoobo-skill-pr-review" | awk '{print $1}')
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)

# Test manually
curl -v https://$APP_URL/health

# Check logs
doctl apps logs $APP_ID --type=run --follow
```

### Merge Conflict

```bash
git merge --abort
cd /tmp/odoobo-worktrees/<skill>
git fetch origin main
git rebase origin/main
# Resolve conflicts
git add . && git rebase --continue
git push origin skill/<skill> --force
```

## File Reference

| File                             | Purpose             |
| -------------------------------- | ------------------- |
| `scripts/setup-worktrees.sh`     | Create 5 worktrees  |
| `scripts/deploy-parallel.sh`     | Parallel deployment |
| `scripts/merge-skills.sh`        | Merge to main       |
| `scripts/rollback-deployment.sh` | Rollback failed     |
| `scripts/monitor-deployments.sh` | Real-time dashboard |
| `scripts/test-skills.sh`         | Test suite          |
| `WORKTREE_STATUS.json`           | Status tracking     |
| `logs/`                          | All deployment logs |

## GitHub Actions

### Manual Trigger

```bash
gh workflow run deploy-skills-parallel.yml

# Specific skills
gh workflow run deploy-skills-parallel.yml -f skills=pr-review,nl-sql

# Force rebuild
gh workflow run deploy-skills-parallel.yml -f force_rebuild=true
```

### View Status

```bash
# List runs
gh run list --workflow=deploy-skills-parallel.yml

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

## Cost Estimate

| Item                           | Cost/Month |
| ------------------------------ | ---------- |
| 5 Skills (DO App Platform)     | $25-40     |
| API Usage (Anthropic + OpenAI) | $10-20     |
| **Total**                      | **$35-60** |

## Support

- **Full Documentation**: [docs/PARALLEL_DEPLOYMENT.md](docs/PARALLEL_DEPLOYMENT.md)
- **Implementation Summary**: [PARALLEL_DEPLOYMENT_SUMMARY.md](PARALLEL_DEPLOYMENT_SUMMARY.md)
- **Issues**: https://github.com/jgtolentino/odoboo-workspace/issues

---

**Generated with Claude Code**
**Last Updated**: 2025-10-21
