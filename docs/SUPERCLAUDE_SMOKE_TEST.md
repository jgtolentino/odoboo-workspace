# SuperClaude Smoke Test Guide

Complete validation checklist for your Odoo-as-Slack + SuperClaude CI/CD orchestration.

---

## Prerequisites

Before running smoke tests, ensure bootstrap completed successfully:

```bash
./scripts/bootstrap_superclaude.sh
```

Expected output:
- ✅ GitHub secrets configured (4 required)
- ✅ Odoo project "CI/CD Pipeline" created
- ✅ 8 stages configured (Backlog → Deployed)
- ✅ 9 custom fields added (x_pr_number, x_build_status, etc.)
- ✅ Discuss channel #ci-updates created

---

## Smoke Test 1: PR Creation Flow

**What it tests**: GitHub → Odoo sync on PR events

### Steps

```bash
# 1. Create test branch
git checkout -b test/superclaude-$(date +%s)

# 2. Add test file
echo "$(date) - SuperClaude smoke test" >> SUPERCLAUDE_SMOKE.md

# 3. Commit and push
git add SUPERCLAUDE_SMOKE.md
git commit -m "chore: superclaude smoke test - PR creation"
git push -u origin HEAD

# 4. Create PR via GitHub CLI
gh pr create \
  --title "🧪 SuperClaude Smoke Test" \
  --body "Automated smoke test for SuperClaude orchestration" \
  --label "test" \
  --draft
```

### Expected Results

**In GitHub Actions** (within 30 seconds):
1. ✅ Workflow `superclaude-pr` starts
2. ✅ Job `orchestrate` completes (sets up context)
3. ✅ Jobs run **in parallel**:
   - `reviewer` (OCA rules, lockfile sync)
   - `security-scan` (secret detection, npm audit)
   - `test-runner` (lint, unit tests)
4. ✅ Job `aggregate` posts results to Odoo

**In Odoo Kanban** (`${ODOO_URL}/web#action=project.action_view_task`):
1. ✅ New task appears in **"In PR"** stage
2. ✅ Task name: `PR #<number>`
3. ✅ Custom fields populated:
   - `x_pr_number`: PR number
   - `x_pr_url`: GitHub PR link
   - `x_repo`: `jgtolentino/odoboo-workspace`
   - `x_build_status`: `queued` → `running` → `passed`
   - `x_author`: Your GitHub username

**In Odoo Discuss** (`${ODOO_URL}/web#action=mail.action_discuss`):
1. ✅ Channel `#ci-updates` shows new message:
   ```
   🔵 PR #<number> opened by <your-username>
   Title: 🧪 SuperClaude Smoke Test
   Link: https://github.com/jgtolentino/odoboo-workspace/pull/<number>
   ```
2. ✅ Follow-up message when CI passes:
   ```
   ✅ CI passed for PR #<number>
   - Reviewer: OCA rules ✓
   - Security: No issues found
   - Tests: All passed
   ```

### Verify Logs

```bash
# GitHub Actions logs
gh run list --limit 5
gh run view <run-id> --log

# Odoo container logs (if sync script runs server-side)
docker logs odoo18 --tail 100 --follow | grep -i "superclaude\|kanban"
```

---

## Smoke Test 2: Parallel Agent Execution

**What it tests**: All 3 agents run concurrently (not sequential)

### Validation

1. Open GitHub Actions run for your PR
2. Click on the running workflow
3. Verify timeline shows **parallel execution**:

```
orchestrate ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✓ (15s)
            ┃
            ┣━━━ reviewer ━━━━━━━━━━━━━━━━━━ ✓ (45s)
            ┃
            ┣━━━ security-scan ━━━━━━━━━━━━ ✓ (38s)
            ┃
            ┣━━━ test-runner ━━━━━━━━━━━━━━ ✓ (52s)
            ┃
            ┗━━━ aggregate ━━━━━━━━━━━━━━━━ ✓ (12s)
```

**Expected behavior**:
- ✅ `reviewer`, `security-scan`, `test-runner` start at **same time**
- ✅ `aggregate` waits for all 3 to complete
- ✅ Total time ≈ max(reviewer, security, test) + overhead
- ❌ **NOT** sequential (would be ~135s instead of ~65s)

---

## Smoke Test 3: CI Status Updates

**What it tests**: Odoo task updates as CI progresses

### Steps

```bash
# 1. Make PR fail intentionally
echo "const broken = 'syntax error" >> app/test-fail.js
git add app/test-fail.js
git commit -m "test: intentional failure"
git push
```

### Expected Results

**In Odoo Kanban**:
1. ✅ Task moves to **"Blocked"** stage
2. ✅ `x_build_status` changes to `failed`
3. ✅ Task description updated with error details

**In Odoo Discuss**:
```
❌ CI failed for PR #<number>
- Reviewer: ✓ Passed
- Security: ✓ Passed
- Tests: ✗ Failed (syntax error in app/test-fail.js)

View logs: https://github.com/jgtolentino/odoboo-workspace/actions/runs/<id>
```

### Fix and Verify

```bash
# 2. Fix the error
git rm app/test-fail.js
git commit -m "test: remove intentional failure"
git push

# 3. Verify task moves back
# Odoo Kanban: Blocked → In PR → CI Green
# Odoo Discuss: "✅ CI passed for PR #<number>"
```

---

## Smoke Test 4: Deployment Flow

**What it tests**: Deploy events sync to Odoo with environment tracking

### Steps

```bash
# 1. Merge PR to trigger staging deploy
gh pr merge --auto --squash

# 2. Wait for deploy workflow
gh run watch
```

### Expected Results

**In Odoo Kanban**:
1. ✅ Task moves through stages:
   - `CI Green` → `Staging ✅` → `Deployed`
2. ✅ `x_env` field changes:
   - `preview` → `staging` → `prod`
3. ✅ `x_deploy_url` populated:
   - Staging: `https://staging.insightpulseai.net`
   - Production: `https://insightpulseai.net`

**In Odoo Discuss**:
```
🚀 Deployed to staging
PR #<number>: 🧪 SuperClaude Smoke Test
URL: https://staging.insightpulseai.net
Commit: abc123f

✅ Smoke tests passed (4/4 endpoints)
Ready for production promotion
```

---

## Smoke Test 5: Manual Agent Dispatch

**What it tests**: Local agent execution (no GitHub Actions needed)

### Steps

```bash
# 1. Run reviewer agent locally
./scripts/agent_dispatch.sh pr_opened <<EOF
{
  "pr_number": 999,
  "repo": "jgtolentino/odoboo-workspace",
  "author": "test-user",
  "title": "Local agent test"
}
EOF

# 2. Check output
# Expected: OCA rules validated, lockfile checked, spec extracted
```

### Expected Output

```
🤖 SuperClaude Orchestrator
Event: pr_opened
Routing to parallel agents: reviewer, security-scan, test-runner

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Reviewer Agent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[OCA Rules]
✓ Manifest found: addons/custom_module/__manifest__.py
✓ License: AGPL-3
✓ Author follows OCA convention

[Lockfile Sync]
✓ package-lock.json in sync with package.json

[Spec Validation]
✓ Found spec: specs/example.spec.md
✓ All required sections present

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Aggregate Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reviewer:  ✅ PASSED
Security:  ✅ PASSED
Tests:     ✅ PASSED

Overall:   ✅ APPROVED
```

---

## Troubleshooting

### Issue: No task appears in Odoo Kanban

**Possible causes**:
1. GitHub secret `ODOO_API_KEY` invalid or missing
2. Odoo user lacks "Project / User (Own Documents Only)" permissions
3. Script `scripts/odoo_kanban_sync.py` not executable

**Fix**:
```bash
# Verify GitHub secret
gh secret list | grep ODOO

# Check Odoo user permissions (via Odoo UI)
Settings → Users → <your-user> → Access Rights
  → Project: User (Own Documents Only) or Manager

# Make script executable
chmod +x scripts/odoo_kanban_sync.py

# Test manually
export ODOO_URL="https://insightpulseai.net"
export ODOO_DATABASE="odoboo_prod"
export ODOO_USER="admin@insightpulseai.net"
export ODOO_API_KEY="<your-key>"

python3 scripts/odoo_kanban_sync.py pr_opened <<EOF
{"pr_number": 1, "repo": "test/test", "author": "test"}
EOF
```

---

### Issue: Discuss channel not receiving messages

**Possible causes**:
1. Channel `#ci-updates` not created
2. Odoo user lacks "Discuss" access rights
3. API call failing silently

**Fix**:
```bash
# Verify channel exists (via Odoo shell)
docker exec -i odoo18 odoo shell -d odoboo_prod <<PY
env = env.sudo()
chan = env['discuss.channel'].search([('name','=','ci-updates')], limit=1)
print(f"Channel ID: {chan.id}" if chan else "NOT FOUND")
PY

# Check user permissions
Settings → Users → <your-user> → Access Rights
  → Discuss: User or Manager

# Test manual message post
docker exec -i odoo18 odoo shell -d odoboo_prod <<PY
env = env.sudo()
chan = env['discuss.channel'].search([('name','=','ci-updates')], limit=1)
if chan:
    chan.message_post(body='🧪 Test message', message_type='comment')
    print("Message posted successfully")
PY
```

---

### Issue: Parallel agents run sequentially

**Possible causes**:
1. Workflow YAML missing `needs: orchestrate` (causes immediate start)
2. `needs: [reviewer, security-scan, test-runner]` in wrong order
3. GitHub Actions runner limit (1 concurrent job on free tier)

**Fix**:
```yaml
# Correct workflow structure (.github/workflows/superclaude-pr.yml)
jobs:
  orchestrate:
    runs-on: ubuntu-latest
    steps: [...]

  reviewer:
    needs: orchestrate  # ← Must wait for orchestrate
    runs-on: ubuntu-latest
    steps: [...]

  security-scan:
    needs: orchestrate  # ← Runs in parallel with reviewer
    runs-on: ubuntu-latest
    steps: [...]

  test-runner:
    needs: orchestrate  # ← Runs in parallel with reviewer + security
    runs-on: ubuntu-latest
    steps: [...]

  aggregate:
    needs: [reviewer, security-scan, test-runner]  # ← Waits for ALL
    runs-on: ubuntu-latest
    steps: [...]
```

**Verify parallel execution**:
- GitHub Actions → Workflow run → Click graph icon (top-right)
- Should show 3 jobs branching from `orchestrate`, merging to `aggregate`

---

### Issue: Custom fields not showing in Odoo UI

**Possible causes**:
1. Fields created but not added to view
2. Studio module not installed (not required, but UI helps)
3. Cache issue (browser or Odoo)

**Fix**:
```bash
# Verify fields exist (via Odoo shell)
docker exec -i odoo18 odoo shell -d odoboo_prod <<PY
env = env.sudo()
fields = env['ir.model.fields'].search([
    ('model','=','project.task'),
    ('name','like','x_%')
])
for f in fields:
    print(f"{f.name}: {f.field_description} ({f.ttype})")
PY

# Add to form view manually (Odoo UI)
# Settings → Technical → User Interface → Views
# Search: project.task.view_form_inherit_superclaude
# Add notebook page with fields

# Or clear cache
Settings → Technical → Database → Clear Caches (then refresh browser)
```

---

## Success Criteria Checklist

Run all 5 smoke tests and verify:

- [ ] **Test 1**: PR creation syncs to Odoo Kanban + Discuss
- [ ] **Test 2**: 3 agents run in parallel (not sequential)
- [ ] **Test 3**: CI failures move task to "Blocked" stage
- [ ] **Test 4**: Deploy events update x_env and x_deploy_url
- [ ] **Test 5**: Local agent dispatch works without GitHub Actions

**If all 5 pass**: Your SuperClaude orchestration is production-ready! 🎉

**If any fail**: See troubleshooting section above or check:
- `docker logs odoo18 --tail 100`
- GitHub Actions workflow logs
- Odoo system logs (Settings → Technical → Logging)

---

## Performance Benchmarks

Expected execution times (adjust for your setup):

| Stage | Sequential | Parallel (SuperClaude) | Speedup |
|-------|-----------|------------------------|---------|
| Reviewer | 45s | 45s | 1.0x |
| Security Scan | 38s | 38s | 1.0x |
| Test Runner | 52s | 52s | 1.0x |
| **Total** | **135s** | **~60s** | **2.25x** |

*Parallel execution reduces total time to max(agents) + overhead*

---

## Next Steps

After successful smoke tests:

1. **Enable auto-merge for passing PRs**:
   ```bash
   gh pr merge --auto --squash
   ```

2. **Configure deployment environments**:
   - GitHub → Settings → Environments
   - Add `staging` and `production` with protection rules

3. **Set up Odoo Portal access for clients**:
   - Settings → Users → Portal
   - Share Kanban board (read-only) for deployment visibility

4. **Customize agent behaviors**:
   - Edit `.claude/agents/*.agent.yaml` for your coding standards
   - Add custom rules to `reviewer.agent.yaml`

5. **Monitor metrics**:
   - Odoo Kanban: Lead time (In PR → Deployed)
   - GitHub Actions: Success rate, average duration
   - Discuss #ci-updates: Message volume (activity indicator)

---

**Your CI/CD is now fully validated and ready for production workloads!** 🚀
