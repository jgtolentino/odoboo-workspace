"""Analytics tool functions for natural language → SQL → charts"""

import asyncio
import os
from typing import Dict, Any, List
import httpx
from anthropic import Anthropic
import psycopg2
import pymongo
import sqlite3


async def nl_to_sql(
    question: str,
    database_schema: Dict[str, Any],
    db_type: str = "postgres"
) -> Dict[str, Any]:
    """
    Convert natural language question to SQL query

    Args:
        question: Natural language question
        database_schema: Database schema metadata
        db_type: Database type (postgres, mysql, sqlite, mongodb, bigquery, snowflake)

    Returns:
        {
            "sql": "SELECT ...",
            "viz_config": {
                "chart_type": "bar",
                "x_axis": "month",
                "y_axis": "revenue"
            },
            "explanation": "This query calculates..."
        }
    """
    try:
        anthropic = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

        # Build schema context
        schema_context = _build_schema_context(database_schema)

        # Create prompt for SQL generation
        prompt = f"""You are a SQL expert. Convert this natural language question to a {db_type} SQL query.

Database Schema:
{schema_context}

Question: {question}

Provide:
1. The SQL query
2. Visualization config (chart type, axes)
3. Brief explanation

Output as JSON with keys: sql, viz_config, explanation"""

        # Call Claude API
        response = anthropic.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=2048,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        # Parse response
        import json
        result = json.loads(response.content[0].text)

        return {
            "sql": result.get("sql", ""),
            "viz_config": result.get("viz_config", {
                "chart_type": "table",
                "x_axis": None,
                "y_axis": None
            }),
            "explanation": result.get("explanation", "")
        }
    except Exception as e:
        raise Exception(f"nl_to_sql failed: {str(e)}")


async def execute_query(sql: str, database_url: str, db_type: str = "postgres") -> Dict[str, Any]:
    """
    Execute SQL query against database

    Args:
        sql: SQL query to execute
        database_url: Database connection URL
        db_type: Database type

    Returns:
        {
            "data": [{"col1": "val1", "col2": "val2"}],
            "rows_affected": 42,
            "execution_time_ms": 123
        }
    """
    try:
        import time
        start_time = time.time()

        if db_type == "postgres":
            data = await _execute_postgres(sql, database_url)
        elif db_type == "mysql":
            data = await _execute_mysql(sql, database_url)
        elif db_type == "sqlite":
            data = await _execute_sqlite(sql, database_url)
        elif db_type == "mongodb":
            data = await _execute_mongodb(sql, database_url)
        elif db_type == "bigquery":
            data = await _execute_bigquery(sql, database_url)
        elif db_type == "snowflake":
            data = await _execute_snowflake(sql, database_url)
        else:
            raise ValueError(f"Unsupported database type: {db_type}")

        end_time = time.time()
        execution_time_ms = int((end_time - start_time) * 1000)

        return {
            "data": data,
            "rows_affected": len(data),
            "execution_time_ms": execution_time_ms
        }
    except Exception as e:
        raise Exception(f"execute_query failed: {str(e)}")


async def generate_chart(data: List[Dict[str, Any]], viz_config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate chart from query results

    Args:
        data: Query result data
        viz_config: Visualization configuration

    Returns:
        {
            "chart_url": "https://storage.url/chart.png",
            "chart_type": "bar",
            "interactive_url": "https://chart.example.com/interactive"
        }
    """
    try:
        import matplotlib.pyplot as plt
        import seaborn as sns
        import tempfile
        import pandas as pd

        # Convert data to DataFrame
        df = pd.DataFrame(data)

        # Get chart config
        chart_type = viz_config.get("chart_type", "bar")
        x_axis = viz_config.get("x_axis")
        y_axis = viz_config.get("y_axis")

        # Create figure
        plt.figure(figsize=(12, 6))

        if chart_type == "bar":
            if x_axis and y_axis:
                df.plot(x=x_axis, y=y_axis, kind="bar")
            else:
                df.plot(kind="bar")
        elif chart_type == "line":
            if x_axis and y_axis:
                df.plot(x=x_axis, y=y_axis, kind="line")
            else:
                df.plot(kind="line")
        elif chart_type == "pie":
            if x_axis and y_axis:
                df.set_index(x_axis)[y_axis].plot(kind="pie")
            else:
                df.iloc[:, 0].plot(kind="pie")
        elif chart_type == "scatter":
            if x_axis and y_axis:
                df.plot(x=x_axis, y=y_axis, kind="scatter")
        else:
            # Default to table
            pass

        plt.title(f"{chart_type.capitalize()} Chart")
        plt.tight_layout()

        # Save chart
        temp_dir = tempfile.mkdtemp()
        chart_path = f"{temp_dir}/chart.png"
        plt.savefig(chart_path, dpi=300, bbox_inches="tight")
        plt.close()

        # TODO: Upload to storage
        chart_url = f"file://{chart_path}"

        return {
            "chart_url": chart_url,
            "chart_type": chart_type,
            "interactive_url": None  # TODO: Generate interactive chart with Plotly
        }
    except Exception as e:
        raise Exception(f"generate_chart failed: {str(e)}")


# Helper functions

def _build_schema_context(schema: Dict[str, Any]) -> str:
    """Build schema context for prompt"""
    if not schema:
        return "No schema provided"

    context = []
    for table_name, table_info in schema.items():
        columns = table_info.get("columns", [])
        context.append(f"Table: {table_name}")
        for col in columns:
            col_name = col.get("name", "")
            col_type = col.get("type", "")
            context.append(f"  - {col_name}: {col_type}")

    return "\n".join(context)


async def _execute_postgres(sql: str, database_url: str) -> List[Dict[str, Any]]:
    """Execute PostgreSQL query"""
    conn = psycopg2.connect(database_url)
    cursor = conn.cursor()

    try:
        cursor.execute(sql)
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = cursor.fetchall()

        data = []
        for row in rows:
            data.append(dict(zip(columns, row)))

        return data
    finally:
        cursor.close()
        conn.close()


async def _execute_mysql(sql: str, database_url: str) -> List[Dict[str, Any]]:
    """Execute MySQL query"""
    # Placeholder - would use mysql-connector-python or pymysql
    raise NotImplementedError("MySQL support not yet implemented")


async def _execute_sqlite(sql: str, database_url: str) -> List[Dict[str, Any]]:
    """Execute SQLite query"""
    # Remove 'sqlite:///' prefix
    db_path = database_url.replace("sqlite:///", "")

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    try:
        cursor.execute(sql)
        rows = cursor.fetchall()

        data = []
        for row in rows:
            data.append(dict(row))

        return data
    finally:
        cursor.close()
        conn.close()


async def _execute_mongodb(sql: str, database_url: str) -> List[Dict[str, Any]]:
    """Execute MongoDB query (convert SQL to aggregation pipeline)"""
    # Placeholder - would convert SQL to MongoDB aggregation
    raise NotImplementedError("MongoDB support not yet implemented")


async def _execute_bigquery(sql: str, database_url: str) -> List[Dict[str, Any]]:
    """Execute BigQuery query"""
    # Placeholder - would use google-cloud-bigquery
    raise NotImplementedError("BigQuery support not yet implemented")


async def _execute_snowflake(sql: str, database_url: str) -> List[Dict[str, Any]]:
    """Execute Snowflake query"""
    # Placeholder - would use snowflake-connector-python
    raise NotImplementedError("Snowflake support not yet implemented")
