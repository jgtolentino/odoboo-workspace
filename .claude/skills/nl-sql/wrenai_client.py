#!/usr/bin/env python3
"""WrenAI Client for NL-to-SQL conversion"""
import asyncio
import json
import logging
import os
from typing import Dict, Any, List
import httpx
from anthropic import Anthropic

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class WrenAIClient:
    def __init__(self, api_url: str = None, anthropic_key: str = None):
        self.api_url = api_url or os.getenv("WRENAI_URL", "https://api.wrenai.dev")
        self.anthropic = Anthropic(api_key=anthropic_key or os.getenv("ANTHROPIC_API_KEY"))
        
    async def __aenter__(self):
        return self
        
    async def __aexit__(self, *args):
        pass
        
    async def nl_to_sql(self, question: str, schema_context: str = "odoo", max_results: int = 100) -> Dict[str, Any]:
        """Convert natural language to SQL"""
        try:
            prompt = f"""Convert this question to SQL for Odoo 19 database:
Question: {question}
Schema context: {schema_context}

Output valid PostgreSQL query only."""

            response = self.anthropic.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}]
            )
            
            sql = response.content[0].text.strip()
            return {"sql": sql, "question": question, "results": []}
        except Exception as e:
            logger.error(f"NL-to-SQL failed: {str(e)}")
            raise

if __name__ == "__main__":
    async def main():
        async with WrenAIClient() as client:
            result = await client.nl_to_sql("Show recent orders")
            print(json.dumps(result, indent=2))
    asyncio.run(main())
