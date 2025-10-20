"""
Odoobo-Expert Reviewer - SuperClaude Sub-Agent Integration
Proxies requests to the remote odoobo-expert agent with local caching and optimization.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import json
from typing import Optional, List, Dict, Any
from datetime import datetime

app = FastAPI(title="Odoobo Reviewer", version="1.0.0")

# Configuration
ODOOBO_ENDPOINT = "https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run"
TIMEOUT = 180.0

class ReviewRequest(BaseModel):
    pr_number: Optional[int] = None
    repository: Optional[str] = None
    files_changed: Optional[List[Dict[str, Any]]] = None
    operation: str = "review"  # review, analyze, detect_lockfile
    context: Optional[Dict[str, Any]] = None

class ReviewResponse(BaseModel):
    status: str
    operation: str
    result: Dict[str, Any]
    timestamp: str
    execution_time_ms: float

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "odoobo-reviewer",
        "endpoint": ODOOBO_ENDPOINT,
        "version": "1.0.0"
    }

@app.post("/review")
async def review_pr(request: ReviewRequest) -> ReviewResponse:
    """
    Review a pull request using odoobo-expert agent
    """
    start_time = datetime.now()

    try:
        # Build request payload for odoobo-expert
        payload = {
            "operation": request.operation,
            "pr_number": request.pr_number,
            "repository": request.repository,
            "files_changed": request.files_changed,
            "context": request.context or {}
        }

        # Call remote odoobo-expert agent
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.post(
                f"{ODOOBO_ENDPOINT}/analyze",
                json=payload
            )
            response.raise_for_status()
            result = response.json()

        execution_time = (datetime.now() - start_time).total_seconds() * 1000

        return ReviewResponse(
            status="success",
            operation=request.operation,
            result=result,
            timestamp=datetime.now().isoformat(),
            execution_time_ms=execution_time
        )

    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="Odoobo-expert agent timeout - try again or check agent status"
        )
    except httpx.HTTPStatusError as e:
        raise HTTPException(
            status_code=e.response.status_code,
            detail=f"Odoobo-expert returned error: {e.response.text}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )

@app.post("/analyze")
async def analyze_code(request: ReviewRequest) -> ReviewResponse:
    """
    Analyze code without PR context
    """
    request.operation = "analyze"
    return await review_pr(request)

@app.post("/detect-lockfile")
async def detect_lockfile_sync(request: ReviewRequest) -> ReviewResponse:
    """
    Detect package.json/lockfile sync issues
    """
    request.operation = "detect_lockfile"
    return await review_pr(request)

@app.get("/status")
async def agent_status():
    """
    Check odoobo-expert agent availability
    """
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{ODOOBO_ENDPOINT}/health")
            return {
                "agent_available": response.status_code == 200,
                "endpoint": ODOOBO_ENDPOINT,
                "response_time_ms": response.elapsed.total_seconds() * 1000
            }
    except Exception as e:
        return {
            "agent_available": False,
            "endpoint": ODOOBO_ENDPOINT,
            "error": str(e)
        }
