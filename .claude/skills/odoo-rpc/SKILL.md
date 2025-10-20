# Odoo RPC Skill

Interact with Odoo ERP system via XML-RPC and JSON-RPC for data access, automation, and integration.

## Capability

Provides full Odoo API access:

- Authentication (session management, API keys)
- Search and read records (with domain filters)
- Create, update, delete operations
- Execute server methods (compute, workflows)
- Metadata inspection (models, fields, access rights)

## Parameters

### Required

- `url` (string): Odoo instance URL (e.g., "https://demo.odoo.com")
- `database` (string): Database name
- `username` (string): Login username
- `password` (string): User password or API key

### Optional

- `protocol` (string): "xmlrpc" or "jsonrpc" (default: "jsonrpc")
- `timeout` (float): Request timeout in seconds (default: 30.0)
- `verify_ssl` (boolean): SSL certificate verification (default: true)

## Usage Examples

### Authentication and Basic Search

```python
from odoo_client import OdooClient

async with OdooClient(
    url="https://demo.odoo.com",
    database="demo",
    username="admin",
    password="admin"
) as client:
    # Search for partners
    partner_ids = await client.search(
        "res.partner",
        domain=[["is_company", "=", True]],
        limit=10
    )

    partners = await client.read(
        "res.partner",
        ids=partner_ids,
        fields=["name", "email", "phone"]
    )

    for partner in partners:
        print(f"{partner['name']}: {partner['email']}")
```

### Create and Update Records

```python
# Create new partner
partner_id = await client.create(
    "res.partner",
    values={
        "name": "ACME Corp",
        "email": "contact@acme.com",
        "is_company": True
    }
)

# Update existing record
await client.write(
    "res.partner",
    ids=[partner_id],
    values={"phone": "+1-555-0100"}
)
```

### Execute Server Methods

```python
# Call custom method
result = await client.execute(
    "sale.order",
    method="action_confirm",
    ids=[order_id]
)

# Search and count
count = await client.search_count(
    "sale.order",
    domain=[["state", "=", "draft"]]
)
```

### Metadata Inspection

```python
# Get model fields
fields = await client.fields_get(
    "res.partner",
    attributes=["string", "type", "required"]
)

# Check access rights
access = await client.check_access_rights(
    "sale.order",
    operation="write"
)
```

## Output Format

### Search Results

```json
{
  "model": "res.partner",
  "ids": [1, 2, 3],
  "count": 3,
  "domain": [["is_company", "=", true]]
}
```

### Read Results

```json
{
  "model": "res.partner",
  "records": [
    {
      "id": 1,
      "name": "ACME Corp",
      "email": "contact@acme.com",
      "is_company": true
    }
  ],
  "count": 1
}
```

### Write/Create Results

```json
{
  "operation": "create",
  "model": "res.partner",
  "id": 42,
  "success": true
}
```

## Odoo Domain Syntax

Domains use Polish notation:

```python
# AND conditions (implicit)
[["field1", "=", "value1"], ["field2", ">", 10]]

# OR conditions
["|", ["field1", "=", "A"], ["field1", "=", "B"]]

# Complex example
[
    "&",
    ["active", "=", True],
    "|",
    ["name", "ilike", "ACME"],
    ["email", "ilike", "@acme.com"]
]
```

## Integration

### Claude Code Tool

```python
{
  "name": "odoo_search",
  "description": "Search Odoo records with domain filters",
  "input_schema": {
    "type": "object",
    "properties": {
      "model": {"type": "string"},
      "domain": {"type": "array"},
      "fields": {"type": "array", "items": {"type": "string"}},
      "limit": {"type": "integer"}
    },
    "required": ["model"]
  }
}
```

### Environment Variables

```bash
export ODOO_URL="https://demo.odoo.com"
export ODOO_DATABASE="demo"
export ODOO_USERNAME="admin"
export ODOO_PASSWORD="admin"
```

## Resource Files

- `resources/odoo_models.json`: Common Odoo models and relationships
- `resources/rpc_methods.json`: Available RPC methods per model
- `resources/domain_examples.json`: Domain filter patterns

## Dependencies

- `httpx`: Async HTTP client
- `xmlrpc.client`: XML-RPC protocol (built-in)
- `pydantic`: Data validation

## Error Handling

- **Authentication errors**: Invalid credentials or expired sessions
- **Access denied**: Insufficient user permissions
- **Model not found**: Invalid model name
- **Field errors**: Unknown field or type mismatch
- **Network errors**: Connection timeout or server unavailable

## Security Considerations

- Store credentials in environment variables
- Use API keys instead of passwords when possible
- Implement rate limiting for bulk operations
- Validate all user inputs before RPC calls
- Log all data modifications for audit trail
