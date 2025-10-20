# Odoobo-Expert Agent - Quick Start Guide

**Version**: 3.0.0
**Architecture**: Anthropic Skills + DO Gradient AI + SuperClaude Framework
**Local Development**: <2 minute iteration cycles
**Production Cost**: <$12/month

---

## 🚀 Quick Start (5 Minutes)

### 1. Setup Git Worktrees for Parallel Development

```bash
# Navigate to odoboo-workspace
cd /Users/tbwa/Library/Mobile\ Documents/com~apple~CloudDocs/Documents/TBWA/odoboo-workspace

# Run automated setup
./scripts/setup-odoobo-worktrees.sh

# Verify worktrees created
./scripts/list-worktrees.sh
```

**Output**: 5 worktrees created at `/tmp/odoobo-worktrees/` with independent Python venvs

### 2. Switch to a Skill Worktree

```bash
# Switch to pr-review skill
./scripts/switch-worktree.sh pr-review

# You're now in /tmp/odoobo-worktrees/pr-review/
# Python venv is auto-activated
```

### 3. Test a Skill Locally

```bash
# Run tests for pr-review skill
./scripts/test-skill.sh pr-review

# Or test manually
cd .claude/skills/pr-review
python analyze_pr.py --help
```

### 4. Deploy to DO Gradient AI (Production)

```bash
# Set DO token
export DO_GRADIENT_TOKEN="your-token-here"

# Deploy all skills
./scripts/deploy-to-gradient-ai.sh
```

---

## 📁 Project Structure

```
odoboo-workspace/
├── .claude/
│   ├── agents/
│   │   ├── odoobo-reviewer.agent.yaml  # Legacy v2.0
│   │   └── odoobo-expert.agent.yaml    # NEW v3.0 with Skills
│   ├── skills/                         # 5 Anthropic Skills
│   │   ├── pr-review/                  # GitHub PR analysis
│   │   ├── odoo-rpc/                   # Odoo ERP integration
│   │   ├── nl-sql/                     # Natural language to SQL
│   │   ├── visual-diff/                # Screenshot comparison
│   │   └── design-tokens/              # Design system extraction
│   └── knowledge-bases/
│       └── odoobo/
│           ├── config.yaml             # KB configuration
│           ├── embeddings/             # Local ChromaDB
│           └── docs/                   # Custom documentation
├── scripts/
│   ├── setup-odoobo-worktrees.sh      # Setup script
│   ├── list-worktrees.sh              # List worktrees
│   ├── switch-worktree.sh             # Switch worktrees
│   ├── test-skill.sh                  # Test individual skill
│   └── deploy-to-gradient-ai.sh       # Deploy to production
└── WORKTREE_STATUS.json               # Worktree status tracking
```

---

## 🛠️ Development Workflow

### Rapid Iteration Loop (<2 minutes)

```bash
# Terminal 1: Switch to skill worktree
./scripts/switch-worktree.sh pr-review

# Terminal 2: Edit skill code
cd .claude/skills/pr-review
vim analyze_pr.py  # Make changes (30s)

# Terminal 3: Run tests (auto-watch mode)
pytest tests/ --watch  # Tests run automatically (20s)

# Terminal 4: Test with agent service
python main.py  # FastAPI server on :8001 (40s)

# Terminal 5: Commit changes
git add .
git commit -m "feat: add breaking change detection"  # (30s)
```

**Total Time**: <2 minutes per iteration

### Parallel Development (5 Skills Simultaneously)

```bash
# Developer 1: PR Review
./scripts/switch-worktree.sh pr-review

# Developer 2: Odoo RPC
./scripts/switch-worktree.sh odoo-rpc

# Developer 3: NL-SQL
./scripts/switch-worktree.sh nl-sql

# Developer 4: Visual Diff
./scripts/switch-worktree.sh visual-diff

# Developer 5: Design Tokens
./scripts/switch-worktree.sh design-tokens

# All 5 developers work independently with:
# - No context switching (no `git checkout`)
# - Independent Python venvs
# - Parallel testing
# - No merge conflicts until integration phase
```

---

## 🧩 Skills Overview

### 1. PR Review (`pr-review/`)

**Capabilities**:

- Lockfile sync detection (package.json ↔ pnpm-lock.yaml)
- Breaking change analysis
- Security vulnerability scanning
- OCA coding standards validation

**Usage**:

```bash
python analyze_pr.py \
  --pr-number 123 \
  --repository owner/repo \
  --severity high
```

### 2. Odoo RPC (`odoo-rpc/`)

**Capabilities**:

- XML-RPC and JSON-RPC client
- CRUD operations on Odoo models
- Domain builder for complex queries
- Multi-instance support

**Usage**:

```bash
python odoo_client.py \
  --model res.partner \
  --operation search_read \
  --domain "[('customer_rank', '>', 0)]" \
  --limit 10
```

### 3. NL-to-SQL (`nl-sql/`)

**Capabilities**:

- Natural language to SQL conversion
- WrenAI integration
- Odoo schema awareness (83 tables)
- Query validation and optimization

**Usage**:

```bash
python wrenai_client.py \
  --question "Show all customers with unpaid invoices" \
  --execute
```

### 4. Visual Diff (`visual-diff/`)

**Capabilities**:

- SSIM-based screenshot comparison
- Responsive design testing (mobile + desktop)
- Percy integration for visual testing
- LPIPS perceptual similarity

**Usage**:

```bash
python percy_client.py \
  --url "https://example.com/expenses" \
  --baseline "baseline.png" \
  --threshold 0.98
```

### 5. Design Tokens (`design-tokens/`)

**Capabilities**:

- CSS variable extraction
- SCSS to Tailwind CSS conversion
- Design system analysis
- Token categorization (colors, typography, spacing)

**Usage**:

```bash
python extract_tokens.py \
  --url "https://www.odoo.com" \
  --output "odoo-tokens.json"
```

---

## 📊 Knowledge Base

### Local Development (ChromaDB)

**Configuration**: `.claude/knowledge-bases/odoobo/config.yaml`

**Data Sources**:

- Odoo official docs (15K chunks)
- OCA maintainer guidelines (5K chunks)
- Community forums (5K chunks)
- Custom documentation (2K chunks)

**Setup**:

```bash
# Initialize local KB
cd ~/.claude/knowledge-bases/odoobo
python scripts/init_local_kb.py

# Query KB
python scripts/query_kb.py "How to create an Odoo module?"
```

### Production (DO Gradient AI)

**Migration**:

```bash
# Export local embeddings
python scripts/export_embeddings.py --output embeddings_export.json

# Upload to DO Gradient AI
python scripts/upload_to_do_gradient.py --input embeddings_export.json
```

**Cost**: <$3/month (embeddings + queries)

---

## 🚢 Deployment

### Local Development

```bash
# Start agent service
cd /Users/tbwa/Library/Mobile\ Documents/com~apple~CloudDocs/Documents/TBWA/odoboo-workspace
python .claude/skills/main.py

# Access at http://localhost:8001
# Swagger docs: http://localhost:8001/docs
```

### DO Gradient AI (Production)

```bash
# Deploy
export DO_GRADIENT_TOKEN="your-token"
./scripts/deploy-to-gradient-ai.sh

# Verify
curl -sf https://odoobo-expert.do-ai.run/health | jq
```

---

## 💰 Cost Breakdown

| Component              | Local Dev           | Production                       |
| ---------------------- | ------------------- | -------------------------------- |
| **Skills Development** | $0/month            | $0/month                         |
| **Knowledge Base**     | $0/month (ChromaDB) | $3/month (DO Managed OpenSearch) |
| **Agent Hosting**      | $0/month            | $5-8/month (DO App Platform)     |
| **API Usage**          | $0/month            | $1-2/month (OpenAI + WrenAI)     |
| **Total**              | **$0/month**        | **<$12/month**                   |

**Comparison**: 87% cheaper than $100/month Azure (previous architecture)

---

## 🎯 Context Engineering Best Practices

Based on [Anthropic's article](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):

### 1. Minimal High-Signal Context

✅ Each skill has focused SKILL.md with clear instructions
✅ XML-structured sections for organization
✅ Diverse, canonical examples (not exhaustive edge cases)

### 2. Tool Design

✅ Self-contained skills with robust error handling
✅ Clear, unambiguous input parameters
✅ Minimal tool set overlap

### 3. Memory Management

✅ Structured note-taking via WORKTREE_STATUS.json
✅ Context compaction through KB summarization
✅ Progressive disclosure (KB retrieval on-demand)

### 4. Cost Optimization

✅ Local development = $0 (no cloud usage)
✅ Context window management (<8K tokens per skill)
✅ Aggressive caching strategy

---

## 🧪 Testing

### Unit Tests (Per Skill)

```bash
# Test single skill
./scripts/test-skill.sh pr-review

# Test all skills
cd .claude/skills
python test_all_skills.py -v
```

### Integration Tests

```bash
# Test agent service with all skills
cd .claude/skills
pytest tests/integration/ -v
```

### Coverage Target

- **Unit Tests**: ≥80% per skill
- **Integration Tests**: ≥70% overall

---

## 📈 Monitoring

### Prometheus Metrics

```bash
# Local development
docker-compose up prometheus grafana

# Access Grafana
open http://localhost:3001
```

**Dashboards**:

- Odoobo-Expert Overview
- Skill Performance
- Knowledge Base Stats

**Metrics**:

- `skill_execution_time`
- `skill_success_rate`
- `kb_retrieval_latency`
- `token_usage`

---

## 🐛 Troubleshooting

### Issue: Worktree creation fails

**Solution**:

```bash
# Remove existing worktrees
git worktree prune

# Re-run setup
./scripts/setup-odoobo-worktrees.sh
```

### Issue: Skill tests fail

**Solution**:

```bash
# Reinstall dependencies
cd /tmp/odoobo-worktrees/pr-review
source .venv/bin/activate
pip install -r .claude/skills/pr-review/requirements.txt
```

### Issue: Deployment fails

**Solution**:

```bash
# Check DO authentication
doctl auth list

# Re-authenticate
doctl auth init --access-token "$DO_GRADIENT_TOKEN"
```

---

## 📚 Additional Resources

- [Anthropic Skills Documentation](https://www.anthropic.com/news/skills)
- [DO Gradient AI Platform](https://docs.digitalocean.com/products/gradient-ai-platform/)
- [Context Engineering Best Practices](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [SuperClaude Framework](~/.claude/knowledge-bases/odoobo-expert/)

---

## 🎉 Next Steps

1. ✅ Run `./scripts/setup-odoobo-worktrees.sh`
2. ✅ Switch to a skill: `./scripts/switch-worktree.sh pr-review`
3. ✅ Make changes and test: `./scripts/test-skill.sh pr-review`
4. ✅ Commit changes in worktree
5. ✅ Deploy to production: `./scripts/deploy-to-gradient-ai.sh`

**Status**: ✅ Ready for parallel development with <2 minute iteration cycles!
