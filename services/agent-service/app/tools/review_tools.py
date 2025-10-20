"""PR review tool functions for automated code review"""

import asyncio
import os
from typing import Dict, Any, List
import httpx
from anthropic import Anthropic


async def analyze_pr_diff(pr_number: int, repository: str, github_token: str = None) -> Dict[str, Any]:
    """
    Analyze PR diff for issues and improvement opportunities

    Args:
        pr_number: Pull request number
        repository: Repository name (owner/repo)
        github_token: GitHub access token

    Returns:
        {
            "files_changed": [
                {
                    "filename": "src/auth.ts",
                    "status": "modified",
                    "additions": 42,
                    "deletions": 15,
                    "changes": 57
                }
            ],
            "issues_detected": [
                {
                    "type": "security",
                    "severity": "high",
                    "file": "src/auth.ts",
                    "line": 45,
                    "message": "Hardcoded credential detected"
                }
            ],
            "total_changes": 57,
            "complexity_score": 0.75
        }
    """
    try:
        token = github_token or os.getenv("GITHUB_TOKEN")
        if not token:
            raise ValueError("GitHub token required")

        # Fetch PR details
        async with httpx.AsyncClient() as client:
            headers = {
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github.v3+json"
            }

            # Get PR files
            files_url = f"https://api.github.com/repos/{repository}/pulls/{pr_number}/files"
            files_response = await client.get(files_url, headers=headers)
            files_response.raise_for_status()
            files_data = files_response.json()

            # Get PR diff
            diff_url = f"https://api.github.com/repos/{repository}/pulls/{pr_number}"
            diff_response = await client.get(
                diff_url,
                headers={**headers, "Accept": "application/vnd.github.v3.diff"}
            )
            diff_response.raise_for_status()
            diff_content = diff_response.text

        # Analyze files
        files_changed = []
        total_changes = 0
        for file_data in files_data:
            file_info = {
                "filename": file_data["filename"],
                "status": file_data["status"],
                "additions": file_data["additions"],
                "deletions": file_data["deletions"],
                "changes": file_data["changes"]
            }
            files_changed.append(file_info)
            total_changes += file_data["changes"]

        # Detect issues
        issues = await _detect_issues(files_changed, diff_content)

        # Calculate complexity
        complexity_score = min(1.0, total_changes / 500)

        return {
            "files_changed": files_changed,
            "issues_detected": issues,
            "total_changes": total_changes,
            "complexity_score": complexity_score
        }
    except Exception as e:
        raise Exception(f"analyze_pr_diff failed: {str(e)}")


async def generate_review_comments(
    issues: List[Dict[str, Any]],
    pr_number: int,
    repository: str,
    github_token: str = None
) -> Dict[str, Any]:
    """
    Generate and post review comments on PR

    Args:
        issues: Detected issues from analyze_pr_diff
        pr_number: Pull request number
        repository: Repository name
        github_token: GitHub access token

    Returns:
        {
            "comments_posted": 5,
            "review_id": 123456,
            "approval_status": "changes_requested"
        }
    """
    try:
        token = github_token or os.getenv("GITHUB_TOKEN")
        if not token:
            raise ValueError("GitHub token required")

        # Fetch commit SHA
        async with httpx.AsyncClient() as client:
            headers = {
                "Authorization": f"Bearer {token}",
                "Accept": "application/vnd.github.v3+json"
            }

            pr_url = f"https://api.github.com/repos/{repository}/pulls/{pr_number}"
            pr_response = await client.get(pr_url, headers=headers)
            pr_response.raise_for_status()
            pr_data = pr_response.json()
            commit_sha = pr_data["head"]["sha"]

        # Group issues by severity
        critical_issues = [i for i in issues if i.get("severity") == "critical"]
        high_issues = [i for i in issues if i.get("severity") == "high"]
        medium_issues = [i for i in issues if i.get("severity") == "medium"]
        low_issues = [i for i in issues if i.get("severity") == "low"]

        # Generate review comments
        comments = []
        for issue in issues:
            comment = {
                "path": issue["file"],
                "line": issue["line"],
                "body": f"**{issue['type'].upper()}** ({issue['severity']}): {issue['message']}"
            }
            if issue.get("suggestion"):
                comment["body"] += f"\n\n**Suggestion**: {issue['suggestion']}"
            comments.append(comment)

        # Determine approval status
        if critical_issues or len(high_issues) > 2:
            approval_status = "REQUEST_CHANGES"
            review_body = f"Found {len(critical_issues)} critical and {len(high_issues)} high severity issues."
        elif high_issues or len(medium_issues) > 5:
            approval_status = "COMMENT"
            review_body = f"Found {len(high_issues)} high and {len(medium_issues)} medium severity issues."
        else:
            approval_status = "APPROVE"
            review_body = f"Looks good! Found {len(medium_issues)} medium and {len(low_issues)} low severity suggestions."

        # Post review
        async with httpx.AsyncClient() as client:
            review_url = f"https://api.github.com/repos/{repository}/pulls/{pr_number}/reviews"
            review_payload = {
                "commit_id": commit_sha,
                "body": review_body,
                "event": approval_status,
                "comments": comments[:50]  # GitHub API limit
            }

            review_response = await client.post(
                review_url,
                headers=headers,
                json=review_payload
            )
            review_response.raise_for_status()
            review_data = review_response.json()

        return {
            "comments_posted": len(comments),
            "review_id": review_data["id"],
            "approval_status": approval_status.lower().replace("_", "_")
        }
    except Exception as e:
        raise Exception(f"generate_review_comments failed: {str(e)}")


async def detect_lockfile_sync(files_changed: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Detect if package.json changes have corresponding lockfile updates

    Args:
        files_changed: List of changed files from analyze_pr_diff

    Returns:
        {
            "synced": false,
            "package_managers": ["npm", "pnpm"],
            "fix_command": "pnpm install"
        }
    """
    try:
        # Check for package.json changes
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
        if not synced and package_managers:
            fix_command = f"{package_managers[0]} install"
        elif not synced:
            fix_command = "npm install"  # Default fallback
        else:
            fix_command = None

        return {
            "synced": synced,
            "package_managers": package_managers,
            "fix_command": fix_command
        }
    except Exception as e:
        raise Exception(f"detect_lockfile_sync failed: {str(e)}")


# Helper functions

async def _detect_issues(files: List[Dict[str, Any]], diff_content: str) -> List[Dict[str, Any]]:
    """Detect issues in PR diff using Claude"""
    try:
        anthropic = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

        # Build context
        files_summary = "\n".join([
            f"- {f['filename']} (+{f['additions']}/-{f['deletions']})"
            for f in files
        ])

        prompt = f"""Analyze this PR diff for issues and improvements.

Files changed:
{files_summary}

Diff:
```
{diff_content[:10000]}  # Limit to first 10K chars
```

Detect issues in these categories:
1. Security (hardcoded secrets, SQL injection, XSS)
2. Performance (inefficient algorithms, memory leaks)
3. Quality (code smells, complexity, duplication)
4. Dependency (outdated packages, vulnerabilities)

Output as JSON array of issues with keys: type, severity, file, line, message, suggestion"""

        response = anthropic.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=4096,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        # Parse response
        import json
        issues = json.loads(response.content[0].text)

        return issues
    except Exception as e:
        # Return empty list if analysis fails
        return []
