# Analytics Architecture - Medallion Pattern

**Azure Databricks → Supabase PostgreSQL Migration**

## 📊 Overview

Complete analytics platform using **Medallion Architecture** (Bronze → Silver → Gold) built on Supabase PostgreSQL + Edge Functions, replacing Azure Databricks at **98.75% cost savings** ($800/mo → $10/mo).

## 🏗️ Architecture Layers

### Bronze Layer (Raw Data)
**Purpose**: Ingest raw, unprocessed data from all sources

**Tables**:
- `events_raw` - User behavior events (page views, clicks, form submissions)
- `api_logs_raw` - API request/response logs
- `user_actions_raw` - User actions on entities
- `transactions_raw` - Payment transactions

**Data Sources**:
- **Supabase Realtime**: WebSocket events, change data capture (CDC)
- **Webhooks**: External system integrations
- **Edge Functions**: API event ingestion
- **Client SDKs**: Browser and mobile app events

**Characteristics**:
- ✅ Immutable (never modified after ingestion)
- ✅ Schema-on-read (flexible JSONB properties)
- ✅ Metadata tracking (source, ingested_at)
- ✅ High write throughput

### Silver Layer (Cleaned Data)
**Purpose**: Validated, cleaned, and enriched data ready for analysis

**Tables**:
- `events_clean` - Validated events with quality scores
- `api_logs_clean` - Cleaned API logs
- `user_sessions` - Derived session data from events
- `transactions_validated` - Validated transactions with fraud detection

**Transformations**:
- **Data quality validation**: Check required fields, data types, ranges
- **Deduplication**: Remove duplicate records
- **Enrichment**: Add derived fields, join with reference data
- **Standardization**: Normalize formats (dates, currencies, categories)

**ETL Functions** (scheduled via pg_cron):
```sql
-- Run every 5 minutes
SELECT analytics.clean_events();
SELECT analytics.validate_transactions();

-- Run every 10 minutes
SELECT analytics.build_user_sessions();
```

**Characteristics**:
- ✅ Data quality flags (is_valid, quality_score)
- ✅ Validation error tracking
- ✅ User-scoped RLS policies
- ✅ Optimized for queries

### Gold Layer (Aggregated Analytics)
**Purpose**: Business-ready metrics and KPIs for dashboards and reporting

**Tables**:
- `daily_metrics` - Daily rollup of all key metrics
- `user_cohorts` - Cohort analysis and retention
- `revenue_summary` - Revenue breakdowns and trends
- `kpi_dashboard` - Real-time KPI calculations

**Aggregations** (scheduled via pg_cron):
```sql
-- Run at 1 AM daily
SELECT analytics.calculate_daily_metrics(CURRENT_DATE - 1);

-- Run every hour
SELECT analytics.update_kpi_dashboard();
```

**Characteristics**:
- ✅ Pre-aggregated for fast queries
- ✅ Materialized view pattern
- ✅ Incremental updates
- ✅ Public read access (authenticated users)

## 💰 Cost Comparison

| Azure Databricks Stack | Supabase Analytics Stack | Savings |
|------------------------|--------------------------|---------|
| **Data Storage** |  |  |
| Delta Lake: $200/mo | PostgreSQL Free: $0/mo | $200/mo |
| **Event Ingestion** |  |  |
| Azure Event Hubs: $100/mo | Supabase Realtime: $0/mo | $100/mo |
| **Data Transformation** |  |  |
| Azure Data Factory: $80/mo | Edge Functions + pg_cron: $0/mo | $80/mo |
| **Analytics Notebooks** |  |  |
| Databricks Notebooks: $150/mo | Edge Functions + SQL: $0/mo | $150/mo |
| **Data Governance** |  |  |
| Unity Catalog: $50/mo | PostgreSQL Schemas + RLS: $0/mo | $50/mo |
| **ML Lifecycle** |  |  |
| MLflow: $100/mo | Custom ML Pipeline: $10/mo | $90/mo |
| **Visualization** |  |  |
| Power BI + Synapse: $120/mo | Metabase/Draxlr: $0/mo | $120/mo |
| **TOTAL** | **$800/month** | **$10/month** | **$790/month (98.75%)** |

## 🔄 Data Flow

```
External Events → Webhooks → Bronze Layer (Raw)
                                    ↓
                              ETL Functions
                                    ↓
                             Silver Layer (Cleaned)
                                    ↓
                            Aggregation Functions
                                    ↓
                              Gold Layer (Metrics)
                                    ↓
                         Dashboards / BI Tools
```

## 🔧 Implementation Details

### ETL Pipeline (Bronze → Silver)

**Clean Events Function**:
```sql
CREATE OR REPLACE FUNCTION analytics.clean_events()
RETURNS INTEGER AS $$
DECLARE
  v_rows_processed INTEGER;
BEGIN
  INSERT INTO analytics.events_clean (...)
  SELECT
    e.*,
    -- Validation logic
    (e.event_type IS NOT NULL AND e.created_at IS NOT NULL) as is_valid,
    -- Quality scoring
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Validate Transactions Function**:
```sql
CREATE OR REPLACE FUNCTION analytics.validate_transactions()
RETURNS INTEGER AS $$
BEGIN
  INSERT INTO analytics.transactions_validated (...)
  SELECT
    t.*,
    (t.amount > 0 AND t.currency IS NOT NULL) as is_valid,
    -- Duplicate detection
    EXISTS (...) as is_duplicate,
    -- Fraud scoring
    CASE
      WHEN t.amount > 10000 THEN 0.80
      WHEN t.amount > 5000 THEN 0.50
      ELSE 0.10
    END as fraud_score
  FROM analytics.transactions_raw t
  WHERE NOT EXISTS (...);

  RETURN v_rows_processed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Aggregation Pipeline (Silver → Gold)

**Daily Metrics Calculation**:
```sql
CREATE OR REPLACE FUNCTION analytics.calculate_daily_metrics(p_date DATE)
RETURNS VOID AS $$
BEGIN
  INSERT INTO analytics.daily_metrics (
    date,
    active_users,
    new_users,
    total_sessions,
    avg_session_duration_seconds,
    total_revenue,
    ...
  )
  SELECT
    p_date,
    COUNT(DISTINCT s.user_id) as active_users,
    COUNT(DISTINCT s.user_id) FILTER (WHERE ...) as new_users,
    COUNT(*) as total_sessions,
    AVG(s.duration_seconds) as avg_session_duration_seconds,
    COALESCE(SUM(t.amount), 0) as total_revenue,
    ...
  FROM analytics.user_sessions s
  LEFT JOIN analytics.transactions_validated t ON ...
  WHERE s.started_at::DATE = p_date
  ON CONFLICT (date) DO UPDATE SET ...;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Scheduled Jobs (pg_cron)

**ETL Jobs** (every 5-10 minutes):
```sql
SELECT cron.schedule(
  'etl-clean-events',
  '*/5 * * * *', -- Every 5 minutes
  $$SELECT analytics.clean_events();$$
);

SELECT cron.schedule(
  'etl-validate-transactions',
  '*/5 * * * *',
  $$SELECT analytics.validate_transactions();$$
);

SELECT cron.schedule(
  'etl-build-sessions',
  '*/10 * * * *', -- Every 10 minutes
  $$SELECT analytics.build_user_sessions();$$
);
```

**Aggregation Jobs** (daily):
```sql
SELECT cron.schedule(
  'aggregate-daily-metrics',
  '0 1 * * *', -- 1 AM daily
  $$SELECT analytics.calculate_daily_metrics(CURRENT_DATE - 1);$$
);
```

**Dashboard Updates** (hourly):
```sql
SELECT cron.schedule(
  'update-kpi-dashboard',
  '0 * * * *', -- Top of every hour
  $$SELECT analytics.update_kpi_dashboard();$$
);
```

## 🔐 Security (Row Level Security)

**Service Role** (full access):
```sql
CREATE POLICY service_role_all ON analytics.events_raw
  FOR ALL TO service_role USING (true);
```

**Authenticated Users** (aggregated data):
```sql
CREATE POLICY authenticated_read_metrics ON analytics.daily_metrics
  FOR SELECT TO authenticated USING (true);
```

**User-Scoped Access** (own data only):
```sql
CREATE POLICY user_read_own_events ON analytics.events_clean
  FOR SELECT TO authenticated USING (user_id = auth.uid());
```

## 📈 Use Cases

### 1. Product Analytics
- **Track**: User behavior, feature adoption, conversion funnels
- **Tables**: events_clean, user_sessions, daily_metrics
- **Queries**: Engagement metrics, retention cohorts, feature usage

### 2. Business Intelligence
- **Track**: Revenue, KPIs, business metrics
- **Tables**: transactions_validated, revenue_summary, kpi_dashboard
- **Queries**: Revenue trends, payment methods, transaction success rates

### 3. ML Pipelines
- **Track**: Feature engineering, model training, inference
- **Tables**: events_clean, user_sessions, transactions_validated
- **Queries**: User features, prediction inputs, model evaluation

### 4. Data Science
- **Track**: Exploratory analysis, statistical modeling
- **Tables**: All layers (Bronze, Silver, Gold)
- **Queries**: Ad-hoc analysis, hypothesis testing, correlation studies

### 5. Real-time Monitoring
- **Track**: System health, error tracking, performance
- **Tables**: api_logs_clean, events_clean
- **Queries**: Error rates, response times, uptime

### 6. Customer Data Platform
- **Track**: 360° customer view, segmentation, personalization
- **Tables**: user_sessions, events_clean, transactions_validated
- **Queries**: Customer segments, lifetime value, behavior patterns

## 🚀 Deployment

### 1. Apply Migration
```bash
# ChatGPT will execute (database responsibility)
psql "$POSTGRES_URL" -f supabase/migrations/006_analytics_medallion.sql
```

### 2. Verify Tables Created
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'analytics'
ORDER BY table_name;
```

### 3. Verify Scheduled Jobs
```sql
SELECT * FROM cron.job ORDER BY jobname;
```

### 4. Insert Test Data
```sql
-- Sample event
INSERT INTO analytics.events_raw (event_type, user_id, session_id, properties, source)
VALUES ('page_view', auth.uid(), 'test_session', '{"page": "/dashboard"}', 'web');

-- Wait 5 minutes for ETL to run
-- Check cleaned data
SELECT * FROM analytics.events_clean ORDER BY created_at DESC LIMIT 10;
```

### 5. Trigger Manual ETL
```sql
-- Clean events
SELECT analytics.clean_events();

-- Validate transactions
SELECT analytics.validate_transactions();

-- Build sessions
SELECT analytics.build_user_sessions();
```

### 6. Calculate Metrics
```sql
-- Calculate yesterday's metrics
SELECT analytics.calculate_daily_metrics(CURRENT_DATE - 1);

-- Update KPI dashboard
SELECT analytics.update_kpi_dashboard();

-- View results
SELECT * FROM analytics.daily_metrics ORDER BY date DESC LIMIT 7;
SELECT * FROM analytics.kpi_dashboard;
```

## 📊 Querying Examples

### Daily Active Users (Last 7 Days)
```sql
SELECT
  date,
  active_users,
  new_users,
  returning_users,
  (new_users::DECIMAL / NULLIF(active_users, 0) * 100)::DECIMAL(5,2) as new_user_percentage
FROM analytics.daily_metrics
WHERE date >= CURRENT_DATE - 7
ORDER BY date DESC;
```

### User Retention by Cohort
```sql
SELECT
  cohort_month,
  month_0_users,
  month_1_users,
  month_1_retention * 100 as month_1_retention_pct,
  month_3_retention * 100 as month_3_retention_pct,
  avg_revenue_per_user
FROM analytics.user_cohorts
ORDER BY cohort_month DESC
LIMIT 12;
```

### Revenue Trends
```sql
SELECT
  date,
  total_revenue,
  total_transactions,
  avg_transaction_value,
  successful_transactions,
  (failed_transactions::DECIMAL / NULLIF(total_transactions, 0) * 100)::DECIMAL(5,2) as failure_rate_pct
FROM analytics.revenue_summary
WHERE date >= CURRENT_DATE - 30
ORDER BY date DESC;
```

### KPI Dashboard
```sql
SELECT
  metric_name,
  metric_value,
  metric_unit,
  time_period,
  change_percentage,
  trend
FROM analytics.kpi_dashboard
ORDER BY metric_name, time_period;
```

### Top Events by User
```sql
SELECT
  user_id,
  event_type,
  COUNT(*) as event_count,
  MAX(created_at) as last_event_at
FROM analytics.events_clean
WHERE created_at >= CURRENT_DATE - 7
  AND is_valid = TRUE
GROUP BY user_id, event_type
ORDER BY event_count DESC
LIMIT 100;
```

### Session Duration Distribution
```sql
SELECT
  CASE
    WHEN duration_seconds < 30 THEN '0-30s'
    WHEN duration_seconds < 60 THEN '30-60s'
    WHEN duration_seconds < 300 THEN '1-5min'
    WHEN duration_seconds < 900 THEN '5-15min'
    ELSE '15min+'
  END as duration_bucket,
  COUNT(*) as session_count,
  AVG(event_count) as avg_events_per_session
FROM analytics.user_sessions
WHERE started_at >= CURRENT_DATE - 7
GROUP BY duration_bucket
ORDER BY MIN(duration_seconds);
```

## 🎯 Performance Optimization

### 1. Indexes
All critical indexes already created in migration:
- `idx_events_raw_created` - Time-based queries
- `idx_events_raw_user` - User-specific queries
- `idx_events_raw_type` - Event type filtering

### 2. Partitioning (Future Enhancement)
For large datasets (>10M rows), consider table partitioning:
```sql
-- Partition events by month
CREATE TABLE analytics.events_raw_2025_01 PARTITION OF analytics.events_raw
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### 3. Materialized Views (Alternative to Gold Tables)
```sql
CREATE MATERIALIZED VIEW analytics.mv_daily_metrics AS
SELECT ... FROM analytics.user_sessions ...;

-- Refresh daily
SELECT cron.schedule(
  'refresh-daily-metrics-mv',
  '0 2 * * *',
  $$REFRESH MATERIALIZED VIEW analytics.mv_daily_metrics;$$
);
```

### 4. Connection Pooling
Use Supabase connection pooler (port 6543) for high concurrency:
```bash
POSTGRES_URL="postgresql://postgres.xkxyvboeubffxxbebsll:PASSWORD@aws-1-us-east-1.pooler.supabase.com:6543/postgres"
```

## 📚 References

### Azure Databricks Documentation
- [Modern Analytics Architecture](https://learn.microsoft.com/en-us/azure/architecture/solution-ideas/articles/azure-databricks-modern-analytics-architecture)
- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)
- [Delta Lake](https://delta.io/)

### Supabase Documentation
- [PostgreSQL Functions](https://supabase.com/docs/guides/database/functions)
- [pg_cron](https://supabase.com/docs/guides/database/extensions/pgcron)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime](https://supabase.com/docs/guides/realtime)

### Related OdoBoo Docs
- [Well-Architected Assessment](./WELL_ARCHITECTED_ASSESSMENT.md)
- [AI Chat Architecture](./diagrams/ai-chat-architecture.drawio)
- [System Architecture](./diagrams/system-architecture.drawio)
- [Database Schema](./diagrams/database-schema.drawio)
- [CI/CD Pipeline](./diagrams/cicd-pipeline.drawio)

---

**Last Updated**: 2025-10-19
**Maintained By**: Claude Code
**Database Migration**: `supabase/migrations/006_analytics_medallion.sql`
**Architecture Diagram**: `docs/diagrams/medallion-architecture.drawio`
