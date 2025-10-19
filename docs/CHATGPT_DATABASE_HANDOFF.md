# ChatGPT Database Operations Handoff

**Date**: 2025-10-19
**Priority**: 🔴 CRITICAL - Run all database operations ASAP
**Assignee**: ChatGPT (Backend/Database Specialist)
**Claude Code Focus**: Frontend, UI components, features (not database)

---

## 🎯 Your Mission (ChatGPT)

You are responsible for **ALL database operations** for the OdoBoo Workspace project. Claude Code will focus on frontend, UI, and features. You handle everything backend/database.

**Environment**:
- Database: Supabase PostgreSQL (project: spdtwktxdalcfigzeqrz)
- Connection: `$POSTGRES_URL` environment variable
- Region: AWS us-east-1
- Access: Service role key in `~/.zshrc`

---

## 📋 Database Operations Checklist

### Phase 1: Core Schema (PRIORITY 1) 🔴

**Status**: ⚠️ NEEDS EXECUTION

**Files to Execute** (in order):

1. ✅ **Notion Workspace Schema**
   ```bash
   psql "$POSTGRES_URL" -f scripts/09_notion_workspace_schema.sql
   ```
   - Creates: content_blocks, database_views, task_dependencies, time_entries, custom_properties, property_values, page_templates
   - Expected: 7 new tables
   - Verify: `\dt` shows all 7 tables

2. ⚠️ **RLS Policies** (NOT YET CREATED - YOU MUST CREATE THIS)
   ```bash
   psql "$POSTGRES_URL" -f scripts/10_notion_workspace_rls.sql
   ```
   - **ACTION REQUIRED**: Create this file first
   - Copy RLS policy SQL from `docs/NOTION_WORKSPACE_DEPLOYMENT.md` (Step 2)
   - Apply company-scoped RLS on all 7 tables
   - Verify: `SELECT * FROM pg_policies WHERE schemaname = 'public'`

3. ⚠️ **Sample Page** (OPTIONAL - for testing)
   ```bash
   psql "$POSTGRES_URL" -f scripts/11_notion_sample_page.sql
   ```
   - Creates demo page with 16 blocks, 5 views, 5 tasks
   - Expected: Success message with counts
   - Verify: `SELECT COUNT(*) FROM content_blocks WHERE page_id = '00000000-0000-0000-0000-000000000100'`

4. ⚠️ **Feature Inventory** (AUTO-DOCUMENTATION)
   ```bash
   psql "$POSTGRES_URL" -f supabase/migrations/003_feature_inventory.sql
   ```
   - Creates: catalog.snapshots, catalog.inventory_current, catalog.inventory_diff
   - Creates: catalog.capture_snapshot() function
   - Creates: pg_cron job for nightly snapshots
   - Verify: `SELECT catalog.capture_snapshot('initial')`

### Phase 2: Agent Registry (PRIORITY 2) 🟡

**Status**: ⚠️ FILE DOES NOT EXIST - YOU MUST CREATE

**Required File**: `supabase/migrations/004_agent_registry.sql`

**Schema to Create**:

```sql
-- CREATE SCHEMA agents for AI agent management
CREATE SCHEMA IF NOT EXISTS agents;

-- TABLE: agents.roles (agent role definitions)
CREATE TABLE IF NOT EXISTS agents.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  skills JSONB NOT NULL DEFAULT '[]'::jsonb,
  mcp_servers JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: agents.skills (reusable skill definitions)
CREATE TABLE IF NOT EXISTS agents.skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('technical', 'business', 'quality', 'security')),
  complexity TEXT NOT NULL CHECK (complexity IN ('basic', 'intermediate', 'advanced', 'expert')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: agents.task_bindings (which agent handles which task type)
CREATE TABLE IF NOT EXISTS agents.task_bindings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES agents.roles(id) ON DELETE CASCADE,
  task_type TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 1,
  conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(role_id, task_type)
);

-- Insert default roles (Odoo/OCA specialists)
INSERT INTO agents.roles (name, description, skills, mcp_servers) VALUES
  ('odoo_core_dev', 'Odoo core framework developer', '["python", "odoo_orm", "xml_views"]'::jsonb, '["context7", "sequential"]'::jsonb),
  ('oca_maintainer', 'OCA module maintainer', '["oca_guidelines", "module_migration", "code_review"]'::jsonb, '["context7", "sequential"]'::jsonb),
  ('frontend_next', 'Next.js frontend developer', '["react", "typescript", "tailwind"]'::jsonb, '["magic", "context7"]'::jsonb),
  ('backend_nest', 'Nest.js backend developer', '["nestjs", "prisma", "api_design"]'::jsonb, '["context7", "sequential"]'::jsonb),
  ('data_supabase', 'Supabase data specialist', '["postgresql", "rls", "edge_functions"]'::jsonb, '["sequential", "context7"]'::jsonb),
  ('devops_do', 'DigitalOcean DevOps engineer', '["do_app_platform", "ci_cd", "monitoring"]'::jsonb, '["sequential", "playwright"]'::jsonb),
  ('doc_extractor_ade', 'Document extraction specialist (ADE)', '["paddleocr", "vision_models", "structured_output"]'::jsonb, '["sequential", "context7"]'::jsonb);

-- Insert default skills
INSERT INTO agents.skills (name, description, category, complexity) VALUES
  ('testing_visual_parity', 'SSIM-based visual regression testing', 'quality', 'advanced'),
  ('migration_qweb_tsx', 'Migrate Odoo QWeb templates to React TSX', 'technical', 'expert'),
  ('schema_guard', 'Database schema drift detection and prevention', 'technical', 'advanced'),
  ('rls_security', 'Row-Level Security policy design and implementation', 'security', 'expert'),
  ('do_pipeline', 'DigitalOcean App Platform deployment automation', 'technical', 'intermediate');

-- Insert task bindings
INSERT INTO agents.task_bindings (role_id, task_type, priority, conditions) VALUES
  ((SELECT id FROM agents.roles WHERE name = 'frontend_next'), 'ui_component', 1, '{}'::jsonb),
  ((SELECT id FROM agents.roles WHERE name = 'backend_nest'), 'api_endpoint', 1, '{}'::jsonb),
  ((SELECT id FROM agents.roles WHERE name = 'data_supabase'), 'database_migration', 1, '{}'::jsonb),
  ((SELECT id FROM agents.roles WHERE name = 'devops_do'), 'deployment', 1, '{}'::jsonb),
  ((SELECT id FROM agents.roles WHERE name = 'doc_extractor_ade'), 'ocr_processing', 1, '{}'::jsonb);

-- Enable RLS
ALTER TABLE agents.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents.task_bindings ENABLE ROW LEVEL SECURITY;

-- RLS policies (read-only for authenticated)
CREATE POLICY agents_roles_select ON agents.roles FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY agents_skills_select ON agents.skills FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY agents_task_bindings_select ON agents.task_bindings FOR SELECT TO authenticated USING (TRUE);

COMMENT ON SCHEMA agents IS 'AI agent registry for task routing and skill management';
COMMENT ON TABLE agents.roles IS 'Agent role definitions with skills and MCP server preferences';
COMMENT ON TABLE agents.skills IS 'Reusable skill library for agent capabilities';
COMMENT ON TABLE agents.task_bindings IS 'Task type to agent role mappings';
```

**Execution**:
```bash
psql "$POSTGRES_URL" -f supabase/migrations/004_agent_registry.sql
```

**Verification**:
```sql
SELECT COUNT(*) FROM agents.roles; -- Should return 7
SELECT COUNT(*) FROM agents.skills; -- Should return 5
SELECT COUNT(*) FROM agents.task_bindings; -- Should return 5
```

### Phase 3: Edge Functions (PRIORITY 3) 🟢

**Status**: ⚠️ NEEDS CREATION

**Required**: Create Supabase Edge Function for feature inventory API

**File**: `supabase/functions/feature-inventory-md/index.ts`

**Purpose**: Generate FEATURE_INVENTORY.md from catalog.snapshots

**You Should Create**:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Fetch latest snapshot
    const { data: snapshot, error } = await supabaseClient
      .from('catalog.inventory_current')
      .select('*')
      .single()

    if (error) throw error

    // Generate markdown
    const markdown = `# Feature Inventory

**Generated**: ${new Date().toISOString()}
**Snapshot**: ${snapshot.taken_at}
**Commit**: ${snapshot.github_commit_sha || 'N/A'}

## Database Objects

### Tables (${snapshot.total_tables})
${JSON.parse(snapshot.tables).map(t => `- \`${t.schema}.${t.table}\` (${t.row_count} rows, ${(t.size_bytes / 1024).toFixed(2)} KB)`).join('\n')}

### Functions (${snapshot.total_functions})
${JSON.parse(snapshot.functions).map(f => `- \`${f.schema}.${f.function}\` → ${f.return_type}`).join('\n')}

### Policies (${snapshot.total_policies})
${JSON.parse(snapshot.policies).map(p => `- \`${p.schema}.${p.table}.${p.policy}\` (${p.command})`).join('\n')}

### Extensions (${snapshot.total_extensions})
${JSON.parse(snapshot.extensions).map(e => `- \`${e.name}\` v${e.version}`).join('\n')}

### Edge Functions (${snapshot.total_edge_functions})
${JSON.parse(snapshot.edge_functions).map(ef => `- \`${ef.name}\``).join('\n')}

---
*Auto-generated by catalog.capture_snapshot()*
`

    return new Response(markdown, {
      headers: { 'Content-Type': 'text/markdown' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

**Deploy**:
```bash
supabase functions deploy feature-inventory-md
```

**Test**:
```bash
curl "https://spdtwktxdalcfigzeqrz.supabase.co/functions/v1/feature-inventory-md" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

### Phase 4: GitHub Actions (PRIORITY 4) 🟢

**Status**: ⚠️ NEEDS CREATION

**Required**: Automated nightly documentation updates

**File**: `.github/workflows/feature-inventory.yml`

**You Should Create**:

```yaml
name: Feature Inventory Auto-Update

on:
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM UTC
  workflow_dispatch: # Manual trigger

jobs:
  update-inventory:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Generate feature inventory
        run: |
          curl -s "https://spdtwktxdalcfigzeqrz.supabase.co/functions/v1/feature-inventory-md" \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
            > docs/FEATURE_INVENTORY.md

      - name: Commit updated inventory
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/FEATURE_INVENTORY.md
          git diff --staged --quiet || git commit -m "docs: auto-update feature inventory [skip ci]"
          git push

      - name: Create summary
        run: |
          echo "## Feature Inventory Updated" >> $GITHUB_STEP_SUMMARY
          echo "Generated: $(date -u)" >> $GITHUB_STEP_SUMMARY
          echo "File: docs/FEATURE_INVENTORY.md" >> $GITHUB_STEP_SUMMARY
```

**Setup Secrets**:
```bash
# Add to GitHub repository secrets
gh secret set SUPABASE_SERVICE_ROLE_KEY --body "$SUPABASE_SERVICE_ROLE_KEY"
```

---

## 🔧 Environment Setup (For You, ChatGPT)

### 1. Get Database Connection String

**Read from ~/.zshrc**:
```bash
source ~/.zshrc
echo $POSTGRES_URL
```

**Format**:
```
postgresql://postgres.spdtwktxdalcfigzeqrz:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

### 2. Verify Access

```bash
# Test connection
psql "$POSTGRES_URL" -c "SELECT version();"

# List existing tables
psql "$POSTGRES_URL" -c "\dt"

# Check current schema
psql "$POSTGRES_URL" -c "SELECT schemaname, COUNT(*) FROM pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema') GROUP BY schemaname;"
```

### 3. Run All Migrations (Your Primary Task)

**Execute in this order**:

```bash
# 1. Notion workspace schema
psql "$POSTGRES_URL" -f scripts/09_notion_workspace_schema.sql

# 2. RLS policies (YOU MUST CREATE THIS FILE FIRST)
# Copy SQL from docs/NOTION_WORKSPACE_DEPLOYMENT.md Step 2
cat > scripts/10_notion_workspace_rls.sql << 'EOF'
-- [PASTE RLS POLICY SQL HERE FROM DEPLOYMENT DOC]
EOF
psql "$POSTGRES_URL" -f scripts/10_notion_workspace_rls.sql

# 3. Sample page (optional, for testing)
psql "$POSTGRES_URL" -f scripts/11_notion_sample_page.sql

# 4. Feature inventory system
psql "$POSTGRES_URL" -f supabase/migrations/003_feature_inventory.sql

# 5. Agent registry (YOU MUST CREATE THIS FILE FIRST)
# Copy SQL from this document (Phase 2)
psql "$POSTGRES_URL" -f supabase/migrations/004_agent_registry.sql

# 6. Capture initial snapshot
psql "$POSTGRES_URL" -c "SELECT catalog.capture_snapshot('chatgpt_initial_setup');"
```

### 4. Verify All Operations

**Run verification script**:

```bash
# Create verification script
cat > scripts/verify_database.sql << 'EOF'
-- Verification: All tables exist
SELECT
  'Tables Created' as check_type,
  COUNT(*) as count,
  jsonb_agg(tablename) as items
FROM pg_tables
WHERE schemaname IN ('public', 'catalog', 'agents')
AND tablename IN (
  'content_blocks', 'database_views', 'task_dependencies', 'time_entries',
  'custom_properties', 'property_values', 'page_templates',
  'snapshots', 'roles', 'skills', 'task_bindings'
);

-- Verification: RLS policies enabled
SELECT
  'RLS Policies' as check_type,
  COUNT(*) as count,
  jsonb_agg(DISTINCT tablename) as tables_with_rls
FROM pg_policies
WHERE schemaname IN ('public', 'catalog', 'agents');

-- Verification: Functions created
SELECT
  'Functions' as check_type,
  COUNT(*) as count,
  jsonb_agg(proname) as function_names
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'catalog'
AND proname IN ('capture_snapshot', 'update_edge_functions');

-- Verification: Cron jobs scheduled
SELECT
  'Cron Jobs' as check_type,
  COUNT(*) as count,
  jsonb_agg(jobname) as jobs
FROM cron.job
WHERE jobname LIKE '%inventory%';

-- Verification: Sample data (if loaded)
SELECT
  'Sample Data' as check_type,
  COUNT(*) as block_count,
  (SELECT COUNT(*) FROM database_views) as view_count,
  (SELECT COUNT(*) FROM project_tasks WHERE project_id = '00000000-0000-0000-0000-000000000300') as task_count
FROM content_blocks
WHERE page_id = '00000000-0000-0000-0000-000000000100';

-- Verification: Agent registry
SELECT
  'Agent Registry' as check_type,
  (SELECT COUNT(*) FROM agents.roles) as role_count,
  (SELECT COUNT(*) FROM agents.skills) as skill_count,
  (SELECT COUNT(*) FROM agents.task_bindings) as binding_count;
EOF

# Run verification
psql "$POSTGRES_URL" -f scripts/verify_database.sql
```

**Expected Results**:
```
check_type        | count | items
------------------+-------+----------------------------------
Tables Created    | 11    | [all table names]
RLS Policies      | 21+   | [tables with RLS]
Functions         | 2     | [capture_snapshot, update_edge_functions]
Cron Jobs         | 1     | [feature_inventory_snapshot]
Sample Data       | 16    | view_count: 5, task_count: 5
Agent Registry    | -     | role_count: 7, skill_count: 5, binding_count: 5
```

---

## 🚨 Error Handling

### Error: "relation already exists"

**Cause**: Table already created

**Solution**: Drop and recreate
```sql
DROP TABLE IF EXISTS [table_name] CASCADE;
-- Then re-run migration
```

### Error: "permission denied for schema"

**Cause**: Insufficient privileges

**Solution**: Use service role key
```bash
# Verify you're using service role, not anon key
echo $SUPABASE_SERVICE_ROLE_KEY | grep "service_role"
```

### Error: "column does not exist"

**Cause**: Missing previous migration

**Solution**: Run migrations in order (see Step 3)

### Error: "pg_cron extension not available"

**Cause**: Extension not enabled in Supabase

**Solution**: Enable via Supabase dashboard
```
Dashboard → Database → Extensions → Enable "pg_cron"
```

---

## 📊 Success Criteria

**You will know you're done when**:

✅ **All 4 schemas exist**: `public`, `catalog`, `agents`, (existing schemas)
✅ **11 new tables created**: 7 Notion tables + 3 catalog tables + 3 agent tables (excluding existing tables like knowledge_pages, project_tasks, companies, auth.users)
✅ **21+ RLS policies active**: All tables have company-scoped or read-only policies
✅ **2 functions created**: `catalog.capture_snapshot()`, `catalog.update_edge_functions()`
✅ **1 cron job scheduled**: Nightly feature inventory at 2 AM UTC
✅ **Sample page loaded**: 16 blocks, 5 views, 5 tasks visible
✅ **Agent registry populated**: 7 roles, 5 skills, 5 task bindings
✅ **Initial snapshot captured**: `catalog.snapshots` has at least 1 row

**Verification Command** (run this when done):
```bash
psql "$POSTGRES_URL" -f scripts/verify_database.sql
```

---

## 🤝 Handoff Back to Claude Code

**When you're done with all database operations, report**:

1. ✅ **Migration Status**: Which migrations succeeded/failed
2. ✅ **Table Counts**: How many tables/functions/policies created
3. ✅ **Sample Data**: Whether sample page loaded successfully
4. ✅ **Verification Results**: Output of `verify_database.sql`
5. ✅ **Any Errors**: Issues encountered and how you resolved them

**Then Claude Code will**:
- Build frontend components (BlockEditor, TableView, etc.)
- Create UI for database views
- Implement real-time collaboration
- Deploy to Vercel

**You (ChatGPT) should NOT**:
- Touch frontend code (React, TypeScript, Tailwind)
- Create UI components
- Modify Next.js app directory
- Deploy to Vercel

**Stay in your lane**: Database, SQL, migrations, backend only.

---

## 📞 Communication Protocol

### When You Need Help

**Tag Claude Code with**:
```
@ClaudeCode: [specific question about frontend integration]
```

### When You're Blocked

**Report to user**:
```
⚠️ BLOCKED: [issue description]
Attempted: [what you tried]
Need: [what's missing]
```

### When You're Done

**Final Report Format**:
```
✅ DATABASE OPERATIONS COMPLETE

Migrations Applied:
- ✅ 09_notion_workspace_schema.sql
- ✅ 10_notion_workspace_rls.sql
- ✅ 11_notion_sample_page.sql
- ✅ 003_feature_inventory.sql
- ✅ 004_agent_registry.sql

Objects Created:
- Tables: 11
- Functions: 2
- Policies: 21
- Cron Jobs: 1
- Sample Blocks: 16
- Agent Roles: 7

Verification: [PASS/FAIL]
Next Steps: Frontend development (Claude Code)
```

---

## 🎯 Priority Order (Do These First)

1. 🔴 **Phase 1**: Notion workspace schema + RLS policies + sample page
2. 🟡 **Phase 2**: Agent registry (create file then apply)
3. 🟢 **Phase 3**: Feature inventory (already created, just apply)
4. 🟢 **Phase 4**: Edge Functions + GitHub Actions (optional for MVP)

**Time Estimate**: 1-2 hours for all operations

**Blocked Until**: You create `scripts/10_notion_workspace_rls.sql` and `supabase/migrations/004_agent_registry.sql`

---

**Start with Phase 1, then report progress.**

Good luck! 🚀
