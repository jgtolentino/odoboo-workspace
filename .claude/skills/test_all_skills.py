#!/usr/bin/env python3
"""
Comprehensive test suite for all Anthropic Skills
"""

import pytest
import asyncio
import os
from pathlib import Path

# Set test environment
os.environ.setdefault("GITHUB_TOKEN", "test_token")
os.environ.setdefault("ANTHROPIC_API_KEY", "test_key")
os.environ.setdefault("ODOO_URL", "https://demo.odoo.com")
os.environ.setdefault("ODOO_DATABASE", "demo")
os.environ.setdefault("ODOO_USERNAME", "admin")
os.environ.setdefault("ODOO_PASSWORD", "admin")

SKILLS_DIR = Path(__file__).parent


class TestSkillStructure:
    """Test that all skills have required structure"""

    def test_skill_directories_exist(self):
        """Verify all skill directories exist"""
        required_skills = [
            "pr-review",
            "odoo-rpc",
            "nl-sql",
            "visual-diff",
            "design-tokens"
        ]
        
        for skill in required_skills:
            skill_dir = SKILLS_DIR / skill
            assert skill_dir.exists(), f"Skill directory {skill} not found"
            assert skill_dir.is_dir(), f"{skill} is not a directory"

    def test_skill_files_exist(self):
        """Verify required files exist in each skill"""
        skills = ["pr-review", "odoo-rpc", "nl-sql", "visual-diff", "design-tokens"]
        
        for skill in skills:
            skill_dir = SKILLS_DIR / skill
            
            # Check SKILL.md
            assert (skill_dir / "SKILL.md").exists(), f"{skill}/SKILL.md missing"
            
            # Check main script
            script_names = {
                "pr-review": "analyze_pr.py",
                "odoo-rpc": "odoo_client.py",
                "nl-sql": "wrenai_client.py",
                "visual-diff": "percy_client.py",
                "design-tokens": "extract_tokens.py"
            }
            script = skill_dir / script_names[skill]
            assert script.exists(), f"{skill}/{script_names[skill]} missing"
            assert script.stat().st_mode & 0o111, f"{script} not executable"
            
            # Check resources directory
            assert (skill_dir / "resources").exists(), f"{skill}/resources missing"
            assert (skill_dir / "resources").is_dir()
            
            # Check requirements.txt
            assert (skill_dir / "requirements.txt").exists()

    def test_unified_requirements_exist(self):
        """Verify unified requirements.txt exists"""
        unified_req = SKILLS_DIR / "requirements.txt"
        assert unified_req.exists()
        
        # Verify it has content
        content = unified_req.read_text()
        assert len(content) > 0
        assert "httpx" in content
        assert "anthropic" in content

    def test_readme_exists(self):
        """Verify README.md exists and has content"""
        readme = SKILLS_DIR / "README.md"
        assert readme.exists()
        
        content = readme.read_text()
        assert len(content) > 1000  # Should be comprehensive
        assert "PR Review" in content
        assert "Odoo RPC" in content


class TestPRReviewSkill:
    """Test PR Review skill"""

    def test_imports(self):
        """Test PR Review can be imported"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "pr-review"))
        
        from analyze_pr import (
            Issue,
            PRAnalysis,
            detect_lockfile_sync,
            calculate_complexity_score
        )
        
        # Test Issue creation
        issue = Issue("security", "high", "test.py", 1, "Test")
        assert issue.type == "security"

    @pytest.mark.asyncio
    async def test_lockfile_detection(self):
        """Test lockfile sync detection"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "pr-review"))
        from analyze_pr import detect_lockfile_sync
        
        # Test synced
        files = [
            {"filename": "package.json"},
            {"filename": "package-lock.json"}
        ]
        result = await detect_lockfile_sync(files)
        assert result["synced"] is True

    def test_complexity_calculation(self):
        """Test complexity score calculation"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "pr-review"))
        from analyze_pr import calculate_complexity_score
        
        score = calculate_complexity_score(100, 5)
        assert 0.0 <= score <= 1.0


class TestOdooRPCSkill:
    """Test Odoo RPC skill"""

    def test_imports(self):
        """Test Odoo RPC can be imported"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "odoo-rpc"))
        
        from odoo_client import (
            OdooClient,
            OdooConfig,
            OdooRPCError
        )
        
        # Test config creation
        config = OdooConfig(
            url="https://demo.odoo.com",
            database="demo",
            username="admin",
            password="admin"
        )
        assert config.url == "https://demo.odoo.com"

    def test_odoo_config_validation(self):
        """Test Odoo config auto-fixes URL"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "odoo-rpc"))
        from odoo_client import OdooConfig
        
        # Test URL normalization
        config = OdooConfig(
            url="demo.odoo.com",  # No https://
            database="demo",
            username="admin",
            password="admin"
        )
        assert config.url.startswith("https://")
        assert not config.url.endswith("/")


class TestNLToSQLSkill:
    """Test NL-to-SQL skill"""

    def test_imports(self):
        """Test NL-to-SQL can be imported"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "nl-sql"))
        
        from wrenai_client import WrenAIClient
        
        # Test client creation
        client = WrenAIClient()
        assert client is not None


class TestVisualDiffSkill:
    """Test Visual Diff skill"""

    def test_imports(self):
        """Test Visual Diff can be imported"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "visual-diff"))
        
        from percy_client import VisualDiffClient
        
        # Test client creation
        client = VisualDiffClient()
        assert client is not None


class TestDesignTokensSkill:
    """Test Design Tokens skill"""

    def test_imports(self):
        """Test Design Tokens can be imported"""
        import sys
        sys.path.insert(0, str(SKILLS_DIR / "design-tokens"))
        
        from extract_tokens import DesignTokenExtractor
        
        # Test extractor creation
        extractor = DesignTokenExtractor()
        assert extractor is not None


class TestResourceFiles:
    """Test resource files are valid JSON"""

    def test_pr_review_resources(self):
        """Test PR Review resource files"""
        import json
        
        resources_dir = SKILLS_DIR / "pr-review" / "resources"
        
        # Test security patterns
        with open(resources_dir / "security_patterns.json") as f:
            data = json.load(f)
            assert "hardcoded_secrets" in data
        
        # Test severity matrix
        with open(resources_dir / "severity_matrix.json") as f:
            data = json.load(f)
            assert "severity_rules" in data

    def test_odoo_rpc_resources(self):
        """Test Odoo RPC resource files"""
        import json
        
        resources_dir = SKILLS_DIR / "odoo-rpc" / "resources"
        
        # Test models
        with open(resources_dir / "odoo_models.json") as f:
            data = json.load(f)
            assert "common_models" in data
        
        # Test domain examples
        with open(resources_dir / "domain_examples.json") as f:
            data = json.load(f)
            assert "basic_domains" in data


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
