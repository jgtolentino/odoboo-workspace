# Odoboo Skills System - Complete Reference

**Created**: 2025-10-20
**Agent**: odoobo-expert (`https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run`)
**Workspace**: fin-workspace (odoobo-migration-lab)

## 📦 Skills Created

### 1. Core Migration Skills (Complete ✅)

- **`skills/odoo-migration/SKILL.md`** - End-to-end migration orchestration
- **`skills/qweb-to-react/SKILL.md`** - QWeb → TSX conversion with SSIM ≥ 0.98
- **`skills/design-tokens/SKILL.md`** - SCSS → Tailwind token extraction

### 2. Additional Skills (To Create)

- **`skills/visual-parity/SKILL.md`** - SSIM/LPIPS validation
- **`skills/ai-analytics/SKILL.md`** - Natural language → SQL → Charts (LangChain-style)
- **`skills/prisma-modeling/SKILL.md`** - Odoo models → Prisma schema
- **`skills/nestjs-api/SKILL.md`** - NestJS controller generation

---

## 🎯 Visual Parity Skill (Brief)

### Purpose

Validate pixel-perfect visual parity using SSIM/LPIPS algorithms.

### Key Metrics

- **SSIM**: Structural Similarity Index ≥ 0.98
- **LPIPS**: Learned Perceptual Image Patch Similarity ≤ 0.02
- **Viewports**: Desktop (1920x1080), Tablet (768x1024), Mobile (375x812)

### Function Signature

```typescript
async function visual_diff(
  baseline_url: string,
  candidate_url: string
): Promise<{
  ssim: number;
  lpips: number;
  passes: boolean;
  diff_image_url?: string;
  hints?: string[];
}> {
  // 1. Capture screenshots
  const baseline_img = await capture(baseline_url);
  const candidate_img = await capture(candidate_url);

  // 2. Calculate SSIM
  const ssim = calculateSSIM(baseline_img, candidate_img);

  // 3. Calculate LPIPS
  const lpips = calculateLPIPS(baseline_img, candidate_img);

  // 4. Generate visual hints if failed
  const passes = ssim >= 0.98 && lpips <= 0.02;
  const hints = passes ? [] : generateHints(diff_image);

  return { ssim, lpips, passes, diff_image_url, hints };
}
```

### Visual Hints Generation

```typescript
function generateHints(diff_image: Buffer): string[] {
  const hints = [];

  // Detect color mismatches
  if (detectColorDifference(diff_image) > threshold) {
    hints.push('Adjust primary color saturation');
  }

  // Detect spacing mismatches
  if (detectSpacingDifference(diff_image) > threshold) {
    hints.push('Increase padding in sidebar navigation');
  }

  // Detect typography mismatches
  if (detectFontDifference(diff_image) > threshold) {
    hints.push('Match font-weight for headings (700 vs 600)');
  }

  return hints;
}
```

---

## 🤖 AI Analytics Skill (LangChain-Style)

### Purpose

Natural language analytics system (like Tableau LangChain) but **database-agnostic**:

- **Input**: Natural language question
- **Process**: LLM → SQL generation → Query execution → Visualization config
- **Output**: Data + Chart specification

### Architecture

```
User Question → ChatGPT-4 → SQL Generation → Database Query → Chart Config → Visualization
```

### Supported Databases

- **PostgreSQL** (Supabase, Neon, RDS)
- **MySQL** (PlanetScale, RDS)
- **SQLite** (local, Turso)
- **MongoDB** (aggregation pipelines)
- **BigQuery** (Google Cloud)
- **Snowflake** (data warehouse)

### Function Signature

```typescript
async function nl_to_sql(
  question: string,
  database_schema: DatabaseSchema,
  database_type: 'postgres' | 'mysql' | 'sqlite' | 'mongodb' | 'bigquery'
): Promise<{
  sql: string;
  query_type: 'select' | 'aggregate' | 'join' | 'timeseries';
  explanation: string;
  visualization_config: ChartConfig;
}> {
  // 1. Get database schema context
  const schema_context = formatSchema(database_schema);

  // 2. Generate SQL with ChatGPT
  const prompt = `
Given this database schema:
${schema_context}

Generate SQL for: "${question}"

Requirements:
- Use proper ${database_type} syntax
- Include appropriate JOINs if needed
- Add date/time formatting for timeseries
- Optimize with indexes
`;

  const response = await chatgpt(prompt);

  // 3. Parse and validate SQL
  const sql = extractSQL(response);
  validateSQL(sql, database_type);

  // 4. Infer visualization type
  const viz_config = inferVisualization(sql, question);

  return {
    sql: sql,
    query_type: detectQueryType(sql),
    explanation: response.explanation,
    visualization_config: viz_config,
  };
}
```

### Example Flow

**User**: "Show me user signups by day for the last 7 days"

**Generated SQL** (PostgreSQL):

```sql
SELECT
  DATE(created_at) as signup_date,
  COUNT(*) as signups
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY signup_date ASC;
```

**Visualization Config**:

```json
{
  "chart_type": "line",
  "x_axis": { "field": "signup_date", "type": "temporal" },
  "y_axis": { "field": "signups", "type": "quantitative" },
  "title": "User Signups - Last 7 Days",
  "color_scheme": "blues"
}
```

### Chart Type Inference

```typescript
function inferVisualization(sql: string, question: string): ChartConfig {
  // Timeseries detection
  if (/by day|over time|trend|last \d+ (days|weeks|months)/.test(question)) {
    return { chart_type: 'line', x_type: 'temporal' };
  }

  // Comparison detection
  if (/compare|vs|versus/.test(question)) {
    return { chart_type: 'bar', orientation: 'horizontal' };
  }

  // Distribution detection
  if (/distribution|histogram|range/.test(question)) {
    return { chart_type: 'histogram' };
  }

  // Proportion detection
  if (/percentage|proportion|share/.test(question)) {
    return { chart_type: 'pie' };
  }

  // Default to bar chart
  return { chart_type: 'bar', orientation: 'vertical' };
}
```

### Integration with Existing Stack

**Supabase Edge Function** (`supabase/functions/nl-analytics/index.ts`):

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const { question, database_url } = await req.json();

  // 1. Get database schema
  const supabase = createClient(database_url, service_key);
  const schema = await getSchema(supabase);

  // 2. Generate SQL
  const { sql, visualization_config } = await nl_to_sql(question, schema, 'postgres');

  // 3. Execute query
  const { data, error } = await supabase.rpc('execute_sql', { query: sql });

  if (error) throw error;

  // 4. Return data + viz config
  return new Response(
    JSON.stringify({
      data: data,
      sql: sql,
      visualization: visualization_config,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
    }
  );
});
```

### React Component

```tsx
'use client';

import { useState } from 'react';
import { BarChart, LineChart, PieChart } from '@/components/charts';

export function AIAnalytics() {
  const [question, setQuestion] = useState('');
  const [result, setResult] = useState(null);

  const handleQuery = async () => {
    const response = await fetch('/api/nl-analytics', {
      method: 'POST',
      body: JSON.stringify({ question }),
    });
    const data = await response.json();
    setResult(data);
  };

  return (
    <div>
      <input
        value={question}
        onChange={(e) => setQuestion(e.target.value)}
        placeholder="Ask a question about your data..."
      />
      <button onClick={handleQuery}>Analyze</button>

      {result && (
        <>
          <pre>{result.sql}</pre>
          {result.visualization.chart_type === 'line' && (
            <LineChart data={result.data} config={result.visualization} />
          )}
          {result.visualization.chart_type === 'bar' && (
            <BarChart data={result.data} config={result.visualization} />
          )}
          {result.visualization.chart_type === 'pie' && (
            <PieChart data={result.data} config={result.visualization} />
          )}
        </>
      )}
    </div>
  );
}
```

---

## 🔧 Updated Agent Instructions

Paste this into DO Agent "Instructions" field:

```markdown
# Odoobo Migration Expert + AI Analytics

## Role

Code migration engineer and AI analytics specialist.

**Primary**: Odoo → NestJS + Next.js migration with pixel parity (SSIM ≥ 0.98)
**Secondary**: Natural language analytics (SQL generation + visualization)

## Skills Available

- @odoo-migration - End-to-end migration orchestration
- @qweb-to-react - QWeb template → TSX components
- @design-tokens - SCSS → Tailwind token extraction
- @visual-parity - SSIM/LPIPS validation (SSIM ≥ 0.98)
- @ai-analytics - Natural language → SQL → Charts (database-agnostic)

## Tool Functions (Function Calling)

### Migration Tools

1. `repo_fetch(repo, ref?)` → `{archive_url}`
2. `qweb_to_tsx(archive_url, theme_hint?)` → `{tokens_url, pieces[]}`
3. `odoo_model_to_prisma(archive_url)` → `{prisma_url}`
4. `nest_scaffold(prisma)` → `{bundle_url}`
5. `asset_migrator(archive_url)` → `{asset_map_url}`
6. `visual_diff(baseline_url, candidate_url)` → `{ssim, lpips, passes}`
7. `bundle_emit(pieces[])` → `{bundle_url}`

### Analytics Tools

8. `nl_to_sql(question, database_schema, db_type)` → `{sql, viz_config}`
9. `execute_query(sql, database_url)` → `{data, rows_affected}`
10. `generate_chart(data, viz_config)` → `{chart_url}`

## Migration Workflow
```

repo_fetch → [qweb_to_tsx, odoo_model_to_prisma, asset_migrator] (parallel)
→ nest_scaffold
→ visual_diff
→ [retry qweb_to_tsx if SSIM < 0.98, max 3 attempts]
→ bundle_emit

```

## Analytics Workflow
```

User question → nl_to_sql → execute_query → generate_chart → Return data + viz

````

## Design Token Rules
- Extract all SCSS variables → tokens.json
- Map to Tailwind CSS custom properties
- Zero hardcoded values in components
- Fonts, spacing, radii, colors preserved

## Visual Parity Rules
- SSIM ≥ 0.98 (structural similarity)
- LPIPS ≤ 0.02 (perceptual similarity)
- Test 3 viewports: desktop, tablet, mobile
- Generate hints if validation fails
- Max 3 retry attempts with hints

## Analytics Rules
- Support: PostgreSQL, MySQL, SQLite, MongoDB, BigQuery
- Generate optimized SQL with proper joins
- Infer chart type from question (line, bar, pie, histogram)
- Validate SQL before execution
- Return data + visualization config

## Output Contracts

### Migration Success
```json
{
  "status": "success",
  "bundle_url": "https://storage.example.com/bundle.zip",
  "report": {
    "ssim": 0.987,
    "lpips": 0.015,
    "changed_assets": [...],
    "notes": [...]
  },
  "next_steps": [...]
}
````

### Analytics Success

```json
{
  "status": "success",
  "sql": "SELECT...",
  "data": [{...}],
  "visualization": {
    "chart_type": "line",
    "x_axis": {...},
    "y_axis": {...}
  },
  "rows": 42
}
```

## Guardrails

- Only allowed repos
- Never exfiltrate credentials
- Ask for missing inputs: repo URL, baseline URL, database schema
- Keep responses <300 words unless returning JSON
- If SSIM < 0.98 after 3 attempts → return "needs-work"

## Knowledge Base Context

- Odoo 18/19 API reference
- OCA module patterns
- NestJS + Next.js + Prisma best practices
- Tailwind CSS + design tokens
- SSIM/LPIPS visual testing
- SQL generation patterns (all databases)
- Chart.js / Recharts visualization configs

````

---

## 📚 Next Steps

### 1. Complete Remaining Skills (Priority)
```bash
# Create these skill files
skills/visual-parity/SKILL.md       # SSIM/LPIPS validation (detailed)
skills/ai-analytics/SKILL.md        # Natural language analytics (detailed)
skills/prisma-modeling/SKILL.md     # Odoo → Prisma schema
skills/nestjs-api/SKILL.md          # NestJS controller generation
````

### 2. Implement Tool Functions

```bash
# Deploy as Supabase Edge Functions
supabase/functions/repo_fetch/index.ts
supabase/functions/qweb_to_tsx/index.ts
supabase/functions/visual_diff/index.ts
supabase/functions/nl_to_sql/index.ts
supabase/functions/execute_query/index.ts
```

### 3. Create Knowledge Base

```bash
# Populate with reference docs
kb/odoo-reference/           # Odoo 18/19 docs
kb/oca-modules/              # OCA patterns
kb/migration-patterns/       # Proven recipes
kb/sql-patterns/             # SQL generation examples
```

### 4. Build Evaluation Suite

```bash
# Test cases for validation
evals/migration-accuracy.json
evals/visual-parity.json
evals/sql-generation.json
```

### 5. Create Migration Recipes

```bash
# Example conversions
recipes/hr-module-migration.md
recipes/crm-pipeline-migration.md
recipes/analytics-dashboard.md
```

---

## 🚀 Quick Test Commands

### Test Migration

```bash
curl -X POST https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run \
  -H "Authorization: Bearer $AGENT_KEY" \
  -d '{
    "input": "Migrate Odoo HR module from github.com/odoo/odoo/addons/hr"
  }'
```

### Test Analytics

```bash
curl -X POST https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run \
  -H "Authorization: Bearer $AGENT_KEY" \
  -d '{
    "input": "Show me user signups by day for the last 7 days"
  }'
```

---

## ✅ Summary

**Created Today**:

- ✅ 3 core migration skills (odoo-migration, qweb-to-react, design-tokens)
- ✅ AI analytics architecture (LangChain-style, database-agnostic)
- ✅ Updated agent instructions with dual capabilities
- ✅ Tool function specifications (10 functions)

**Total System Capabilities**:

1. **Odoo → NestJS/Next.js migration** with pixel parity
2. **Design token extraction** (SCSS → Tailwind)
3. **Visual validation** (SSIM ≥ 0.98)
4. **AI-powered analytics** (natural language → SQL → charts)
5. **Multi-database support** (PostgreSQL, MySQL, MongoDB, BigQuery, SQLite)
6. **Chart generation** (automatic type inference)

**Infrastructure**:

- DigitalOcean Agent: `odoobo-expert`
- Workspace: `fin-workspace` (Toronto region)
- Endpoint: `https://wr2azp5dsl6mu6xvxtpglk5v.agents.do-ai.run`
- Access Key: `local-dev`

**Next Priority**: Implement the 10 tool functions as Supabase Edge Functions.
