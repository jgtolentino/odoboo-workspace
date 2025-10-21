# Knowledge Base Integration Specification

**Version**: 1.0.0
**Status**: 📋 Planned
**Owner**: AI/ML Team
**Priority**: P1

---

## Overview

Integration of Odoo core docs, OCA modules, Supabase documentation, and DigitalOcean product docs into odoobo-expert's knowledge base for enhanced agent capabilities.

## Goals

1. **Comprehensive Documentation Access**: Agent has instant access to vendor docs
2. **CLI-First Workflow**: No Zapier dependencies, pure command-line operations
3. **Automated Refresh**: Nightly CI/CD sync with diff budgets
4. **Multi-Source Support**: Odoo + OCA + Supabase + DigitalOcean

## Architecture

### Source Mirrors

```
knowledge/sources/
├── odoo/                    # Odoo core docs (sparse checkout: /doc)
├── OCA/
│   ├── web/                 # OCA web modules
│   ├── server-tools/        # OCA server tools
│   └── account-financial-tools/
├── supabase/                # Supabase public docs
└── digitalocean/            # DO product docs (static snapshot)
```

### Chunk Pipeline

```
Raw Markdown → Chunker → JSON Chunks → OpenSearch/Chroma → Agent Skills
```

**Chunking Strategy**:

- Target: ~1K tokens per chunk
- Split on: Double newlines (`\n{2,}`)
- Min length: 200 characters
- ID: SHA-1 hash of `${file_path}:${chunk_index}`

### Agent Integration

**New Skill**: `doc-lookup`

```yaml
name: doc-lookup
description: Retrieve and cite docs from local knowledge chunks
inputs:
  - query: string (required)
  - source: string (optional) - odoo|oca|supabase|digitalocean|all
  - max_results: number (optional, default: 8)
tool:
  command: node
  args: [".claude/skills/doc-lookup/run.mjs", "{{query}}", "{{source}}", "{{max_results}}"]
```

## Implementation

### Phase 1: Source Setup (Week 1)

**Tasks**:

1. ✅ Create `knowledge/sources/` directory structure
2. ✅ Clone Odoo core with sparse checkout
3. ✅ Clone OCA repositories (web, server-tools, account-financial-tools)
4. ✅ Clone Supabase docs
5. ✅ Download DigitalOcean docs (App Platform, Droplets, Container Registry)

**Script**: `scripts/kb-setup-sources.sh`

```bash
#!/bin/bash
set -euo pipefail

mkdir -p knowledge/sources && cd knowledge/sources

# Odoo core docs (sparse to /doc)
git clone --depth 1 --filter=blob:none --sparse https://github.com/odoo/odoo.git
cd odoo && git sparse-checkout set doc && cd ..

# OCA (only repos we use)
for r in web server-tools account-financial-tools ; do
  git clone --depth 1 https://github.com/OCA/$r.git
done

# Supabase docs
git clone --depth 1 https://github.com/supabase/supabase.git

# DigitalOcean (static snapshot)
mkdir -p digitalocean && cd digitalocean
wget -e robots=off -r -np -k -nH --cut-dirs=1 \
  https://docs.digitalocean.com/products/app-platform/ \
  https://docs.digitalocean.com/products/droplets/ \
  https://docs.digitalocean.com/products/container-registry/
cd ..

echo "✅ Knowledge sources setup complete"
```

### Phase 2: Chunking Pipeline (Week 2)

**Script**: `scripts/kb-build.mjs`

```javascript
import fs from 'fs';
import crypto from 'crypto';

const SRC = 'knowledge/sources';
const OUT = 'knowledge/chunks';

// Clean output directory
fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

// Recursive file walker
function walk(p) {
  return fs.statSync(p).isDirectory() ? fs.readdirSync(p).flatMap((f) => walk(p + '/' + f)) : [p];
}

// Supported extensions
const EXTS = new Set(['.md', '.rst', '.txt', '.html']);
const files = walk(SRC).filter((f) => {
  const ext = '.' + f.split('.').pop();
  return EXTS.has(ext);
});

let chunkCount = 0;

for (const file of files) {
  const text = fs.readFileSync(file, 'utf8');

  // Naive splitter: double newlines
  const parts = text.split(/\n{2,}/g);
  let index = 0;

  for (const part of parts) {
    if (part.trim().length < 200) continue; // Skip small chunks

    const id = crypto.createHash('sha1').update(`${file}:${index}`).digest('hex');

    const chunk = {
      id,
      source: file,
      chunk: part,
      created_at: new Date().toISOString(),
    };

    fs.writeFileSync(`${OUT}/${id}.json`, JSON.stringify(chunk, null, 2));

    index++;
    chunkCount++;
  }
}

console.log(`✅ Generated ${chunkCount} chunks`);
```

**Validation**:

- Chunk count: 10,000-50,000 expected
- Avg chunk size: 800-1200 chars
- No duplicates (SHA-1 collision check)

### Phase 3: Agent Skill (Week 3)

**File**: `.claude/skills/doc-lookup/run.mjs`

```javascript
import fs from 'fs';
import path from 'path';

const query = (process.argv[2] || '').toLowerCase();
const source = process.argv[3] || 'all';
const maxResults = parseInt(process.argv[4] || '8');

const chunkDir = 'knowledge/chunks';
const files = fs.readdirSync(chunkDir).slice(0, 5000); // Cap for performance

const scored = files
  .map((f) => {
    const chunk = JSON.parse(fs.readFileSync(path.join(chunkDir, f), 'utf8'));

    // Filter by source
    if (source !== 'all' && !chunk.source.includes(source)) {
      return null;
    }

    // Score by keyword matches
    const keywords = query.split(/\s+/);
    const text = chunk.chunk.toLowerCase();
    const score = keywords.reduce((acc, kw) => {
      const matches = (text.match(new RegExp(kw, 'g')) || []).length;
      return acc + matches;
    }, 0);

    return { score, ...chunk };
  })
  .filter((x) => x && x.score > 0)
  .sort((a, b) => b.score - a.score)
  .slice(0, maxResults);

console.log(JSON.stringify({ results: scored }, null, 2));
```

**Agent Instructions Update**:

```markdown
When asked about Odoo, OCA modules, Supabase, or DigitalOcean:

1. **Use doc-lookup first** before web search
2. Cite source file paths in responses
3. Provide links to official docs when available
```

### Phase 4: CI/CD Integration (Week 4)

**Workflow**: `.github/workflows/kb-sync.yml`

```yaml
name: Knowledge Base Sync

on:
  schedule:
    - cron: '17 3 * * *' # Nightly at 3:17 AM UTC
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Pull source mirrors
        run: |
          git -C knowledge/sources/odoo pull || echo "Odoo unchanged"
          for r in web server-tools account-financial-tools; do
            git -C knowledge/sources/OCA/$r pull || echo "$r unchanged"
          done
          git -C knowledge/sources/supabase pull || echo "Supabase unchanged"

      - name: Rebuild chunks
        run: node scripts/kb-build.mjs

      - name: Size guard (fail if >25% growth)
        run: |
          CURRENT=$(find knowledge/chunks -type f | wc -l)
          BASELINE=${BASELINE_CHUNK_COUNT:-15000}
          THRESHOLD=$(echo "$BASELINE * 1.25" | bc)

          if (( CURRENT > THRESHOLD )); then
            echo "❌ Chunk count ($CURRENT) exceeds threshold ($THRESHOLD)"
            exit 1
          fi

          echo "✅ Chunk count: $CURRENT (baseline: $BASELINE)"

      - name: Commit changes
        run: |
          git config user.email "bot@insightpulseai.net"
          git config user.name "KB Bot"
          git add knowledge/chunks
          git commit -m "kb: nightly refresh" || echo "No changes"
          git push || true
```

**Environment Variables**:

- `BASELINE_CHUNK_COUNT`: Set to initial chunk count after first build

## Success Metrics

### Performance

- **Query Latency**: P95 <500ms for doc-lookup
- **Chunk Relevance**: Top-3 result accuracy ≥85%
- **Refresh Time**: <10 minutes for full rebuild

### Quality

- **Coverage**: ≥95% of documented features have source chunks
- **Freshness**: ≤24 hours stale (nightly sync)
- **Accuracy**: ≥90% citation correctness (manual audit)

## Testing

### Unit Tests

```javascript
// tests/kb-chunker.test.js
import { test } from 'node:test';
import assert from 'assert';
import { chunkText } from '../scripts/kb-build.mjs';

test('chunks have minimum length', () => {
  const text = 'Short.\n\nLong enough paragraph to be chunked properly.';
  const chunks = chunkText(text);
  assert(chunks.every((c) => c.length >= 200));
});

test('chunk IDs are unique', () => {
  const chunks = chunkText('A\n\nB\n\nC');
  const ids = chunks.map((c) => c.id);
  assert.strictEqual(new Set(ids).size, ids.length);
});
```

### Integration Tests

```bash
# Test doc-lookup skill
node .claude/skills/doc-lookup/run.mjs "odoo model inheritance" "odoo" 5
# Expected: 5 results from Odoo docs about model inheritance

# Test MCP spec-inventory
node mcp-servers/spec-inventory/dist/index.js
# Send: { "tool": "search_specs", "arguments": { "query": "knowledge base" } }
# Expected: This spec file in results
```

## Governance

### Licensing

- **Odoo**: LGPL-3.0 (read-only mirrors, citation required)
- **OCA**: AGPL-3.0 (read-only mirrors, citation required)
- **Supabase**: Apache 2.0 (read-only mirror, citation required)
- **DigitalOcean**: Proprietary (fair use snippets, link back)

**Policy**:

- Do NOT republish vendor docs verbatim
- Serve **links/snippets only**
- Embed chunks for retrieval (transformative use)
- Log all queries for audit

### Security

- **Domain Allowlist**: `odoo.com`, `github.com/odoo`, `github.com/OCA`, `supabase.com`, `docs.digitalocean.com`
- **Rate Limiting**: 60 queries/minute per user
- **Audit Logging**: Log all doc-lookup queries with timestamp + query

## Rollout Plan

### Week 1: Setup

- ✅ Clone all source repositories
- ✅ Create directory structure
- ✅ Initial chunk generation

### Week 2: Integration

- ✅ Create doc-lookup skill
- ✅ Add to agent tools list
- ✅ Test with odoobo-expert agent

### Week 3: CI/CD

- ✅ Create kb-sync workflow
- ✅ Set baseline chunk count
- ✅ Test automated refresh

### Week 4: Production

- ✅ Deploy to insightpulseai.net
- ✅ Monitor query patterns
- ✅ Tune relevance scoring

## Dependencies

- **Node.js**: 18.0.0+
- **Git**: 2.30.0+
- **wget**: 1.21.0+ (for DigitalOcean docs)
- **bc**: For shell arithmetic in CI

## References

- [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Odoo Documentation](https://www.odoo.com/documentation/18.0/)
- [OCA Maintainer Guidelines](https://github.com/OCA/maintainer-tools/wiki)
- [Supabase Docs](https://supabase.com/docs)
- [DigitalOcean Product Docs](https://docs.digitalocean.com/)

---

**Last Updated**: 2025-10-21
**Next Review**: 2025-11-01
