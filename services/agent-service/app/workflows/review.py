"""PR review workflow implementation"""

import asyncio
from typing import Dict, Any
from anthropic import Anthropic
import os

from app.models.requests import ChatRequest, ReviewRequest
from app.models.responses import ReviewResponse, Issue
from app.tools.review_tools import (
    analyze_pr_diff,
    generate_review_comments,
    detect_lockfile_sync,
)


class ReviewWorkflow:
    def __init__(self):
        self.anthropic = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
        self.tools = [
            {
                "name": "analyze_pr_diff",
                "description": "Analyze PR diff for issues and improvements",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "pr_number": {
                            "type": "integer",
                            "description": "Pull request number",
                        },
                        "repository": {
                            "type": "string",
                            "description": "Repository name (owner/repo)",
                        },
                    },
                    "required": ["pr_number", "repository"],
                },
            },
            {
                "name": "generate_review_comments",
                "description": "Generate and post review comments on PR",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "issues": {
                            "type": "array",
                            "description": "Detected issues",
                        },
                        "pr_number": {
                            "type": "integer",
                            "description": "Pull request number",
                        },
                        "repository": {
                            "type": "string",
                            "description": "Repository name",
                        },
                    },
                    "required": ["issues", "pr_number", "repository"],
                },
            },
            {
                "name": "detect_lockfile_sync",
                "description": "Detect if package.json changes have lockfile updates",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "files_changed": {
                            "type": "array",
                            "description": "List of changed files",
                        }
                    },
                    "required": ["files_changed"],
                },
            },
        ]

    async def handle_chat(self, request: ChatRequest) -> Dict[str, Any]:
        """Handle chat request with function calling"""
        # TODO: Implement Claude API integration with function calling
        pass

    async def execute(self, request: ReviewRequest) -> ReviewResponse:
        """
        Execute complete PR review workflow:
        1. analyze_pr_diff
        2. detect_lockfile_sync
        3. Parallel: Security, performance, quality, dependency checks
        4. generate_review_comments
        """
        try:
            # Step 1: Analyze PR diff
            analysis = await analyze_pr_diff(
                request.pr_number,
                request.repository,
                request.github_token
            )

            # Step 2: Check lockfile sync
            lockfile_check = await detect_lockfile_sync(analysis["files_changed"])

            # Add lockfile issue if not synced
            issues = list(analysis["issues_detected"])
            if not lockfile_check["synced"]:
                issues.append({
                    "type": "dependency",
                    "severity": "high",
                    "file": "package.json",
                    "line": 1,
                    "message": "package.json changed without updating lockfile",
                    "suggestion": f"Run: {lockfile_check['fix_command']}"
                })

            # Step 3: Generate review comments
            review_result = await generate_review_comments(
                issues,
                request.pr_number,
                request.repository,
                request.github_token
            )

            # Build issue objects
            issue_objects = []
            for issue in issues:
                issue_objects.append(
                    Issue(
                        type=issue["type"],
                        severity=issue["severity"],
                        file=issue["file"],
                        line=issue["line"],
                        message=issue["message"],
                        suggestion=issue.get("suggestion")
                    )
                )

            # Generate summary
            summary = _generate_summary(analysis, issues)

            return ReviewResponse(
                status="success",
                pr_number=request.pr_number,
                repository=request.repository,
                analysis={
                    "total_changes": analysis["total_changes"],
                    "complexity_score": analysis["complexity_score"],
                    "files_changed": len(analysis["files_changed"]),
                    "lockfile_synced": lockfile_check["synced"]
                },
                issues=issue_objects,
                approval_status=review_result["approval_status"],
                summary=summary
            )

        except Exception as e:
            raise Exception(f"Review workflow failed: {str(e)}")


def _generate_summary(analysis: Dict[str, Any], issues: List[Dict[str, Any]]) -> str:
    """Generate review summary"""
    total_changes = analysis["total_changes"]
    complexity = analysis["complexity_score"]

    critical = len([i for i in issues if i["severity"] == "critical"])
    high = len([i for i in issues if i["severity"] == "high"])
    medium = len([i for i in issues if i["severity"] == "medium"])
    low = len([i for i in issues if i["severity"] == "low"])

    summary = f"Reviewed {total_changes} lines (complexity: {complexity:.2f}). "

    if critical > 0:
        summary += f"🚨 {critical} critical issues require immediate attention. "
    if high > 0:
        summary += f"⚠️ {high} high severity issues found. "
    if medium > 0:
        summary += f"ℹ️ {medium} medium severity suggestions. "
    if low > 0:
        summary += f"💡 {low} minor improvements possible."

    return summary
