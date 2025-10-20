"""Request models for agent service"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: str = "claude-3-5-sonnet-20241022"
    messages: List[Message]
    temperature: float = 1.0
    max_tokens: int = 4096
    tools: Optional[List[Dict[str, Any]]] = None
    tool_choice: Optional[str] = "auto"


class MigrationRequest(BaseModel):
    repo: str = Field(..., description="GitHub repository URL")
    ref: str = Field(default="main", description="Branch, tag, or commit SHA")
    theme_hint: Optional[str] = Field(
        None, description="Odoo theme name for style extraction"
    )
    baseline_url: Optional[str] = Field(
        None, description="Baseline screenshot URL for visual diff"
    )


class ReviewRequest(BaseModel):
    pr_number: int = Field(..., description="Pull request number")
    repository: str = Field(..., description="Repository name (owner/repo)")
    github_token: Optional[str] = Field(None, description="GitHub access token")


class AnalyticsRequest(BaseModel):
    question: str = Field(..., description="Natural language question")
    database_url: str = Field(..., description="Database connection URL")
    database_type: str = Field(
        default="postgres",
        description="Database type: postgres, mysql, sqlite, mongodb, bigquery, snowflake",
    )
    database_schema: Optional[Dict[str, Any]] = Field(
        None, description="Database schema metadata"
    )
