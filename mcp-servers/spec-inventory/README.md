# MCP Spec Inventory Server

MCP (Model Context Protocol) server for querying and managing feature specifications and project inventory.

## Features

This server provides tools to:

- **List features** from `FEATURES.md` with filtering by status and category
- **Search specifications** across `spec/`, `plan/`, and `docs/` directories
- **Read spec files** by filename or path
- **Get statistics** about feature implementation progress

## Installation

```bash
cd mcp-servers/spec-inventory
npm install
npm run build
```

## Usage

### Standalone

```bash
npm start
```

### Claude Desktop Configuration

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "spec-inventory": {
      "command": "node",
      "args": ["/absolute/path/to/odoboo-workspace/mcp-servers/spec-inventory/dist/index.js"]
    }
  }
}
```

### VS Code Extension Integration

The MCP server can be used from the VS Code extension via Claude Code:

```typescript
// Example usage from extension
const features = await mcp.callTool('list_features', {
  status: 'implemented',
});

const searchResults = await mcp.callTool('search_specs', {
  query: 'OCR',
  category: 'spec',
});
```

## Available Tools

### `list_features`

List all features from FEATURES.md, optionally filtered by status or category.

**Parameters**:

- `status` (optional): Filter by status - `implemented`, `in_progress`, `planned`, `on_hold`, `deprecated`, or `all`
- `category` (optional): Filter by category name (partial match)

**Example**:

```json
{
  "status": "implemented",
  "category": "OCR"
}
```

### `search_specs`

Search across all specification files for a given query.

**Parameters**:

- `query` (required): Search query (case-insensitive)
- `category` (optional): Limit search to `spec`, `plan`, `doc`, or `all`

**Example**:

```json
{
  "query": "expense processing",
  "category": "spec"
}
```

### `read_spec`

Read the full contents of a specific specification file.

**Parameters**:

- `filename` (required): Filename or full path

**Example**:

```json
{
  "filename": "01-ocr-expense-processing.md"
}
```

### `get_feature_stats`

Get statistics about feature implementation across the project.

**Parameters**: None

**Returns**: Statistics including:

- Total categories and features
- Breakdown by status (implemented, in progress, planned, on hold, deprecated)
- Completion percentage

## Project Structure

The server expects this directory structure:

```
project-root/
├── FEATURES.md         # Main feature inventory
├── spec/              # Product specifications
├── plan/              # Architecture and planning docs
├── docs/              # Additional documentation
└── mcp-servers/
    └── spec-inventory/ # This server
```

## Development

### Build

```bash
npm run build
```

### Watch Mode

```bash
npm run watch
```

### Run Tests

```bash
npm test
```

## How It Works

1. **Project Detection**: Automatically finds project root by looking for `FEATURES.md`
2. **Feature Parsing**: Parses FEATURES.md to extract categories, statuses, and feature lists
3. **Spec Indexing**: Scans `spec/`, `plan/`, and `docs/` directories for markdown files
4. **Search**: Provides case-insensitive search across filenames and content
5. **Statistics**: Calculates implementation progress metrics

## Example Queries

### Get all implemented features

```json
{
  "tool": "list_features",
  "arguments": {
    "status": "implemented"
  }
}
```

### Find OCR-related specifications

```json
{
  "tool": "search_specs",
  "arguments": {
    "query": "OCR",
    "category": "all"
  }
}
```

### Read architecture document

```json
{
  "tool": "read_spec",
  "arguments": {
    "filename": "architecture.md"
  }
}
```

### Get implementation progress

```json
{
  "tool": "get_feature_stats",
  "arguments": {}
}
```

## Output Format

All tools return structured markdown output that can be:

- Displayed directly to users
- Parsed by LLMs for further processing
- Used in automation workflows

## License

MIT
