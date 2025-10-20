# Odoobo-Expert Agent: Local-First Architecture

**Complete development environment for building production-ready AI agent with 5 specialized skills**

---

## What Was Delivered

This architecture provides a **local-first development environment** for the odoobo-expert agent, optimized for:

- ✅ **Zero-cost development** (<$10/month production)
- ✅ **Rapid iteration** (<2 minutes per skill test)
- ✅ **Parallel development** (5 skills simultaneously)
- ✅ **Smooth deployment path** (local → DO Gradient AI)

---

## Architecture Components

### 1. Anthropic Skills Framework Integration

**5 Portable Skills** in `~/.claude/skills/odoobo-expert/`:

| Skill             | Capability       | Status            | Purpose                                          |
| ----------------- | ---------------- | ----------------- | ------------------------------------------------ |
| **pr-review**     | Code Analysis    | ✅ Skeleton Ready | GitHub PR analysis with lockfile detection       |
| **odoo-rpc**      | API Client       | 📋 Planned        | XML-RPC/JSON-RPC interaction with Odoo instances |
| **nl-sql**        | Query Generation | 📋 Planned        | Natural language → SQL for Odoo databases        |
| **visual-diff**   | Image Analysis   | 📋 Planned        | SSIM + LPIPS screenshot comparison               |
| **design-tokens** | CSS Extraction   | 📋 Planned        | SCSS → Tailwind CSS token conversion             |

**Each skill follows Anthropic Skills pattern**:

```
skill-name/
├── SKILL.md              # Instructions (Anthropic format)
├── skill.py              # Executable implementation
├── requirements.txt      # Dependencies
├── tests/                # Test suite (≥80% coverage)
└── resources/            # Patterns, schemas, templates
```

### 2. Git Worktrees for Parallel Development

**5 Isolated Development Environments**:

```
~/Documents/TBWA/
├── odoboo-workspace/               [main branch]
├── odoboo-workspace-pr-review/     [feature/pr-review]
├── odoboo-workspace-odoo-rpc/      [feature/odoo-rpc]
├── odoboo-workspace-nl-sql/        [feature/nl-sql]
├── odoboo-workspace-visual-diff/   [feature/visual-diff]
└── odoboo-workspace-design-tokens/ [feature/design-tokens]
```

**Benefits**:

- ✅ No context switching (no `git checkout`)
- ✅ Independent Python venvs per worktree
- ✅ Parallel testing in 5 terminals
- ✅ Zero merge conflicts until integration

### 3. SuperClaude Framework Integration

**Agent Configuration**: `~/.claude/agents/odoobo-expert.agent.yaml`

**Features**:

- ✅ Auto-persona activation (analyzer, qa, backend, security)
- ✅ MCP server integration (sequential-thinking, context7, playwright)
- ✅ Quality gates (lockfile checks, security scans, SSIM thresholds)
- ✅ Command system (`/review`, `/odoo-query`, `/sql`, `/visual-diff`)

**Skills Registry**: `~/.claude/skills/odoobo-expert/REGISTRY.md`

- Tracks skill status, versions, test coverage
- Documents integration patterns (sequential, parallel, conditional)
- Provides execution examples

### 4. DigitalOcean Gradient AI Knowledge Base

**Local Development** (Phase 1):

- **Vector Store**: ChromaDB (SQLite + in-memory vectors)
- **Embedding Model**: sentence-transformers/all-MiniLM-L6-v2 (384 dim, CPU)
- **Cost**: $0/month

**Production** (Phase 2):

- **Vector Store**: DO Gradient AI managed service
- **Embedding Model**: text-embedding-ada-002 (1536 dim, OpenAI via DO)
- **Data Sources**: 50K+ Odoo documentation chunks
- **Cost**: <$3/month (embeddings + queries)

**Knowledge Base Structure**:

```
~/.claude/knowledge-bases/odoobo/
├── embeddings/              # Local ChromaDB vectors
├── docs/
│   ├── odoo-18.0/          # Official Odoo docs (15K chunks)
│   ├── oca/                # OCA guidelines (5K chunks)
│   ├── forums/             # Odoo forums Q&A (5K chunks)
│   └── custom/             # Internal patterns (2K chunks)
├── index.json              # Search index metadata
└── config.yaml             # KB configuration
```

---

## Quick Start (10 Minutes)

### Prerequisites

```bash
# Check versions
python3 --version  # 3.11+
git --version      # 2.25+ (for worktrees)
node --version     # 18+

# Set environment variables
export GITHUB_TOKEN=github_pat_...
export ANTHROPIC_API_KEY=sk-ant-...
```

### Step 1: Run Setup Script

```bash
cd ~/Documents/TBWA/odoboo-workspace
./scripts/setup-odoobo-dev.sh
```

**What it does** (<5 minutes):

1. Creates `~/.claude/skills/odoobo-expert/` directory structure
2. Creates `~/.claude/knowledge-bases/odoobo/` for local RAG
3. Creates 5 git worktrees for parallel development
4. Initializes Python venv for each worktree
5. Creates agent config + skill skeletons

### Step 2: Verify Installation

```bash
# Check worktrees
./scripts/list-worktrees.sh

# Check skills directory
ls -la ~/.claude/skills/odoobo-expert/

# Check agent config
cat ~/.claude/agents/odoobo-expert.agent.yaml
```

### Step 3: Start Development

```bash
# Terminal 1: Agent Service
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service
source .venv/bin/activate
uvicorn app.main:app --reload --port 8001

# Terminal 2: Skill Development
./scripts/switch-worktree.sh pr-review
code ~/.claude/skills/odoobo-expert/pr-review/

# Terminal 3: Testing
cd ~/.claude/skills/odoobo-expert/pr-review
pytest tests/ -v --watch
```

---

## Development Workflow

### Rapid Iteration Loop (<2 Minutes)

```bash
# 1. Edit skill code (30s)
vim ~/.claude/skills/odoobo-expert/pr-review/review.py

# 2. Run unit tests (20s)
pytest tests/test_review.py -v

# 3. Test with agent (40s)
curl -X POST http://localhost:8001/v1/chat/completions \
  -d '{"messages": [{"role": "user", "content": "/review 123 odoo/odoo"}]}'

# 4. Commit changes (30s)
git commit -m "feat(pr-review): Add lockfile detection"
```

### Parallel Development (5 Developers)

**Developer 1**: PR Review Skill

```bash
cd ~/Documents/TBWA/odoboo-workspace-pr-review
# Develop independently
git push origin feature/pr-review
```

**Developer 2**: Odoo RPC Skill

```bash
cd ~/Documents/TBWA/odoboo-workspace-odoo-rpc
# Develop independently
git push origin feature/odoo-rpc
```

_... (3 more developers working in parallel)_

**Benefits**: No context switching, no merge conflicts, independent testing.

---

## Documentation Overview

### Core Documents

| Document                                                             | Purpose                      | Size |
| -------------------------------------------------------------------- | ---------------------------- | ---- |
| **[ODOOBO_EXPERT_ARCHITECTURE.md](./ODOOBO_EXPERT_ARCHITECTURE.md)** | Complete system architecture | 51KB |
| **[ODOOBO_QUICKSTART.md](./ODOOBO_QUICKSTART.md)**                   | Quick start guide + examples | 15KB |
| **[ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)**             | Mermaid visual diagrams      | 11KB |
| **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)**         | Deliverables + checklist     | 17KB |

### Architecture Document Contents

**[ODOOBO_EXPERT_ARCHITECTURE.md](./ODOOBO_EXPERT_ARCHITECTURE.md)** (51KB):

1. Executive Summary
2. Architecture Overview (text-based diagrams)
3. Anthropic Skills Framework Integration (5 skills)
4. SuperClaude Framework Integration
5. Git Worktrees Strategy (parallel development)
6. DO Gradient AI Knowledge Base Design
7. Local Development Workflow
8. Deployment Path (local → production)
9. Monitoring & Observability
10. Cost Summary ($0 dev, <$10/month prod)
11. Success Metrics & Next Steps
12. Appendices (file structure, references)

### Quick Start Guide Contents

**[ODOOBO_QUICKSTART.md](./ODOOBO_QUICKSTART.md)** (15KB):

1. Prerequisites & Setup
2. 5-Minute Setup Instructions
3. Development Workflow (terminal layout)
4. Skill Development Loop (<2 min)
5. Skill Implementation Example (PR review)
6. Knowledge Base Setup (optional)
7. Parallel Development Strategy
8. Integration Testing
9. Troubleshooting
10. Cost Tracking & Next Steps

### Visual Diagrams Contents

**[ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)** (11KB):

1. System Architecture Overview
2. Skill Architecture (Anthropic pattern)
3. Git Worktrees Development Flow
4. Knowledge Base Architecture
5. Development Timeline (Gantt chart)
6. Skill Execution Flow (sequence diagram)
7. Cost Optimization Strategy
8. Skill Composition Patterns
9. Deployment Architecture
10. Performance Targets & Security Architecture

All diagrams use **Mermaid.js** (viewable in GitHub, VS Code, or https://mermaid.live/).

### Implementation Summary Contents

**[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** (17KB):

1. Deliverables Complete (what was built)
2. Skills Folder Structure Specification
3. Git Worktree Setup Commands
4. DO Gradient AI Integration Plan
5. Local Development Workflow
6. Visual Diagrams Overview
7. Implementation Checklist (10 phases)
8. Success Metrics
9. Risk Mitigation
10. Resources & Next Actions

---

## Implementation Timeline

**Week 0**: Setup (Day 1)

- Run setup script
- Verify worktrees
- Test PR review skeleton

**Weeks 1-5**: Skill Development

- Week 1: PR Review (lockfile, security, OCA)
- Week 2: Odoo RPC (XML-RPC, JSON-RPC, domain builder)
- Week 3: NL-SQL (schema, PostgreSQL, validation)
- Week 4: Visual Diff (SSIM, LPIPS, responsive)
- Week 5: Design Tokens (CSS, SCSS, Tailwind)

**Week 6**: Integration Testing

- Merge all branches
- Run integration tests
- Test skill composition
- Load test (100 concurrent)

**Weeks 7-8**: Knowledge Base

- Scrape Odoo docs (15K chunks)
- Clone OCA guidelines (5K chunks)
- Generate local embeddings
- Test retrieval quality

**Week 9**: Production Deployment

- Migrate to DO Gradient AI
- Deploy agent service
- Configure monitoring
- Run smoke tests

**Week 10+**: Optimization

- Tune RAG pipeline
- Add caching layer
- Scale to 50K+ chunks
- Cost optimization

---

## Cost Analysis

### Development Phase (Months 1-3)

| Component              | Cost         |
| ---------------------- | ------------ |
| Local development      | $0           |
| Git worktrees          | $0           |
| Local ChromaDB         | $0           |
| Testing infrastructure | $0           |
| **Total**              | **$0/month** |

### Production Phase (Month 4+)

| Component                 | Cost          |
| ------------------------- | ------------- |
| DO Gradient AI embeddings | $2/month      |
| DO Gradient AI queries    | $1/month      |
| DO App Platform (agent)   | $5/month      |
| DO Spaces (storage)       | $0.01/month   |
| **Total**                 | **~$8/month** |

### Scaling Projections

| Scale                                | Monthly Cost |
| ------------------------------------ | ------------ |
| Current (50K chunks, 10K queries)    | $8           |
| 2x (100K chunks, 20K queries)        | $15          |
| 10x (500K chunks, 100K queries)      | $60          |
| Enterprise (1M chunks, 500K queries) | $150         |

---

## Key Advantages

### Local-First Development

- ✅ **Zero Cloud Costs**: All development happens locally
- ✅ **Fast Iteration**: <2 minutes per skill test cycle
- ✅ **Offline Capable**: Work without internet connection
- ✅ **Full Control**: Complete control over development environment

### Parallel Development

- ✅ **Zero Context Switching**: Each skill has isolated worktree
- ✅ **Independent Testing**: Separate venv per worktree
- ✅ **No Merge Conflicts**: Until integration phase
- ✅ **Team Collaboration**: 5 developers working simultaneously

### Cost Optimization

- ✅ **$0 Development**: Local ChromaDB, no cloud usage
- ✅ **<$10 Production**: DO Gradient AI managed service
- ✅ **Scalable**: Linear cost growth with usage
- ✅ **Predictable**: No surprise bills

### Deployment Path

- ✅ **Smooth Migration**: Local → production with export/import scripts
- ✅ **Same Code**: Skills work identically in local and production
- ✅ **Incremental**: Deploy skills individually or as bundle
- ✅ **Rollback Ready**: Easy rollback with git worktrees

---

## Success Metrics

### Development Velocity

- ✅ Setup time: <10 minutes
- ✅ Skill iteration: <2 minutes
- ✅ Parallel development: 5 skills simultaneously
- ✅ Test coverage: ≥80% per skill

### Production Readiness

- ✅ Skill execution: P95 <5s
- ✅ KB retrieval: P95 <200ms
- ✅ End-to-end: P95 <10s
- ✅ Uptime: 99.9%

### Cost Efficiency

- ✅ Development: $0/month
- ✅ Production: <$10/month
- ✅ Cost per query: <$0.001
- ✅ Scaling: 10x growth → <$30/month

---

## Files Created

### Documentation (94KB total)

```
odoboo-workspace/
├── ODOOBO_EXPERT_ARCHITECTURE.md    # 51KB - Full architecture
├── ODOOBO_QUICKSTART.md             # 15KB - Quick start guide
├── ARCHITECTURE_DIAGRAM.md           # 11KB - Visual diagrams
├── IMPLEMENTATION_SUMMARY.md         # 17KB - Deliverables checklist
└── ODOOBO_EXPERT_README.md          # This file
```

### Scripts (10KB total)

```
odoboo-workspace/scripts/
├── setup-odoobo-dev.sh              # 9.2KB - Automated setup
├── list-worktrees.sh                # Generated by setup
└── switch-worktree.sh               # Generated by setup
```

### Configuration (Generated by Setup Script)

```
~/.claude/
├── agents/
│   └── odoobo-expert.agent.yaml     # Agent configuration
├── skills/odoobo-expert/
│   ├── REGISTRY.md                  # Skills manifest
│   └── pr-review/                   # PR review skill skeleton
│       ├── SKILL.md
│       ├── review.py
│       ├── requirements.txt
│       └── tests/test_review.py
└── knowledge-bases/odoobo/
    ├── config.yaml                  # KB configuration
    ├── embeddings/                  # Local ChromaDB
    └── docs/                        # Raw documentation
```

---

## Next Steps

### Immediate Actions (Today)

1. ✅ Review architecture documentation
2. [ ] Run setup script: `./scripts/setup-odoobo-dev.sh`
3. [ ] Verify worktrees: `./scripts/list-worktrees.sh`
4. [ ] Set environment variables in ~/.zshrc
5. [ ] Test PR review skeleton

### This Week (Week 1)

1. [ ] Implement PR review skill lockfile detection
2. [ ] Add security vulnerability scanning
3. [ ] Achieve 80% test coverage
4. [ ] Test with real GitHub PRs
5. [ ] Document lessons learned

### This Month (Weeks 1-5)

1. [ ] Complete all 5 skills
2. [ ] Run integration tests (Week 6)
3. [ ] Initialize knowledge base (Weeks 7-8)
4. [ ] Deploy to production (Week 9)

### This Quarter (Weeks 1-10+)

1. [ ] Optimize RAG pipeline
2. [ ] Scale to 50K+ chunks
3. [ ] Add advanced skill composition
4. [ ] Cost optimization (<$10/month)

---

## Support & Resources

### Documentation

- **Full Architecture**: [ODOOBO_EXPERT_ARCHITECTURE.md](./ODOOBO_EXPERT_ARCHITECTURE.md)
- **Quick Start**: [ODOOBO_QUICKSTART.md](./ODOOBO_QUICKSTART.md)
- **Visual Diagrams**: [ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)
- **Implementation Summary**: [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)

### External References

- **Anthropic Skills**: https://docs.anthropic.com/en/docs/build-with-claude/skills
- **Code Execution Tool**: https://docs.anthropic.com/en/docs/build-with-claude/tool-use/code-execution
- **Git Worktrees**: https://git-scm.com/docs/git-worktree
- **DO Gradient AI**: https://docs.digitalocean.com/products/gradient-ai/
- **ChromaDB**: https://docs.trychroma.com/
- **Odoo Developer Guide**: https://www.odoo.com/documentation/18.0/developer/

### Troubleshooting

- **Setup Issues**: See ODOOBO_QUICKSTART.md troubleshooting section
- **Worktree Problems**: Run `git worktree list` to verify
- **Python venv Issues**: Activate correct venv per worktree
- **Agent Service Won't Start**: Check dependencies in requirements.txt

---

## Architecture Status

**Status**: ✅ Ready for Implementation
**Estimated Timeline**: 10 weeks (setup → production)
**Estimated Cost**: $0 development, <$10/month production
**Risk Level**: Low (proven technologies, incremental approach)

**Deliverables Complete**:

- ✅ Complete architecture document (51KB)
- ✅ Skills folder structure specification
- ✅ Git worktree setup commands (automated script)
- ✅ DO Gradient AI integration plan
- ✅ Local development workflow (<2 min iterations)
- ✅ Visual diagrams (11 Mermaid charts)
- ✅ Implementation checklist (10 phases)

**Architect**: System Architect Persona
**Date**: 2025-10-21

---

**Ready to start?** Run `./scripts/setup-odoobo-dev.sh` and begin building! 🚀
