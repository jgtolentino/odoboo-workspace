# PR Review Skill

Automated pull request code review with security scanning, breaking change detection, and quality analysis.

## Capability

Analyzes GitHub pull requests for:

- Security vulnerabilities (hardcoded secrets, SQL injection, XSS)
- Breaking changes in APIs and dependencies
- Code quality issues (complexity, duplication, code smells)
- Lockfile sync validation
- Performance concerns

## Parameters

### Required

- `pr_number` (int): Pull request number
- `repository` (string): Repository in format "owner/repo"

### Optional

- `github_token` (string): GitHub access token (defaults to GITHUB_TOKEN env var)
- `severity_threshold` (string): Minimum severity to report (low|medium|high|critical)
- `check_lockfile` (boolean): Enable lockfile sync validation (default: true)
- `auto_comment` (boolean): Post review comments on PR (default: false)

## Usage Examples

### Basic PR Review

```python
from analyze_pr import analyze_pull_request

result = await analyze_pull_request(
    pr_number=123,
    repository="owner/repo"
)

print(f"Found {len(result['issues'])} issues")
print(f"Complexity: {result['complexity_score']}")
```

### Review with Auto-Comments

```python
result = await analyze_pull_request(
    pr_number=123,
    repository="owner/repo",
    auto_comment=True,
    severity_threshold="high"
)
```

### Lockfile Validation Only

```python
from analyze_pr import detect_lockfile_sync

lockfile_status = await detect_lockfile_sync(
    pr_number=123,
    repository="owner/repo"
)

if not lockfile_status['synced']:
    print(f"Run: {lockfile_status['fix_command']}")
```

## Output Format

```json
{
  "pr_number": 123,
  "repository": "owner/repo",
  "files_changed": [
    {
      "filename": "src/auth.ts",
      "status": "modified",
      "additions": 42,
      "deletions": 15,
      "changes": 57
    }
  ],
  "issues": [
    {
      "type": "security",
      "severity": "high",
      "file": "src/auth.ts",
      "line": 45,
      "message": "Hardcoded credential detected",
      "suggestion": "Use environment variables for secrets"
    }
  ],
  "lockfile_sync": {
    "synced": false,
    "package_managers": ["npm"],
    "fix_command": "npm install"
  },
  "complexity_score": 0.75,
  "total_changes": 57,
  "approval_recommendation": "request_changes"
}
```

## Issue Severity Levels

- **critical**: Security vulnerabilities, data loss risks
- **high**: Breaking changes, major bugs, security concerns
- **medium**: Performance issues, code quality problems
- **low**: Style suggestions, minor improvements

## Integration

### Claude Code Tool

```python
# In Claude Code tool manifest
{
  "name": "pr_review",
  "description": "Analyze GitHub pull request for issues",
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

### GitHub Actions

```yaml
name: PR Review
on: pull_request

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run PR Review
        run: |
          python .claude/skills/pr-review/analyze_pr.py \
            --pr-number ${{ github.event.pull_request.number }} \
            --repository ${{ github.repository }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Resource Files

- `resources/review_checklist.json`: Review criteria and patterns
- `resources/severity_matrix.json`: Severity classification rules
- `resources/security_patterns.json`: Security vulnerability patterns

## Dependencies

- `httpx`: Async HTTP client
- `anthropic`: Claude API client
- `PyGithub`: GitHub API wrapper (optional)
- `pydantic`: Data validation

## Error Handling

- **GitHub API errors**: Returns partial results with error details
- **Anthropic API errors**: Falls back to pattern-based detection
- **Rate limiting**: Implements exponential backoff
- **Timeout**: 180s default timeout with configurable override

## Security Considerations

- Never logs full GitHub tokens (only prefixes)
- Sanitizes output to prevent secret leakage
- Validates input repository format
- Rate limits to prevent abuse
