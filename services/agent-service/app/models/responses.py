"""Response models for agent service"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


class ChatChoice(BaseModel):
    index: int
    message: Dict[str, Any]
    finish_reason: str


class ChatResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[ChatChoice]
    usage: Optional[Dict[str, int]] = None


class MigrationResponse(BaseModel):
    status: str = Field(..., description="success | needs-work")
    bundle_url: str = Field(..., description="Downloadable bundle URL")
    report: Dict[str, Any] = Field(..., description="Migration report with metrics")
    next_steps: List[str] = Field(..., description="Next actions to take")


class Issue(BaseModel):
    type: str = Field(..., description="security | performance | quality | dependency")
    severity: str = Field(..., description="critical | high | medium | low")
    file: str
    line: int
    message: str
    suggestion: Optional[str] = None


class ReviewResponse(BaseModel):
    status: str = "success"
    pr_number: int
    repository: str
    analysis: Dict[str, Any]
    issues: List[Issue]
    approval_status: str = Field(
        ..., description="approved | changes_requested | commented"
    )
    summary: str


class AnalyticsResponse(BaseModel):
    status: str = "success"
    question: str
    sql: str
    data: List[Dict[str, Any]]
    visualization: Dict[str, Any]
    chart_url: Optional[str] = None
    interactive_url: Optional[str] = None
    insights: Optional[List[str]] = None
    rows: int
    execution_time_ms: int
