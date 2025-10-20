#!/usr/bin/env python3
"""
Unit tests for PR Review skill
"""

import pytest
import asyncio
from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from analyze_pr import (
    Issue,
    PRAnalysis,
    detect_lockfile_sync,
    calculate_complexity_score,
    determine_approval_recommendation
)


class TestIssue:
    """Test Issue dataclass"""

    def test_issue_creation(self):
        issue = Issue(
            type="security",
            severity="high",
            file="test.py",
            line=42,
            message="Test issue",
            suggestion="Fix it"
        )
        assert issue.type == "security"
        assert issue.severity == "high"
        assert issue.line == 42

    def test_issue_to_dict(self):
        issue = Issue(
            type="security",
            severity="high",
            file="test.py",
            line=42,
            message="Test issue"
        )
        result = issue.to_dict()
        assert result["type"] == "security"
        assert result["file"] == "test.py"
        assert "suggestion" in result


class TestLockfileSync:
    """Test lockfile sync detection"""

    @pytest.mark.asyncio
    async def test_synced_npm(self):
        files = [
            {"filename": "package.json"},
            {"filename": "package-lock.json"}
        ]
        result = await detect_lockfile_sync(files)
        assert result["synced"] is True
        assert "npm" in result["package_managers"]

    @pytest.mark.asyncio
    async def test_unsynced_package_json(self):
        files = [
            {"filename": "package.json"}
        ]
        result = await detect_lockfile_sync(files)
        assert result["synced"] is False
        assert result["fix_command"] == "npm install"

    @pytest.mark.asyncio
    async def test_pnpm_detected(self):
        files = [
            {"filename": "package.json"},
            {"filename": "pnpm-lock.yaml"}
        ]
        result = await detect_lockfile_sync(files)
        assert result["synced"] is True
        assert "pnpm" in result["package_managers"]

    @pytest.mark.asyncio
    async def test_yarn_detected(self):
        files = [
            {"filename": "package.json"},
            {"filename": "yarn.lock"}
        ]
        result = await detect_lockfile_sync(files)
        assert result["synced"] is True
        assert "yarn" in result["package_managers"]

    @pytest.mark.asyncio
    async def test_no_package_json(self):
        files = [
            {"filename": "src/index.ts"}
        ]
        result = await detect_lockfile_sync(files)
        assert result["synced"] is True  # No package.json = synced


class TestComplexityScore:
    """Test complexity calculation"""

    def test_low_complexity(self):
        score = calculate_complexity_score(total_changes=50, files_count=2)
        assert score < 0.3

    def test_high_complexity(self):
        score = calculate_complexity_score(total_changes=600, files_count=25)
        assert score > 0.8

    def test_medium_complexity(self):
        score = calculate_complexity_score(total_changes=250, files_count=10)
        assert 0.3 <= score <= 0.8

    def test_zero_changes(self):
        score = calculate_complexity_score(total_changes=0, files_count=0)
        assert score == 0.0


class TestApprovalRecommendation:
    """Test approval recommendation logic"""

    def test_critical_issue_requests_changes(self):
        issues = [
            Issue("security", "critical", "test.py", 1, "Critical issue")
        ]
        recommendation = determine_approval_recommendation(issues, 0.5)
        assert recommendation == "request_changes"

    def test_multiple_high_issues_requests_changes(self):
        issues = [
            Issue("security", "high", "test.py", 1, "Issue 1"),
            Issue("security", "high", "test.py", 2, "Issue 2"),
            Issue("security", "high", "test.py", 3, "Issue 3")
        ]
        recommendation = determine_approval_recommendation(issues, 0.5)
        assert recommendation == "request_changes"

    def test_few_medium_issues_comments(self):
        issues = [
            Issue("quality", "medium", "test.py", 1, "Issue 1"),
            Issue("quality", "medium", "test.py", 2, "Issue 2")
        ]
        recommendation = determine_approval_recommendation(issues, 0.5)
        assert recommendation == "comment"

    def test_high_complexity_comments(self):
        issues = []
        recommendation = determine_approval_recommendation(issues, 0.9)
        assert recommendation == "comment"

    def test_no_issues_approves(self):
        issues = []
        recommendation = determine_approval_recommendation(issues, 0.3)
        assert recommendation == "approve"

    def test_low_severity_issues_approves(self):
        issues = [
            Issue("style", "low", "test.py", 1, "Style issue")
        ]
        recommendation = determine_approval_recommendation(issues, 0.2)
        assert recommendation == "approve"


class TestPRAnalysis:
    """Test PRAnalysis dataclass"""

    def test_pr_analysis_creation(self):
        analysis = PRAnalysis(
            pr_number=123,
            repository="owner/repo",
            files_changed=[],
            issues=[],
            lockfile_sync={"synced": True},
            complexity_score=0.5,
            total_changes=100,
            approval_recommendation="approve"
        )
        assert analysis.pr_number == 123
        assert analysis.repository == "owner/repo"

    def test_pr_analysis_to_dict(self):
        issue = Issue("security", "high", "test.py", 1, "Test")
        analysis = PRAnalysis(
            pr_number=123,
            repository="owner/repo",
            files_changed=[],
            issues=[issue],
            lockfile_sync={"synced": True},
            complexity_score=0.5,
            total_changes=100,
            approval_recommendation="approve"
        )
        result = analysis.to_dict()
        assert result["pr_number"] == 123
        assert len(result["issues"]) == 1
        assert "analysis_timestamp" in result


# Mock tests for integration (require actual API keys)
class TestIntegration:
    """Integration tests requiring API access"""

    @pytest.mark.skip(reason="Requires GitHub API access")
    @pytest.mark.asyncio
    async def test_analyze_real_pr(self):
        """Test with real PR - skipped by default"""
        from analyze_pr import analyze_pull_request

        result = await analyze_pull_request(
            pr_number=1,
            repository="owner/repo"
        )
        assert isinstance(result, PRAnalysis)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
