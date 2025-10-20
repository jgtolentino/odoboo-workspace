"""
Agent Service - Consolidated AI Agent with 5 Core Capabilities
- Code Migration & Transformation
- PR Code Review
- Solutions Architecture
- AI-Powered Analytics
- Data Visualization
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import os
from datetime import datetime

from app.workflows.migration import MigrationWorkflow
from app.workflows.review import ReviewWorkflow
from app.workflows.analytics import AnalyticsWorkflow
from app.models.requests import (
    ChatRequest,
    MigrationRequest,
    ReviewRequest,
    AnalyticsRequest,
)
from app.models.responses import (
    ChatResponse,
    MigrationResponse,
    ReviewResponse,
    AnalyticsResponse,
)

# Initialize FastAPI
app = FastAPI(
    title="Odoobo Agent Service",
    description="Multi-expert AI agent with migration, review, analytics capabilities",
    version="2.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize workflows
migration_workflow = MigrationWorkflow()
review_workflow = ReviewWorkflow()
analytics_workflow = AnalyticsWorkflow()


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "agent-service",
        "version": "2.0.0",
        "timestamp": datetime.utcnow().isoformat(),
        "capabilities": [
            "migration",
            "review",
            "analytics",
            "architecture",
            "visualization",
        ],
    }


@app.post("/v1/chat/completions", response_model=ChatResponse)
async def chat_completions(request: ChatRequest):
    """
    OpenAI-compatible chat endpoint with function calling
    Supports all 13 tool functions
    """
    try:
        # Route to appropriate workflow based on message content
        message = request.messages[-1]["content"]

        # Migration keywords
        if any(kw in message.lower() for kw in ["migrate", "convert", "odoo"]):
            result = await migration_workflow.handle_chat(request)
            return result

        # Review keywords
        if any(kw in message.lower() for kw in ["review", "pr", "pull request"]):
            result = await review_workflow.handle_chat(request)
            return result

        # Analytics keywords
        if any(
            kw in message.lower()
            for kw in ["analytics", "query", "sql", "data", "chart"]
        ):
            result = await analytics_workflow.handle_chat(request)
            return result

        # Default: general conversation
        return ChatResponse(
            id=f"chat-{datetime.utcnow().timestamp()}",
            object="chat.completion",
            created=int(datetime.utcnow().timestamp()),
            model=request.model,
            choices=[
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "I'm Odoobo-Expert, a multi-capability AI agent. I can help with:\n\n"
                        "1. **Code Migration**: Odoo → NestJS + Next.js\n"
                        "2. **PR Code Review**: Automated suggestions\n"
                        "3. **Solutions Architecture**: Diagram generation\n"
                        "4. **AI Analytics**: Natural language → SQL\n"
                        "5. **Data Visualization**: Charts and reports\n\n"
                        "What would you like help with?",
                    },
                    "finish_reason": "stop",
                }
            ],
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/v1/migrate", response_model=MigrationResponse)
async def migrate_odoo(request: MigrationRequest, background_tasks: BackgroundTasks):
    """
    Odoo → NestJS + Next.js migration workflow

    Executes:
    1. repo_fetch(repo, ref)
    2. [PARALLEL] qweb_to_tsx, odoo_model_to_prisma, asset_migrator
    3. nest_scaffold(prisma_schema)
    4. visual_diff(baseline, candidate)
    5. bundle_emit(pieces)
    """
    try:
        result = await migration_workflow.execute(request)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/v1/review", response_model=ReviewResponse)
async def review_pr(request: ReviewRequest):
    """
    PR code review workflow

    Executes:
    1. analyze_pr_diff(pr_number, repository)
    2. detect_lockfile_sync(files_changed)
    3. [PARALLEL] Security, performance, quality, dependency checks
    4. generate_review_comments(issues, pr_number, repository)
    """
    try:
        result = await review_workflow.execute(request)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/v1/analytics", response_model=AnalyticsResponse)
async def analytics_query(request: AnalyticsRequest):
    """
    Natural language analytics workflow

    Executes:
    1. nl_to_sql(question, database_schema, db_type)
    2. execute_query(sql, database_url)
    3. generate_chart(data, viz_config)
    """
    try:
        result = await analytics_workflow.execute(request)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/v1/tools")
async def list_tools():
    """List all available tool functions"""
    return {
        "migration_tools": [
            "repo_fetch",
            "qweb_to_tsx",
            "odoo_model_to_prisma",
            "nest_scaffold",
            "asset_migrator",
            "visual_diff",
            "bundle_emit",
        ],
        "analytics_tools": ["nl_to_sql", "execute_query", "generate_chart"],
        "review_tools": [
            "analyze_pr_diff",
            "generate_review_comments",
            "detect_lockfile_sync",
        ],
        "total": 13,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
