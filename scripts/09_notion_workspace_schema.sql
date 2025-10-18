-- Notion-Style Workspace Database Schema
-- This extends the existing Odoo-style platform with Notion-like features

-- Block-based content storage
CREATE TABLE IF NOT EXISTS content_blocks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  page_id UUID REFERENCES knowledge_pages(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('text', 'heading', 'list', 'table', 'embed', 'code', 'image', 'file', 'divider', 'quote')),
  content JSONB NOT NULL DEFAULT '{}',
  position INTEGER NOT NULL,
  parent_block_id UUID REFERENCES content_blocks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  
  -- Ensure unique positions per page
  UNIQUE(page_id, position)
);

-- Database views configuration for Notion-style views
CREATE TABLE IF NOT EXISTS database_views (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('table', 'board', 'calendar', 'gallery', 'list')),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('knowledge_page', 'project_task', 'vendor_document')),
  filters JSONB DEFAULT '{}',
  sort_order JSONB DEFAULT '[]',
  visible_columns JSONB DEFAULT '[]',
  group_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Task dependencies for advanced project management
CREATE TABLE IF NOT EXISTS task_dependencies (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES project_tasks(id) ON DELETE CASCADE,
  depends_on_task_id UUID REFERENCES project_tasks(id) ON DELETE CASCADE,
  dependency_type TEXT NOT NULL CHECK (dependency_type IN ('blocks', 'finish_to_start', 'start_to_start', 'finish_to_finish')),
  lag_days INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent circular dependencies
  CHECK (task_id != depends_on_task_id),
  UNIQUE(task_id, depends_on_task_id)
);

-- Time tracking with real-time capabilities
CREATE TABLE IF NOT EXISTS time_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES project_tasks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_minutes INTEGER,
  description TEXT,
  billable BOOLEAN DEFAULT true,
  billing_rate DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Custom properties for database-like functionality
CREATE TABLE IF NOT EXISTS custom_properties (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('knowledge_page', 'project_task', 'vendor_document')),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('text', 'number', 'date', 'select', 'multi_select', 'person', 'file', 'checkbox', 'url', 'email', 'phone')),
  options JSONB DEFAULT '[]',
  required BOOLEAN DEFAULT false,
  position INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(entity_type, name)
);

-- Property values for entities
CREATE TABLE IF NOT EXISTS property_values (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID REFERENCES custom_properties(id) ON DELETE CASCADE,
  entity_id UUID NOT NULL, -- References knowledge_pages.id, project_tasks.id, etc.
  entity_type TEXT NOT NULL,
  value JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(property_id, entity_id, entity_type)
);

-- Page templates for quick content creation
CREATE TABLE IF NOT EXISTS page_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  icon TEXT,
  content_structure JSONB NOT NULL, -- Array of block definitions
  properties JSONB DEFAULT '{}', -- Default property values
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Workspace navigation and organization
CREATE TABLE IF NOT EXISTS workspace_navigation (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  icon TEXT,
  type TEXT NOT NULL CHECK (type IN ('page', 'database', 'view', 'link', 'separator')),
  target_id UUID, -- References knowledge_pages.id, database_views.id, etc.
  target_type TEXT, -- 'knowledge_page', 'database_view', etc.
  parent_id UUID REFERENCES workspace_navigation(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, parent_id, position)
);

-- Enable Row Level Security
ALTER TABLE content_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE database_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_navigation ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Content blocks: Users can see blocks for pages they have access to
CREATE POLICY "Users can view content blocks for accessible pages" ON content_blocks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM knowledge_pages kp
      WHERE kp.id = content_blocks.page_id
      AND (kp.is_public = true OR kp.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can manage their own content blocks" ON content_blocks
  FOR ALL USING (created_by = auth.uid());

-- Database views: Users can see and manage their own views
CREATE POLICY "Users can view database views" ON database_views
  FOR SELECT USING (created_by = auth.uid() OR entity_type = 'knowledge_page' AND EXISTS (
    SELECT 1 FROM knowledge_pages WHERE is_public = true
  ));

CREATE POLICY "Users can manage their database views" ON database_views
  FOR ALL USING (created_by = auth.uid());

-- Task dependencies: Inherit permissions from tasks
CREATE POLICY "Users can view task dependencies" ON task_dependencies
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM project_tasks pt
      WHERE pt.id = task_dependencies.task_id
      AND (pt.created_by = auth.uid() OR EXISTS (
        SELECT 1 FROM project_members pm 
        WHERE pm.project_id = pt.project_id AND pm.user_id = auth.uid()
      ))
    )
  );

-- Time entries: Users can only see and manage their own time entries
CREATE POLICY "Users can view their time entries" ON time_entries
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their time entries" ON time_entries
  FOR ALL USING (user_id = auth.uid());

-- Custom properties: Admin users can manage, all can view
CREATE POLICY "Users can view custom properties" ON custom_properties
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage custom properties" ON custom_properties
  FOR ALL USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND role = 'admin'));

-- Property values: Users can see values for entities they have access to
CREATE POLICY "Users can view property values" ON property_values
  FOR SELECT USING (
    CASE entity_type
      WHEN 'knowledge_page' THEN EXISTS (
        SELECT 1 FROM knowledge_pages kp
        WHERE kp.id = property_values.entity_id
        AND (kp.is_public = true OR kp.created_by = auth.uid())
      )
      WHEN 'project_task' THEN EXISTS (
        SELECT 1 FROM project_tasks pt
        WHERE pt.id = property_values.entity_id
        AND (pt.created_by = auth.uid() OR EXISTS (
          SELECT 1 FROM project_members pm 
          WHERE pm.project_id = pt.project_id AND pm.user_id = auth.uid()
        ))
      )
      ELSE false
    END
  );

-- Page templates: All users can view, creators can manage
CREATE POLICY "Users can view page templates" ON page_templates
  FOR SELECT USING (true);

CREATE POLICY "Users can manage their page templates" ON page_templates
  FOR ALL USING (created_by = auth.uid());

-- Workspace navigation: Users can only see and manage their own navigation
CREATE POLICY "Users can view their workspace navigation" ON workspace_navigation
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their workspace navigation" ON workspace_navigation
  FOR ALL USING (user_id = auth.uid());

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_content_blocks_page_id ON content_blocks(page_id);
CREATE INDEX IF NOT EXISTS idx_content_blocks_position ON content_blocks(page_id, position);
CREATE INDEX IF NOT EXISTS idx_content_blocks_parent ON content_blocks(parent_block_id);
CREATE INDEX IF NOT EXISTS idx_task_dependencies_task ON task_dependencies(task_id);
CREATE INDEX IF NOT EXISTS idx_task_dependencies_depends ON task_dependencies(depends_on_task_id);
CREATE INDEX IF NOT EXISTS idx_time_entries_task_user ON time_entries(task_id, user_id);
CREATE INDEX IF NOT EXISTS idx_time_entries_start_time ON time_entries(start_time);
CREATE INDEX IF NOT EXISTS idx_property_values_entity ON property_values(entity_id, entity_type);
CREATE INDEX IF NOT EXISTS idx_workspace_navigation_user ON workspace_navigation(user_id);
CREATE INDEX IF NOT EXISTS idx_workspace_navigation_parent ON workspace_navigation(parent_id);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_content_blocks_updated_at BEFORE UPDATE ON content_blocks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_database_views_updated_at BEFORE UPDATE ON database_views FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_time_entries_updated_at BEFORE UPDATE ON time_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_custom_properties_updated_at BEFORE UPDATE ON custom_properties FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_property_values_updated_at BEFORE UPDATE ON property_values FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_page_templates_updated_at BEFORE UPDATE ON page_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workspace_navigation_updated_at BEFORE UPDATE ON workspace_navigation FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing
INSERT INTO custom_properties (entity_type, name, type, position, options) VALUES
('knowledge_page', 'Status', 'select', 1, '["Draft", "In Progress", "Completed", "Archived"]'::jsonb),
('knowledge_page', 'Priority', 'select', 2, '["Low", "Medium", "High", "Critical"]'::jsonb),
('project_task', 'Status', 'select', 1, '["Backlog", "Todo", "In Progress", "Review", "Done"]'::jsonb),
('project_task', 'Priority', 'select', 2, '["Low", "Medium", "High", "Urgent"]'::jsonb);

INSERT INTO page_templates (name, description, category, icon, content_structure) VALUES
('Meeting Notes', 'Template for capturing meeting discussions and action items', 'Productivity', '📝', '[
  {"type": "heading", "content": {"text": "Meeting Notes", "level": 1}},
  {"type": "text", "content": {"text": "**Date:** {{date}}"} },
  {"type": "text", "content": {"text": "**Attendees:** "} },
  {"type": "heading", "content": {"text": "Agenda", "level": 2}},
  {"type": "list", "content": {"items": ["Item 1", "Item 2", "Item 3"], "type": "bullet"} },
  {"type": "heading", "content": {"text": "Discussion", "level": 2}},
  {"type": "text", "content": {"text": "Key discussion points..."} },
  {"type": "heading", "content": {"text": "Action Items", "level": 2}},
  {"type": "list", "content": {"items": ["Task 1 - Owner", "Task 2 - Owner"], "type": "bullet"} }
]'::jsonb),
('Project Plan', 'Template for outlining project goals and milestones', 'Project Management', '📋', '[
  {"type": "heading", "content": {"text": "Project Plan", "level": 1}},
  {"type": "text", "content": {"text": "**Project:** {{project_name}}"} },
  {"type": "text", "content": {"text": "**Timeline:** {{start_date}} - {{end_date}}"} },
  {"type": "heading", "content": {"text": "Goals", "level": 2}},
  {"type": "list", "content": {"items": ["Goal 1", "Goal 2", "Goal 3"], "type": "bullet"} },
  {"type": "heading", "content": {"text": "Milestones", "level": 2}},
  {"type": "table", "content": {"headers": ["Milestone", "Due Date", "Owner"], "rows": []} },
  {"type": "heading", "content": {"text": "Resources", "level": 2}},
  {"type": "text", "content": {"text": "Team members, tools, and budget..."} }
]'::jsonb);

COMMENT ON TABLE content_blocks IS 'Stores block-based content for Notion-style editing';
COMMENT ON TABLE database_views IS 'Configuration for different view types (table, board, calendar, etc.)';
COMMENT ON TABLE task_dependencies IS 'Advanced task dependency relationships for project management';
COMMENT ON TABLE time_entries IS 'Real-time time tracking with billing capabilities';
COMMENT ON TABLE custom_properties IS 'Custom fields and properties for database-like functionality';
COMMENT ON TABLE property_values IS 'Values for custom properties on entities';
COMMENT ON TABLE page_templates IS 'Pre-built templates for quick content creation';
COMMENT ON TABLE workspace_navigation IS 'User-specific workspace navigation and organization';
