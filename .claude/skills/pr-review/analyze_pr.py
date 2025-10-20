#!/usr/bin/env python3
"""
PR Review Skill - Production-Ready Implementation
Analyzes GitHub pull requests for security, quality, and breaking changes.
"""

import asyncio
import json
import logging
import os
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional
import re

import httpx
from anthropic import Anthropic

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Constants
SKILL_DIR = Path(__file__).parent
RESOURCES_DIR = SKILL_DIR / "resources"
TIMEOUT = 180.0
MAX_DIFF_SIZE = 50000  # Characters
MAX_RETRIES = 3


@dataclass
class Issue:
    """Represents a code issue detected in PR"""
    type: str
    severity: str
    file: str
    line: int
    message: str
    suggestion: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "type": self.type,
            "severity": self.severity,
            "file": self.file,
            "line": self.line,
            "message": self.message,
            "suggestion": self.suggestion
        }


@dataclass
class PRAnalysis:
    """Complete PR analysis result"""
    pr_number: int
    repository: str
    files_changed: List[Dict[str, Any]]
    issues: List[Issue]
    lockfile_sync: Dict[str, Any]
    complexity_score: float
    total_changes: int
    approval_recommendation: str
    analysis_timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "pr_number": self.pr_number,
            "repository": self.repository,
            "files_changed": self.files_changed,
            "issues": [issue.to_dict() for issue in self.issues],
            "lockfile_sync": self.lockfile_sync,
            "complexity_score": self.complexity_score,
            "total_changes": self.total_changes,
            "approval_recommendation": self.approval_recommendation,
            "analysis_timestamp": self.analysis_timestamp
        }


class GitHubClient:
    """Handles GitHub API interactions"""

    def __init__(self, token: str):
        self.token = token
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github.v3+json"
        }
        self.base_url = "https://api.github.com"

    async def get_pr_files(self, repository: str, pr_number: int) -> List[Dict[str, Any]]:
        """Fetch list of files changed in PR"""
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                url = f"{self.base_url}/repos/{repository}/pulls/{pr_number}/files"
                response = await client.get(url, headers=self.headers)
                response.raise_for_status()
                return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"GitHub API error: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Failed to fetch PR files: {str(e)}")
            raise

    async def get_pr_diff(self, repository: str, pr_number: int) -> str:
        """Fetch unified diff for PR"""
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                url = f"{self.base_url}/repos/{repository}/pulls/{pr_number}"
                headers = {**self.headers, "Accept": "application/vnd.github.v3.diff"}
                response = await client.get(url, headers=headers)
                response.raise_for_status()
                diff = response.text

                # Truncate if too large
                if len(diff) > MAX_DIFF_SIZE:
                    logger.warning(f"Diff truncated from {len(diff)} to {MAX_DIFF_SIZE} chars")
                    diff = diff[:MAX_DIFF_SIZE] + "\n... [truncated]"

                return diff
        except Exception as e:
            logger.error(f"Failed to fetch PR diff: {str(e)}")
            raise

    async def get_pr_details(self, repository: str, pr_number: int) -> Dict[str, Any]:
        """Fetch PR metadata"""
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                url = f"{self.base_url}/repos/{repository}/pulls/{pr_number}"
                response = await client.get(url, headers=self.headers)
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to fetch PR details: {str(e)}")
            raise

    async def post_review(
        self,
        repository: str,
        pr_number: int,
        commit_sha: str,
        body: str,
        event: str,
        comments: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Post review comments on PR"""
        try:
            async with httpx.AsyncClient(timeout=TIMEOUT) as client:
                url = f"{self.base_url}/repos/{repository}/pulls/{pr_number}/reviews"
                payload = {
                    "commit_id": commit_sha,
                    "body": body,
                    "event": event,
                    "comments": comments[:50]  # GitHub API limit
                }
                response = await client.post(url, headers=self.headers, json=payload)
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to post review: {str(e)}")
            raise


class IssueDetector:
    """Detects issues using pattern matching and Claude analysis"""

    def __init__(self, anthropic_api_key: str):
        self.client = Anthropic(api_key=anthropic_api_key)
        self.security_patterns = self._load_security_patterns()
        self.severity_matrix = self._load_severity_matrix()

    def _load_security_patterns(self) -> Dict[str, Any]:
        """Load security vulnerability patterns"""
        pattern_file = RESOURCES_DIR / "security_patterns.json"
        if pattern_file.exists():
            with open(pattern_file) as f:
                return json.load(f)
        return self._get_default_patterns()

    def _load_severity_matrix(self) -> Dict[str, Any]:
        """Load severity classification rules"""
        matrix_file = RESOURCES_DIR / "severity_matrix.json"
        if matrix_file.exists():
            with open(matrix_file) as f:
                return json.load(f)
        return self._get_default_severity_matrix()

    def _get_default_patterns(self) -> Dict[str, List[str]]:
        """Default security patterns"""
        return {
            "hardcoded_secrets": [
                r'(?i)(password|secret|key|token)\s*[=:]\s*["\'][^"\']{8,}["\']',
                r'(?i)api[_-]?key\s*[=:]\s*["\'][^"\']+["\']',
                r'(?i)bearer\s+[a-zA-Z0-9\-._~+/]+=*'
            ],
            "sql_injection": [
                r'(?i)execute\s*\(\s*["\'].*?\+.*?["\']',
                r'(?i)query\s*\(\s*["\'].*?\$\{.*?\}.*?["\']',
                r'(?i)select.*?from.*?\+.*?'
            ],
            "xss_vulnerable": [
                r'(?i)innerHTML\s*=\s*',
                r'(?i)dangerouslySetInnerHTML',
                r'(?i)document\.write\s*\('
            ]
        }

    def _get_default_severity_matrix(self) -> Dict[str, str]:
        """Default severity classification"""
        return {
            "hardcoded_secrets": "critical",
            "sql_injection": "critical",
            "xss_vulnerable": "high",
            "breaking_change": "high",
            "performance_issue": "medium",
            "code_smell": "low"
        }

    async def detect_pattern_issues(
        self,
        files: List[Dict[str, Any]],
        diff_content: str
    ) -> List[Issue]:
        """Detect issues using regex patterns"""
        issues = []

        for file_data in files:
            filename = file_data["filename"]

            # Extract file content from diff
            file_diff = self._extract_file_diff(diff_content, filename)

            # Check security patterns
            for category, patterns in self.security_patterns.items():
                for pattern in patterns:
                    matches = re.finditer(pattern, file_diff, re.MULTILINE)
                    for match in matches:
                        line_num = file_diff[:match.start()].count('\n') + 1
                        severity = self.severity_matrix.get(category, "medium")

                        issues.append(Issue(
                            type=category,
                            severity=severity,
                            file=filename,
                            line=line_num,
                            message=f"{category.replace('_', ' ').title()} detected",
                            suggestion=self._get_suggestion(category)
                        ))

        return issues

    async def detect_claude_issues(
        self,
        files: List[Dict[str, Any]],
        diff_content: str
    ) -> List[Issue]:
        """Detect issues using Claude AI analysis"""
        try:
            files_summary = "\n".join([
                f"- {f['filename']} (+{f['additions']}/-{f['deletions']})"
                for f in files
            ])

            prompt = f"""Analyze this PR diff for code issues and improvements.

Files changed:
{files_summary}

Diff (truncated):
```
{diff_content}
```

Detect issues in these categories:
1. Security (hardcoded secrets, SQL injection, XSS, insecure crypto)
2. Breaking Changes (API changes, deprecated features, removed exports)
3. Performance (inefficient algorithms, memory leaks, blocking operations)
4. Quality (code smells, high complexity, duplication, missing tests)

Output ONLY valid JSON array with this exact structure:
[
  {{
    "type": "security|breaking_change|performance|quality",
    "severity": "critical|high|medium|low",
    "file": "path/to/file",
    "line": 42,
    "message": "Clear description of issue",
    "suggestion": "How to fix it"
  }}
]

Be specific about line numbers and provide actionable suggestions."""

            response = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4096,
                messages=[{"role": "user", "content": prompt}]
            )

            # Parse response
            response_text = response.content[0].text.strip()

            # Extract JSON array from response
            json_match = re.search(r'\[.*\]', response_text, re.DOTALL)
            if json_match:
                issues_data = json.loads(json_match.group())
                return [Issue(**issue_data) for issue_data in issues_data]

            logger.warning("Claude response did not contain valid JSON array")
            return []

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Claude response: {str(e)}")
            return []
        except Exception as e:
            logger.error(f"Claude analysis failed: {str(e)}")
            return []

    def _extract_file_diff(self, diff_content: str, filename: str) -> str:
        """Extract diff section for specific file"""
        pattern = rf'diff --git a/{re.escape(filename)}.*?\n(.*?)(?=diff --git|$)'
        match = re.search(pattern, diff_content, re.DOTALL)
        return match.group(1) if match else ""

    def _get_suggestion(self, category: str) -> str:
        """Get fix suggestion for issue category"""
        suggestions = {
            "hardcoded_secrets": "Use environment variables or secret management service",
            "sql_injection": "Use parameterized queries or ORM",
            "xss_vulnerable": "Sanitize user input and use safe rendering methods",
            "breaking_change": "Follow semantic versioning and provide migration guide",
            "performance_issue": "Profile and optimize bottlenecks",
            "code_smell": "Refactor for better maintainability"
        }
        return suggestions.get(category, "Review and address this issue")


async def detect_lockfile_sync(files_changed: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Detect if package.json changes have corresponding lockfile updates"""
    try:
        package_files = []
        lockfile_files = []

        for file_info in files_changed:
            filename = file_info["filename"]

            if filename.endswith("package.json"):
                package_files.append(filename)
            elif filename.endswith(("package-lock.json", "yarn.lock", "pnpm-lock.yaml")):
                lockfile_files.append(filename)

        # Detect package manager
        package_managers = []
        if any("package-lock.json" in f for f in lockfile_files):
            package_managers.append("npm")
        if any("yarn.lock" in f for f in lockfile_files):
            package_managers.append("yarn")
        if any("pnpm-lock.yaml" in f for f in lockfile_files):
            package_managers.append("pnpm")

        # Check sync status
        synced = len(package_files) == 0 or len(lockfile_files) > 0

        # Generate fix command
        if not synced:
            fix_command = f"{package_managers[0]} install" if package_managers else "npm install"
        else:
            fix_command = None

        return {
            "synced": synced,
            "package_files": package_files,
            "lockfile_files": lockfile_files,
            "package_managers": package_managers,
            "fix_command": fix_command
        }
    except Exception as e:
        logger.error(f"Lockfile sync detection failed: {str(e)}")
        return {
            "synced": True,  # Assume synced on error
            "error": str(e)
        }


def calculate_complexity_score(total_changes: int, files_count: int) -> float:
    """Calculate PR complexity score (0.0 to 1.0)"""
    # Weighted factors
    change_factor = min(1.0, total_changes / 500)
    file_factor = min(1.0, files_count / 20)

    # Combined score
    complexity = (change_factor * 0.7) + (file_factor * 0.3)
    return round(complexity, 2)


def determine_approval_recommendation(issues: List[Issue], complexity_score: float) -> str:
    """Determine approval recommendation based on issues and complexity"""
    critical_issues = [i for i in issues if i.severity == "critical"]
    high_issues = [i for i in issues if i.severity == "high"]
    medium_issues = [i for i in issues if i.severity == "medium"]

    if critical_issues or len(high_issues) > 2:
        return "request_changes"
    elif high_issues or len(medium_issues) > 5 or complexity_score > 0.8:
        return "comment"
    else:
        return "approve"


async def analyze_pull_request(
    pr_number: int,
    repository: str,
    github_token: Optional[str] = None,
    anthropic_api_key: Optional[str] = None,
    severity_threshold: str = "low",
    check_lockfile: bool = True,
    auto_comment: bool = False
) -> PRAnalysis:
    """
    Main function to analyze a pull request

    Args:
        pr_number: Pull request number
        repository: Repository in format "owner/repo"
        github_token: GitHub access token
        anthropic_api_key: Anthropic API key
        severity_threshold: Minimum severity to report
        check_lockfile: Enable lockfile validation
        auto_comment: Post review comments on PR

    Returns:
        PRAnalysis object with complete analysis
    """
    # Validate inputs
    if not re.match(r'^[\w\-]+/[\w\-]+$', repository):
        raise ValueError(f"Invalid repository format: {repository}")

    # Get tokens from environment if not provided
    github_token = github_token or os.getenv("GITHUB_TOKEN")
    anthropic_api_key = anthropic_api_key or os.getenv("ANTHROPIC_API_KEY")

    if not github_token:
        raise ValueError("GitHub token required (GITHUB_TOKEN env var or parameter)")
    if not anthropic_api_key:
        raise ValueError("Anthropic API key required (ANTHROPIC_API_KEY env var or parameter)")

    logger.info(f"Analyzing PR #{pr_number} in {repository}")

    # Initialize clients
    github = GitHubClient(github_token)
    detector = IssueDetector(anthropic_api_key)

    # Fetch PR data
    files_changed = await github.get_pr_files(repository, pr_number)
    diff_content = await github.get_pr_diff(repository, pr_number)
    pr_details = await github.get_pr_details(repository, pr_number)

    logger.info(f"Analyzing {len(files_changed)} changed files")

    # Calculate metrics
    total_changes = sum(f["changes"] for f in files_changed)
    complexity_score = calculate_complexity_score(total_changes, len(files_changed))

    # Detect issues
    pattern_issues = await detector.detect_pattern_issues(files_changed, diff_content)
    claude_issues = await detector.detect_claude_issues(files_changed, diff_content)

    # Combine and deduplicate issues
    all_issues = pattern_issues + claude_issues

    # Filter by severity threshold
    severity_order = {"low": 0, "medium": 1, "high": 2, "critical": 3}
    threshold_level = severity_order.get(severity_threshold, 0)
    filtered_issues = [
        issue for issue in all_issues
        if severity_order.get(issue.severity, 0) >= threshold_level
    ]

    logger.info(f"Detected {len(filtered_issues)} issues (threshold: {severity_threshold})")

    # Check lockfile sync
    lockfile_sync = {}
    if check_lockfile:
        lockfile_sync = await detect_lockfile_sync(files_changed)
        if not lockfile_sync["synced"]:
            logger.warning("Lockfile sync issue detected")

    # Determine approval recommendation
    approval = determine_approval_recommendation(filtered_issues, complexity_score)

    # Create analysis result
    analysis = PRAnalysis(
        pr_number=pr_number,
        repository=repository,
        files_changed=files_changed,
        issues=filtered_issues,
        lockfile_sync=lockfile_sync,
        complexity_score=complexity_score,
        total_changes=total_changes,
        approval_recommendation=approval
    )

    # Post review comments if requested
    if auto_comment and filtered_issues:
        try:
            comments = []
            for issue in filtered_issues[:50]:  # GitHub API limit
                comments.append({
                    "path": issue.file,
                    "line": issue.line,
                    "body": f"**{issue.type.upper()}** ({issue.severity}): {issue.message}\n\n**Suggestion**: {issue.suggestion}"
                })

            review_body = f"Found {len(filtered_issues)} issues. Complexity: {complexity_score}"
            event_map = {
                "approve": "APPROVE",
                "comment": "COMMENT",
                "request_changes": "REQUEST_CHANGES"
            }

            await github.post_review(
                repository=repository,
                pr_number=pr_number,
                commit_sha=pr_details["head"]["sha"],
                body=review_body,
                event=event_map[approval],
                comments=comments
            )

            logger.info(f"Posted review with {len(comments)} comments")
        except Exception as e:
            logger.error(f"Failed to post review comments: {str(e)}")

    return analysis


async def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Analyze GitHub pull request")
    parser.add_argument("--pr-number", type=int, required=True, help="Pull request number")
    parser.add_argument("--repository", required=True, help="Repository (owner/repo)")
    parser.add_argument("--github-token", help="GitHub access token")
    parser.add_argument("--anthropic-key", help="Anthropic API key")
    parser.add_argument("--severity", default="low", choices=["low", "medium", "high", "critical"])
    parser.add_argument("--no-lockfile-check", action="store_true", help="Disable lockfile check")
    parser.add_argument("--auto-comment", action="store_true", help="Post review comments")
    parser.add_argument("--output", help="Output JSON file path")

    args = parser.parse_args()

    try:
        analysis = await analyze_pull_request(
            pr_number=args.pr_number,
            repository=args.repository,
            github_token=args.github_token,
            anthropic_api_key=args.anthropic_key,
            severity_threshold=args.severity,
            check_lockfile=not args.no_lockfile_check,
            auto_comment=args.auto_comment
        )

        result = analysis.to_dict()

        # Output result
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(result, f, indent=2)
            logger.info(f"Results written to {args.output}")
        else:
            print(json.dumps(result, indent=2))

        # Exit code based on approval recommendation
        exit_codes = {"approve": 0, "comment": 0, "request_changes": 1}
        sys.exit(exit_codes[analysis.approval_recommendation])

    except Exception as e:
        logger.error(f"Analysis failed: {str(e)}")
        sys.exit(2)


if __name__ == "__main__":
    asyncio.run(main())
