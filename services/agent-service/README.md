# Odoobo-Expert Agent Service

Multi-capability AI agent with 5 core feature categories and 13 tool functions.

## Features

### 1. Code Migration & Transformation

- **Full Stack Migration**: Odoo → NestJS API + Next.js UI
- **Visual Parity Validation**: SSIM ≥ 0.98, LPIPS ≤ 0.02
- **Design Token Extraction**: SCSS → Tailwind CSS
- **QWeb → React Conversion**: Template-to-component transformation
- **Database Migration**: Python models → Prisma schema
- **Asset Management**: Static file migration with path mapping

**Workflow**: repo_fetch → parallel(qweb_to_tsx, odoo_model_to_prisma, asset_migrator) → nest_scaffold → visual_diff → bundle_emit

### 2. PR Code Review

- **Automated Analysis**: Line-level issue detection
- **Multi-Framework Support**: Odoo, OCA, Supabase, Docker, GitHub Actions
- **Issue Categories**: Security, performance, quality, dependency
- **Lockfile Sync Detection**: Automatic package.json vs lockfile validation
- **Approval Recommendations**: changes_requested, approved, commented

**Workflow**: analyze_pr_diff → detect_lockfile_sync → generate_review_comments

### 3. Solutions Architecture

- **System Design Diagrams**: Mermaid, Draw.io, PlantUML
- **Technology Stack Recommendations**: Evidence-based technology selection
- **Architectural Patterns**: Microservices, monorepo, serverless
- **Scalability Analysis**: Performance and scalability assessment

### 4. AI-Powered Analytics

- **Natural Language → SQL**: Conversational query generation
- **Multi-Database Support**: PostgreSQL, MySQL, SQLite, MongoDB, BigQuery, Snowflake
- **Conversational Analytics**: Context-aware follow-up queries
- **Insight Generation**: Automatic data analysis and recommendations

**Workflow**: nl_to_sql → execute_query → generate_chart

### 5. Data Visualization & Export

- **Publication-Quality Charts**: Bar, line, pie, scatter, heatmap
- **Multi-Format Reports**: PDF, DOCX, PPTX, HTML
- **Interactive Dashboards**: Plotly-based interactive visualizations

## Tool Functions

### Migration Tools (7)

1. **repo_fetch** - Clone and extract Odoo module source code
2. **qweb_to_tsx** - Convert QWeb templates to React/TSX components
3. **odoo_model_to_prisma** - Convert Odoo Python models to Prisma schema
4. **nest_scaffold** - Generate NestJS controllers from Prisma schema
5. **asset_migrator** - Migrate static assets with path mapping
6. **visual_diff** - Compare screenshots for visual parity validation
7. **bundle_emit** - Package all generated code into deployable bundle

### Analytics Tools (3)

8. **nl_to_sql** - Convert natural language to SQL query
9. **execute_query** - Execute SQL query against database
10. **generate_chart** - Generate visualization from query results

### PR Review Tools (3)

11. **analyze_pr_diff** - Analyze PR diff for issues and improvements
12. **generate_review_comments** - Generate and post review comments on PR
13. **detect_lockfile_sync** - Detect lockfile sync issues

## API Endpoints

### Health Check

```bash
GET /health

Response:
{
  "status": "healthy",
  "service": "agent-service",
  "version": "2.0.0",
  "capabilities": ["migration", "review", "analytics", "architecture", "visualization"]
}
```

### Chat (OpenAI-Compatible)

```bash
POST /v1/chat/completions

Body:
{
  "model": "claude-3-5-sonnet-20241022",
  "messages": [
    {"role": "user", "content": "Migrate this Odoo module to Next.js"}
  ],
  "temperature": 1.0,
  "max_tokens": 4096
}

Response:
{
  "id": "chat-1234567890",
  "object": "chat.completion",
  "created": 1734567890,
  "model": "claude-3-5-sonnet-20241022",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I'll help you migrate..."
      },
      "finish_reason": "stop"
    }
  ]
}
```

### Migration Workflow

```bash
POST /v1/migrate

Body:
{
  "repo": "https://github.com/odoo/odoo",
  "ref": "18.0",
  "theme_hint": "default",
  "baseline_url": "https://example.com/baseline.png"
}

Response:
{
  "status": "success",
  "bundle_url": "https://storage.url/bundle.zip",
  "report": {
    "ssim": 0.985,
    "lpips": 0.015,
    "changed_assets": [...],
    "notes": [...]
  },
  "next_steps": [...]
}
```

### PR Review Workflow

```bash
POST /v1/review

Body:
{
  "pr_number": 123,
  "repository": "owner/repo",
  "github_token": "github_pat_..."
}

Response:
{
  "status": "success",
  "pr_number": 123,
  "repository": "owner/repo",
  "analysis": {
    "total_changes": 57,
    "complexity_score": 0.75,
    "files_changed": 3,
    "lockfile_synced": false
  },
  "issues": [...],
  "approval_status": "changes_requested",
  "summary": "Reviewed 57 lines (complexity: 0.75). 🚨 1 critical issue..."
}
```

### Analytics Workflow

```bash
POST /v1/analytics

Body:
{
  "question": "What are the top 10 products by revenue?",
  "database_url": "postgresql://...",
  "database_type": "postgres",
  "database_schema": {...}
}

Response:
{
  "status": "success",
  "question": "What are the top 10 products by revenue?",
  "sql": "SELECT product_name, SUM(revenue) as total_revenue...",
  "data": [...],
  "visualization": {
    "chart_type": "bar",
    "x_axis": "product_name",
    "y_axis": "total_revenue"
  },
  "chart_url": "https://storage.url/chart.png",
  "insights": [
    "Top product accounts for 30% of total revenue",
    "Revenue follows power law distribution"
  ],
  "rows": 10,
  "execution_time_ms": 123
}
```

### List Tools

```bash
GET /v1/tools

Response:
{
  "migration_tools": ["repo_fetch", "qweb_to_tsx", ...],
  "analytics_tools": ["nl_to_sql", "execute_query", ...],
  "review_tools": ["analyze_pr_diff", ...],
  "total": 13
}
```

## Environment Variables

```bash
# Required
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GITHUB_TOKEN=github_pat_...
SUPABASE_URL=https://...supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...

# Optional
DATABASE_URL=postgresql://...
LOG_LEVEL=INFO
WORKERS=4
```

## Development

### Local Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
cp .env.example .env
# Edit .env with your keys

# Run locally
uvicorn app.main:app --reload --port 8001
```

### Docker

```bash
# Build image
docker build -t agent-service .

# Run container
docker run -p 8001:8001 --env-file .env agent-service
```

### Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest

# Test specific workflow
pytest tests/test_migration.py
```

## Architecture

```
app/
├── main.py                 # FastAPI application
├── models/
│   ├── requests.py         # Request models
│   └── responses.py        # Response models
├── workflows/
│   ├── migration.py        # Migration workflow
│   ├── review.py           # PR review workflow
│   └── analytics.py        # Analytics workflow
└── tools/
    ├── migration_tools.py  # 7 migration functions
    ├── analytics_tools.py  # 3 analytics functions
    └── review_tools.py     # 3 review functions
```

## Performance

- **Latency**: P95 < 30s for migration, < 5s for review, < 10s for analytics
- **Throughput**: 10-30 requests/second
- **Token Usage**: Average 2K-10K tokens per request
- **Memory**: 500MB-2GB depending on workload

## Security

- **API Keys**: Store in environment variables, never in code
- **GitHub Token**: Use fine-grained personal access tokens with minimum scopes
- **Database Credentials**: Use read-only credentials for analytics
- **Rate Limiting**: 30 requests/second default (configurable in nginx)

## Limitations

- **Migration**: Requires manual verification of converted code
- **Visual Parity**: May require baseline screenshot tuning for complex UIs
- **Analytics**: Limited to 6 database types, MongoDB/BigQuery WIP
- **PR Review**: Best effort analysis, not replacement for human review

## Roadmap

- [ ] Add support for Vue.js and Angular migrations
- [ ] Implement visual diff with LPIPS (currently only SSIM)
- [ ] Add support for MongoDB aggregation pipeline generation
- [ ] Add support for BigQuery and Snowflake analytics
- [ ] Implement interactive dashboard generation
- [ ] Add CI/CD integration for automated PR reviews
- [ ] Add streaming responses for long-running operations

## Support

**Issues**: https://github.com/jgtolentino/odoboo-workspace/issues
**Docs**: https://github.com/jgtolentino/odoboo-workspace/tree/main/docs
**Agent Endpoint**: https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run (deprecated, use self-hosted)
