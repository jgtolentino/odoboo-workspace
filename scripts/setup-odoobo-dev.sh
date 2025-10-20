#!/bin/bash
# Setup Odoobo-Expert Development Environment
# Usage: ./scripts/setup-odoobo-dev.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME="$HOME/.claude"
SKILLS_DIR="$CLAUDE_HOME/skills/odoobo-expert"
KB_DIR="$CLAUDE_HOME/knowledge-bases/odoobo"

echo "=========================================="
echo "Odoobo-Expert Development Setup"
echo "=========================================="

# Step 1: Create directory structure
echo ""
echo "📁 Creating directory structure..."
mkdir -p "$SKILLS_DIR"/{pr-review,odoo-rpc,nl-sql,visual-diff,design-tokens}/{tests,resources}
mkdir -p "$KB_DIR"/{embeddings,docs/{odoo-18.0,oca,custom}}
mkdir -p "$CLAUDE_HOME/agents"
mkdir -p "$CLAUDE_HOME/commands"

# Step 2: Create git worktrees
echo ""
echo "🌳 Creating git worktrees..."
cd "$REPO_ROOT"

# Create feature branches if they don't exist
git checkout main 2>/dev/null || git checkout -b main
for skill in pr-review odoo-rpc nl-sql visual-diff design-tokens; do
    if ! git show-ref --verify --quiet "refs/heads/feature/$skill"; then
        echo "  Creating branch: feature/$skill"
        git branch "feature/$skill"
    else
        echo "  Branch exists: feature/$skill"
    fi
done

# Create worktrees
cd "$(dirname "$REPO_ROOT")"
for skill in pr-review odoo-rpc nl-sql visual-diff design-tokens; do
    WORKTREE_DIR="odoboo-workspace-$skill"
    if [ ! -d "$WORKTREE_DIR" ]; then
        echo "  Creating worktree: $WORKTREE_DIR"
        git -C "$REPO_ROOT" worktree add "../$WORKTREE_DIR" "feature/$skill"
    else
        echo "  Worktree exists: $WORKTREE_DIR"
    fi
done

# Step 3: Initialize Python environments for each worktree
echo ""
echo "🐍 Initializing Python environments..."
cd "$(dirname "$REPO_ROOT")"
for skill in pr-review odoo-rpc nl-sql visual-diff design-tokens; do
    WORKTREE_DIR="odoboo-workspace-$skill"
    echo "  Setting up venv for: $WORKTREE_DIR"
    cd "$WORKTREE_DIR"

    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
    fi

    source .venv/bin/activate
    pip install --upgrade pip setuptools wheel

    # Install agent service dependencies if they exist
    if [ -f "services/agent-service/requirements.txt" ]; then
        pip install -r services/agent-service/requirements.txt
    fi

    # Install testing dependencies
    pip install pytest pytest-asyncio pytest-cov httpx

    deactivate
    cd ..
done

# Step 4: Create agent configuration
echo ""
echo "⚙️  Creating agent configuration..."
cat > "$CLAUDE_HOME/agents/odoobo-expert.agent.yaml" <<'EOF'
---
agent: odoobo-expert
description: Multi-capability Odoo specialist with 5 core skills
version: 2.0.0
runtime: claude-3-5-sonnet-20241022
token_budget: 8000

capabilities:
  - pr_review
  - odoo_rpc
  - nl_sql
  - visual_diff
  - design_tokens

skills_directory: ~/.claude/skills/odoobo-expert/
knowledge_base: ~/.claude/knowledge-bases/odoobo/

execution:
  environment: python3.11
  timeout_seconds: 30
  max_memory_mb: 512
  retry_attempts: 2

authentication:
  required:
    - GITHUB_TOKEN
    - ANTHROPIC_API_KEY
  optional:
    - ODOO_URL
    - ODOO_USERNAME
    - ODOO_PASSWORD
    - POSTGRES_URL

mcp_integration:
  servers:
    - sequential-thinking
    - context7
    - playwright

personas:
  primary: analyzer
  secondary: [qa, backend, security]

quality_gates:
  pr_review:
    lockfile_sync_check: required
    security_scan: required
    complexity_threshold: 0.75
  visual_diff:
    ssim_threshold: 0.98
    lpips_threshold: 0.02
  nl_sql:
    destructive_operations: blocked
    query_validation: required
EOF

# Step 5: Create knowledge base config
echo ""
echo "📚 Creating knowledge base configuration..."
cat > "$KB_DIR/config.yaml" <<'EOF'
---
knowledge_base: odoobo
version: 1.0.0
description: Odoo expertise knowledge base for odoobo-expert agent

data_sources:
  odoo_docs:
    url: https://www.odoo.com/documentation/18.0/
    type: html
    chunk_size: 512
    chunk_overlap: 50
    refresh_interval: 7d

  oca_guidelines:
    url: https://github.com/OCA/maintainer-tools
    type: markdown
    chunk_size: 512
    chunk_overlap: 50
    refresh_interval: 30d

local_development:
  vector_store: chromadb
  embedding_model: sentence-transformers/all-MiniLM-L6-v2
  embedding_dimensions: 384
  storage_path: ~/.claude/knowledge-bases/odoobo/embeddings/

retrieval:
  top_k: 5
  similarity_threshold: 0.75
  rerank: false

indexing:
  batch_size: 100
  workers: 4
  retry_attempts: 3
EOF

# Step 6: Create PR review skill skeleton
echo ""
echo "🔍 Creating PR review skill skeleton..."
cat > "$SKILLS_DIR/pr-review/SKILL.md" <<'EOF'
---
skill: pr-review
capability: code_analysis
runtime: python3.11
security_level: medium
requires_auth: true
---

# PR Review Skill

Automated GitHub PR analysis for Odoo, OCA, and Next.js codebases.

## Inputs
- pr_number: integer
- repository: string (owner/repo)
- github_token: string (env: GITHUB_TOKEN)

## Outputs
- analysis: ReviewAnalysis (severity, category, line_numbers)
- approval_status: "approved" | "changes_requested" | "commented"
- lockfile_synced: boolean

## Usage
```python
from skills.odoobo_expert.pr_review import analyze_pr

result = analyze_pr(
    pr_number=123,
    repository="odoo/odoo",
    github_token=os.getenv("GITHUB_TOKEN")
)
```
EOF

cat > "$SKILLS_DIR/pr-review/review.py" <<'EOF'
#!/usr/bin/env python3
"""PR Review Skill - Automated GitHub PR analysis."""
import os
from dataclasses import dataclass
from typing import List, Literal

@dataclass
class ReviewIssue:
    severity: Literal["critical", "high", "medium", "low"]
    category: str
    line_number: int
    message: str
    suggestion: str

@dataclass
class ReviewResult:
    pr_number: int
    repository: str
    approval_status: Literal["approved", "changes_requested", "commented"]
    lockfile_synced: bool
    issues: List[ReviewIssue]
    summary: str

def analyze_pr(pr_number: int, repository: str, github_token: str) -> ReviewResult:
    """Analyze GitHub PR for issues."""
    # TODO: Implement PR analysis logic
    return ReviewResult(
        pr_number=pr_number,
        repository=repository,
        approval_status="commented",
        lockfile_synced=True,
        issues=[],
        summary=f"PR #{pr_number} in {repository} analyzed"
    )

if __name__ == "__main__":
    # Example usage
    result = analyze_pr(
        pr_number=123,
        repository="odoo/odoo",
        github_token=os.getenv("GITHUB_TOKEN", "")
    )
    print(f"Analysis: {result.summary}")
    print(f"Status: {result.approval_status}")
    print(f"Lockfile synced: {result.lockfile_synced}")
EOF

cat > "$SKILLS_DIR/pr-review/requirements.txt" <<'EOF'
requests>=2.31.0
PyGithub>=2.1.1
pytest>=7.4.0
pytest-asyncio>=0.21.0
EOF

# Step 7: Create test skeleton
cat > "$SKILLS_DIR/pr-review/tests/test_review.py" <<'EOF'
import pytest
from pr_review.review import analyze_pr, ReviewResult

def test_analyze_pr_basic():
    """Test basic PR analysis."""
    result = analyze_pr(
        pr_number=123,
        repository="odoo/odoo",
        github_token="fake_token"
    )
    assert isinstance(result, ReviewResult)
    assert result.pr_number == 123
    assert result.repository == "odoo/odoo"

def test_lockfile_detection():
    """Test lockfile sync detection."""
    # TODO: Implement test
    pass

def test_security_scan():
    """Test security vulnerability detection."""
    # TODO: Implement test
    pass
EOF

# Step 8: Create helper scripts
echo ""
echo "🛠️  Creating helper scripts..."

# Script to test skill locally
cat > "$SKILLS_DIR/pr-review/test_skill.sh" <<'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source ../../../.venv/bin/activate 2>/dev/null || source .venv/bin/activate
pytest tests/ -v
EOF
chmod +x "$SKILLS_DIR/pr-review/test_skill.sh"

# Script to list worktrees
cat > "$REPO_ROOT/scripts/list-worktrees.sh" <<'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
echo "Git Worktrees:"
git worktree list
EOF
chmod +x "$REPO_ROOT/scripts/list-worktrees.sh"

# Script to switch between worktrees
cat > "$REPO_ROOT/scripts/switch-worktree.sh" <<'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: ./scripts/switch-worktree.sh <skill-name>"
    echo "Skills: pr-review, odoo-rpc, nl-sql, visual-diff, design-tokens"
    exit 1
fi

SKILL=$1
WORKTREE_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)")/odoboo-workspace-$SKILL"

if [ ! -d "$WORKTREE_DIR" ]; then
    echo "Error: Worktree not found: $WORKTREE_DIR"
    exit 1
fi

echo "Switching to worktree: $WORKTREE_DIR"
cd "$WORKTREE_DIR" && exec $SHELL
EOF
chmod +x "$REPO_ROOT/scripts/switch-worktree.sh"

# Step 9: Print summary
echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📁 Skills Directory: $SKILLS_DIR"
echo "📚 Knowledge Base: $KB_DIR"
echo "⚙️  Agent Config: $CLAUDE_HOME/agents/odoobo-expert.agent.yaml"
echo ""
echo "🌳 Git Worktrees:"
git -C "$REPO_ROOT" worktree list
echo ""
echo "🚀 Next Steps:"
echo "  1. Switch to a worktree: ./scripts/switch-worktree.sh pr-review"
echo "  2. Develop skill: cd ~/.claude/skills/odoobo-expert/pr-review/"
echo "  3. Run tests: ./test_skill.sh"
echo "  4. Commit: git add . && git commit -m 'feat: Add PR review skill'"
echo ""
echo "📖 Full architecture: ./ODOOBO_EXPERT_ARCHITECTURE.md"
