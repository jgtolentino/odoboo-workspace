# Odoobo-Expert Anthropic Skills

Production-ready implementation of 5 specialized skills for Claude Code using Anthropic Skills architecture.

## Skills Overview

### 1. PR Review (`pr-review/`)

**Purpose**: Automated pull request code review with security scanning and quality analysis

**Capabilities**:

- Security vulnerability detection (hardcoded secrets, SQL injection, XSS)
- Breaking change identification
- Code quality analysis
- Lockfile sync validation
- Auto-approval recommendations

**Usage**:

```bash
python .claude/skills/pr-review/analyze_pr.py \
  --pr-number 123 \
  --repository owner/repo \
  --severity high
```

**Key Files**:

- `SKILL.md`: Complete documentation
- `analyze_pr.py`: Main implementation
- `resources/security_patterns.json`: Vulnerability patterns
- `resources/severity_matrix.json`: Risk classification
- `resources/review_checklist.json`: Review criteria

### 2. Odoo RPC (`odoo-rpc/`)

**Purpose**: Interact with Odoo ERP system via XML-RPC and JSON-RPC

**Capabilities**:

- Authentication and session management
- Search and read operations with domain filters
- CRUD operations (create, update, delete)
- Execute server methods and workflows
- Metadata inspection

**Usage**:

```bash
python .claude/skills/odoo-rpc/odoo_client.py \
  --url https://demo.odoo.com \
  --database demo \
  --username admin \
  --password admin \
  --model res.partner \
  --operation search_read
```

**Key Files**:

- `SKILL.md`: API documentation
- `odoo_client.py`: RPC client implementation
- `resources/odoo_models.json`: Common Odoo models
- `resources/rpc_methods.json`: Available RPC methods
- `resources/domain_examples.json`: Query patterns

### 3. NL-to-SQL (`nl-sql/`)

**Purpose**: Convert natural language to SQL queries for Odoo database analysis

**Capabilities**:

- Natural language understanding
- Odoo schema awareness
- SQL query generation
- Query optimization

**Usage**:

```python
from wrenai_client import WrenAIClient

async with WrenAIClient() as client:
    result = await client.nl_to_sql("Show top 10 customers by revenue")
    print(result['sql'])
```

**Key Files**:

- `SKILL.md`: Query conversion guide
- `wrenai_client.py`: NL-to-SQL implementation
- `resources/wrenai-odoo-schema.json`: Schema definitions
- `resources/query_templates.json`: Query patterns

### 4. Visual Diff (`visual-diff/`)

**Purpose**: Visual regression testing with SSIM-based screenshot comparison

**Capabilities**:

- Automated screenshot capture
- SSIM algorithm comparison
- Baseline management
- Multi-resolution testing

**Usage**:

```python
from percy_client import VisualDiffClient

async with VisualDiffClient() as client:
    result = await client.compare_screenshots(
        base_url="http://localhost:4173",
        routes=["/expenses", "/tasks"],
        threshold=0.98
    )
```

**Key Files**:

- `SKILL.md`: Visual testing guide
- `percy_client.py`: Screenshot and comparison
- `resources/baseline_routes.json`: Test routes
- `resources/ssim_thresholds.json`: Acceptance criteria

### 5. Design Tokens (`design-tokens/`)

**Purpose**: Extract and analyze design tokens from websites

**Capabilities**:

- CSS variable extraction
- Tailwind config parsing
- Token categorization
- Design system comparison

**Usage**:

```python
from extract_tokens import DesignTokenExtractor

async with DesignTokenExtractor() as extractor:
    tokens = await extractor.extract(
        url="https://example.com",
        categories=["colors", "spacing", "typography"]
    )
```

**Key Files**:

- `SKILL.md`: Extraction guide
- `extract_tokens.py`: Token extraction
- `resources/token_categories.json`: Token types
- `resources/design_systems.json`: Known design systems

## Installation

### 1. Install Dependencies

```bash
# From skills directory
pip install -r requirements.txt

# Install Playwright browsers
playwright install --with-deps chromium
```

### 2. Set Environment Variables

```bash
# GitHub integration
export GITHUB_TOKEN="github_pat_..."

# Anthropic API
export ANTHROPIC_API_KEY="sk-ant-..."

# Odoo connection (optional)
export ODOO_URL="https://demo.odoo.com"
export ODOO_DATABASE="demo"
export ODOO_USERNAME="admin"
export ODOO_PASSWORD="admin"

# WrenAI (optional)
export WRENAI_URL="https://api.wrenai.dev"
```

### 3. Run Tests

```bash
# Test individual skills
pytest .claude/skills/pr-review/tests/ -v
pytest .claude/skills/odoo-rpc/tests/ -v

# Test all skills
pytest .claude/skills/ -v

# With coverage
pytest .claude/skills/ --cov=.claude/skills --cov-report=html
```

## Integration with Claude Code

### Tool Manifest

Each skill can be integrated as a Claude Code tool:

```python
# Example: PR Review tool
{
  "name": "pr_review",
  "description": "Analyze GitHub pull request for security and quality issues",
  "input_schema": {
    "type": "object",
    "properties": {
      "pr_number": {"type": "integer"},
      "repository": {"type": "string"},
      "severity_threshold": {"type": "string", "enum": ["low", "medium", "high", "critical"]}
    },
    "required": ["pr_number", "repository"]
  }
}
```

### GitHub Actions Integration

```yaml
name: Odoobo-Expert Skills
on: pull_request

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r .claude/skills/requirements.txt

      - name: Run PR Review
        run: |
          python .claude/skills/pr-review/analyze_pr.py \
            --pr-number ${{ github.event.pull_request.number }} \
            --repository ${{ github.repository }} \
            --auto-comment
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Local Development

### Running Individual Skills

```bash
# PR Review
python .claude/skills/pr-review/analyze_pr.py --help

# Odoo RPC
python .claude/skills/odoo-rpc/odoo_client.py --help

# NL-to-SQL
python .claude/skills/nl-sql/wrenai_client.py

# Visual Diff
python .claude/skills/visual-diff/percy_client.py

# Design Tokens
python .claude/skills/design-tokens/extract_tokens.py
```

### Mock Data for Offline Development

Each skill includes test fixtures:

- `tests/fixtures/`: Mock API responses
- `resources/`: Configuration and examples

### Debugging

Enable debug logging:

```bash
export LOG_LEVEL=DEBUG
python .claude/skills/pr-review/analyze_pr.py ...
```

## CI/CD Integration

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: skill-tests
        name: Run Anthropic Skills Tests
        entry: pytest .claude/skills/ -v
        language: system
        pass_filenames: false
```

### Docker Support

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY .claude/skills/requirements.txt .
RUN pip install -r requirements.txt && \
    playwright install --with-deps chromium

# Copy skills
COPY .claude/skills/ /app/.claude/skills/

# Run tests
CMD ["pytest", "/app/.claude/skills/", "-v"]
```

## Security Considerations

1. **Secret Management**:
   - Never commit API keys or tokens
   - Use environment variables or secret managers
   - Sanitize logs to prevent secret leakage

2. **Input Validation**:
   - All user inputs are validated
   - Repository names match pattern `owner/repo`
   - URLs are validated before browser navigation

3. **Rate Limiting**:
   - Built-in retry logic with exponential backoff
   - Configurable timeouts
   - Request throttling for bulk operations

4. **Error Handling**:
   - Graceful degradation on API failures
   - Detailed error messages in logs
   - Sanitized error responses to users

## Performance

| Skill         | Avg Time | Token Usage | Rate Limit  |
| ------------- | -------- | ----------- | ----------- |
| PR Review     | 5-15s    | 2-5K tokens | 50 req/min  |
| Odoo RPC      | <1s      | N/A         | 100 req/min |
| NL-to-SQL     | 2-5s     | 1-2K tokens | 50 req/min  |
| Visual Diff   | 3-10s    | N/A         | 20 req/min  |
| Design Tokens | 2-5s     | N/A         | 30 req/min  |

## Troubleshooting

### Common Issues

**1. GitHub API Rate Limiting**

```bash
# Check rate limit
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/rate_limit
```

**2. Playwright Browser Issues**

```bash
# Reinstall browsers
playwright install --force chromium
```

**3. Odoo Connection Errors**

```bash
# Test connection
python -c "import xmlrpc.client; print(xmlrpc.client.ServerProxy('$ODOO_URL/xmlrpc/2/common').version())"
```

## Contributing

### Adding New Skills

1. Create skill directory: `.claude/skills/new-skill/`
2. Add required files:
   - `SKILL.md`: Documentation
   - `main_script.py`: Implementation
   - `resources/`: Config files
   - `tests/`: Unit tests
   - `requirements.txt`: Dependencies
3. Update unified `requirements.txt`
4. Add to this README

### Testing Guidelines

- Minimum 80% code coverage
- Include integration tests (can be skipped in CI)
- Mock external API calls
- Provide test fixtures

## License

MIT License - See LICENSE file

## Support

For issues or questions:

- GitHub Issues: https://github.com/jgtolentino/odoboo-workspace/issues
- Documentation: Each skill's SKILL.md file
