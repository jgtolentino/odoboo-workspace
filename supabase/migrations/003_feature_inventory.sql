-- Migration: Feature Inventory System
-- Description: Auto-generates living documentation of all database objects
-- Purpose: Nightly refresh of FEATURE_INVENTORY.md via Edge Function + GitHub Action
-- Author: Claude Code + SuperClaude Framework
-- Date: 2025-10-19

-- ============================================================================
-- SCHEMA: catalog (Feature Inventory & Lineage Tracking)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS catalog;
COMMENT ON SCHEMA catalog IS 'Feature inventory, entity lineage, and system metadata tracking';

-- ============================================================================
-- TABLE: catalog.snapshots
-- Purpose: Store nightly snapshots of all database objects for drift detection
-- ============================================================================

CREATE TABLE IF NOT EXISTS catalog.snapshots (
  id BIGSERIAL PRIMARY KEY,
  taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Database objects (JSONB for flexibility)
  tables JSONB NOT NULL DEFAULT '[]'::jsonb,
  functions JSONB NOT NULL DEFAULT '[]'::jsonb,
  extensions JSONB NOT NULL DEFAULT '[]'::jsonb,
  policies JSONB NOT NULL DEFAULT '[]'::jsonb,
  edge_functions JSONB NOT NULL DEFAULT '[]'::jsonb,
  triggers JSONB NOT NULL DEFAULT '[]'::jsonb,
  views JSONB NOT NULL DEFAULT '[]'::jsonb,
  indexes JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- Application metadata
  github_commit_sha TEXT,
  deployment_id TEXT,

  -- Metrics
  total_tables INTEGER GENERATED ALWAYS AS (jsonb_array_length(tables)) STORED,
  total_functions INTEGER GENERATED ALWAYS AS (jsonb_array_length(functions)) STORED,
  total_policies INTEGER GENERATED ALWAYS AS (jsonb_array_length(policies)) STORED,

  CONSTRAINT snapshots_taken_at_unique UNIQUE (taken_at)
);

CREATE INDEX idx_snapshots_taken_at ON catalog.snapshots(taken_at DESC);
CREATE INDEX idx_snapshots_commit ON catalog.snapshots(github_commit_sha) WHERE github_commit_sha IS NOT NULL;

COMMENT ON TABLE catalog.snapshots IS 'Nightly snapshots of database schema and objects for inventory and drift detection';
COMMENT ON COLUMN catalog.snapshots.tables IS 'JSON array of {schema, table_name, row_count, size_bytes}';
COMMENT ON COLUMN catalog.snapshots.functions IS 'JSON array of {schema, function_name, return_type, language}';
COMMENT ON COLUMN catalog.snapshots.policies IS 'JSON array of {schema, table, policy_name, roles, command}';

-- ============================================================================
-- VIEW: catalog.inventory_current
-- Purpose: Latest snapshot formatted for easy querying
-- ============================================================================

CREATE OR REPLACE VIEW catalog.inventory_current AS
SELECT
  taken_at,
  github_commit_sha,

  -- Counts
  total_tables,
  total_functions,
  total_policies,
  jsonb_array_length(extensions) as total_extensions,
  jsonb_array_length(edge_functions) as total_edge_functions,
  jsonb_array_length(triggers) as total_triggers,
  jsonb_array_length(views) as total_views,
  jsonb_array_length(indexes) as total_indexes,

  -- Raw data
  tables,
  functions,
  extensions,
  policies,
  edge_functions,
  triggers,
  views,
  indexes
FROM catalog.snapshots
WHERE id = (SELECT MAX(id) FROM catalog.snapshots);

COMMENT ON VIEW catalog.inventory_current IS 'Most recent feature inventory snapshot';

-- ============================================================================
-- VIEW: catalog.inventory_diff
-- Purpose: Detect changes between last two snapshots
-- ============================================================================

CREATE OR REPLACE VIEW catalog.inventory_diff AS
WITH latest_two AS (
  SELECT * FROM catalog.snapshots
  ORDER BY taken_at DESC
  LIMIT 2
),
current AS (SELECT * FROM latest_two ORDER BY taken_at DESC LIMIT 1),
previous AS (SELECT * FROM latest_two ORDER BY taken_at ASC LIMIT 1)
SELECT
  current.taken_at as current_snapshot,
  previous.taken_at as previous_snapshot,

  -- Table changes
  (current.total_tables - previous.total_tables) as tables_added,

  -- Function changes
  (current.total_functions - previous.total_functions) as functions_added,

  -- Policy changes
  (current.total_policies - previous.total_policies) as policies_added,

  -- New tables (in current but not in previous)
  (
    SELECT jsonb_agg(t)
    FROM jsonb_array_elements(current.tables) t
    WHERE NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(previous.tables) p
      WHERE p->>'table_name' = t->>'table_name'
        AND p->>'table_schema' = t->>'table_schema'
    )
  ) as new_tables,

  -- Dropped tables (in previous but not in current)
  (
    SELECT jsonb_agg(t)
    FROM jsonb_array_elements(previous.tables) t
    WHERE NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(current.tables) c
      WHERE c->>'table_name' = t->>'table_name'
        AND c->>'table_schema' = t->>'table_schema'
    )
  ) as dropped_tables
FROM current, previous
WHERE current.id != previous.id;

COMMENT ON VIEW catalog.inventory_diff IS 'Schema drift detection between last two snapshots';

-- ============================================================================
-- FUNCTION: catalog.capture_snapshot()
-- Purpose: Capture current state of all database objects
-- ============================================================================

CREATE OR REPLACE FUNCTION catalog.capture_snapshot(
  p_commit_sha TEXT DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_snapshot_id BIGINT;
  v_tables JSONB;
  v_functions JSONB;
  v_extensions JSONB;
  v_policies JSONB;
  v_triggers JSONB;
  v_views JSONB;
  v_indexes JSONB;
BEGIN
  -- Capture tables with row counts and sizes
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', schemaname,
      'table', tablename,
      'row_count', (
        SELECT reltuples::bigint
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = schemaname AND c.relname = tablename
      ),
      'size_bytes', pg_total_relation_size(schemaname||'.'||tablename)
    )
  )
  INTO v_tables
  FROM pg_tables
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'auth', 'storage', 'realtime', 'supabase_migrations');

  -- Capture functions
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', n.nspname,
      'function', p.proname,
      'return_type', pg_get_function_result(p.oid),
      'language', l.lanname,
      'security', CASE WHEN p.prosecdef THEN 'definer' ELSE 'invoker' END
    )
  )
  INTO v_functions
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  JOIN pg_language l ON l.oid = p.prolang
  WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND p.prokind = 'f'; -- Functions only, not aggregates/procedures

  -- Capture extensions
  SELECT jsonb_agg(
    jsonb_build_object(
      'name', extname,
      'version', extversion,
      'schema', (SELECT nspname FROM pg_namespace WHERE oid = extnamespace)
    )
  )
  INTO v_extensions
  FROM pg_extension
  WHERE extname NOT IN ('plpgsql'); -- Exclude built-in

  -- Capture RLS policies
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', schemaname,
      'table', tablename,
      'policy', policyname,
      'roles', roles,
      'command', cmd,
      'permissive', permissive
    )
  )
  INTO v_policies
  FROM pg_policies;

  -- Capture triggers
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', n.nspname,
      'table', c.relname,
      'trigger', t.tgname,
      'function', p.proname,
      'timing', CASE t.tgtype & 2 WHEN 2 THEN 'BEFORE' ELSE 'AFTER' END,
      'event', CASE t.tgtype & 28
        WHEN 4 THEN 'INSERT'
        WHEN 8 THEN 'DELETE'
        WHEN 16 THEN 'UPDATE'
        ELSE 'OTHER'
      END
    )
  )
  INTO v_triggers
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  JOIN pg_proc p ON p.oid = t.tgfoid
  WHERE NOT t.tgisinternal
    AND n.nspname NOT IN ('pg_catalog', 'information_schema');

  -- Capture views
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', schemaname,
      'view', viewname,
      'is_materialized', FALSE
    )
  )
  INTO v_views
  FROM pg_views
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  UNION ALL
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', schemaname,
      'view', matviewname,
      'is_materialized', TRUE
    )
  )
  FROM pg_matviews
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

  -- Capture indexes
  SELECT jsonb_agg(
    jsonb_build_object(
      'schema', schemaname,
      'table', tablename,
      'index', indexname,
      'definition', indexdef,
      'is_unique', (SELECT indisunique FROM pg_index WHERE indexrelid = (schemaname||'.'||indexname)::regclass)
    )
  )
  INTO v_indexes
  FROM pg_indexes
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

  -- Insert snapshot
  INSERT INTO catalog.snapshots (
    taken_at,
    tables,
    functions,
    extensions,
    policies,
    edge_functions,
    triggers,
    views,
    indexes,
    github_commit_sha
  )
  VALUES (
    NOW(),
    COALESCE(v_tables, '[]'::jsonb),
    COALESCE(v_functions, '[]'::jsonb),
    COALESCE(v_extensions, '[]'::jsonb),
    COALESCE(v_policies, '[]'::jsonb),
    '[]'::jsonb, -- Edge functions populated separately
    COALESCE(v_triggers, '[]'::jsonb),
    COALESCE(v_views, '[]'::jsonb),
    COALESCE(v_indexes, '[]'::jsonb),
    p_commit_sha
  )
  RETURNING id INTO v_snapshot_id;

  RAISE NOTICE 'Snapshot % captured: % tables, % functions, % policies',
    v_snapshot_id,
    jsonb_array_length(COALESCE(v_tables, '[]'::jsonb)),
    jsonb_array_length(COALESCE(v_functions, '[]'::jsonb)),
    jsonb_array_length(COALESCE(v_policies, '[]'::jsonb));

  RETURN v_snapshot_id;
END;
$$;

COMMENT ON FUNCTION catalog.capture_snapshot IS 'Capture snapshot of all database objects for feature inventory';

-- ============================================================================
-- FUNCTION: catalog.update_edge_functions()
-- Purpose: Update edge_functions field in latest snapshot (called from Edge Function)
-- ============================================================================

CREATE OR REPLACE FUNCTION catalog.update_edge_functions(
  p_edge_functions JSONB
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE catalog.snapshots
  SET edge_functions = p_edge_functions
  WHERE id = (SELECT MAX(id) FROM catalog.snapshots);

  RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION catalog.update_edge_functions IS 'Update edge_functions field in latest snapshot (called from Edge Function)';

-- ============================================================================
-- CRON JOB: Nightly snapshot at 2 AM UTC
-- ============================================================================

SELECT cron.schedule(
  'feature_inventory_snapshot',
  '0 2 * * *', -- 2 AM UTC daily
  $$
    SELECT catalog.capture_snapshot(NULL);
  $$
);

COMMENT ON EXTENSION pg_cron IS 'Cron-based job scheduler including nightly feature inventory';

-- ============================================================================
-- INITIAL SNAPSHOT: Capture current state
-- ============================================================================

SELECT catalog.capture_snapshot('initial_snapshot');

-- ============================================================================
-- GRANTS: Allow service role to query inventory
-- ============================================================================

GRANT USAGE ON SCHEMA catalog TO service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA catalog TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA catalog TO service_role;

-- ============================================================================
-- RLS: Inventory is read-only for authenticated users
-- ============================================================================

ALTER TABLE catalog.snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY snapshots_read_all ON catalog.snapshots
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
