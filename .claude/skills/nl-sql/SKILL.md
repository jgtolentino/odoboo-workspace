# NL-to-SQL Skill

Convert natural language questions to SQL queries using WrenAI integration for Odoo database analysis.

## Capability

- Natural language to SQL conversion
- Odoo schema understanding
- Query execution and result formatting
- Query optimization suggestions

## Parameters

- `question` (string): Natural language question
- `schema_context` (string): Optional schema context
- `max_results` (int): Result limit (default: 100)

## Usage

```python
from wrenai_client import WrenAIClient

async with WrenAIClient() as client:
    result = await client.nl_to_sql(
        question="Show top 10 customers by revenue",
        schema_context="odoo"
    )
    print(result['sql'])
    print(result['results'])
```

## Dependencies

- httpx
- anthropic
