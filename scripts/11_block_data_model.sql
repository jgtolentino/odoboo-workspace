-- Block Data Model Schema
-- This adds the missing block, block_prop, and block_history tables for Notion-style editor

-- Main blocks table for storing block-based content
CREATE TABLE IF NOT EXISTS block (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  page_id UUID REFERENCES knowledge_page(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'text', 'heading', 'list', 'table', 'embed', 'code', 
    'image', 'file', 'divider', 'quote', 'callout', 'toggle'
  )),
  content JSONB NOT NULL DEFAULT '{}',
  position INTEGER NOT NULL DEFAULT 0,
  parent_block_id UUID REFERENCES block(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  
  -- Ensure blocks are unique within a page and position
  UNIQUE(page_id, position)
);

-- Block properties for custom metadata (like Notion's properties)
CREATE TABLE IF NOT EXISTS block_prop (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  block_id UUID REFERENCES block(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('text', 'number', 'date', 'select', 'multi_select', 'person', 'file', 'checkbox', 'url')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(block_id, key)
);

-- Block history for version control and undo/redo
CREATE TABLE IF NOT EXISTS block_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  block_id UUID REFERENCES block(id) ON DELETE CASCADE,
  old_content JSONB,
  new_content JSONB,
  operation TEXT NOT NULL CHECK (operation IN ('create', 'update', 'delete', 'move')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security
ALTER TABLE block ENABLE ROW LEVEL SECURITY;
ALTER TABLE block_prop ENABLE ROW LEVEL SECURITY;
ALTER TABLE block_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Block policies: Users can see blocks from pages they have access to
CREATE POLICY "Users can view blocks from accessible pages" ON block
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM knowledge_page kp
      WHERE kp.id = block.page_id AND (
        kp.created_by = auth.uid() OR
        kp.is_public = true OR
        EXISTS (
          SELECT 1 FROM knowledge_page_collaborator kpc
          WHERE kpc.page_id = kp.id AND kpc.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Users can manage blocks in their pages" ON block
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM knowledge_page kp
      WHERE kp.id = block.page_id AND (
        kp.created_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM knowledge_page_collaborator kpc
          WHERE kpc.page_id = kp.id AND kpc.user_id = auth.uid() AND kpc.can_edit = true
        )
      )
    )
  );

-- Block property policies: Inherit from block
CREATE POLICY "Users can view block properties from accessible blocks" ON block_prop
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM block b
      JOIN knowledge_page kp ON kp.id = b.page_id
      WHERE b.id = block_prop.block_id AND (
        kp.created_by = auth.uid() OR
        kp.is_public = true OR
        EXISTS (
          SELECT 1 FROM knowledge_page_collaborator kpc
          WHERE kpc.page_id = kp.id AND kpc.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Users can manage block properties in their pages" ON block_prop
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM block b
      JOIN knowledge_page kp ON kp.id = b.page_id
      WHERE b.id = block_prop.block_id AND (
        kp.created_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM knowledge_page_collaborator kpc
          WHERE kpc.page_id = kp.id AND kpc.user_id = auth.uid() AND kpc.can_edit = true
        )
      )
    )
  );

-- Block history policies: Read-only access for users with page access
CREATE POLICY "Users can view block history from accessible pages" ON block_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM block b
      JOIN knowledge_page kp ON kp.id = b.page_id
      WHERE b.id = block_history.block_id AND (
        kp.created_by = auth.uid() OR
        kp.is_public = true OR
        EXISTS (
          SELECT 1 FROM knowledge_page_collaborator kpc
          WHERE kpc.page_id = kp.id AND kpc.user_id = auth.uid()
        )
      )
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_block_page_id ON block(page_id);
CREATE INDEX IF NOT EXISTS idx_block_position ON block(page_id, position);
CREATE INDEX IF NOT EXISTS idx_block_parent ON block(parent_block_id);
CREATE INDEX IF NOT EXISTS idx_block_type ON block(type);
CREATE INDEX IF NOT EXISTS idx_block_prop_block ON block_prop(block_id);
CREATE INDEX IF NOT EXISTS idx_block_prop_key ON block_prop(key);
CREATE INDEX IF NOT EXISTS idx_block_history_block ON block_history(block_id);
CREATE INDEX IF NOT EXISTS idx_block_history_created_at ON block_history(created_at);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_block_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_block_updated_at BEFORE UPDATE ON block FOR EACH ROW EXECUTE FUNCTION update_block_updated_at();
CREATE TRIGGER update_block_prop_updated_at BEFORE UPDATE ON block_prop FOR EACH ROW EXECUTE FUNCTION update_block_updated_at();

-- Function to migrate existing knowledge_page content to blocks
CREATE OR REPLACE FUNCTION migrate_page_content_to_blocks()
RETURNS void AS $$
DECLARE
  page_record RECORD;
  block_id UUID;
BEGIN
  FOR page_record IN SELECT id, title, content, created_by FROM knowledge_page WHERE content IS NOT NULL AND content != '' LOOP
    -- Create a heading block for the page title
    INSERT INTO block (page_id, type, content, position, created_by)
    VALUES (page_record.id, 'heading', jsonb_build_object('text', page_record.title, 'level', 1), 0, page_record.created_by);
    
    -- Create a text block for the page content
    INSERT INTO block (page_id, type, content, position, created_by)
    VALUES (page_record.id, 'text', jsonb_build_object('text', page_record.content), 1, page_record.created_by);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Insert sample blocks for testing
INSERT INTO block (page_id, type, content, position) VALUES
(
  (SELECT id FROM knowledge_page WHERE title = 'Getting Started' LIMIT 1),
  'heading',
  '{"text": "Welcome to Notion-Style Workspace", "level": 1}',
  0
),
(
  (SELECT id FROM knowledge_page WHERE title = 'Getting Started' LIMIT 1),
  'text',
  '{"text": "This is a sample text block demonstrating the block-based editor."}',
  1
),
(
  (SELECT id FROM knowledge_page WHERE title = 'Getting Started' LIMIT 1),
  'list',
  '{"items": ["Feature 1: Block-based editing", "Feature 2: Real-time collaboration", "Feature 3: Custom properties"], "type": "bullet"}',
  2
);

-- Add sample block properties
INSERT INTO block_prop (block_id, key, value, type) VALUES
(
  (SELECT id FROM block WHERE position = 0 LIMIT 1),
  'color',
  '"blue"',
  'select'
),
(
  (SELECT id FROM block WHERE position = 0 LIMIT 1),
  'tags',
  '["welcome", "introduction"]',
  'multi_select'
);

COMMENT ON TABLE block IS 'Block-based content storage for Notion-style editor';
COMMENT ON TABLE block_prop IS 'Custom properties and metadata for blocks';
COMMENT ON TABLE block_history IS 'Version history for block content changes';
COMMENT ON FUNCTION migrate_page_content_to_blocks IS 'Migrates existing knowledge_page content to block format';
