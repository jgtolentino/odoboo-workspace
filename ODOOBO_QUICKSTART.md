# Odoobo-Expert Agent: Quick Start Guide

**Goal**: Set up local development environment and start building skills in <10 minutes.

---

## Prerequisites

- **Python 3.11+**: `python3 --version`
- **Git 2.25+**: `git --version` (for worktrees support)
- **Node.js 18+**: `node --version` (for agent service)
- **Disk Space**: ~5GB for worktrees + dependencies

**Environment Variables** (add to ~/.zshrc):

```bash
export GITHUB_TOKEN=github_pat_...
export ANTHROPIC_API_KEY=sk-ant-...
```

---

## 5-Minute Setup

### Step 1: Run Setup Script

```bash
cd ~/Documents/TBWA/odoboo-workspace
./scripts/setup-odoobo-dev.sh
```

**What it does**:

1. ✅ Creates `~/.claude/skills/odoobo-expert/` directory structure
2. ✅ Creates `~/.claude/knowledge-bases/odoobo/` for local RAG
3. ✅ Creates 5 git worktrees for parallel development
4. ✅ Initializes Python venv for each worktree
5. ✅ Creates agent config at `~/.claude/agents/odoobo-expert.agent.yaml`
6. ✅ Creates PR review skill skeleton with tests

**Expected Output**:

```
✅ Setup Complete!
📁 Skills Directory: /Users/tbwa/.claude/skills/odoobo-expert
📚 Knowledge Base: /Users/tbwa/.claude/knowledge-bases/odoobo
⚙️  Agent Config: /Users/tbwa/.claude/agents/odoobo-expert.agent.yaml

🌳 Git Worktrees:
/Users/tbwa/Documents/TBWA/odoboo-workspace                 [main]
/Users/tbwa/Documents/TBWA/odoboo-workspace-pr-review       [feature/pr-review]
/Users/tbwa/Documents/TBWA/odoboo-workspace-odoo-rpc        [feature/odoo-rpc]
/Users/tbwa/Documents/TBWA/odoboo-workspace-nl-sql          [feature/nl-sql]
/Users/tbwa/Documents/TBWA/odoboo-workspace-visual-diff     [feature/visual-diff]
/Users/tbwa/Documents/TBWA/odoboo-workspace-design-tokens   [feature/design-tokens]
```

### Step 2: Verify Installation

```bash
# Check worktrees
./scripts/list-worktrees.sh

# Check skills directory
ls -la ~/.claude/skills/odoobo-expert/

# Check agent config
cat ~/.claude/agents/odoobo-expert.agent.yaml
```

---

## Development Workflow

### Terminal Layout (Recommended)

**Terminal 1: Agent Service** (main worktree)

```bash
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service
source .venv/bin/activate
uvicorn app.main:app --reload --port 8001
```

**Terminal 2: Skill Development** (skill-specific worktree)

```bash
# Switch to PR review worktree
./scripts/switch-worktree.sh pr-review

# Or manually:
cd ~/Documents/TBWA/odoboo-workspace-pr-review

# Open skill in editor
code ~/.claude/skills/odoobo-expert/pr-review/
```

**Terminal 3: Testing** (same worktree as Terminal 2)

```bash
cd ~/.claude/skills/odoobo-expert/pr-review
source .venv/bin/activate

# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=. --cov-report=html

# Watch mode (requires pytest-watch)
ptw tests/ -v
```

**Terminal 4: Git Operations** (same worktree as Terminal 2)

```bash
cd ~/Documents/TBWA/odoboo-workspace-pr-review

# Check status
git status

# Stage changes
git add ~/.claude/skills/odoobo-expert/pr-review/

# Commit
git commit -m "feat(pr-review): Add lockfile detection logic"

# Push feature branch
git push origin feature/pr-review
```

---

## Skill Development Loop (<2 Minutes)

### Example: PR Review Skill

**1. Edit Skill Code** (30s)

```bash
cd ~/Documents/TBWA/odoboo-workspace-pr-review
vim ~/.claude/skills/odoobo-expert/pr-review/review.py
```

**2. Run Unit Tests** (20s)

```bash
cd ~/.claude/skills/odoobo-expert/pr-review
pytest tests/test_review.py -v -k test_lockfile_detection
```

**3. Test with Agent Service** (40s)

```bash
# Agent service running in Terminal 1
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [
      {"role": "user", "content": "/review 123 odoo/odoo"}
    ]
  }' | jq
```

**4. Commit Changes** (30s)

```bash
git add ~/.claude/skills/odoobo-expert/pr-review/
git commit -m "fix(pr-review): Improve lockfile detection accuracy

- Add support for pnpm-lock.yaml
- Handle monorepo lockfile paths
- Test coverage: 85%"
```

**Total**: <2 minutes per iteration

---

## Skill Implementation Example

### PR Review Skill: Lockfile Detection

**File**: `~/.claude/skills/odoobo-expert/pr-review/review.py`

```python
#!/usr/bin/env python3
import os
import re
from typing import Optional
from github import Github

def detect_lockfile_sync(pr_diff: str, github_token: str) -> bool:
    """
    Detect if package.json changes have corresponding lockfile updates.

    Returns:
        True if synced (or no package.json changes)
        False if package.json changed but lockfile missing
    """
    package_json_changed = "package.json" in pr_diff
    lockfile_changed = any(
        lockfile in pr_diff
        for lockfile in ["package-lock.json", "yarn.lock", "pnpm-lock.yaml"]
    )

    if package_json_changed and not lockfile_changed:
        return False

    return True

def analyze_pr(pr_number: int, repository: str, github_token: str):
    """Analyze GitHub PR for issues."""
    g = Github(github_token)
    repo = g.get_repo(repository)
    pr = repo.get_pull(pr_number)

    # Get PR diff
    pr_diff = pr.get_files()
    diff_text = "\n".join([f.filename for f in pr_diff])

    # Check lockfile sync
    lockfile_synced = detect_lockfile_sync(diff_text, github_token)

    # Analyze code changes
    issues = []
    if not lockfile_synced:
        issues.append({
            "severity": "high",
            "category": "dependency",
            "message": "package.json changed but lockfile not updated",
            "suggestion": "Run npm install and commit lockfile"
        })

    # Generate summary
    approval_status = "changes_requested" if issues else "approved"
    summary = f"Reviewed {len(list(pr_diff))} files. "
    summary += f"Lockfile {'synced' if lockfile_synced else 'NOT synced'}. "
    summary += f"Found {len(issues)} issues."

    return {
        "pr_number": pr_number,
        "repository": repository,
        "approval_status": approval_status,
        "lockfile_synced": lockfile_synced,
        "issues": issues,
        "summary": summary
    }
```

**Test**: `~/.claude/skills/odoobo-expert/pr-review/tests/test_review.py`

```python
import pytest
from unittest.mock import Mock, patch
from pr_review.review import detect_lockfile_sync, analyze_pr

def test_lockfile_sync_detected():
    """Test lockfile sync detection when both files changed."""
    pr_diff = """
    package.json
    package-lock.json
    src/index.ts
    """
    assert detect_lockfile_sync(pr_diff, "fake_token") is True

def test_lockfile_not_synced():
    """Test detection when package.json changed but lockfile missing."""
    pr_diff = """
    package.json
    src/index.ts
    """
    assert detect_lockfile_sync(pr_diff, "fake_token") is False

def test_no_package_changes():
    """Test when neither package.json nor lockfile changed."""
    pr_diff = """
    src/index.ts
    README.md
    """
    assert detect_lockfile_sync(pr_diff, "fake_token") is True

@patch("pr_review.review.Github")
def test_analyze_pr_with_lockfile_issue(mock_github):
    """Test PR analysis when lockfile is not synced."""
    # Mock GitHub API
    mock_pr = Mock()
    mock_pr.get_files.return_value = [
        Mock(filename="package.json"),
        Mock(filename="src/index.ts")
    ]
    mock_repo = Mock()
    mock_repo.get_pull.return_value = mock_pr
    mock_github.return_value.get_repo.return_value = mock_repo

    # Analyze PR
    result = analyze_pr(123, "odoo/odoo", "fake_token")

    assert result["lockfile_synced"] is False
    assert result["approval_status"] == "changes_requested"
    assert len(result["issues"]) == 1
    assert result["issues"][0]["severity"] == "high"
```

**Run Tests**:

```bash
cd ~/.claude/skills/odoobo-expert/pr-review
pytest tests/test_review.py -v

# Expected output:
# tests/test_review.py::test_lockfile_sync_detected PASSED
# tests/test_review.py::test_lockfile_not_synced PASSED
# tests/test_review.py::test_no_package_changes PASSED
# tests/test_review.py::test_analyze_pr_with_lockfile_issue PASSED
# ================================ 4 passed in 0.5s ================================
```

---

## Knowledge Base Setup (Optional for Development)

### Quick Start: Local ChromaDB

```bash
# Install dependencies
cd ~/.claude/knowledge-bases/odoobo
pip install chromadb sentence-transformers tqdm

# Download sample Odoo docs (small subset for testing)
mkdir -p docs/odoo-18.0/developer
curl -o docs/odoo-18.0/developer/orm.html \
  https://www.odoo.com/documentation/18.0/developer/reference/backend/orm.html

# Generate embeddings
python scripts/generate_embeddings.py \
  --config config.yaml \
  --mode local \
  --output embeddings/
```

### Test Retrieval

```bash
# Query knowledge base
python scripts/test_retrieval.py \
  --query "How to create a many2one field in Odoo?" \
  --top_k 5

# Expected output:
# Query: How to create a many2one field in Odoo?
#
# Top 5 Results:
# 1. [Score: 0.89] Many2one fields are used to define relationships...
# 2. [Score: 0.85] When defining a many2one field, specify comodel_name...
# ...
```

---

## Parallel Development Strategy

### Scenario: 5 Developers Working on 5 Skills

**Developer 1: PR Review Skill**

```bash
cd ~/Documents/TBWA/odoboo-workspace-pr-review
# Work on pr-review skill independently
git push origin feature/pr-review
```

**Developer 2: Odoo RPC Skill**

```bash
cd ~/Documents/TBWA/odoboo-workspace-odoo-rpc
# Work on odoo-rpc skill independently
git push origin feature/odoo-rpc
```

**Developer 3: NL-SQL Skill**

```bash
cd ~/Documents/TBWA/odoboo-workspace-nl-sql
# Work on nl-sql skill independently
git push origin feature/nl-sql
```

**Developer 4: Visual Diff Skill**

```bash
cd ~/Documents/TBWA/odoboo-workspace-visual-diff
# Work on visual-diff skill independently
git push origin feature/visual-diff
```

**Developer 5: Design Tokens Skill**

```bash
cd ~/Documents/TBWA/odoboo-workspace-design-tokens
# Work on design-tokens skill independently
git push origin feature/design-tokens
```

**Benefits**:

- ✅ No context switching (each developer stays in their worktree)
- ✅ No merge conflicts until integration phase
- ✅ Independent testing (each worktree has own venv)
- ✅ Fast iteration (<2 min per cycle)

---

## Integration Testing

### After All Skills Complete

**Step 1: Merge All Branches to Main**

```bash
cd ~/Documents/TBWA/odoboo-workspace

# Merge in order of dependency
git checkout main
git merge feature/pr-review --no-ff
git merge feature/odoo-rpc --no-ff
git merge feature/nl-sql --no-ff
git merge feature/visual-diff --no-ff
git merge feature/design-tokens --no-ff

git push origin main
```

**Step 2: Run Integration Tests**

```bash
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service

# Test skill orchestration
pytest tests/integration/test_skill_composition.py -v

# Test with real agent
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [
      {"role": "user", "content": "Review PR #123 and generate visual diff"}
    ]
  }' | jq
```

**Step 3: Cleanup Worktrees** (Optional)

```bash
cd ~/Documents/TBWA/odoboo-workspace

git worktree remove ../odoboo-workspace-pr-review
git worktree remove ../odoboo-workspace-odoo-rpc
git worktree remove ../odoboo-workspace-nl-sql
git worktree remove ../odoboo-workspace-visual-diff
git worktree remove ../odoboo-workspace-design-tokens
```

---

## Troubleshooting

### Worktree Creation Fails

**Error**: `fatal: 'feature/pr-review' is already checked out`

**Solution**: Worktree already exists, list and verify:

```bash
git worktree list
cd ~/Documents/TBWA/odoboo-workspace-pr-review
git status
```

### Python venv Issues

**Error**: `No module named 'pytest'`

**Solution**: Activate correct venv:

```bash
cd ~/Documents/TBWA/odoboo-workspace-pr-review
source .venv/bin/activate
pip install pytest pytest-asyncio
```

### Agent Service Won't Start

**Error**: `ImportError: No module named 'anthropic'`

**Solution**: Install dependencies:

```bash
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service
source .venv/bin/activate
pip install -r requirements.txt
```

### GitHub API Rate Limit

**Error**: `Rate limit exceeded`

**Solution**: Use authenticated requests (higher rate limit):

```bash
export GITHUB_TOKEN=github_pat_...
# 5,000 requests/hour vs 60 requests/hour unauthenticated
```

---

## Cost Tracking

### Development Phase

| Component         | Cost         |
| ----------------- | ------------ |
| Local development | $0           |
| Git worktrees     | $0           |
| Local ChromaDB    | $0           |
| Testing           | $0           |
| **Total**         | **$0/month** |

### Production Phase (After Deployment)

| Component                 | Cost          |
| ------------------------- | ------------- |
| DO Gradient AI embeddings | $2/month      |
| DO Gradient AI queries    | $1/month      |
| DO App Platform           | $5/month      |
| **Total**                 | **~$8/month** |

---

## Next Steps

### Week 1: PR Review Skill

- [ ] Implement lockfile detection (done in example above)
- [ ] Add security vulnerability scanning
- [ ] Add OCA guideline validation
- [ ] Test with real GitHub PRs
- [ ] Achieve 80%+ test coverage

### Week 2: Odoo RPC Skill

- [ ] Implement XML-RPC client
- [ ] Add JSON-RPC support (Odoo 16+)
- [ ] Add domain builder (NL → Odoo domain)
- [ ] Test with demo.odoo.com
- [ ] Handle authentication caching

### Week 3: NL-SQL Skill

- [ ] Implement schema introspection
- [ ] Add PostgreSQL query generator
- [ ] Add query validation (block destructive ops)
- [ ] Test with sample Odoo database
- [ ] Add visualization recommendations

### Week 4-5: Visual Diff + Design Tokens

- [ ] Implement SSIM + LPIPS comparison
- [ ] Add CSS token extractor
- [ ] Add Tailwind converter
- [ ] Test responsive breakpoints
- [ ] Generate design system documentation

### Week 6: Integration & Testing

- [ ] Merge all skills to main
- [ ] Run comprehensive integration tests
- [ ] Load test with 100 concurrent requests
- [ ] Document skill composition patterns

### Week 7-8: Knowledge Base

- [ ] Scrape Odoo documentation
- [ ] Generate local embeddings (50K chunks)
- [ ] Test retrieval quality
- [ ] Optimize chunk size parameters

### Week 9: Production Deployment

- [ ] Migrate to DO Gradient AI
- [ ] Deploy agent service to DO App Platform
- [ ] Configure production monitoring
- [ ] Run smoke tests

### Week 10+: Optimization

- [ ] Tune RAG pipeline
- [ ] Add caching layer
- [ ] Scale to 100K+ chunks
- [ ] Add skill composition examples

---

## Resources

- **Full Architecture**: [ODOOBO_EXPERT_ARCHITECTURE.md](./ODOOBO_EXPERT_ARCHITECTURE.md)
- **Setup Script**: [scripts/setup-odoobo-dev.sh](./scripts/setup-odoobo-dev.sh)
- **Anthropic Skills**: https://docs.anthropic.com/en/docs/build-with-claude/skills
- **Git Worktrees**: https://git-scm.com/docs/git-worktree
- **DO Gradient AI**: https://docs.digitalocean.com/products/gradient-ai/

---

**Status**: ✅ Ready for Development
**Setup Time**: <10 minutes
**First Skill**: PR Review (~1 week)
**Production Ready**: ~10 weeks
