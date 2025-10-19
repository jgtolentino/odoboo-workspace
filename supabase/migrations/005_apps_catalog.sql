-- ============================================================================
-- Apps Catalog Schema
-- ============================================================================
-- Purpose: Odoo-style app marketplace for workspace modules
-- Date: 2025-10-19
-- ============================================================================

-- TABLE: app_category
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_category (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  icon TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE app_category IS 'App categories for marketplace organization';

-- Insert default categories
INSERT INTO app_category (name, slug, description, icon) VALUES
  ('Productivity', 'productivity', 'Task management, notes, and collaboration tools', '📊'),
  ('Sales', 'sales', 'CRM, pipeline management, and sales automation', '💼'),
  ('Finance', 'finance', 'Accounting, expenses, and financial management', '💰'),
  ('HR', 'hr', 'Employee management, recruitment, and payroll', '👥'),
  ('Marketing', 'marketing', 'Campaigns, analytics, and customer engagement', '📈'),
  ('Operations', 'operations', 'Inventory, manufacturing, and supply chain', '⚙️'),
  ('Communication', 'communication', 'Email, chat, and team messaging', '💬'),
  ('Analytics', 'analytics', 'Dashboards, reporting, and business intelligence', '📉')
ON CONFLICT (slug) DO NOTHING;

-- TABLE: app
-- ============================================================================

CREATE TABLE IF NOT EXISTS app (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  summary TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  category_id BIGINT REFERENCES app_category(id) ON DELETE SET NULL,
  version TEXT NOT NULL DEFAULT '1.0.0',
  author TEXT,
  website TEXT,
  repository TEXT,
  license TEXT DEFAULT 'MIT',
  price_monthly DECIMAL(10,2) DEFAULT 0.00,
  price_yearly DECIMAL(10,2) DEFAULT 0.00,
  is_featured BOOLEAN DEFAULT FALSE,
  is_published BOOLEAN DEFAULT TRUE,
  install_count INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE app IS 'Installable apps and modules for workspace';

CREATE INDEX idx_app_category ON app(category_id);
CREATE INDEX idx_app_slug ON app(slug);
CREATE INDEX idx_app_published ON app(is_published) WHERE is_published = TRUE;

-- Insert sample apps
INSERT INTO app (name, slug, summary, description, icon, category_id, version, author) VALUES
  -- Productivity
  (
    'Notion Workspace',
    'notion-workspace',
    'Block-based knowledge management with real-time collaboration',
    'Full-featured Notion-style workspace with block editor, database views, and real-time collaboration. Includes 9 block types, 5 view types, and custom properties.',
    '📝',
    (SELECT id FROM app_category WHERE slug = 'productivity'),
    '1.0.0',
    'OdoBoo Team'
  ),
  (
    'Task Manager',
    'task-manager',
    'Project management with Kanban boards and Gantt charts',
    'Comprehensive task management with dependencies, time tracking, and visual parity testing.',
    '✅',
    (SELECT id FROM app_category WHERE slug = 'productivity'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- Finance
  (
    'Expense Tracker',
    'expense-tracker',
    'Expense management with OCR receipt scanning',
    'Auto-extract expense data from receipts using PaddleOCR-VL. Custom expense system (NOT SAP/Concur).',
    '💳',
    (SELECT id FROM app_category WHERE slug = 'finance'),
    '1.0.0',
    'OdoBoo Team'
  ),
  (
    'Accounting',
    'accounting',
    'Double-entry bookkeeping and financial reporting',
    'Complete accounting system with chart of accounts, journals, and financial statements.',
    '📒',
    (SELECT id FROM app_category WHERE slug = 'finance'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- Sales
  (
    'CRM',
    'crm',
    'Customer relationship management and pipeline tracking',
    'Manage leads, opportunities, and customer relationships with visual pipeline.',
    '🤝',
    (SELECT id FROM app_category WHERE slug = 'sales'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- HR
  (
    'Employee Directory',
    'employee-directory',
    'Employee profiles and organizational charts',
    'Manage employee information, departments, and reporting structure.',
    '👤',
    (SELECT id FROM app_category WHERE slug = 'hr'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- Marketing
  (
    'Email Campaigns',
    'email-campaigns',
    'Email marketing automation and analytics',
    'Create, send, and track email campaigns with built-in analytics.',
    '📧',
    (SELECT id FROM app_category WHERE slug = 'marketing'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- Analytics
  (
    'Analytics Dashboard',
    'analytics-dashboard',
    'Business intelligence with custom dashboards',
    'Self-hosted analytics alternative to Draxlr. Based on Metabase.',
    '📊',
    (SELECT id FROM app_category WHERE slug = 'analytics'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- Communication
  (
    'Team Chat',
    'team-chat',
    'Real-time team messaging and collaboration',
    'Slack-style team chat with channels, threads, and file sharing.',
    '💬',
    (SELECT id FROM app_category WHERE slug = 'communication'),
    '1.0.0',
    'OdoBoo Team'
  ),
  -- Operations
  (
    'Inventory',
    'inventory',
    'Stock management and warehouse operations',
    'Track inventory levels, locations, and movements.',
    '📦',
    (SELECT id FROM app_category WHERE slug = 'operations'),
    '1.0.0',
    'OdoBoo Team'
  )
ON CONFLICT (slug) DO NOTHING;

-- TABLE: app_install
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_install (
  id BIGSERIAL PRIMARY KEY,
  app_id BIGINT NOT NULL REFERENCES app(id) ON DELETE CASCADE,
  user_id UUID NOT NULL, -- Will reference auth.users eventually
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  installed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(app_id, user_id, company_id)
);

COMMENT ON TABLE app_install IS 'Track which apps are installed for which users/companies';

CREATE INDEX idx_app_install_user ON app_install(user_id);
CREATE INDEX idx_app_install_company ON app_install(company_id);
CREATE INDEX idx_app_install_app ON app_install(app_id);

-- TABLE: app_review
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_review (
  id BIGSERIAL PRIMARY KEY,
  app_id BIGINT NOT NULL REFERENCES app(id) ON DELETE CASCADE,
  user_id UUID NOT NULL, -- Will reference auth.users eventually
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(app_id, user_id)
);

COMMENT ON TABLE app_review IS 'User reviews and ratings for apps';

CREATE INDEX idx_app_review_app ON app_review(app_id);
CREATE INDEX idx_app_review_user ON app_review(user_id);

-- FUNCTION: Update app rating
-- ============================================================================

CREATE OR REPLACE FUNCTION update_app_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE app
  SET
    rating = (
      SELECT ROUND(AVG(rating)::numeric, 2)
      FROM app_review
      WHERE app_id = NEW.app_id
    ),
    updated_at = NOW()
  WHERE id = NEW.app_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_app_rating
AFTER INSERT OR UPDATE ON app_review
FOR EACH ROW
EXECUTE FUNCTION update_app_rating();

-- FUNCTION: Increment install count
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_app_install_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_active = TRUE THEN
    UPDATE app
    SET install_count = install_count + 1
    WHERE id = NEW.app_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_increment_install_count
AFTER INSERT ON app_install
FOR EACH ROW
EXECUTE FUNCTION increment_app_install_count();

-- RLS Policies
-- ============================================================================

ALTER TABLE app_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE app ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_install ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_review ENABLE ROW LEVEL SECURITY;

-- app_category: Public read
CREATE POLICY app_category_select ON app_category
  FOR SELECT
  USING (TRUE);

-- app: Public read for published apps
CREATE POLICY app_select ON app
  FOR SELECT
  USING (is_published = TRUE);

-- app_install: Users see own installs
CREATE POLICY app_install_select ON app_install
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR company_id = ops.jwt_company_id());

CREATE POLICY app_install_insert ON app_install
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid() AND company_id = ops.jwt_company_id());

CREATE POLICY app_install_update ON app_install
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid() OR company_id = ops.jwt_company_id());

CREATE POLICY app_install_delete ON app_install
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() OR company_id = ops.jwt_company_id());

-- app_review: Users see all reviews, can only modify own
CREATE POLICY app_review_select ON app_review
  FOR SELECT
  USING (TRUE);

CREATE POLICY app_review_insert ON app_review
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY app_review_update ON app_review
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY app_review_delete ON app_review
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================================
-- Verification
-- ============================================================================

SELECT
  'Apps Catalog Created' as status,
  (SELECT COUNT(*) FROM app_category) as categories,
  (SELECT COUNT(*) FROM app) as apps;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
