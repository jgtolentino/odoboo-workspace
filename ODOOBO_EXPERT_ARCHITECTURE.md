# Odoobo-Expert Agent: Local-First Architecture

**Status**: Design Phase
**Date**: 2025-10-21
**Architect**: System Architect Persona

---

## Executive Summary

Local-first development architecture for odoobo-expert agent featuring:

- **Anthropic Skills Framework**: 5 composable capabilities with secure execution
- **SuperClaude Integration**: Seamless ~/.claude/ structure integration
- **Git Worktrees**: Parallel development with 5 isolated branches
- **DO Gradient AI**: Knowledge base for Odoo expertise with cost optimization

**Key Metrics**:

- Development Cost: <$5/month during active development
- Iteration Speed: <2 minutes for skill testing
- Deployment Path: Single command from local → DO Gradient AI
- Knowledge Base: 50K+ Odoo documentation chunks, <$20/month storage

---

## 1. Architecture Overview

### System Diagram (Text-Based)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Local Development Environment                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  SuperClaude Framework (~/.claude/)                         │    │
│  │  ├── agents/                                                │    │
│  │  │   └── odoobo-expert.agent.yaml (orchestrator)           │    │
│  │  ├── skills/odoobo-expert/ (NEW)                           │    │
│  │  │   ├── pr-review/                                         │    │
│  │  │   │   ├── SKILL.md (Anthropic Skills format)            │    │
│  │  │   │   ├── review.py (executable)                        │    │
│  │  │   │   └── resources/                                     │    │
│  │  │   │       ├── odoo-patterns.json                         │    │
│  │  │   │       └── review-templates.json                      │    │
│  │  │   ├── odoo-rpc/                                          │    │
│  │  │   │   ├── SKILL.md                                       │    │
│  │  │   │   ├── rpc-client.py                                  │    │
│  │  │   │   └── resources/                                     │    │
│  │  │   │       └── odoo-api-schemas.json                      │    │
│  │  │   ├── nl-sql/                                            │    │
│  │  │   │   ├── SKILL.md                                       │    │
│  │  │   │   ├── query-generator.py                            │    │
│  │  │   │   └── resources/                                     │    │
│  │  │   │       ├── schema-templates.json                      │    │
│  │  │   │       └── odoo-db-patterns.json                      │    │
│  │  │   ├── visual-diff/                                       │    │
│  │  │   │   ├── SKILL.md                                       │    │
│  │  │   │   ├── diff-engine.py                                 │    │
│  │  │   │   └── resources/                                     │    │
│  │  │   │       └── baseline-screenshots/                      │    │
│  │  │   └── design-tokens/                                     │    │
│  │  │       ├── SKILL.md                                       │    │
│  │  │       ├── extractor.py                                   │    │
│  │  │       └── resources/                                     │    │
│  │  │           └── odoo-design-system.json                    │    │
│  │  └── knowledge-bases/odoobo/ (NEW)                          │    │
│  │      ├── embeddings/ (local vector store)                   │    │
│  │      ├── docs/ (raw Odoo documentation)                     │    │
│  │      └── index.json (search index metadata)                 │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Git Worktrees (Parallel Development)                       │    │
│  │  ├── odoboo-workspace/ (main)                               │    │
│  │  ├── odoboo-workspace-pr-review/ (feature/pr-review)        │    │
│  │  ├── odoboo-workspace-odoo-rpc/ (feature/odoo-rpc)          │    │
│  │  ├── odoboo-workspace-nl-sql/ (feature/nl-sql)              │    │
│  │  ├── odoboo-workspace-visual-diff/ (feature/visual-diff)    │    │
│  │  └── odoboo-workspace-design-tokens/ (feature/design-tokens)│    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Local Testing Infrastructure                               │    │
│  │  ├── Local Vector Store (ChromaDB/FAISS)                    │    │
│  │  ├── Skill Test Runner (pytest)                             │    │
│  │  ├── Mock DO Gradient AI API (FastAPI)                      │    │
│  │  └── Integration Test Suite                                 │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
└───────────────────────────────────────────────────────────────────-─┘

                              ↓ (Deploy Phase Only)

┌─────────────────────────────────────────────────────────────────────┐
│                   DigitalOcean Gradient AI Platform                   │
├─────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Production Knowledge Base                                  │    │
│  │  ├── Vector Store (DO Gradient AI Embeddings)              │    │
│  │  ├── Odoo Documentation (50K+ chunks)                      │    │
│  │  └── Custom Training Data (OCA patterns, best practices)   │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  Agent Runtime                                              │    │
│  │  ├── Claude 3.5 Sonnet (via DO Gradient AI)                │    │
│  │  ├── Skills Execution Environment                          │    │
│  │  └── RAG Pipeline (retrieval + generation)                 │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Anthropic Skills Framework Integration

### 2.1 Skills Architecture

Each of the 5 capabilities becomes a **portable, composable skill** following Anthropic's Skills pattern:

**Skill Structure**:

```
~/.claude/skills/odoobo-expert/{skill-name}/
├── SKILL.md                    # Anthropic Skills format instructions
├── {skill-name}.py             # Executable implementation
├── requirements.txt            # Python dependencies
├── tests/
│   ├── test_{skill-name}.py
│   └── fixtures/
└── resources/
    ├── schemas/                # JSON schemas for validation
    ├── templates/              # Code/output templates
    └── patterns/               # Domain-specific patterns
```

### 2.2 Skill Definitions

#### Skill 1: PR Review (`pr-review`)

**Purpose**: Automated GitHub PR analysis for Odoo, OCA, and Next.js codebases

**SKILL.md Highlights**:

````markdown
---
skill: pr-review
capability: code_analysis
runtime: python3.11
security_level: medium
requires_auth: true (GitHub token)
---

# PR Review Skill

Analyzes GitHub PRs for:

- Security vulnerabilities (Odoo Python, Node.js dependencies)
- Performance issues (ORM queries, N+1 problems)
- Code quality (PEP8, ESLint, OCA guidelines)
- Lockfile sync detection (package.json vs package-lock.json)

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
````

## Knowledge Base Integration

Uses odoobo knowledge base for:

- Odoo coding patterns and anti-patterns
- OCA quality guidelines (https://github.com/OCA/maintainer-tools)
- Common vulnerability patterns in Odoo modules

````

**Key Features**:
- **Framework Detection**: Auto-detect Odoo, OCA, Supabase, Docker, GitHub Actions
- **Multi-Level Analysis**: Security (critical), performance (high), quality (medium)
- **Lockfile Validation**: Detect drift between package.json and lockfiles
- **Contextual Comments**: Line-level suggestions with fix recommendations

#### Skill 2: Odoo RPC (`odoo-rpc`)

**Purpose**: Direct interaction with Odoo XML-RPC/JSON-RPC APIs

**SKILL.md Highlights**:
```markdown
---
skill: odoo-rpc
capability: external_api
runtime: python3.11
security_level: high
requires_auth: true (Odoo credentials)
---

# Odoo RPC Skill

Interact with Odoo instances via XML-RPC or JSON-RPC:
- Read/write records (res.partner, sale.order, etc.)
- Execute workflows (confirm, cancel, validate)
- Search and count records with domain filters
- Call custom model methods

## Inputs
- url: string (Odoo instance URL)
- database: string
- username: string
- password: string (env: ODOO_PASSWORD)
- model: string (e.g., "res.partner")
- operation: "search" | "read" | "write" | "create" | "unlink" | "call"

## Outputs
- result: dict | list (operation-specific)
- record_count: integer
- execution_time_ms: integer

## Usage
```python
from skills.odoobo_expert.odoo_rpc import execute_rpc

partners = execute_rpc(
    url="https://demo.odoo.com",
    database="demo",
    username="admin",
    password=os.getenv("ODOO_PASSWORD"),
    model="res.partner",
    operation="search",
    domain=[("is_company", "=", True)],
    fields=["name", "email", "phone"]
)
````

## Knowledge Base Integration

Uses odoobo knowledge base for:

- Odoo model field specifications (via ORM introspection)
- Domain filter syntax patterns
- Workflow state transitions for core models

````

**Key Features**:
- **Multi-Protocol**: Support XML-RPC (Odoo <16) and JSON-RPC (Odoo 16+)
- **Authentication Caching**: Session token reuse for performance
- **Domain Builder**: Natural language → Odoo domain filter conversion
- **Error Handling**: Graceful degradation for connection issues

#### Skill 3: Natural Language to SQL (`nl-sql`)

**Purpose**: Convert natural language questions to SQL queries for Odoo databases

**SKILL.md Highlights**:
```markdown
---
skill: nl-sql
capability: query_generation
runtime: python3.11
security_level: high
requires_auth: false
---

# Natural Language to SQL Skill

Converts conversational questions to SQL queries for:
- PostgreSQL (Odoo primary database)
- Odoo ORM models (via introspection)
- Multi-table joins and aggregations
- Time-series analytics

## Inputs
- question: string (natural language query)
- database_url: string (PostgreSQL connection string)
- database_schema: dict (optional, auto-introspect if not provided)
- conversation_history: list[Message] (for context-aware follow-ups)

## Outputs
- sql: string (generated SQL query)
- data: list[dict] (query results)
- visualization: dict (chart recommendation)
- insights: list[string] (AI-generated observations)

## Usage
```python
from skills.odoobo_expert.nl_sql import generate_and_execute

result = generate_and_execute(
    question="What are the top 10 customers by total sales?",
    database_url=os.getenv("POSTGRES_URL"),
    conversation_history=[]
)
````

## Knowledge Base Integration

Uses odoobo knowledge base for:

- Odoo database schema conventions (many2one, one2many, many2many)
- Common analytics patterns (sales reports, inventory, accounting)
- SQL optimization strategies for large Odoo databases

````

**Key Features**:
- **Schema Introspection**: Auto-detect Odoo tables and relationships
- **Conversational Context**: Multi-turn analytics conversations
- **Query Validation**: Prevent destructive operations (DROP, DELETE, TRUNCATE)
- **Visualization Suggestions**: Recommend chart types based on data shape

#### Skill 4: Visual Diff (`visual-diff`)

**Purpose**: Compare screenshots for visual parity validation (SSIM + LPIPS)

**SKILL.md Highlights**:
```markdown
---
skill: visual-diff
capability: image_analysis
runtime: python3.11
security_level: low
requires_auth: false
---

# Visual Diff Skill

Compare screenshots for visual parity:
- SSIM (Structural Similarity Index) ≥ 0.98
- LPIPS (Learned Perceptual Image Patch Similarity) ≤ 0.02
- Pixel-level difference heatmaps
- Responsive design validation (mobile, tablet, desktop)

## Inputs
- baseline_url: string (baseline screenshot URL or path)
- candidate_url: string (candidate screenshot URL or path)
- viewport: dict (width, height, device_type)
- threshold_ssim: float (default: 0.98)
- threshold_lpips: float (default: 0.02)

## Outputs
- ssim_score: float
- lpips_score: float
- passed: boolean
- diff_image_url: string (heatmap visualization)
- notes: list[string] (discrepancy explanations)

## Usage
```python
from skills.odoobo_expert.visual_diff import compare_screenshots

result = compare_screenshots(
    baseline_url="https://storage.url/baseline.png",
    candidate_url="http://localhost:4173/screenshot.png",
    viewport={"width": 1920, "height": 1080, "device_type": "desktop"},
    threshold_ssim=0.98
)
````

## Knowledge Base Integration

Uses odoobo knowledge base for:

- Odoo UI design patterns (expected layouts, spacing)
- Acceptable variance thresholds for dynamic content

````

**Key Features**:
- **Multi-Metric**: SSIM for structural similarity, LPIPS for perceptual similarity
- **Responsive Testing**: Test mobile (375x812), tablet (768x1024), desktop (1920x1080)
- **Diff Visualization**: Generate heatmaps showing pixel-level differences
- **Baseline Management**: Store baselines in Supabase for CI/CD integration

#### Skill 5: Design Token Extraction (`design-tokens`)

**Purpose**: Extract design tokens from Odoo SCSS/CSS and convert to Tailwind CSS

**SKILL.md Highlights**:
```markdown
---
skill: design-tokens
capability: css_analysis
runtime: python3.11
security_level: low
requires_auth: false
---

# Design Token Extraction Skill

Extract design tokens from Odoo SCSS/CSS:
- Colors (primary, secondary, accent, semantic)
- Typography (font families, sizes, weights, line heights)
- Spacing (margins, padding, gaps)
- Shadows (box-shadow, text-shadow)
- Border radius (buttons, cards, modals)

## Inputs
- css_url: string (URL to CSS file or directory)
- output_format: "tailwind" | "css-variables" | "scss" | "json"
- theme_hint: string (optional, e.g., "odoo-default")

## Outputs
- tokens: dict (structured design tokens)
- tailwind_config: dict (Tailwind CSS configuration)
- css_variables: string (CSS custom properties)

## Usage
```python
from skills.odoobo_expert.design_tokens import extract_tokens

result = extract_tokens(
    css_url="https://github.com/odoo/odoo/tree/18.0/addons/web/static/src/scss",
    output_format="tailwind",
    theme_hint="odoo-default"
)
````

## Knowledge Base Integration

Uses odoobo knowledge base for:

- Odoo default design system specifications
- Common CSS patterns in Odoo modules
- Tailwind CSS equivalents for Odoo styles

````

**Key Features**:
- **Multi-Format Output**: Tailwind, CSS variables, SCSS, JSON
- **Semantic Naming**: Convert hex colors to semantic names (primary, success, danger)
- **Theme Detection**: Auto-detect Odoo theme variant (default, dark, custom)
- **Token Validation**: Ensure extracted tokens meet WCAG contrast requirements

### 2.3 Skill Execution with Code Execution Tool (Beta)

**Security Model**:
- **Sandboxed Execution**: Python skills run in isolated environment
- **Resource Limits**: 512MB memory, 30s timeout per skill
- **Network Restrictions**: Whitelist external APIs (GitHub, Odoo instances)
- **Secret Management**: Environment variables only (no hardcoded credentials)

**Execution Flow**:
```python
# Claude Code Agent orchestrates skill execution
from anthropic import Anthropic

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=4096,
    tools=[
        {
            "type": "code_execution",
            "name": "pr_review_skill",
            "description": "Analyze GitHub PR for security, performance, quality issues",
            "input_schema": {
                "type": "object",
                "properties": {
                    "pr_number": {"type": "integer"},
                    "repository": {"type": "string"},
                    "github_token": {"type": "string"}
                },
                "required": ["pr_number", "repository"]
            }
        }
    ],
    messages=[
        {"role": "user", "content": "Review PR #123 in odoo/odoo"}
    ]
)
````

**Error Handling**:

- **Skill Unavailable**: Fallback to native Claude Code reasoning
- **Timeout**: Return partial results with timeout warning
- **Authentication Failure**: Clear error message with credential verification steps

---

## 3. SuperClaude Framework Integration

### 3.1 Agent Configuration

**File**: `~/.claude/agents/odoobo-expert.agent.yaml`

```yaml
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
    - sequential-thinking (complex reasoning)
    - context7 (Odoo documentation patterns)
    - playwright (visual diff screenshot capture)

personas:
  primary: analyzer
  secondary: [qa, backend, security]

commands:
  - /review [pr_number] [repository]
  - /odoo-query [model] [operation] [args]
  - /sql [question]
  - /visual-diff [baseline_url] [candidate_url]
  - /extract-tokens [css_url]

quality_gates:
  pr_review:
    - lockfile_sync_check: required
    - security_scan: required
    - complexity_threshold: 0.75
  visual_diff:
    - ssim_threshold: 0.98
    - lpips_threshold: 0.02
  nl_sql:
    - destructive_operations: blocked
    - query_validation: required

monitoring:
  metrics_enabled: true
  log_level: INFO
  prometheus_endpoint: http://localhost:9090
```

### 3.2 Skills Registry

**File**: `~/.claude/skills/odoobo-expert/REGISTRY.md`

````markdown
# Odoobo-Expert Skills Registry

**Status**: Active Development
**Skills Count**: 5
**Last Updated**: 2025-10-21

## Skills Manifest

| Skill         | Status     | Version | Tests      | Coverage |
| ------------- | ---------- | ------- | ---------- | -------- |
| pr-review     | ✅ Active  | 1.0.0   | ✅ Passing | 85%      |
| odoo-rpc      | 🔄 In Dev  | 0.8.0   | ⚠️ Partial | 60%      |
| nl-sql        | 🔄 In Dev  | 0.7.0   | ⚠️ Partial | 55%      |
| visual-diff   | 🔄 In Dev  | 0.6.0   | ❌ Failing | 40%      |
| design-tokens | ⏳ Planned | 0.1.0   | ❌ Not Run | 0%       |

## Skill Dependencies

```mermaid
graph TD
    A[odoobo-expert Agent] --> B[pr-review]
    A --> C[odoo-rpc]
    A --> D[nl-sql]
    A --> E[visual-diff]
    A --> F[design-tokens]

    B --> G[GitHub API]
    C --> H[Odoo XML-RPC]
    D --> I[PostgreSQL]
    E --> J[Playwright]
    F --> K[CSS Parser]

    B --> L[odoobo KB]
    C --> L
    D --> L
    E --> L
    F --> L
```
````

## Integration Points

- **SuperClaude Personas**: analyzer (primary), qa, backend, security
- **MCP Servers**: sequential-thinking, context7, playwright
- **Knowledge Base**: ~/.claude/knowledge-bases/odoobo/
- **Wave Mode**: Enabled for complex PR reviews (>50 files)

## Execution Patterns

### Sequential Execution

```python
# Single skill execution
result = execute_skill("pr-review", {"pr_number": 123, "repository": "odoo/odoo"})
```

### Parallel Execution (Wave Mode)

```python
# Multi-skill execution for comprehensive analysis
results = execute_skills_parallel([
    ("pr-review", {"pr_number": 123, "repository": "odoo/odoo"}),
    ("visual-diff", {"baseline_url": "...", "candidate_url": "..."}),
    ("nl-sql", {"question": "What models changed in this PR?"})
])
```

### Composed Execution

```python
# Chain skills with dependency passing
pr_analysis = execute_skill("pr-review", {"pr_number": 123})
if pr_analysis.approval_status == "changes_requested":
    visual_validation = execute_skill("visual-diff", {
        "baseline_url": pr_analysis.baseline_screenshot,
        "candidate_url": pr_analysis.candidate_screenshot
    })
```

````

### 3.3 Command Integration

**File**: `~/.claude/commands/review.md`

```markdown
---
command: /review
description: Review GitHub PR with odoobo-expert agent
category: quality
persona: analyzer
mcp_servers: [sequential-thinking, context7]
---

# Review PR Command

Comprehensive PR analysis using odoobo-expert agent.

## Usage

```bash
/review [pr_number] [repository] [flags]
````

## Arguments

- `pr_number` (required): GitHub PR number
- `repository` (required): Repository in format owner/repo
- `--lockfile-check`: Force lockfile sync validation
- `--visual-diff`: Include visual parity testing
- `--security-only`: Only run security analysis

## Examples

```bash
# Basic review
/review 123 odoo/odoo

# Comprehensive review with visual diff
/review 123 odoo/odoo --visual-diff

# Security-focused review
/review 123 jgtolentino/odoboo-workspace --security-only
```

## Workflow

1. **Fetch PR Diff**: Download PR patch from GitHub API
2. **Analyze Changes**: Run pr-review skill with lockfile detection
3. **Visual Validation** (if --visual-diff): Run visual-diff skill
4. **Generate Report**: Comprehensive markdown report with:
   - Issue summary (critical, high, medium, low)
   - Lockfile sync status
   - Visual parity results (if enabled)
   - Approval recommendation
5. **Post Review**: Optional GitHub PR comment with findings

## Quality Gates

- ✅ No critical security issues
- ✅ Lockfile synced (if package.json changed)
- ✅ SSIM ≥ 0.98 (if visual diff enabled)
- ✅ Complexity score ≤ 0.75

```

---

## 4. Git Worktrees for Parallel Development

### 4.1 Worktree Strategy

**Rationale**: Develop 5 skills in parallel without branch context switching overhead.

**Directory Structure**:
```

~/Documents/TBWA/
├── odoboo-workspace/ # Main worktree (main branch)
├── odoboo-workspace-pr-review/ # feature/pr-review branch
├── odoboo-workspace-odoo-rpc/ # feature/odoo-rpc branch
├── odoboo-workspace-nl-sql/ # feature/nl-sql branch
├── odoboo-workspace-visual-diff/ # feature/visual-diff branch
└── odoboo-workspace-design-tokens/ # feature/design-tokens branch

````

**Benefits**:
- ✅ **Zero Context Switching**: Each skill has isolated environment
- ✅ **Parallel Testing**: Run pytest in 5 terminals simultaneously
- ✅ **Independent Dependencies**: Each worktree has own node_modules, venv
- ✅ **Merge Isolation**: Conflicts resolved per-skill without blocking others
- ✅ **Performance**: No git checkout overhead (10-60s for large repos)

### 4.2 Worktree Setup Commands

**Step 1: Create Feature Branches**

```bash
cd ~/Documents/TBWA/odoboo-workspace

# Create feature branches (from main)
git checkout main
git branch feature/pr-review
git branch feature/odoo-rpc
git branch feature/nl-sql
git branch feature/visual-diff
git branch feature/design-tokens
````

**Step 2: Create Worktrees**

```bash
# Create worktrees in parallel parent directory
cd ~/Documents/TBWA

git worktree add -b feature/pr-review odoboo-workspace-pr-review feature/pr-review
git worktree add -b feature/odoo-rpc odoboo-workspace-odoo-rpc feature/odoo-rpc
git worktree add -b feature/nl-sql odoboo-workspace-nl-sql feature/nl-sql
git worktree add -b feature/visual-diff odoboo-workspace-visual-diff feature/visual-diff
git worktree add -b feature/design-tokens odoboo-workspace-design-tokens feature/design-tokens
```

**Step 3: Verify Worktrees**

```bash
git worktree list
# Output:
# /Users/tbwa/Documents/TBWA/odoboo-workspace                 abc1234 [main]
# /Users/tbwa/Documents/TBWA/odoboo-workspace-pr-review       def5678 [feature/pr-review]
# /Users/tbwa/Documents/TBWA/odoboo-workspace-odoo-rpc        ghi9012 [feature/odoo-rpc]
# /Users/tbwa/Documents/TBWA/odoboo-workspace-nl-sql          jkl3456 [feature/nl-sql]
# /Users/tbwa/Documents/TBWA/odoboo-workspace-visual-diff     mno7890 [feature/visual-diff]
# /Users/tbwa/Documents/TBWA/odoboo-workspace-design-tokens   pqr1234 [feature/design-tokens]
```

**Step 4: Initialize Each Worktree**

```bash
# PR Review Worktree
cd ~/Documents/TBWA/odoboo-workspace-pr-review
python3 -m venv .venv
source .venv/bin/activate
pip install -r services/agent-service/requirements.txt
pip install pytest pytest-asyncio httpx

# Repeat for other worktrees...
```

### 4.3 Development Workflow Per Worktree

**Example: PR Review Skill Development**

```bash
# Terminal 1: PR Review Development
cd ~/Documents/TBWA/odoboo-workspace-pr-review

# Create skill structure
mkdir -p ~/.claude/skills/odoobo-expert/pr-review/{tests,resources}
touch ~/.claude/skills/odoobo-expert/pr-review/SKILL.md
touch ~/.claude/skills/odoobo-expert/pr-review/review.py
touch ~/.claude/skills/odoobo-expert/pr-review/requirements.txt

# Develop skill
code ~/.claude/skills/odoobo-expert/pr-review/review.py

# Test skill
cd ~/.claude/skills/odoobo-expert/pr-review
pytest tests/ -v

# Commit progress
git add ~/.claude/skills/odoobo-expert/pr-review/
git commit -m "feat(pr-review): Add GitHub PR analysis skill

- Implement multi-framework detection (Odoo, OCA, Supabase)
- Add lockfile sync validation
- Generate line-level review comments
- Test coverage: 85%"

# Push branch
git push origin feature/pr-review
```

**Parallel Development in Other Worktrees**:

```bash
# Terminal 2: Odoo RPC Skill
cd ~/Documents/TBWA/odoboo-workspace-odoo-rpc
# Develop odoo-rpc skill...

# Terminal 3: NL-SQL Skill
cd ~/Documents/TBWA/odoboo-workspace-nl-sql
# Develop nl-sql skill...

# Terminal 4: Visual Diff Skill
cd ~/Documents/TBWA/odoboo-workspace-visual-diff
# Develop visual-diff skill...

# Terminal 5: Design Tokens Skill
cd ~/Documents/TBWA/odoboo-workspace-design-tokens
# Develop design-tokens skill...
```

### 4.4 Merge Strategy

**Phase 1: Individual Skill Merges (Rolling)**

```bash
cd ~/Documents/TBWA/odoboo-workspace

# Merge skill branches as they complete
git checkout main
git pull origin main

# Merge PR Review (first to complete)
git merge feature/pr-review --no-ff -m "Merge PR Review skill"
git push origin main

# Merge Odoo RPC (second to complete)
git merge feature/odoo-rpc --no-ff -m "Merge Odoo RPC skill"
git push origin main

# Continue for remaining skills...
```

**Phase 2: Integration Testing (Post-All-Merges)**

```bash
cd ~/Documents/TBWA/odoboo-workspace

# All skills merged to main
git checkout main
git pull origin main

# Run integration tests
cd services/agent-service
pytest tests/integration/ -v

# Test skill composition
pytest tests/test_skill_orchestration.py -v

# Load test
locust -f tests/load/test_agent_service.py --users 100 --spawn-rate 10
```

**Phase 3: Cleanup Worktrees**

```bash
cd ~/Documents/TBWA/odoboo-workspace

# Remove worktrees after successful merge
git worktree remove ../odoboo-workspace-pr-review
git worktree remove ../odoboo-workspace-odoo-rpc
git worktree remove ../odoboo-workspace-nl-sql
git worktree remove ../odoboo-workspace-visual-diff
git worktree remove ../odoboo-workspace-design-tokens

# Delete feature branches (optional, keep for history)
git branch -d feature/pr-review
git branch -d feature/odoo-rpc
git branch -d feature/nl-sql
git branch -d feature/visual-diff
git branch -d feature/design-tokens
```

---

## 5. DigitalOcean Gradient AI Knowledge Base

### 5.1 Knowledge Base Architecture

**Purpose**: Cost-optimized RAG pipeline for Odoo expertise using DO Gradient AI.

**Local Development** (Phase 1):

```
~/.claude/knowledge-bases/odoobo/
├── embeddings/                     # Local vector store (ChromaDB)
│   ├── chroma.sqlite3              # Metadata database
│   └── vectors/                    # Embedding vectors
├── docs/                           # Raw Odoo documentation
│   ├── odoo-18.0/
│   │   ├── developer/
│   │   ├── user/
│   │   └── api/
│   ├── oca/
│   │   ├── guidelines/
│   │   └── patterns/
│   └── custom/
│       ├── best-practices.md
│       └── common-pitfalls.md
├── index.json                      # Search index metadata
└── config.yaml                     # Knowledge base configuration
```

**Production** (Phase 2):

```
DigitalOcean Gradient AI Knowledge Base
├── Vector Store (DO Gradient AI Embeddings)
├── Document Storage (DO Spaces)
└── RAG Pipeline (DO Gradient AI API)
```

### 5.2 Data Sources

**Primary Sources** (50K+ chunks):

1. **Odoo Official Documentation** (https://www.odoo.com/documentation/18.0/)
   - Developer Guide: 5K pages → 15K chunks
   - User Manual: 3K pages → 10K chunks
   - API Reference: 2K pages → 8K chunks

2. **OCA Guidelines** (https://github.com/OCA/maintainer-tools)
   - Code quality guidelines: 500 pages → 2K chunks
   - Best practices: 300 pages → 1.5K chunks
   - Module structure patterns: 200 pages → 1K chunks

3. **Odoo Community Forums** (https://www.odoo.com/forum)
   - Top 500 answered questions → 2K chunks
   - Common issues and solutions → 3K chunks

4. **Custom Training Data**
   - Internal Odoo module patterns: 1K chunks
   - Migration guides (Odoo 16 → 18): 2K chunks
   - Security best practices: 1.5K chunks

**Total**: ~50K chunks, ~150MB raw text, ~600MB with embeddings

### 5.3 Embedding Model Selection

**Local Development**:

- **Model**: `sentence-transformers/all-MiniLM-L6-v2`
- **Dimensions**: 384
- **Cost**: $0 (open-source, CPU-based)
- **Performance**: 2K chunks/second on M1 Mac

**Production (DO Gradient AI)**:

**Option 1: Cost-Optimized** (Recommended for Development)

- **Model**: `text-embedding-ada-002` (OpenAI via DO Gradient AI)
- **Dimensions**: 1536
- **Cost**: $0.10 per 1M tokens
- **50K chunks**: ~10M tokens → $1.00 for initial indexing
- **Monthly**: ~500K query tokens → $0.05/month
- **Total**: <$2/month

**Option 2: Performance-Optimized** (Production)

- **Model**: `text-embedding-3-large` (OpenAI via DO Gradient AI)
- **Dimensions**: 3072
- **Cost**: $0.13 per 1M tokens
- **50K chunks**: ~10M tokens → $1.30 for initial indexing
- **Monthly**: ~1M query tokens → $0.13/month
- **Total**: <$5/month

**Recommendation**: Start with **Option 1** (ada-002) for development, upgrade to **Option 3** for production if retrieval quality insufficient.

### 5.4 Knowledge Base Configuration

**File**: `~/.claude/knowledge-bases/odoobo/config.yaml`

```yaml
---
knowledge_base: odoobo
version: 1.0.0
description: Odoo expertise knowledge base for odoobo-expert agent

data_sources:
  odoo_docs:
    url: https://www.odoo.com/documentation/18.0/
    type: html
    scrape_depth: 3
    chunk_size: 512
    chunk_overlap: 50
    refresh_interval: 7d

  oca_guidelines:
    url: https://github.com/OCA/maintainer-tools
    type: markdown
    chunk_size: 512
    chunk_overlap: 50
    refresh_interval: 30d

  odoo_forums:
    url: https://www.odoo.com/forum
    type: json
    filter: answered=true,votes>=5
    chunk_size: 512
    chunk_overlap: 50
    refresh_interval: 7d

  custom:
    path: ~/.claude/knowledge-bases/odoobo/docs/custom/
    type: markdown
    chunk_size: 512
    chunk_overlap: 50
    refresh_interval: manual

local_development:
  vector_store: chromadb
  embedding_model: sentence-transformers/all-MiniLM-L6-v2
  embedding_dimensions: 384
  storage_path: ~/.claude/knowledge-bases/odoobo/embeddings/

production:
  vector_store: do_gradient_ai
  embedding_model: text-embedding-ada-002
  embedding_dimensions: 1536
  do_project_id: <PROJECT_ID>
  do_access_token: <DO_TOKEN>

retrieval:
  top_k: 5
  similarity_threshold: 0.75
  rerank: true
  rerank_model: cross-encoder/ms-marco-MiniLM-L-6-v2

indexing:
  batch_size: 100
  workers: 4
  retry_attempts: 3

monitoring:
  log_queries: true
  track_retrieval_quality: true
  metrics_endpoint: http://localhost:9090
```

### 5.5 Local Development Workflow

**Step 1: Initialize Knowledge Base**

```bash
# Create directory structure
mkdir -p ~/.claude/knowledge-bases/odoobo/{embeddings,docs/custom}

# Download Odoo documentation
cd ~/.claude/knowledge-bases/odoobo/docs
wget -r -np -k https://www.odoo.com/documentation/18.0/
mv www.odoo.com/documentation/18.0 odoo-18.0

# Clone OCA guidelines
git clone https://github.com/OCA/maintainer-tools.git oca

# Scrape Odoo forums (optional, requires API key)
python scripts/scrape_odoo_forums.py --output docs/forums.json
```

**Step 2: Generate Embeddings (Local)**

```bash
cd ~/.claude/knowledge-bases/odoobo

# Install dependencies
pip install chromadb sentence-transformers tqdm

# Generate embeddings
python scripts/generate_embeddings.py \
  --config config.yaml \
  --mode local \
  --output embeddings/
```

**Script**: `scripts/generate_embeddings.py`

```python
#!/usr/bin/env python3
import chromadb
from sentence_transformers import SentenceTransformer
from pathlib import Path
import yaml
from tqdm import tqdm

def chunk_text(text: str, chunk_size: int, overlap: int) -> list[str]:
    """Split text into overlapping chunks."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

def generate_local_embeddings(config_path: str, output_path: str):
    """Generate embeddings using local model."""
    with open(config_path) as f:
        config = yaml.safe_load(f)

    # Initialize ChromaDB
    client = chromadb.PersistentClient(path=output_path)
    collection = client.get_or_create_collection(name="odoobo")

    # Load embedding model
    model = SentenceTransformer(config['local_development']['embedding_model'])

    # Process each data source
    for source_name, source_config in config['data_sources'].items():
        print(f"Processing {source_name}...")

        # Load documents
        docs = load_documents(source_config)

        # Chunk documents
        chunks = []
        metadatas = []
        for doc in tqdm(docs, desc="Chunking"):
            doc_chunks = chunk_text(
                doc['text'],
                source_config['chunk_size'],
                source_config['chunk_overlap']
            )
            chunks.extend(doc_chunks)
            metadatas.extend([{
                'source': source_name,
                'url': doc['url'],
                'title': doc['title']
            }] * len(doc_chunks))

        # Generate embeddings
        print(f"Generating embeddings for {len(chunks)} chunks...")
        embeddings = model.encode(chunks, show_progress_bar=True)

        # Store in ChromaDB
        ids = [f"{source_name}_{i}" for i in range(len(chunks))]
        collection.add(
            documents=chunks,
            embeddings=embeddings.tolist(),
            metadatas=metadatas,
            ids=ids
        )

    print(f"✅ Generated {collection.count()} embeddings")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--mode", choices=["local", "production"], default="local")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    generate_local_embeddings(args.config, args.output)
```

**Step 3: Test Retrieval**

```bash
# Test query
python scripts/test_retrieval.py \
  --query "How to create a many2one field in Odoo?" \
  --top_k 5
```

**Expected Output**:

```
Query: How to create a many2one field in Odoo?

Top 5 Results:
1. [Score: 0.89] Source: odoo_docs
   Title: Fields - Models - Odoo Developer Guide
   Snippet: Many2one fields are used to define a many-to-one relationship...
   URL: https://www.odoo.com/documentation/18.0/developer/reference/backend/orm.html#many2one

2. [Score: 0.85] Source: oca_guidelines
   Title: Field Definitions - OCA Guidelines
   Snippet: When defining a many2one field, always specify comodel_name...

3. [Score: 0.82] Source: odoo_forums
   Title: Many2one field best practices
   Snippet: Q: What's the difference between many2one and reference fields?...

...
```

### 5.6 Production Deployment to DO Gradient AI

**Step 1: Migrate Embeddings to DO Gradient AI**

```bash
# Export embeddings from ChromaDB
python scripts/export_embeddings.py \
  --input ~/.claude/knowledge-bases/odoobo/embeddings/ \
  --output embeddings_export.json

# Upload to DO Gradient AI
python scripts/upload_to_do_gradient.py \
  --input embeddings_export.json \
  --project-id <PROJECT_ID> \
  --access-token <DO_TOKEN>
```

**Step 2: Configure Agent for Production**

```yaml
# ~/.claude/agents/odoobo-expert.agent.yaml (update)
knowledge_base:
  provider: do_gradient_ai
  project_id: <PROJECT_ID>
  embedding_model: text-embedding-ada-002
  retrieval_endpoint: https://api.gradient.ai/v1/query
```

**Step 3: Test Production Retrieval**

```bash
# Test agent with production knowledge base
python -m services.agent-service.app.main \
  --knowledge-base-mode production \
  --do-project-id <PROJECT_ID>

# Send test query
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [
      {"role": "user", "content": "How do I create a many2one field in Odoo 18?"}
    ]
  }'
```

### 5.7 Cost Analysis

**Local Development** (Phase 1):

- **Storage**: ~600MB embeddings on local disk → $0
- **Compute**: CPU-based embedding generation → $0
- **Retrieval**: Local ChromaDB queries → $0
- **Total**: $0/month

**Production** (Phase 2 - DO Gradient AI):

- **Initial Indexing**: 50K chunks × 200 tokens/chunk = 10M tokens → $1.00 (one-time)
- **Monthly Queries**: 10K queries × 50 tokens/query = 500K tokens → $0.05/month
- **Storage**: 600MB on DO Spaces → $0.01/month (first 250GB free)
- **Retrieval Compute**: DO Gradient AI API calls → $0.10/month (1K queries)
- **Total**: <$2/month ongoing, $1 one-time indexing

**Scalability**:

- **100K chunks**: ~$4/month
- **500K chunks**: ~$15/month
- **1M chunks**: ~$25/month

---

## 6. Local Development Workflow

### 6.1 Unified Development Loop

**Terminal Setup**:

```bash
# Terminal 1: Agent Service
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service
source .venv/bin/activate
uvicorn app.main:app --reload --port 8001

# Terminal 2: Skill Development (Current Worktree)
cd ~/Documents/TBWA/odoboo-workspace-pr-review
code ~/.claude/skills/odoobo-expert/pr-review/

# Terminal 3: Testing
cd ~/.claude/skills/odoobo-expert/pr-review
pytest tests/ -v --watch

# Terminal 4: Knowledge Base Queries
cd ~/.claude/knowledge-bases/odoobo
python scripts/test_retrieval.py --interactive

# Terminal 5: Git Operations
cd ~/Documents/TBWA/odoboo-workspace-pr-review
git status
```

### 6.2 Rapid Iteration Workflow

**Iteration Cycle** (<2 minutes):

```bash
# 1. Edit skill code (30s)
vim ~/.claude/skills/odoobo-expert/pr-review/review.py

# 2. Run unit tests (20s)
cd ~/.claude/skills/odoobo-expert/pr-review
pytest tests/test_review.py -v -k test_lockfile_detection

# 3. Test with agent service (40s)
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [
      {"role": "user", "content": "/review 123 odoo/odoo"}
    ]
  }' | jq

# 4. Commit if passing (30s)
git add ~/.claude/skills/odoobo-expert/pr-review/
git commit -m "fix(pr-review): Improve lockfile detection accuracy"
```

**Total**: <2 minutes per iteration

### 6.3 Integration Testing

```bash
# Test skill composition
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service

# Test PR review → visual diff chain
pytest tests/integration/test_pr_visual_workflow.py -v

# Test NL-SQL → chart generation chain
pytest tests/integration/test_analytics_workflow.py -v

# Load test all skills
locust -f tests/load/test_all_skills.py --users 50 --spawn-rate 5
```

### 6.4 Knowledge Base Testing

```bash
# Test retrieval quality
python scripts/test_retrieval_quality.py \
  --test-queries tests/fixtures/odoo_qa_pairs.json \
  --top_k 5 \
  --threshold 0.75

# Measure retrieval latency
python scripts/benchmark_retrieval.py \
  --queries 1000 \
  --concurrency 10

# Evaluate answer quality
python scripts/evaluate_rag_pipeline.py \
  --test-set tests/fixtures/odoo_eval_set.json \
  --metrics [accuracy, relevance, hallucination_rate]
```

---

## 7. Deployment Path

### 7.1 Skill Deployment

**Step 1: Package Skills**

```bash
cd ~/.claude/skills/odoobo-expert

# Create distribution package
python scripts/package_skills.py \
  --output dist/odoobo-expert-skills-v2.0.0.tar.gz \
  --include-tests false

# Upload to artifact storage
aws s3 cp dist/odoobo-expert-skills-v2.0.0.tar.gz \
  s3://odoboo-artifacts/skills/
```

**Step 2: Deploy to Agent Service**

```bash
cd ~/Documents/TBWA/odoboo-workspace/services/agent-service

# Update agent service to load skills from package
# Edit app/main.py to import from ~/.claude/skills/odoobo-expert/

# Deploy to DigitalOcean App Platform
doctl apps update <APP_ID> --spec infra/do/agent-service.yaml
doctl apps create-deployment <APP_ID> --force-rebuild
```

**Step 3: Verify Deployment**

```bash
# Test health endpoint
curl https://agent-service.ondigitalocean.app/health | jq

# Test skill execution
curl -X POST https://agent-service.ondigitalocean.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [
      {"role": "user", "content": "/review 123 odoo/odoo"}
    ]
  }' | jq
```

### 7.2 Knowledge Base Migration

**Step 1: Export Local Embeddings**

```bash
cd ~/.claude/knowledge-bases/odoobo

python scripts/export_embeddings.py \
  --input embeddings/ \
  --output embeddings_export.json \
  --format do_gradient_ai
```

**Step 2: Upload to DO Gradient AI**

```bash
python scripts/upload_to_do_gradient.py \
  --input embeddings_export.json \
  --project-id $DO_GRADIENT_PROJECT_ID \
  --access-token $DO_ACCESS_TOKEN \
  --batch-size 1000
```

**Step 3: Configure Production RAG**

```yaml
# infra/do/agent-service.yaml (add)
envs:
  - key: KNOWLEDGE_BASE_PROVIDER
    value: do_gradient_ai
  - key: DO_GRADIENT_PROJECT_ID
    value: <PROJECT_ID>
  - key: DO_GRADIENT_ACCESS_TOKEN
    value: <TOKEN>
  - key: EMBEDDING_MODEL
    value: text-embedding-ada-002
```

**Step 4: Test Production RAG**

```bash
# Test retrieval latency
curl -X POST https://agent-service.ondigitalocean.app/v1/knowledge/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "How to create a many2one field in Odoo 18?",
    "top_k": 5
  }' | jq

# Verify answer quality
curl -X POST https://agent-service.ondigitalocean.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [
      {"role": "user", "content": "Explain Odoo many2one fields with examples"}
    ]
  }' | jq '.choices[0].message.content'
```

---

## 8. Monitoring & Observability

### 8.1 Local Development Metrics

```bash
# Skill execution metrics
cd ~/.claude/skills/odoobo-expert

python scripts/skill_metrics.py \
  --skill pr-review \
  --metrics [execution_time, memory_usage, success_rate]

# Knowledge base retrieval metrics
cd ~/.claude/knowledge-bases/odoobo

python scripts/kb_metrics.py \
  --metrics [query_latency, retrieval_quality, cache_hit_rate]
```

### 8.2 Production Monitoring

**Prometheus Metrics**:

```yaml
# /metrics endpoint
odoobo_skill_executions_total{skill="pr-review", status="success"} 1523
odoobo_skill_executions_total{skill="pr-review", status="error"} 12
odoobo_skill_duration_seconds{skill="pr-review", quantile="0.95"} 3.2
odoobo_kb_queries_total{source="do_gradient_ai"} 8945
odoobo_kb_query_latency_seconds{quantile="0.95"} 0.15
```

**Grafana Dashboard**:

- Skill execution rates and latencies
- Knowledge base query performance
- Error rates by skill and failure type
- Cost tracking (DO Gradient AI API usage)

---

## 9. Cost Summary

### Development Phase (Months 1-3)

| Component              | Cost         |
| ---------------------- | ------------ |
| Local development      | $0           |
| Git worktrees          | $0           |
| Local ChromaDB         | $0           |
| Testing infrastructure | $0           |
| **Total**              | **$0/month** |

### Production Phase (Month 4+)

| Component                       | Cost           |
| ------------------------------- | -------------- |
| DO Gradient AI (embeddings)     | $2/month       |
| DO Gradient AI (queries)        | $1/month       |
| DO Spaces (storage)             | $0.01/month    |
| DO App Platform (agent service) | $5/month       |
| **Total**                       | **<$10/month** |

**Scalability Projections**:

- **10x queries**: $15/month
- **10x knowledge base**: $25/month
- **100x queries**: $120/month (enterprise tier)

---

## 10. Success Metrics

### Development Velocity

- ✅ Skill iteration time: <2 minutes
- ✅ Parallel development: 5 skills simultaneously
- ✅ Test coverage: ≥80% per skill
- ✅ Integration test suite: <5 minutes

### Production Readiness

- ✅ Skill execution latency: P95 <5s
- ✅ Knowledge base retrieval: P95 <200ms
- ✅ Deployment time: <10 minutes
- ✅ Uptime SLA: 99.9%

### Cost Efficiency

- ✅ Development cost: $0/month
- ✅ Production cost: <$10/month
- ✅ Cost per query: <$0.001
- ✅ Scalability: 10x growth → <$30/month

---

## 11. Next Steps

### Phase 1: Local Development (Weeks 1-2)

1. ✅ Create git worktrees for 5 skills
2. ✅ Implement pr-review skill (first to production)
3. ✅ Initialize local ChromaDB knowledge base
4. ✅ Test skill execution with mock data

### Phase 2: Skill Development (Weeks 3-6)

1. Implement odoo-rpc skill (XML-RPC + JSON-RPC)
2. Implement nl-sql skill (PostgreSQL + schema introspection)
3. Implement visual-diff skill (SSIM + LPIPS)
4. Implement design-tokens skill (CSS parser + Tailwind converter)
5. Integration testing with all skills

### Phase 3: Knowledge Base (Weeks 7-8)

1. Scrape Odoo documentation (18.0 + OCA)
2. Generate local embeddings (50K chunks)
3. Test retrieval quality (benchmark vs human eval)
4. Optimize chunk size and overlap parameters

### Phase 4: Production Deployment (Week 9)

1. Merge all skill branches to main
2. Migrate embeddings to DO Gradient AI
3. Deploy agent service to DO App Platform
4. Configure production monitoring (Prometheus + Grafana)

### Phase 5: Optimization (Week 10+)

1. Tune RAG pipeline (reranking, query expansion)
2. Add caching layer for common queries
3. Implement skill composition patterns
4. Scale to 100K+ knowledge base chunks

---

## Appendix A: File Structure

```
~/.claude/
├── agents/
│   └── odoobo-expert.agent.yaml
├── skills/
│   └── odoobo-expert/
│       ├── REGISTRY.md
│       ├── pr-review/
│       │   ├── SKILL.md
│       │   ├── review.py
│       │   ├── requirements.txt
│       │   ├── tests/
│       │   └── resources/
│       ├── odoo-rpc/
│       ├── nl-sql/
│       ├── visual-diff/
│       └── design-tokens/
├── knowledge-bases/
│   └── odoobo/
│       ├── embeddings/
│       ├── docs/
│       ├── index.json
│       └── config.yaml
└── commands/
    └── review.md

~/Documents/TBWA/
├── odoboo-workspace/                    # main branch
├── odoboo-workspace-pr-review/          # feature/pr-review
├── odoboo-workspace-odoo-rpc/           # feature/odoo-rpc
├── odoboo-workspace-nl-sql/             # feature/nl-sql
├── odoboo-workspace-visual-diff/        # feature/visual-diff
└── odoboo-workspace-design-tokens/      # feature/design-tokens
```

---

## Appendix B: References

- **Anthropic Skills Framework**: https://docs.anthropic.com/en/docs/build-with-claude/skills
- **Code Execution Tool Beta**: https://docs.anthropic.com/en/docs/build-with-claude/tool-use/code-execution
- **Git Worktrees**: https://git-scm.com/docs/git-worktree
- **DigitalOcean Gradient AI**: https://docs.digitalocean.com/products/gradient-ai/
- **ChromaDB**: https://docs.trychroma.com/
- **Odoo Developer Guide**: https://www.odoo.com/documentation/18.0/developer/
- **OCA Guidelines**: https://github.com/OCA/maintainer-tools

---

**Architecture Status**: ✅ Ready for Implementation
**Estimated Development Time**: 10 weeks
**Total Cost**: <$10/month production, $0 development
**Risk Level**: Low (proven technologies, incremental deployment)
