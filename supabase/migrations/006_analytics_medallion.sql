-- =====================================================
-- MEDALLION ARCHITECTURE FOR ANALYTICS
-- Bronze (Raw) → Silver (Cleaned) → Gold (Aggregated)
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- =====================================================
-- BRONZE LAYER (Raw Data)
-- =====================================================

-- Raw Events Table
CREATE TABLE IF NOT EXISTS analytics.events_raw (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL,
  user_id UUID,
  session_id TEXT,
  properties JSONB,
  user_agent TEXT,
  ip_address INET,
  referrer TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata for data quality tracking
  source TEXT NOT NULL, -- 'web', 'mobile', 'api'
  ingested_at TIMESTAMPTZ DEFAULT NOW()
);

-- Raw API Logs Table
CREATE TABLE IF NOT EXISTS analytics.api_logs_raw (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  method TEXT NOT NULL,
  path TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER,
  user_id UUID,
  request_body JSONB,
  response_body JSONB,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata
  source TEXT NOT NULL,
  ingested_at TIMESTAMPTZ DEFAULT NOW()
);

-- Raw User Actions Table
CREATE TABLE IF NOT EXISTS analytics.user_actions_raw (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata
  source TEXT NOT NULL,
  ingested_at TIMESTAMPTZ DEFAULT NOW()
);

-- Raw Transactions Table
CREATE TABLE IF NOT EXISTS analytics.transactions_raw (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  payment_method TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata
  source TEXT NOT NULL,
  ingested_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Bronze Layer
CREATE INDEX IF NOT EXISTS idx_events_raw_created ON analytics.events_raw(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_raw_user ON analytics.events_raw(user_id);
CREATE INDEX IF NOT EXISTS idx_events_raw_type ON analytics.events_raw(event_type);

CREATE INDEX IF NOT EXISTS idx_api_logs_raw_created ON analytics.api_logs_raw(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_logs_raw_user ON analytics.api_logs_raw(user_id);
CREATE INDEX IF NOT EXISTS idx_api_logs_raw_path ON analytics.api_logs_raw(path);

CREATE INDEX IF NOT EXISTS idx_user_actions_raw_created ON analytics.user_actions_raw(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_actions_raw_user ON analytics.user_actions_raw(user_id);

CREATE INDEX IF NOT EXISTS idx_transactions_raw_created ON analytics.transactions_raw(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_raw_user ON analytics.transactions_raw(user_id);

-- =====================================================
-- SILVER LAYER (Cleaned Data)
-- =====================================================

-- Cleaned Events Table
CREATE TABLE IF NOT EXISTS analytics.events_clean (
  id UUID PRIMARY KEY,
  event_type TEXT NOT NULL,
  user_id UUID,
  session_id TEXT,
  properties JSONB,
  user_agent TEXT,
  ip_address INET,
  referrer TEXT,
  created_at TIMESTAMPTZ NOT NULL,

  -- Metadata
  source TEXT NOT NULL,
  ingested_at TIMESTAMPTZ NOT NULL,
  cleaned_at TIMESTAMPTZ DEFAULT NOW(),

  -- Data quality flags
  is_valid BOOLEAN DEFAULT TRUE,
  quality_score DECIMAL(3, 2) DEFAULT 1.00, -- 0.00 to 1.00
  validation_errors JSONB
);

-- Cleaned API Logs Table
CREATE TABLE IF NOT EXISTS analytics.api_logs_clean (
  id UUID PRIMARY KEY,
  method TEXT NOT NULL,
  path TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER,
  user_id UUID,
  request_body JSONB,
  response_body JSONB,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL,

  -- Metadata
  source TEXT NOT NULL,
  ingested_at TIMESTAMPTZ NOT NULL,
  cleaned_at TIMESTAMPTZ DEFAULT NOW(),

  -- Data quality flags
  is_valid BOOLEAN DEFAULT TRUE,
  quality_score DECIMAL(3, 2) DEFAULT 1.00,
  validation_errors JSONB
);

-- User Sessions Table (Derived from Events)
CREATE TABLE IF NOT EXISTS analytics.user_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  session_id TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  event_count INTEGER DEFAULT 0,
  page_views INTEGER DEFAULT 0,

  -- Session details
  landing_page TEXT,
  exit_page TEXT,
  referrer TEXT,
  device_type TEXT,
  browser TEXT,
  os TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Validated Transactions Table
CREATE TABLE IF NOT EXISTS analytics.transactions_validated (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  payment_method TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL,

  -- Validation flags
  is_valid BOOLEAN DEFAULT TRUE,
  is_duplicate BOOLEAN DEFAULT FALSE,
  is_fraud BOOLEAN DEFAULT FALSE,
  fraud_score DECIMAL(3, 2), -- 0.00 to 1.00

  -- Metadata
  source TEXT NOT NULL,
  ingested_at TIMESTAMPTZ NOT NULL,
  validated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Silver Layer
CREATE INDEX IF NOT EXISTS idx_events_clean_created ON analytics.events_clean(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_clean_user ON analytics.events_clean(user_id);
CREATE INDEX IF NOT EXISTS idx_events_clean_valid ON analytics.events_clean(is_valid);

CREATE INDEX IF NOT EXISTS idx_api_logs_clean_created ON analytics.api_logs_clean(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_logs_clean_user ON analytics.api_logs_clean(user_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON analytics.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_started ON analytics.user_sessions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_transactions_validated_user ON analytics.transactions_validated(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_validated_created ON analytics.transactions_validated(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_validated_valid ON analytics.transactions_validated(is_valid);

-- =====================================================
-- GOLD LAYER (Aggregated Analytics)
-- =====================================================

-- Daily Metrics Table
CREATE TABLE IF NOT EXISTS analytics.daily_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,

  -- User metrics
  active_users INTEGER DEFAULT 0,
  new_users INTEGER DEFAULT 0,
  returning_users INTEGER DEFAULT 0,

  -- Engagement metrics
  total_sessions INTEGER DEFAULT 0,
  avg_session_duration_seconds DECIMAL(10, 2),
  total_events INTEGER DEFAULT 0,
  avg_events_per_session DECIMAL(10, 2),

  -- Revenue metrics
  total_revenue DECIMAL(12, 2) DEFAULT 0.00,
  total_transactions INTEGER DEFAULT 0,
  avg_transaction_value DECIMAL(12, 2),

  -- API metrics
  total_requests INTEGER DEFAULT 0,
  avg_response_time_ms DECIMAL(10, 2),
  error_rate DECIMAL(5, 4), -- 0.0000 to 1.0000

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_daily_metrics UNIQUE (date)
);

-- User Cohorts Table
CREATE TABLE IF NOT EXISTS analytics.user_cohorts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cohort_month DATE NOT NULL, -- First day of month when user joined

  -- Retention metrics by month
  month_0_users INTEGER DEFAULT 0, -- First month (100%)
  month_1_users INTEGER DEFAULT 0,
  month_2_users INTEGER DEFAULT 0,
  month_3_users INTEGER DEFAULT 0,
  month_6_users INTEGER DEFAULT 0,
  month_12_users INTEGER DEFAULT 0,

  -- Retention rates
  month_1_retention DECIMAL(5, 4),
  month_3_retention DECIMAL(5, 4),
  month_12_retention DECIMAL(5, 4),

  -- Revenue metrics
  total_revenue DECIMAL(12, 2) DEFAULT 0.00,
  avg_revenue_per_user DECIMAL(12, 2),

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_user_cohort UNIQUE (cohort_month)
);

-- Revenue Summary Table
CREATE TABLE IF NOT EXISTS analytics.revenue_summary (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,

  -- Revenue breakdown
  total_revenue DECIMAL(12, 2) DEFAULT 0.00,
  new_customer_revenue DECIMAL(12, 2) DEFAULT 0.00,
  returning_customer_revenue DECIMAL(12, 2) DEFAULT 0.00,

  -- Transaction metrics
  total_transactions INTEGER DEFAULT 0,
  successful_transactions INTEGER DEFAULT 0,
  failed_transactions INTEGER DEFAULT 0,

  -- Payment method breakdown
  credit_card_revenue DECIMAL(12, 2) DEFAULT 0.00,
  paypal_revenue DECIMAL(12, 2) DEFAULT 0.00,
  other_revenue DECIMAL(12, 2) DEFAULT 0.00,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_revenue_summary UNIQUE (date)
);

-- KPI Dashboard Table (Materialized View Alternative)
CREATE TABLE IF NOT EXISTS analytics.kpi_dashboard (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metric_name TEXT NOT NULL,
  metric_value DECIMAL(12, 2) NOT NULL,
  metric_unit TEXT, -- 'count', 'percentage', 'currency', 'seconds'
  time_period TEXT NOT NULL, -- 'today', 'week', 'month', 'quarter', 'year'

  -- Comparison metrics
  previous_value DECIMAL(12, 2),
  change_percentage DECIMAL(6, 2),
  trend TEXT, -- 'up', 'down', 'stable'

  -- Metadata
  calculated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_kpi UNIQUE (metric_name, time_period)
);

-- Indexes for Gold Layer
CREATE INDEX IF NOT EXISTS idx_daily_metrics_date ON analytics.daily_metrics(date DESC);
CREATE INDEX IF NOT EXISTS idx_user_cohorts_month ON analytics.user_cohorts(cohort_month DESC);
CREATE INDEX IF NOT EXISTS idx_revenue_summary_date ON analytics.revenue_summary(date DESC);
CREATE INDEX IF NOT EXISTS idx_kpi_dashboard_name ON analytics.kpi_dashboard(metric_name);
CREATE INDEX IF NOT EXISTS idx_kpi_dashboard_period ON analytics.kpi_dashboard(time_period);

-- =====================================================
-- ETL FUNCTIONS (Bronze → Silver)
-- =====================================================

-- Clean Events Function
CREATE OR REPLACE FUNCTION analytics.clean_events()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows_processed INTEGER;
BEGIN
  -- Insert new cleaned events
  INSERT INTO analytics.events_clean (
    id, event_type, user_id, session_id, properties,
    user_agent, ip_address, referrer, created_at,
    source, ingested_at, is_valid, quality_score
  )
  SELECT
    e.id,
    e.event_type,
    e.user_id,
    e.session_id,
    e.properties,
    e.user_agent,
    e.ip_address,
    e.referrer,
    e.created_at,
    e.source,
    e.ingested_at,
    -- Validation logic
    (e.event_type IS NOT NULL AND e.created_at IS NOT NULL) as is_valid,
    CASE
      WHEN e.event_type IS NULL THEN 0.00
      WHEN e.user_id IS NULL THEN 0.50
      WHEN e.session_id IS NULL THEN 0.70
      ELSE 1.00
    END as quality_score
  FROM analytics.events_raw e
  WHERE NOT EXISTS (
    SELECT 1 FROM analytics.events_clean ec WHERE ec.id = e.id
  );

  GET DIAGNOSTICS v_rows_processed = ROW_COUNT;
  RETURN v_rows_processed;
END;
$$;

-- Validate Transactions Function
CREATE OR REPLACE FUNCTION analytics.validate_transactions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows_processed INTEGER;
BEGIN
  -- Insert validated transactions
  INSERT INTO analytics.transactions_validated (
    id, user_id, amount, currency, status, payment_method,
    metadata, created_at, source, ingested_at,
    is_valid, is_duplicate, fraud_score
  )
  SELECT
    t.id,
    t.user_id,
    t.amount,
    t.currency,
    t.status,
    t.payment_method,
    t.metadata,
    t.created_at,
    t.source,
    t.ingested_at,
    -- Validation logic
    (t.amount > 0 AND t.currency IS NOT NULL) as is_valid,
    -- Check for duplicates (same user, amount, within 1 minute)
    EXISTS (
      SELECT 1 FROM analytics.transactions_raw t2
      WHERE t2.user_id = t.user_id
      AND t2.amount = t.amount
      AND t2.created_at BETWEEN t.created_at - interval '1 minute' AND t.created_at
      AND t2.id < t.id
    ) as is_duplicate,
    -- Simple fraud score (sophisticated logic would go here)
    CASE
      WHEN t.amount > 10000 THEN 0.80
      WHEN t.amount > 5000 THEN 0.50
      ELSE 0.10
    END as fraud_score
  FROM analytics.transactions_raw t
  WHERE NOT EXISTS (
    SELECT 1 FROM analytics.transactions_validated tv WHERE tv.id = t.id
  );

  GET DIAGNOSTICS v_rows_processed = ROW_COUNT;
  RETURN v_rows_processed;
END;
$$;

-- Build User Sessions Function
CREATE OR REPLACE FUNCTION analytics.build_user_sessions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows_processed INTEGER;
BEGIN
  -- Create or update sessions from events
  INSERT INTO analytics.user_sessions (
    user_id, session_id, started_at, ended_at, duration_seconds,
    event_count, page_views, landing_page, referrer
  )
  SELECT
    user_id,
    session_id,
    MIN(created_at) as started_at,
    MAX(created_at) as ended_at,
    EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at)))::INTEGER as duration_seconds,
    COUNT(*) as event_count,
    COUNT(*) FILTER (WHERE event_type = 'page_view') as page_views,
    (SELECT properties->>'page' FROM analytics.events_clean
     WHERE session_id = e.session_id AND event_type = 'page_view'
     ORDER BY created_at LIMIT 1) as landing_page,
    (SELECT referrer FROM analytics.events_clean
     WHERE session_id = e.session_id
     ORDER BY created_at LIMIT 1) as referrer
  FROM analytics.events_clean e
  WHERE is_valid = TRUE
  GROUP BY user_id, session_id
  ON CONFLICT (id) DO UPDATE SET
    ended_at = EXCLUDED.ended_at,
    duration_seconds = EXCLUDED.duration_seconds,
    event_count = EXCLUDED.event_count,
    page_views = EXCLUDED.page_views,
    updated_at = NOW();

  GET DIAGNOSTICS v_rows_processed = ROW_COUNT;
  RETURN v_rows_processed;
END;
$$;

-- =====================================================
-- AGGREGATION FUNCTIONS (Silver → Gold)
-- =====================================================

-- Calculate Daily Metrics Function
CREATE OR REPLACE FUNCTION analytics.calculate_daily_metrics(p_date DATE)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Upsert daily metrics
  INSERT INTO analytics.daily_metrics (
    date,
    active_users,
    new_users,
    returning_users,
    total_sessions,
    avg_session_duration_seconds,
    total_events,
    avg_events_per_session,
    total_revenue,
    total_transactions,
    avg_transaction_value,
    total_requests,
    avg_response_time_ms,
    error_rate
  )
  SELECT
    p_date,
    -- User metrics
    COUNT(DISTINCT s.user_id) as active_users,
    COUNT(DISTINCT s.user_id) FILTER (
      WHERE s.started_at::DATE = p_date
      AND NOT EXISTS (
        SELECT 1 FROM analytics.user_sessions s2
        WHERE s2.user_id = s.user_id AND s2.started_at::DATE < p_date
      )
    ) as new_users,
    COUNT(DISTINCT s.user_id) FILTER (
      WHERE EXISTS (
        SELECT 1 FROM analytics.user_sessions s2
        WHERE s2.user_id = s.user_id AND s2.started_at::DATE < p_date
      )
    ) as returning_users,
    -- Engagement metrics
    COUNT(*) as total_sessions,
    AVG(s.duration_seconds) as avg_session_duration_seconds,
    SUM(s.event_count) as total_events,
    AVG(s.event_count) as avg_events_per_session,
    -- Revenue metrics
    COALESCE(SUM(t.amount), 0) as total_revenue,
    COUNT(t.id) as total_transactions,
    AVG(t.amount) as avg_transaction_value,
    -- API metrics
    COUNT(a.id) as total_requests,
    AVG(a.response_time_ms) as avg_response_time_ms,
    COUNT(*) FILTER (WHERE a.status_code >= 400)::DECIMAL / NULLIF(COUNT(*), 0) as error_rate
  FROM analytics.user_sessions s
  LEFT JOIN analytics.transactions_validated t
    ON t.user_id = s.user_id AND t.created_at::DATE = p_date AND t.is_valid = TRUE
  LEFT JOIN analytics.api_logs_clean a
    ON a.created_at::DATE = p_date AND a.is_valid = TRUE
  WHERE s.started_at::DATE = p_date
  ON CONFLICT (date) DO UPDATE SET
    active_users = EXCLUDED.active_users,
    new_users = EXCLUDED.new_users,
    returning_users = EXCLUDED.returning_users,
    total_sessions = EXCLUDED.total_sessions,
    avg_session_duration_seconds = EXCLUDED.avg_session_duration_seconds,
    total_events = EXCLUDED.total_events,
    avg_events_per_session = EXCLUDED.avg_events_per_session,
    total_revenue = EXCLUDED.total_revenue,
    total_transactions = EXCLUDED.total_transactions,
    avg_transaction_value = EXCLUDED.avg_transaction_value,
    total_requests = EXCLUDED.total_requests,
    avg_response_time_ms = EXCLUDED.avg_response_time_ms,
    error_rate = EXCLUDED.error_rate,
    updated_at = NOW();
END;
$$;

-- Update KPI Dashboard Function
CREATE OR REPLACE FUNCTION analytics.update_kpi_dashboard()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Today's Active Users
  INSERT INTO analytics.kpi_dashboard (metric_name, metric_value, metric_unit, time_period, previous_value, change_percentage, trend)
  SELECT
    'Active Users',
    active_users,
    'count',
    'today',
    LAG(active_users) OVER (ORDER BY date),
    ((active_users::DECIMAL / NULLIF(LAG(active_users) OVER (ORDER BY date), 0) - 1) * 100)::DECIMAL(6,2),
    CASE
      WHEN active_users > LAG(active_users) OVER (ORDER BY date) THEN 'up'
      WHEN active_users < LAG(active_users) OVER (ORDER BY date) THEN 'down'
      ELSE 'stable'
    END
  FROM analytics.daily_metrics
  WHERE date = CURRENT_DATE
  ON CONFLICT (metric_name, time_period) DO UPDATE SET
    metric_value = EXCLUDED.metric_value,
    previous_value = EXCLUDED.previous_value,
    change_percentage = EXCLUDED.change_percentage,
    trend = EXCLUDED.trend,
    calculated_at = NOW();

  -- More KPI calculations would follow similar pattern
END;
$$;

-- =====================================================
-- SCHEDULED JOBS (pg_cron)
-- =====================================================

-- Schedule ETL jobs to run every 5 minutes
SELECT cron.schedule(
  'etl-clean-events',
  '*/5 * * * *', -- Every 5 minutes
  $$SELECT analytics.clean_events();$$
);

SELECT cron.schedule(
  'etl-validate-transactions',
  '*/5 * * * *', -- Every 5 minutes
  $$SELECT analytics.validate_transactions();$$
);

SELECT cron.schedule(
  'etl-build-sessions',
  '*/10 * * * *', -- Every 10 minutes
  $$SELECT analytics.build_user_sessions();$$
);

-- Schedule daily aggregation to run at 1 AM
SELECT cron.schedule(
  'aggregate-daily-metrics',
  '0 1 * * *', -- 1 AM daily
  $$SELECT analytics.calculate_daily_metrics(CURRENT_DATE - 1);$$
);

-- Schedule KPI dashboard update to run every hour
SELECT cron.schedule(
  'update-kpi-dashboard',
  '0 * * * *', -- Top of every hour
  $$SELECT analytics.update_kpi_dashboard();$$
);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE analytics.events_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.events_clean ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.api_logs_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.api_logs_clean ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.user_actions_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.transactions_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.transactions_validated ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.user_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.revenue_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.kpi_dashboard ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can do everything
CREATE POLICY service_role_all ON analytics.events_raw FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.events_clean FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.api_logs_raw FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.api_logs_clean FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.user_actions_raw FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.user_sessions FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.transactions_raw FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.transactions_validated FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.daily_metrics FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.user_cohorts FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.revenue_summary FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all ON analytics.kpi_dashboard FOR ALL TO service_role USING (true);

-- Policy: Authenticated users can read aggregated data (Gold layer)
CREATE POLICY authenticated_read_metrics ON analytics.daily_metrics FOR SELECT TO authenticated USING (true);
CREATE POLICY authenticated_read_cohorts ON analytics.user_cohorts FOR SELECT TO authenticated USING (true);
CREATE POLICY authenticated_read_revenue ON analytics.revenue_summary FOR SELECT TO authenticated USING (true);
CREATE POLICY authenticated_read_kpi ON analytics.kpi_dashboard FOR SELECT TO authenticated USING (true);

-- Policy: Authenticated users can only read their own data (Silver layer)
CREATE POLICY user_read_own_events ON analytics.events_clean FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY user_read_own_sessions ON analytics.user_sessions FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY user_read_own_transactions ON analytics.transactions_validated FOR SELECT TO authenticated USING (user_id = auth.uid());

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert sample raw events
INSERT INTO analytics.events_raw (event_type, user_id, session_id, properties, source)
VALUES
  ('page_view', uuid_generate_v4(), 'session_1', '{"page": "/dashboard"}', 'web'),
  ('button_click', uuid_generate_v4(), 'session_1', '{"button": "submit"}', 'web'),
  ('form_submit', uuid_generate_v4(), 'session_2', '{"form": "contact"}', 'web');

-- Insert sample raw transactions
INSERT INTO analytics.transactions_raw (user_id, amount, currency, status, payment_method, source)
VALUES
  (uuid_generate_v4(), 99.99, 'USD', 'completed', 'credit_card', 'web'),
  (uuid_generate_v4(), 149.99, 'USD', 'completed', 'paypal', 'mobile'),
  (uuid_generate_v4(), 29.99, 'USD', 'failed', 'credit_card', 'web');

-- =====================================================
-- END OF MIGRATION
-- =====================================================
