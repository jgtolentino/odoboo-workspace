-- Migration State Tracking
-- This MUST be the first migration to run
-- Tracks which migrations have been applied and provides rollback capability

-- Migration tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  checksum TEXT NOT NULL,
  execution_time_ms INTEGER,
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed', 'rolled_back')),
  error_message TEXT,
  applied_by TEXT
);

-- Migration history for rollbacks
CREATE TABLE IF NOT EXISTS migration_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version TEXT NOT NULL REFERENCES schema_migrations(version),
  action TEXT NOT NULL CHECK (action IN ('apply', 'rollback')),
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  execution_time_ms INTEGER,
  status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
  error_message TEXT,
  executed_by TEXT,
  environment TEXT -- 'staging', 'production', 'development'
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_schema_migrations_status ON schema_migrations(status);
CREATE INDEX IF NOT EXISTS idx_schema_migrations_applied_at ON schema_migrations(applied_at);
CREATE INDEX IF NOT EXISTS idx_migration_history_version ON migration_history(version);
CREATE INDEX IF NOT EXISTS idx_migration_history_executed_at ON migration_history(executed_at);

-- Function to validate migration checksum
CREATE OR REPLACE FUNCTION validate_migration_checksum(
  p_version TEXT,
  p_checksum TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_stored_checksum TEXT;
BEGIN
  SELECT checksum INTO v_stored_checksum
  FROM schema_migrations
  WHERE version = p_version AND status = 'completed';

  IF v_stored_checksum IS NULL THEN
    RETURN TRUE; -- Migration not applied yet
  END IF;

  RETURN v_stored_checksum = p_checksum;
END;
$$ LANGUAGE plpgsql;

-- Function to record migration start
CREATE OR REPLACE FUNCTION start_migration(
  p_version TEXT,
  p_name TEXT,
  p_checksum TEXT,
  p_executed_by TEXT DEFAULT 'system'
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO schema_migrations (version, name, checksum, status, applied_by)
  VALUES (p_version, p_name, p_checksum, 'running', p_executed_by)
  ON CONFLICT (version) DO UPDATE
  SET status = 'running',
      applied_at = NOW(),
      applied_by = p_executed_by;
END;
$$ LANGUAGE plpgsql;

-- Function to record migration completion
CREATE OR REPLACE FUNCTION complete_migration(
  p_version TEXT,
  p_execution_time_ms INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE schema_migrations
  SET status = 'completed',
      execution_time_ms = p_execution_time_ms,
      error_message = NULL
  WHERE version = p_version;

  INSERT INTO migration_history (version, action, execution_time_ms, status)
  VALUES (p_version, 'apply', p_execution_time_ms, 'success');
END;
$$ LANGUAGE plpgsql;

-- Function to record migration failure
CREATE OR REPLACE FUNCTION fail_migration(
  p_version TEXT,
  p_error_message TEXT,
  p_execution_time_ms INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  UPDATE schema_migrations
  SET status = 'failed',
      error_message = p_error_message,
      execution_time_ms = p_execution_time_ms
  WHERE version = p_version;

  INSERT INTO migration_history (version, action, execution_time_ms, status, error_message)
  VALUES (p_version, 'apply', p_execution_time_ms, 'failed', p_error_message);
END;
$$ LANGUAGE plpgsql;

-- Function to get pending migrations
CREATE OR REPLACE FUNCTION get_pending_migrations()
RETURNS TABLE (
  version TEXT,
  name TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT sm.version, sm.name, sm.status
  FROM schema_migrations sm
  WHERE sm.status IN ('pending', 'failed')
  ORDER BY sm.version;
END;
$$ LANGUAGE plpgsql;

-- Function to get migration status
CREATE OR REPLACE FUNCTION get_migration_status()
RETURNS TABLE (
  total_migrations BIGINT,
  completed BIGINT,
  failed BIGINT,
  pending BIGINT,
  last_migration TEXT,
  last_applied_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT as total_migrations,
    COUNT(*) FILTER (WHERE status = 'completed')::BIGINT as completed,
    COUNT(*) FILTER (WHERE status = 'failed')::BIGINT as failed,
    COUNT(*) FILTER (WHERE status = 'pending')::BIGINT as pending,
    MAX(version) FILTER (WHERE status = 'completed') as last_migration,
    MAX(applied_at) FILTER (WHERE status = 'completed') as last_applied_at
  FROM schema_migrations;
END;
$$ LANGUAGE plpgsql;

-- View for migration status dashboard
CREATE OR REPLACE VIEW migration_status_view AS
SELECT
  sm.version,
  sm.name,
  sm.status,
  sm.applied_at,
  sm.execution_time_ms,
  sm.error_message,
  sm.applied_by,
  (
    SELECT COUNT(*)
    FROM migration_history mh
    WHERE mh.version = sm.version
  ) as execution_count
FROM schema_migrations sm
ORDER BY sm.version DESC;

COMMENT ON TABLE schema_migrations IS 'Tracks database migration state with checksums for safety';
COMMENT ON TABLE migration_history IS 'Audit log of all migration executions and rollbacks';
COMMENT ON FUNCTION validate_migration_checksum IS 'Validates that migration file has not been modified after application';
COMMENT ON FUNCTION start_migration IS 'Records the start of a migration execution';
COMMENT ON FUNCTION complete_migration IS 'Records successful migration completion';
COMMENT ON FUNCTION fail_migration IS 'Records migration failure with error details';
COMMENT ON VIEW migration_status_view IS 'Dashboard view of migration status';
