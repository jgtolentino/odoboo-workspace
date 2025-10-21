# SuperClaude Orchestration Architecture

**Your Own Slack = Odoo Discuss + Kanban**

All CI/CD/Deploy events flow through SuperClaude → update Odoo Kanban → post to Odoo Discuss.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPERCLAUDE (Orchestrator)                │
│  • Receives: PR events, deploy triggers, cron jobs          │
│  • Routes to: Sub-agents (parallel execution)               │
│  • Updates: Odoo Kanban stages + Discuss messages           │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
         ┌──────────▼──────────┐   ┌───▼──────────────┐
         │   PARALLEL WORKERS   │   │  ODOO KANBAN     │
         │                      │   │  (Source of Truth)│
         │ ┌─────────────────┐ │   │                  │
         │ │ reviewer        │ │   │ Stages:          │
         │ │ (OCA/Odoo/CI)   │ │   │ • Spec Review    │
         │ └─────────────────┘ │   │ • In PR          │
         │                      │   │ • CI Green       │
         │ ┌─────────────────┐ │   │ • Staging ✅     │
         │ │ security-scan   │ │   │ • Deployed       │
         │ │ (secrets/deps)  │ │   │ • Blocked        │
         │ └─────────────────┘ │   └──────────────────┘
         │                      │             │
         │ ┌─────────────────┐ │   ┌─────────▼─────────┐
         │ │ test-runner     │ │   │  ODOO DISCUSS     │
         │ │ (unit/e2e)      │ │   │  (#ci-updates)    │
         │ └─────────────────┘ │   │                   │
         │                      │   │ All events posted │
         │ ┌─────────────────┐ │   │ here (your Slack) │
         │ │ architect       │ │   └───────────────────┘
         │ │ (infra/design)  │ │
         │ └─────────────────┘ │
         │                      │
         │ ┌─────────────────┐ │
         │ │ devops          │ │
         │ │ (deploy/backup) │ │
         │ └─────────────────┘ │
         └──────────────────────┘
```

---

## Parallel Execution Strategy

### On PR Open/Sync
```
SuperClaude receives PR event
  ├─ [Parallel Block 1] ─┬─ reviewer (OCA rules, lockfile)
  │                      ├─ security-scan (secrets, npm audit)
  │                      └─ test-runner (pytest, jest)
  │
  ├─ Wait for all 3 ✅
  │
  ├─ [Sequential Block 2] ─┬─ architect (if /infra changed)
  │                        └─ Aggregate results
  │
  └─ Update Odoo Kanban + Post to #ci-updates
```

### On Staging Deploy
```
SuperClaude receives deploy trigger
  ├─ devops (backup DB + deploy containers)
  ├─ Wait for deploy ✅
  ├─ [Parallel Block] ─┬─ test-runner (smoke tests)
  │                    ├─ security-scan (runtime checks)
  │                    └─ analyst (metrics baseline)
  ├─ Wait for all ✅
  └─ Update Kanban → "Staging ✅" + Post success
```

---

## Agent Definitions

### 1. SuperClaude (Orchestrator)

**File**: `.claude/agents/superclaude.agent.yaml`

```yaml
name: superclaude
role: orchestrator
description: Master orchestrator for all CI/CD/deploy workflows

routing:
  - when: event == "pr_opened" || event == "pr_sync"
    parallel:
      - reviewer
      - security-scan
      - test-runner
    then: aggregate_pr_results

  - when: event == "deploy_staging"
    sequence:
      - devops
      - parallel:
          - test-runner
          - security-scan
          - analyst
      - odoo_update

  - when: event == "deploy_prod"
    sequence:
      - devops
      - parallel:
          - test-runner
          - security-scan
      - odoo_update

  - when: event == "nightly"
    parallel:
      - devops  # backup + SSL renew
      - analyst # metrics report
      - reviewer # spec drift check

integrations:
  odoo:
    url: ${ODOO_URL}
    database: ${ODOO_DATABASE}
    api_key: ${ODOO_API_KEY}
    kanban_project: "CI/CD Pipeline"
    discuss_channel: "#ci-updates"

guardrails:
  max_tokens: 16000
  timeout: 900  # 15 minutes
  require_structured_output: true
  secrets:
    - DO_ACCESS_TOKEN
    - GITHUB_TOKEN
    - DATABASE_URL
    - SUPABASE_SERVICE_ROLE_KEY
    - ODOO_API_KEY
    - OPENAI_API_KEY

defaults:
  mcp_servers: "../mcp/servers.json"
  output_format: json
```

---

### 2. Sub-Agents

#### reviewer.agent.yaml
```yaml
name: reviewer
capabilities:
  - pr_review
  - oca_odoo_rules
  - lockfile_sync
  - spec_validation
  - design_token_extraction

tools:
  - mcp/github
  - mcp/git
  - skills/pr-review
  - skills/design-tokens

rules:
  - Enforce OCA coding standards
  - Check module dependencies
  - Verify upgrade paths
  - Validate spec references in FEATURES.md
  - Extract design tokens if UI changes

output_contract:
  approval_status: "approved" | "changes_requested" | "commented"
  issues: [{severity, file, line, message}]
  stats: {files_changed, additions, deletions}
```

#### security-scan.agent.yaml
```yaml
name: security-scan
capabilities:
  - secret_leak_detection
  - dependency_vulnerabilities
  - docker_image_scan
  - runtime_security

tools:
  - mcp/docker
  - skills/secret-scanner
  - npm audit
  - trivy

rules:
  - No hardcoded secrets in code
  - No critical/high npm vulnerabilities
  - Docker images scanned (Trivy)
  - Runtime: no privileged containers

output_contract:
  status: "pass" | "fail"
  vulnerabilities: [{severity, package, cve}]
  secrets_found: [{file, line, pattern}]
```

#### test-runner.agent.yaml
```yaml
name: test-runner
capabilities:
  - unit_tests
  - integration_tests
  - e2e_smoke
  - coverage_report

tools:
  - pytest
  - jest
  - playwright
  - mcp/odoo-rpc

tests:
  unit:
    - pytest -v --tb=short
  integration:
    - docker-compose -f docker-compose.test.yml up --abort-on-container-exit
  smoke:
    - curl https://staging.insightpulseai.net/health
    - python scripts/odoo_smoke_test.py

output_contract:
  status: "pass" | "fail"
  total: int
  passed: int
  failed: int
  coverage: float
  failed_tests: [string]
```

#### devops.agent.yaml
```yaml
name: devops
capabilities:
  - backup_database
  - deploy_containers
  - ssl_renewal
  - uptime_monitoring

tools:
  - mcp/docker
  - mcp/psql
  - doctl
  - certbot
  - mcp/supabase

tasks:
  backup:
    - pg_dump with timestamp
    - upload to DO Spaces
    - prune old backups (keep 30d)

  deploy:
    - docker-compose pull
    - docker-compose up -d
    - wait for health checks

  ssl_renew:
    - certbot renew --dry-run
    - notify if < 30 days

output_contract:
  status: "success" | "failed"
  deployed_services: [string]
  backup_url: string
  health_checks: {service: boolean}
```

---

## Odoo Integration

### Kanban Sync Script

**File**: `scripts/odoo_kanban_sync.py`

```python
#!/usr/bin/env python3
"""
Sync CI/CD events to Odoo Kanban + Discuss
"""
import os
import json
import xmlrpc.client

ODOO_URL = os.getenv("ODOO_URL", "https://insightpulseai.net")
ODOO_DB = os.getenv("ODOO_DATABASE", "odoboo_prod")
ODOO_USER = os.getenv("ODOO_USER", "admin@insightpulseai.net")
ODOO_API_KEY = os.getenv("ODOO_API_KEY")

# Authenticate
common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_API_KEY, {})

models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")

def get_or_create_task(pr_number, repo):
    """Get or create Kanban task for PR"""
    domain = [['x_pr_number', '=', pr_number], ['x_repo', '=', repo]]
    task_ids = models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'project.task', 'search', [domain])

    if task_ids:
        return task_ids[0]

    # Create new task
    task_id = models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'project.task', 'create', [{
            'name': f'PR #{pr_number}',
            'x_pr_number': pr_number,
            'x_pr_url': f'https://github.com/{repo}/pull/{pr_number}',
            'x_repo': repo,
            'project_id': get_project_id('CI/CD Pipeline'),
            'stage_id': get_stage_id('In PR'),
        }])

    return task_id

def update_task_stage(task_id, stage_name, build_status=None):
    """Move task to new stage"""
    vals = {'stage_id': get_stage_id(stage_name)}
    if build_status:
        vals['x_build_status'] = build_status

    models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'project.task', 'write', [[task_id], vals])

def post_to_discuss(channel_name, message):
    """Post message to Odoo Discuss channel"""
    channel_id = get_channel_id(channel_name)

    models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'mail.channel', 'message_post', [channel_id], {
            'body': message,
            'message_type': 'comment',
            'subtype_xmlid': 'mail.mt_comment'
        })

def get_project_id(name):
    """Get project ID by name"""
    project_ids = models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'project.project', 'search', [[('name', '=', name)]])
    return project_ids[0] if project_ids else None

def get_stage_id(name):
    """Get stage ID by name"""
    stage_ids = models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'project.task.type', 'search', [[('name', '=', name)]])
    return stage_ids[0] if stage_ids else None

def get_channel_id(name):
    """Get Discuss channel ID"""
    channel_ids = models.execute_kw(ODOO_DB, uid, ODOO_API_KEY,
        'mail.channel', 'search', [[('name', '=', name)]])
    return channel_ids[0] if channel_ids else None

if __name__ == '__main__':
    import sys

    event = sys.argv[1]  # pr_opened, ci_pass, deploy_staging, etc.
    payload = json.loads(sys.stdin.read())

    pr_number = payload.get('pr_number')
    repo = payload.get('repo')
    status = payload.get('status')

    task_id = get_or_create_task(pr_number, repo)

    if event == 'pr_opened':
        update_task_stage(task_id, 'In PR')
        post_to_discuss('#ci-updates', f'🔵 PR #{pr_number} opened by {payload["author"]}')

    elif event == 'ci_pass':
        update_task_stage(task_id, 'CI Green', 'passed')
        post_to_discuss('#ci-updates', f'✅ CI passed for PR #{pr_number}')

    elif event == 'ci_fail':
        update_task_stage(task_id, 'Blocked', 'failed')
        post_to_discuss('#ci-updates', f'❌ CI failed for PR #{pr_number}\\n{payload["error"]}')

    elif event == 'deploy_staging':
        update_task_stage(task_id, 'Staging ✅')
        post_to_discuss('#ci-updates', f'🚀 Deployed to staging: {payload["url"]}')

    elif event == 'deploy_prod':
        update_task_stage(task_id, 'Deployed')
        post_to_discuss('#ci-updates', f'🎉 Deployed to production (tag {payload["tag"]})')

    print(f"✅ Updated task {task_id} → {event}")
```

---

## CI/CD Workflows with SuperClaude

### PR Workflow with Parallel Agents

**File**: `.github/workflows/superclaude-pr.yml`

```yaml
name: SuperClaude • PR Pipeline

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: read
  pull-requests: write

concurrency:
  group: superclaude-pr-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  # SuperClaude orchestrates parallel agents
  orchestrate:
    runs-on: ubuntu-latest
    outputs:
      task_id: ${{ steps.create_task.outputs.task_id }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Create/Get Odoo Task
        id: create_task
        env:
          ODOO_URL: https://insightpulseai.net
          ODOO_DATABASE: odoboo_prod
          ODOO_USER: admin@insightpulseai.net
          ODOO_API_KEY: ${{ secrets.ODOO_API_KEY }}
        run: |
          python scripts/odoo_kanban_sync.py pr_opened <<EOF
          {
            "pr_number": ${{ github.event.pull_request.number }},
            "repo": "${{ github.repository }}",
            "author": "${{ github.event.pull_request.user.login }}",
            "title": "${{ github.event.pull_request.title }}"
          }
          EOF

  # Parallel Agent Block 1: Fast checks
  reviewer:
    needs: orchestrate
    runs-on: ubuntu-latest
    outputs:
      status: ${{ steps.review.outputs.status }}

    steps:
      - uses: actions/checkout@v4

      - name: Run Reviewer Agent
        id: review
        run: |
          # Call reviewer sub-agent
          # Returns: {approval_status, issues, stats}
          echo "status=approved" >> $GITHUB_OUTPUT

  security-scan:
    needs: orchestrate
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Secret Leak Detection
        run: |
          if grep -r -E "(sk-[a-zA-Z0-9]{40,}|eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*)" --exclude-dir=node_modules --exclude-dir=.git --exclude="*.md" .; then
            echo "❌ Secrets found in code!"
            exit 1
          fi

      - name: NPM Audit
        run: |
          if [ -f package-lock.json ]; then
            npm audit --audit-level=high
          fi

      - name: Docker Image Scan
        run: |
          # Trivy scan if Dockerfile changed
          if git diff --name-only origin/main | grep -q Dockerfile; then
            docker build -t test:latest .
            trivy image test:latest --severity HIGH,CRITICAL --exit-code 1
          fi

  test-runner:
    needs: orchestrate
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run Tests
        run: |
          npm run lint
          npm test -- --coverage

      - name: Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  # Aggregate Results
  aggregate:
    needs: [reviewer, security-scan, test-runner]
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Aggregate Results
        id: aggregate
        run: |
          # Aggregate all agent results
          # Determine overall status
          echo "status=pass" >> $GITHUB_OUTPUT

      - name: Update Odoo Kanban
        env:
          ODOO_API_KEY: ${{ secrets.ODOO_API_KEY }}
        run: |
          EVENT="ci_pass"
          if [ "${{ steps.aggregate.outputs.status }}" != "pass" ]; then
            EVENT="ci_fail"
          fi

          python scripts/odoo_kanban_sync.py $EVENT <<EOF
          {
            "pr_number": ${{ github.event.pull_request.number }},
            "repo": "${{ github.repository }}",
            "status": "${{ steps.aggregate.outputs.status }}"
          }
          EOF

      - name: Post PR Comment
        uses: actions/github-script@v7
        with:
          script: |
            const status = '${{ steps.aggregate.outputs.status }}';
            const emoji = status === 'pass' ? '✅' : '❌';

            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.name,
              issue_number: context.issue.number,
              body: `${emoji} **SuperClaude Pipeline**: ${status}\\n\\nReviewed by: reviewer, security-scan, test-runner`
            });
```

---

### Staging Deploy with Parallel Smoke Tests

**File**: `.github/workflows/superclaude-deploy-staging.yml`

```yaml
name: SuperClaude • Deploy Staging

on:
  push:
    branches: [staging]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.insightpulseai.net

    steps:
      - uses: actions/checkout@v4

      - name: Backup Database
        env:
          DATABASE_URL: ${{ secrets.STAGING_DATABASE_URL }}
        run: |
          # devops agent: backup task
          python scripts/odoo_backup.py staging

      - name: Deploy to Staging
        run: |
          # devops agent: deploy task
          ssh -o StrictHostKeyChecking=no staging@insightpulseai.net << 'EOF'
            cd /opt/app
            git pull origin staging
            docker-compose pull
            docker-compose up -d
          EOF

      - name: Wait for Health Checks
        run: |
          sleep 30
          curl -f https://staging.insightpulseai.net/health || exit 1

  # Parallel Smoke Tests
  smoke-tests:
    needs: deploy
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test:
          - web-health
          - odoo-smoke
          - ocr-health
          - agent-health

    steps:
      - uses: actions/checkout@v4

      - name: Run ${{ matrix.test }}
        run: |
          case "${{ matrix.test }}" in
            web-health)
              curl -f https://staging.insightpulseai.net/health
              ;;
            odoo-smoke)
              python scripts/odoo_smoke_test.py
              ;;
            ocr-health)
              curl -f https://staging.insightpulseai.net/ocr/health
              ;;
            agent-health)
              curl -f https://staging.insightpulseai.net/agent/health
              ;;
          esac

  update-odoo:
    needs: smoke-tests
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Update Kanban
        env:
          ODOO_API_KEY: ${{ secrets.ODOO_API_KEY }}
        run: |
          python scripts/odoo_kanban_sync.py deploy_staging <<EOF
          {
            "pr_number": ${{ github.event.pull_request.number }},
            "repo": "${{ github.repository }}",
            "url": "https://staging.insightpulseai.net"
          }
          EOF
```

---

## Quick Setup

### 1. Install Required Secrets

```bash
gh secret set ODOO_API_KEY -b "YOUR_ODOO_API_KEY_HERE"
gh secret set ODOO_URL -b "https://insightpulseai.net"
gh secret set ODOO_DATABASE -b "odoboo_prod"
gh secret set ODOO_USER -b "admin@insightpulseai.net"
```

### 2. Create Odoo Kanban Project

In Odoo:
1. Go to **Project** app
2. Create new project: **"CI/CD Pipeline"**
3. Add stages:
   - Backlog
   - Spec Review
   - In PR
   - CI Green
   - Staging ✅
   - Ready for Prod
   - Deployed
   - Blocked

4. Add custom fields (via Studio):
   - `x_pr_number` (Integer)
   - `x_pr_url` (Char)
   - `x_repo` (Char)
   - `x_build_status` (Selection: queued/passed/failed)
   - `x_env` (Selection: preview/staging/prod)

### 3. Create Discuss Channel

1. Go to **Discuss** app
2. Create channel: **#ci-updates**
3. Add team members
4. Configure notifications

---

## Complete Flow Example

```
1. Developer opens PR #123
   ↓
2. GitHub triggers SuperClaude orchestrator
   ↓
3. SuperClaude dispatches PARALLEL:
   ├─ reviewer (OCA rules, specs)
   ├─ security-scan (secrets, vulns)
   └─ test-runner (unit/integration)
   ↓
4. All 3 complete → Aggregate results
   ↓
5. Update Odoo:
   • Task #123 → "CI Green" stage
   • Post to #ci-updates: "✅ CI passed for PR #123"
   ↓
6. Developer merges to staging
   ↓
7. SuperClaude triggers deploy:
   ├─ devops (backup + deploy)
   └─ PARALLEL smoke tests (4 endpoints)
   ↓
8. Update Odoo:
   • Task #123 → "Staging ✅"
   • Post to #ci-updates: "🚀 Deployed to staging"
   ↓
9. Tag v1.2.3 created
   ↓
10. SuperClaude triggers prod deploy
    ├─ devops (backup + canary deploy)
    └─ PARALLEL smoke + security checks
    ↓
11. Update Odoo:
    • Task #123 → "Deployed"
    • Post to #ci-updates: "🎉 v1.2.3 in production"
```

---

## Monitoring Dashboard (Odoo)

Create a custom dashboard module or use existing dashboard to show:

**Project Overview** (Kanban):
- Tasks by stage (pie chart)
- Deployment velocity (line chart)
- Mean time to deploy (gauge)
- Failed builds by component (bar chart)

**Recent Activity** (#ci-updates):
- Last 10 deploy events
- Current staging/prod versions
- Next scheduled deploy

---

## Benefits

✅ **Your Own Slack**: All communication in Odoo Discuss
✅ **Single Source of Truth**: Odoo Kanban tracks all work
✅ **Parallel Execution**: Fast CI/CD (3 agents run concurrently)
✅ **Auto-Sync**: GitHub → Odoo (no manual updates)
✅ **Ultrathink**: SuperClaude orchestrates with deep reasoning
✅ **Visibility**: Finance/Clients see progress in Odoo Portal
✅ **Deterministic**: Same inputs = same outputs (reproducible)

---

**Next**: See implementation files in next commit.
