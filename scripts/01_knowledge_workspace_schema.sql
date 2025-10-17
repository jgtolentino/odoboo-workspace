-- Knowledge Workspace Schema
-- Core document/page management tables

-- Knowledge Categories
CREATE TABLE IF NOT EXISTS knowledge_category (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  parent_id BIGINT REFERENCES knowledge_category(id) ON DELETE SET NULL,
  color VARCHAR(7),
  icon VARCHAR(50),
  sequence INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);

-- Knowledge Tags
CREATE TABLE IF NOT EXISTS knowledge_tag (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  color VARCHAR(7),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Knowledge Pages
CREATE TABLE IF NOT EXISTS knowledge_page (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  category_id BIGINT REFERENCES knowledge_category(id) ON DELETE SET NULL,
  parent_page_id BIGINT REFERENCES knowledge_page(id) ON DELETE SET NULL,
  status VARCHAR(50) DEFAULT 'draft', -- draft, published, archived
  access_level VARCHAR(50) DEFAULT 'private', -- private, team, public
  version INT DEFAULT 1,
  is_template BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id),
  published_at TIMESTAMP
);

-- Knowledge Page Tags (many-to-many)
CREATE TABLE IF NOT EXISTS knowledge_page_tag (
  page_id BIGINT REFERENCES knowledge_page(id) ON DELETE CASCADE,
  tag_id BIGINT REFERENCES knowledge_tag(id) ON DELETE CASCADE,
  PRIMARY KEY (page_id, tag_id)
);

-- Knowledge Page History (versioning)
CREATE TABLE IF NOT EXISTS knowledge_page_history (
  id BIGSERIAL PRIMARY KEY,
  page_id BIGINT NOT NULL REFERENCES knowledge_page(id) ON DELETE CASCADE,
  version INT NOT NULL,
  title VARCHAR(255),
  content TEXT,
  change_summary VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Create indexes for performance
CREATE INDEX idx_knowledge_page_category ON knowledge_page(category_id);
CREATE INDEX idx_knowledge_page_parent ON knowledge_page(parent_page_id);
CREATE INDEX idx_knowledge_page_status ON knowledge_page(status);
CREATE INDEX idx_knowledge_page_created_by ON knowledge_page(created_by);
CREATE INDEX idx_knowledge_page_history_page ON knowledge_page_history(page_id);
