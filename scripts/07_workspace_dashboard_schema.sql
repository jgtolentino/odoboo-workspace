-- Workspace Dashboard Schema
-- Unified dashboard, activity tracking, user preferences

-- Workspace Activity Log
CREATE TABLE IF NOT EXISTS workspace_activity (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  activity_type VARCHAR(100), -- created, updated, deleted, commented, shared
  entity_type VARCHAR(100), -- page, task, invoice, expense, vendor
  entity_id BIGINT,
  entity_name VARCHAR(255),
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Preferences
CREATE TABLE IF NOT EXISTS user_preference (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id),
  theme VARCHAR(50) DEFAULT 'light', -- light, dark, auto
  language VARCHAR(10) DEFAULT 'en',
  timezone VARCHAR(50) DEFAULT 'UTC',
  notifications_enabled BOOLEAN DEFAULT TRUE,
  email_digest VARCHAR(50) DEFAULT 'daily', -- daily, weekly, never
  default_view VARCHAR(50) DEFAULT 'dashboard',
  sidebar_collapsed BOOLEAN DEFAULT FALSE,
  preferences JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workspace Favorites
-- Removed duplicate PRIMARY KEY definition - using composite key only
CREATE TABLE IF NOT EXISTS workspace_favorite (
  user_id UUID NOT NULL REFERENCES auth.users(id),
  entity_type VARCHAR(100),
  entity_id BIGINT,
  entity_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, entity_type, entity_id)
);

CREATE INDEX idx_workspace_activity_user ON workspace_activity(user_id);
CREATE INDEX idx_workspace_activity_type ON workspace_activity(activity_type);
CREATE INDEX idx_workspace_favorite_user ON workspace_favorite(user_id);
