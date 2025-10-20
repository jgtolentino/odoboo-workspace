# Development Guide - Anthropic Skills

Local development, testing, and deployment guide for odoobo-expert Anthropic Skills.

## Quick Start

### 1. Environment Setup

```bash
# Clone repository (if not already)
cd /path/to/odoboo-workspace

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r .claude/skills/requirements.txt

# Install Playwright browsers (for Visual Diff and Design Tokens)
playwright install --with-deps chromium
```

### 2. Configure Environment Variables

Create `.env` file in project root:

```bash
# .env file
# GitHub Integration
GITHUB_TOKEN=github_pat_your_token_here

# Anthropic API
ANTHROPIC_API_KEY=sk-ant-your_key_here

# Odoo Connection (optional - for Odoo RPC skill)
ODOO_URL=https://demo.odoo.com
ODOO_DATABASE=demo
ODOO_USERNAME=admin
ODOO_PASSWORD=admin

# WrenAI (optional - for NL-SQL skill)
WRENAI_URL=https://api.wrenai.dev
```

Load environment:

```bash
export $(cat .env | xargs)
```

### 3. Run Individual Skills

```bash
# PR Review
python3 .claude/skills/pr-review/analyze_pr.py \
  --pr-number 123 \
  --repository owner/repo \
  --severity high

# Odoo RPC
python3 .claude/skills/odoo-rpc/odoo_client.py \
  --model res.partner \
  --operation search_read \
  --limit 10

# NL-to-SQL
python3 .claude/skills/nl-sql/wrenai_client.py

# Visual Diff
python3 .claude/skills/visual-diff/percy_client.py

# Design Tokens
python3 .claude/skills/design-tokens/extract_tokens.py
```

### 4. Run Tests

```bash
# Run all skills tests
python3 .claude/skills/test_all_skills.py -v

# Run specific skill tests
pytest .claude/skills/pr-review/tests/ -v
pytest .claude/skills/odoo-rpc/tests/ -v

# Run with coverage
pytest .claude/skills/ --cov=.claude/skills --cov-report=html
open htmlcov/index.html
```

## Development Workflow

### Adding New Features

1. **Create feature branch**:

```bash
git checkout -b feature/skill-enhancement
```

2. **Make changes** to skill implementation

3. **Add tests**:

```python
# In tests/test_new_feature.py
@pytest.mark.asyncio
async def test_new_feature():
    # Test implementation
    pass
```

4. **Run tests**:

```bash
pytest .claude/skills/your-skill/tests/ -v
```

5. **Update documentation** in `SKILL.md`

6. **Commit and push**:

```bash
git add .claude/skills/your-skill/
git commit -m "feat: add new feature to skill"
git push origin feature/skill-enhancement
```

### Debugging

#### Enable Debug Logging

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

Or via environment:

```bash
export LOG_LEVEL=DEBUG
python3 .claude/skills/pr-review/analyze_pr.py ...
```

#### Interactive Debugging

```python
# Add breakpoint in code
import pdb; pdb.set_trace()

# Run with debugger
python3 -m pdb .claude/skills/pr-review/analyze_pr.py
```

#### Common Issues

**Issue: Import errors**

```bash
# Ensure skill directory is in Python path
export PYTHONPATH=$PYTHONPATH:$(pwd)/.claude/skills/pr-review
```

**Issue: GitHub API rate limiting**

```bash
# Check remaining quota
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/rate_limit | jq .rate.remaining
```

**Issue: Playwright browser not found**

```bash
# Reinstall browsers
playwright install --force chromium
```

**Issue: Odoo authentication fails**

```bash
# Test connection
python3 -c "import xmlrpc.client; \
  proxy = xmlrpc.client.ServerProxy('$ODOO_URL/xmlrpc/2/common'); \
  print(proxy.version())"
```

## Testing Strategy

### Unit Tests

Test individual functions in isolation:

```python
# tests/test_unit.py
import pytest
from analyze_pr import calculate_complexity_score

def test_complexity_low():
    score = calculate_complexity_score(50, 2)
    assert score < 0.3

def test_complexity_high():
    score = calculate_complexity_score(600, 25)
    assert score > 0.8
```

### Integration Tests

Test interactions with external services (skipped in CI):

```python
# tests/test_integration.py
import pytest

@pytest.mark.integration
@pytest.mark.asyncio
async def test_github_api():
    from analyze_pr import analyze_pull_request

    result = await analyze_pull_request(
        pr_number=1,
        repository="owner/repo"
    )
    assert result.pr_number == 1
```

Run integration tests:

```bash
pytest -m integration
```

Skip integration tests:

```bash
pytest -m "not integration"
```

### Mock Data

Use fixtures for consistent testing:

```python
# tests/conftest.py
import pytest

@pytest.fixture
def mock_pr_files():
    return [
        {"filename": "src/auth.ts", "additions": 10, "deletions": 5}
    ]

@pytest.fixture
def mock_github_client(mocker):
    client = mocker.Mock()
    client.get_pr_files.return_value = []
    return client
```

## Code Quality

### Linting

```bash
# Install linters
pip install black flake8 mypy

# Format code
black .claude/skills/

# Check style
flake8 .claude/skills/ --max-line-length=100

# Type checking
mypy .claude/skills/pr-review/analyze_pr.py
```

### Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Setup hooks
cat > .pre-commit-config.yaml << EOF
repos:
  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
        files: ^\.claude/skills/

  - repo: https://github.com/PyCQA/flake8
    rev: 7.1.0
    hooks:
      - id: flake8
        args: [--max-line-length=100]
        files: ^\.claude/skills/

  - repo: local
    hooks:
      - id: pytest
        name: pytest
        entry: pytest
        language: system
        args: [".claude/skills/", "-v"]
        pass_filenames: false
EOF

pre-commit install
```

## Performance Optimization

### Profiling

```python
import cProfile
import pstats

# Profile function
cProfile.run('asyncio.run(analyze_pull_request(...))', 'profile_stats')

# Analyze results
p = pstats.Stats('profile_stats')
p.sort_stats('cumulative')
p.print_stats(20)
```

### Async Optimization

```python
# Bad: Sequential operations
result1 = await operation1()
result2 = await operation2()

# Good: Parallel operations
results = await asyncio.gather(
    operation1(),
    operation2()
)
```

### Caching

```python
from functools import lru_cache

@lru_cache(maxsize=128)
def expensive_operation(param):
    # Cached result
    return result
```

## Docker Development

### Build Docker Image

```dockerfile
# Dockerfile.skills
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY .claude/skills/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    playwright install --with-deps chromium

# Copy skills
COPY .claude/skills/ /app/.claude/skills/

# Run tests by default
CMD ["pytest", "/app/.claude/skills/", "-v"]
```

### Build and Run

```bash
# Build image
docker build -f Dockerfile.skills -t odoobo-skills:latest .

# Run tests
docker run --rm \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  odoobo-skills:latest

# Run specific skill
docker run --rm \
  -e GITHUB_TOKEN=$GITHUB_TOKEN \
  odoobo-skills:latest \
  python /app/.claude/skills/pr-review/analyze_pr.py --help
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/skills-test.yml
name: Test Anthropic Skills

on:
  push:
    paths:
      - '.claude/skills/**'
  pull_request:
    paths:
      - '.claude/skills/**'

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('.claude/skills/requirements.txt') }}

      - name: Install dependencies
        run: |
          pip install -r .claude/skills/requirements.txt
          playwright install --with-deps chromium

      - name: Run tests
        run: pytest .claude/skills/ -v --cov=.claude/skills --cov-report=xml
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
```

### Pre-deployment Checks

```bash
# Run before deploying
./scripts/pre-deploy-check.sh

# Contents of pre-deploy-check.sh:
#!/bin/bash
set -e

echo "Running pre-deployment checks..."

# 1. Run tests
pytest .claude/skills/ -v

# 2. Check code quality
black --check .claude/skills/
flake8 .claude/skills/

# 3. Security scan
bandit -r .claude/skills/

# 4. Dependency audit
pip-audit

echo "All checks passed!"
```

## Monitoring and Observability

### Logging

```python
import logging
import sys

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('skills.log')
    ]
)

logger = logging.getLogger(__name__)

# Use in code
logger.info("Processing PR", extra={"pr_number": 123})
logger.error("API error", exc_info=True)
```

### Metrics

```python
import time
from functools import wraps

def measure_time(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start = time.time()
        result = await func(*args, **kwargs)
        duration = time.time() - start

        logger.info(f"{func.__name__} took {duration:.2f}s")
        return result
    return wrapper

@measure_time
async def analyze_pull_request(...):
    # Implementation
    pass
```

## Security Best Practices

1. **Never commit secrets**:

```bash
# Add to .gitignore
echo ".env" >> .gitignore
echo "**/*.key" >> .gitignore
echo "**/*.pem" >> .gitignore
```

2. **Use secret scanning**:

```bash
# Install git-secrets
brew install git-secrets

# Setup for repository
git secrets --install
git secrets --register-aws
```

3. **Validate inputs**:

```python
import re

def validate_repository(repo: str) -> bool:
    pattern = r'^[\w\-]+/[\w\-]+$'
    return bool(re.match(pattern, repo))
```

4. **Sanitize logs**:

```python
def sanitize_token(token: str) -> str:
    """Show only first 10 characters"""
    return token[:10] + "..." if len(token) > 10 else "***"

logger.info(f"Using token: {sanitize_token(token)}")
```

## Troubleshooting

### Skill-Specific Issues

**PR Review**:

- Issue: GitHub API 403 Forbidden
- Solution: Check token permissions (repo, read:org required)

**Odoo RPC**:

- Issue: XML-RPC Fault
- Solution: Verify Odoo version compatibility (tested on 19.0)

**Visual Diff**:

- Issue: Playwright timeout
- Solution: Increase timeout or check network connectivity

**Design Tokens**:

- Issue: CSS variables not found
- Solution: Ensure target site uses CSS variables (--\*)

## Contributing

See main [README.md](README.md) for contribution guidelines.

## Support

- GitHub Issues: https://github.com/jgtolentino/odoboo-workspace/issues
- Documentation: Each skill's SKILL.md
- Email: support@example.com
