-- Project Management Schema
-- This adds the missing project, task, and timesheet tables

-- Projects table
CREATE TABLE IF NOT EXISTS project (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'archived', 'on_hold')) DEFAULT 'active',
  start_date DATE,
  end_date DATE,
  budget DECIMAL(10,2),
  priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Tasks table
CREATE TABLE IF NOT EXISTS task (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES project(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL CHECK (status IN ('backlog', 'todo', 'in_progress', 'review', 'done')) DEFAULT 'todo',
  priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
  assignee_id UUID REFERENCES auth.users(id),
  due_date DATE,
  estimated_hours DECIMAL(5,2),
  actual_hours DECIMAL(5,2),
  position INTEGER NOT NULL DEFAULT 0,
  parent_task_id UUID REFERENCES task(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Kanban columns for project boards
CREATE TABLE IF NOT EXISTS kanban_column (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES project(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  position INTEGER NOT NULL,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Task assignments (many-to-many relationship)
CREATE TABLE IF NOT EXISTS task_assignment (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES task(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID REFERENCES auth.users(id),
  
  UNIQUE(task_id, user_id)
);

-- Timesheet entries for time tracking
CREATE TABLE IF NOT EXISTS timesheet (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES task(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  date DATE NOT NULL,
  hours DECIMAL(4,2) NOT NULL CHECK (hours > 0 AND hours <= 24),
  description TEXT,
  billable BOOLEAN DEFAULT true,
  billing_rate DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(task_id, user_id, date)
);

-- Enable Row Level Security
ALTER TABLE project ENABLE ROW LEVEL SECURITY;
ALTER TABLE task ENABLE ROW LEVEL SECURITY;
ALTER TABLE kanban_column ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE timesheet ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Project policies: Users can see projects they created or are members of
CREATE POLICY "Users can view projects they created or are members of" ON project
  FOR SELECT USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM task_assignment ta
      JOIN task t ON t.id = ta.task_id
      WHERE t.project_id = project.id AND ta.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their own projects" ON project
  FOR ALL USING (created_by = auth.uid());

-- Task policies: Users can see tasks from projects they have access to
CREATE POLICY "Users can view tasks from accessible projects" ON task
  FOR SELECT USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM project p
      WHERE p.id = task.project_id AND p.created_by = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM task_assignment ta
      WHERE ta.task_id = task.id AND ta.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage tasks in their projects" ON task
  FOR ALL USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM project p
      WHERE p.id = task.project_id AND p.created_by = auth.uid()
    )
  );

-- Kanban column policies: Inherit from project
CREATE POLICY "Users can view kanban columns from accessible projects" ON kanban_column
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM project p
      WHERE p.id = kanban_column.project_id AND (
        p.created_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM task_assignment ta
          JOIN task t ON t.id = ta.task_id
          WHERE t.project_id = p.id AND ta.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Project owners can manage kanban columns" ON kanban_column
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM project p
      WHERE p.id = kanban_column.project_id AND p.created_by = auth.uid()
    )
  );

-- Task assignment policies
CREATE POLICY "Users can view task assignments for accessible tasks" ON task_assignment
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM task t
      WHERE t.id = task_assignment.task_id AND (
        t.created_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM project p
          WHERE p.id = t.project_id AND p.created_by = auth.uid()
        ) OR
        task_assignment.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Project owners can manage task assignments" ON task_assignment
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM task t
      JOIN project p ON p.id = t.project_id
      WHERE t.id = task_assignment.task_id AND p.created_by = auth.uid()
    )
  );

-- Timesheet policies: Users can only see and manage their own timesheets
CREATE POLICY "Users can view their timesheets" ON timesheet
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their timesheets" ON timesheet
  FOR ALL USING (user_id = auth.uid());

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_task_project_id ON task(project_id);
CREATE INDEX IF NOT EXISTS idx_task_status ON task(status);
CREATE INDEX IF NOT EXISTS idx_task_assignee ON task(assignee_id);
CREATE INDEX IF NOT EXISTS idx_task_parent ON task(parent_task_id);
CREATE INDEX IF NOT EXISTS idx_kanban_column_project ON kanban_column(project_id);
CREATE INDEX IF NOT EXISTS idx_task_assignment_task ON task_assignment(task_id);
CREATE INDEX IF NOT EXISTS idx_task_assignment_user ON task_assignment(user_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_task_user ON timesheet(task_id, user_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_date ON timesheet(date);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_project_updated_at BEFORE UPDATE ON project FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_task_updated_at BEFORE UPDATE ON task FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_kanban_column_updated_at BEFORE UPDATE ON kanban_column FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_timesheet_updated_at BEFORE UPDATE ON timesheet FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing
INSERT INTO project (name, description, status, priority) VALUES
('Website Redesign', 'Complete redesign of company website with modern UI/UX', 'active', 'high'),
('Mobile App Development', 'Build cross-platform mobile application', 'active', 'medium'),
('Q4 Marketing Campaign', 'End of year marketing initiatives', 'planning', 'high');

INSERT INTO kanban_column (project_id, name, position, color) VALUES
((SELECT id FROM project WHERE name = 'Website Redesign'), 'Backlog', 0, '#6B7280'),
((SELECT id FROM project WHERE name = 'Website Redesign'), 'To Do', 1, '#3B82F6'),
((SELECT id FROM project WHERE name = 'Website Redesign'), 'In Progress', 2, '#F59E0B'),
((SELECT id FROM project WHERE name = 'Website Redesign'), 'Review', 3, '#8B5CF6'),
((SELECT id FROM project WHERE name = 'Website Redesign'), 'Done', 4, '#10B981');

INSERT INTO task (project_id, title, description, status, priority) VALUES
((SELECT id FROM project WHERE name = 'Website Redesign'), 'Design Homepage', 'Create wireframes and mockups for homepage', 'todo', 'high'),
((SELECT id FROM project WHERE name = 'Website Redesign'), 'Implement Header', 'Build responsive header component', 'in_progress', 'medium'),
((SELECT id FROM project WHERE name = 'Website Redesign'), 'Setup CI/CD Pipeline', 'Configure automated deployment pipeline', 'done', 'medium');

COMMENT ON TABLE project IS 'Project management with status tracking and budgeting';
COMMENT ON TABLE task IS 'Individual tasks with assignments and progress tracking';
COMMENT ON TABLE kanban_column IS 'Kanban board columns for project organization';
COMMENT ON TABLE task_assignment IS 'Many-to-many relationship between tasks and users';
COMMENT ON TABLE timesheet IS 'Time tracking entries for tasks with billing support';
