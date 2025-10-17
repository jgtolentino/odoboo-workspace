-- Workspace Analytics & Rollups Schema
-- Cross-module metrics and aggregations

-- Workspace Metrics
CREATE TABLE IF NOT EXISTS workspace_metric (
  id BIGSERIAL PRIMARY KEY,
  metric_name VARCHAR(255) NOT NULL,
  metric_type VARCHAR(50), -- count, sum, average, max, min
  module_name VARCHAR(100),
  value DECIMAL(12, 2),
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(metric_name, module_name)
);

-- Workspace Rollups (custom aggregations)
CREATE TABLE IF NOT EXISTS workspace_rollup (
  id BIGSERIAL PRIMARY KEY,
  rollup_name VARCHAR(255) NOT NULL,
  source_table VARCHAR(100),
  source_field VARCHAR(100),
  aggregation_type VARCHAR(50), -- sum, count, average, max, min
  filter_condition TEXT,
  result_value DECIMAL(12, 2),
  last_calculated TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Dashboard Widgets
CREATE TABLE IF NOT EXISTS dashboard_widget (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  widget_type VARCHAR(100), -- metric, chart, list, rollup
  widget_title VARCHAR(255),
  widget_config JSONB,
  position INT,
  size VARCHAR(50), -- small, medium, large
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workspace_metric_name ON workspace_metric(metric_name);
CREATE INDEX idx_workspace_rollup_source ON workspace_rollup(source_table);
CREATE INDEX idx_dashboard_widget_user ON dashboard_widget(user_id);
