"""Analytics workflow implementation"""

import asyncio
from typing import Dict, Any
from anthropic import Anthropic
import os

from app.models.requests import ChatRequest, AnalyticsRequest
from app.models.responses import AnalyticsResponse
from app.tools.analytics_tools import (
    nl_to_sql,
    execute_query,
    generate_chart,
)


class AnalyticsWorkflow:
    def __init__(self):
        self.anthropic = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
        self.tools = [
            {
                "name": "nl_to_sql",
                "description": "Convert natural language to SQL query",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "question": {
                            "type": "string",
                            "description": "Natural language question",
                        },
                        "database_schema": {
                            "type": "object",
                            "description": "Database schema metadata",
                        },
                        "db_type": {
                            "type": "string",
                            "description": "Database type (postgres, mysql, etc)",
                        },
                    },
                    "required": ["question", "database_schema", "db_type"],
                },
            },
            {
                "name": "execute_query",
                "description": "Execute SQL query against database",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "sql": {
                            "type": "string",
                            "description": "SQL query to execute",
                        },
                        "database_url": {
                            "type": "string",
                            "description": "Database connection URL",
                        },
                        "db_type": {
                            "type": "string",
                            "description": "Database type",
                        },
                    },
                    "required": ["sql", "database_url", "db_type"],
                },
            },
            {
                "name": "generate_chart",
                "description": "Generate visualization from query results",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "data": {
                            "type": "array",
                            "description": "Query result data",
                        },
                        "viz_config": {
                            "type": "object",
                            "description": "Visualization configuration",
                        },
                    },
                    "required": ["data", "viz_config"],
                },
            },
        ]

    async def handle_chat(self, request: ChatRequest) -> Dict[str, Any]:
        """Handle chat request with function calling"""
        # TODO: Implement Claude API integration with function calling
        pass

    async def execute(self, request: AnalyticsRequest) -> AnalyticsResponse:
        """
        Execute complete analytics workflow:
        1. nl_to_sql: Convert question to SQL
        2. execute_query: Run query against database
        3. generate_chart: Create visualization
        """
        try:
            # Step 1: Convert NL to SQL
            sql_result = await nl_to_sql(
                request.question,
                request.database_schema or {},
                request.database_type
            )

            # Step 2: Execute query
            query_result = await execute_query(
                sql_result["sql"],
                request.database_url,
                request.database_type
            )

            # Step 3: Generate chart
            chart_result = await generate_chart(
                query_result["data"],
                sql_result["viz_config"]
            )

            # Generate insights using Claude
            insights = await _generate_insights(
                request.question,
                query_result["data"],
                sql_result["sql"]
            )

            return AnalyticsResponse(
                status="success",
                question=request.question,
                sql=sql_result["sql"],
                data=query_result["data"],
                visualization=sql_result["viz_config"],
                chart_url=chart_result["chart_url"],
                interactive_url=chart_result["interactive_url"],
                insights=insights,
                rows=query_result["rows_affected"],
                execution_time_ms=query_result["execution_time_ms"]
            )

        except Exception as e:
            raise Exception(f"Analytics workflow failed: {str(e)}")


async def _generate_insights(question: str, data: list, sql: str) -> list:
    """Generate insights from query results using Claude"""
    try:
        anthropic = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

        # Prepare data summary
        row_count = len(data)
        sample_rows = data[:5] if data else []

        prompt = f"""Analyze this data and provide 3-5 key insights.

Question: {question}

SQL Query:
{sql}

Results: {row_count} rows
Sample data:
{sample_rows}

Provide insights as a JSON array of strings."""

        response = anthropic.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        # Parse response
        import json
        insights = json.loads(response.content[0].text)

        return insights
    except Exception as e:
        return [f"Error generating insights: {str(e)}"]
