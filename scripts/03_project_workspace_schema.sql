-- Project Workspace Schema
-- Kanban boards, project wiki, task management

-- Projects (extended)
CREATE TABLE IF NOT EXISTS project (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'active', -- active, on_hold, completed, archived
  project_manager_id UUID REFERENCES auth.users(id),
  team_lead_id UUID REFERENCES auth.users(id),
  start_date DATE,
  end_date DATE,
  budget DECIMAL(12, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Project Tasks
CREATE TABLE IF NOT EXISTS project_task (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'todo', -- todo, in_progress, review, done
  priority VARCHAR(50) DEFAULT 'medium', -- low, medium, high, urgent
  assigned_to UUID REFERENCES auth.users(id),
  due_date DATE,
  start_date DATE,
  estimated_hours DECIMAL(8, 2),
  actual_hours DECIMAL(8, 2),
  parent_task_id BIGINT REFERENCES project_task(id) ON DELETE SET NULL,
  sequence INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Task Dependencies
CREATE TABLE IF NOT EXISTS task_dependency (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES project_task(id) ON DELETE CASCADE,
  depends_on_task_id BIGINT NOT NULL REFERENCES project_task(id) ON DELETE CASCADE,
  dependency_type VARCHAR(50) DEFAULT 'blocks', -- blocks, blocked_by, relates_to
  PRIMARY KEY (task_id, depends_on_task_id)
);

-- Project Wiki Pages
CREATE TABLE IF NOT EXISTS project_wiki (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  status VARCHAR(50) DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Project Team Members
CREATE TABLE IF NOT EXISTS project_team_member (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role VARCHAR(50) DEFAULT 'member', -- manager, lead, member
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, user_id)
);

-- Kanban Board Columns
CREATE TABLE IF NOT EXISTS kanban_column (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  status_value VARCHAR(50),
  sequence INT DEFAULT 0,
  color VARCHAR(7),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_project_task_project ON project_task(project_id);
CREATE INDEX idx_project_task_status ON project_task(status);
CREATE INDEX idx_project_task_assigned ON project_task(assigned_to);
CREATE INDEX idx_project_wiki_project ON project_wiki(project_id);
CREATE INDEX idx_task_dependency_task ON task_dependency(task_id);
