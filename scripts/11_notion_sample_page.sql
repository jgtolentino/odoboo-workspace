-- ============================================================================
-- Notion Workspace Sample Page - Full Schema Demonstration
-- ============================================================================
-- Purpose: Create sample page with all block types, views, and features
-- Author: Claude Code
-- Date: 2025-10-19
-- ============================================================================

-- Step 1: Create sample company (if not exists)
-- ============================================================================

INSERT INTO companies (id, name, created_at, updated_at)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Demo Company',
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Create sample user (if not exists)
-- ============================================================================

INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'demo@odoboo.com',
  crypt('demo123', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Step 3: Create sample knowledge page
-- ============================================================================

INSERT INTO knowledge_pages (
  id,
  company_id,
  title,
  icon,
  cover_image,
  created_by,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000100'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  'OdoBoo Workspace - Feature Showcase',
  '🚀',
  NULL,
  '00000000-0000-0000-0000-000000000001'::uuid,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Step 4: Create content blocks (all 9 types)
-- ============================================================================

-- Block 1: Heading (Introduction)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000200'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Welcome to OdoBoo Workspace',
    'level', 1
  ),
  0,
  NULL,
  NOW(),
  NOW()
);

-- Block 2: Text (Introduction paragraph)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000201'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'text',
  jsonb_build_object(
    'text', 'This is a comprehensive demonstration of all Notion-style features available in OdoBoo Workspace. Explore block-based editing, database views, task management, and real-time collaboration.',
    'formatting', jsonb_build_array(
      jsonb_build_object('type', 'bold', 'start', 0, 'end', 15)
    )
  ),
  1,
  NULL,
  NOW(),
  NOW()
);

-- Block 3: Divider
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000202'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'divider',
  jsonb_build_object(),
  2,
  NULL,
  NOW(),
  NOW()
);

-- Block 4: Heading (Features section)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000203'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Key Features',
    'level', 2
  ),
  3,
  NULL,
  NOW(),
  NOW()
);

-- Block 5: List (Bullet points)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000204'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'list',
  jsonb_build_object(
    'items', jsonb_build_array(
      '📝 Block-based editor with 9 block types',
      '📊 Database views (table, board, calendar, gallery, list)',
      '⏱️ Time tracking with real-time timers',
      '🔗 Task dependencies with critical path',
      '🎨 Custom properties for dynamic metadata',
      '📄 Page templates for quick content creation',
      '👥 Real-time collaboration with presence',
      '🔍 Full-text search across all content'
    ),
    'ordered', false
  ),
  4,
  NULL,
  NOW(),
  NOW()
);

-- Block 6: Quote
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000205'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'quote',
  jsonb_build_object(
    'text', 'OdoBoo Workspace combines the best of Notion''s user experience with Odoo''s business logic, creating a modern workspace for knowledge management and project collaboration.',
    'author', 'OdoBoo Team'
  ),
  5,
  NULL,
  NOW(),
  NOW()
);

-- Block 7: Heading (Code example)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000206'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Code Example: Block Editor Hook',
    'level', 2
  ),
  6,
  NULL,
  NOW(),
  NOW()
);

-- Block 8: Code (TypeScript example)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000207'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'code',
  jsonb_build_object(
    'language', 'typescript',
    'code', 'export function useBlockEditor(pageId: string) {
  const [blocks, setBlocks] = useState<Block[]>([]);
  const supabase = createClient();

  useEffect(() => {
    // Load blocks
    const loadBlocks = async () => {
      const { data } = await supabase
        .from(''content_blocks'')
        .select(''*'')
        .eq(''page_id'', pageId)
        .order(''position'');

      setBlocks(data || []);
    };

    // Real-time subscription
    const channel = supabase
      .channel(`page:${pageId}`)
      .on(''postgres_changes'', {
        event: ''*'',
        schema: ''public'',
        table: ''content_blocks'',
        filter: `page_id=eq.${pageId}`
      }, loadBlocks)
      .subscribe();

    loadBlocks();
    return () => { supabase.removeChannel(channel); };
  }, [pageId]);

  return { blocks, setBlocks };
}'
  ),
  7,
  NULL,
  NOW(),
  NOW()
);

-- Block 9: Heading (Table example)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000208'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Performance Benchmarks',
    'level', 2
  ),
  8,
  NULL,
  NOW(),
  NOW()
);

-- Block 10: Table
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000209'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'table',
  jsonb_build_object(
    'headers', jsonb_build_array('Metric', 'Target', 'Current', 'Status'),
    'rows', jsonb_build_array(
      jsonb_build_array('Page Load (TTI)', '< 2.5s', '2.1s', '✅ Pass'),
      jsonb_build_array('Editor Latency', '< 100ms', '85ms', '✅ Pass'),
      jsonb_build_array('Search Response', '< 500ms', '420ms', '✅ Pass'),
      jsonb_build_array('Real-time Sync', '< 500ms', '380ms', '✅ Pass')
    )
  ),
  9,
  NULL,
  NOW(),
  NOW()
);

-- Block 11: Heading (Embedded content)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000210'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Architecture Diagram',
    'level', 2
  ),
  10,
  NULL,
  NOW(),
  NOW()
);

-- Block 12: Embed (Figma mockup)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000211'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'embed',
  jsonb_build_object(
    'url', 'https://www.figma.com/embed?embed_host=odoboo&url=https://www.figma.com/file/sample',
    'type', 'figma',
    'width', 800,
    'height', 600
  ),
  11,
  NULL,
  NOW(),
  NOW()
);

-- Block 13: Heading (Image example)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000212'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Screenshot: Dashboard View',
    'level', 2
  ),
  12,
  NULL,
  NOW(),
  NOW()
);

-- Block 14: Image
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000213'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'image',
  jsonb_build_object(
    'url', '/screenshots/dashboard-view.png',
    'alt', 'OdoBoo Dashboard - Table View with Filters',
    'width', 1200,
    'height', 800,
    'caption', 'Dashboard showing table view with custom filters and sorting'
  ),
  13,
  NULL,
  NOW(),
  NOW()
);

-- Block 15: Heading (Attachments)
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000214'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'heading',
  jsonb_build_object(
    'text', 'Documentation Files',
    'level', 2
  ),
  14,
  NULL,
  NOW(),
  NOW()
);

-- Block 16: File attachment
INSERT INTO content_blocks (
  id,
  page_id,
  type,
  content,
  position,
  parent_block_id,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000215'::uuid,
  '00000000-0000-0000-0000-000000000100'::uuid,
  'file',
  jsonb_build_object(
    'url', '/docs/NOTION_WORKSPACE_DEPLOYMENT.md',
    'filename', 'NOTION_WORKSPACE_DEPLOYMENT.md',
    'size', 45678,
    'type', 'text/markdown',
    'uploaded_at', NOW()
  ),
  15,
  NULL,
  NOW(),
  NOW()
);

-- Step 5: Create sample tasks for demonstration
-- ============================================================================

-- Sample project
INSERT INTO projects (
  id,
  company_id,
  name,
  description,
  status,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000300'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Notion Workspace Launch',
  'Deploy Notion-style workspace with all features',
  'in_progress',
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Sample tasks
INSERT INTO project_tasks (
  id,
  company_id,
  project_id,
  title,
  description,
  status,
  priority,
  assignee_id,
  due_date,
  created_at,
  updated_at
)
VALUES
  -- Task 1: Database migration
  (
    '00000000-0000-0000-0000-000000000400'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000300'::uuid,
    'Apply database migrations',
    'Deploy 09_notion_workspace_schema.sql and 10_notion_workspace_rls.sql',
    'completed',
    'high',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() + INTERVAL '1 day',
    NOW() - INTERVAL '1 day',
    NOW()
  ),
  -- Task 2: Frontend components
  (
    '00000000-0000-0000-0000-000000000401'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000300'::uuid,
    'Build BlockEditor component',
    'Create main editor container with Tiptap integration',
    'in_progress',
    'high',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() + INTERVAL '2 days',
    NOW(),
    NOW()
  ),
  -- Task 3: Database views
  (
    '00000000-0000-0000-0000-000000000402'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000300'::uuid,
    'Implement TableView component',
    'Create table view with filters and sorting',
    'pending',
    'medium',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() + INTERVAL '3 days',
    NOW(),
    NOW()
  ),
  -- Task 4: Real-time sync
  (
    '00000000-0000-0000-0000-000000000403'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000300'::uuid,
    'Set up Supabase Realtime',
    'Configure real-time subscriptions for collaborative editing',
    'pending',
    'high',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() + INTERVAL '3 days',
    NOW(),
    NOW()
  ),
  -- Task 5: Deployment
  (
    '00000000-0000-0000-0000-000000000404'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000300'::uuid,
    'Deploy to Vercel production',
    'Build, test, and deploy to production',
    'pending',
    'high',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() + INTERVAL '4 days',
    NOW(),
    NOW()
  );

-- Step 6: Create task dependencies
-- ============================================================================

INSERT INTO task_dependencies (
  id,
  task_id,
  depends_on_task_id,
  dependency_type,
  created_at
)
VALUES
  -- Frontend depends on database migration
  (
    '00000000-0000-0000-0000-000000000500'::uuid,
    '00000000-0000-0000-0000-000000000401'::uuid,
    '00000000-0000-0000-0000-000000000400'::uuid,
    'finish_to_start',
    NOW()
  ),
  -- Database views depend on BlockEditor
  (
    '00000000-0000-0000-0000-000000000501'::uuid,
    '00000000-0000-0000-0000-000000000402'::uuid,
    '00000000-0000-0000-0000-000000000401'::uuid,
    'finish_to_start',
    NOW()
  ),
  -- Real-time depends on BlockEditor
  (
    '00000000-0000-0000-0000-000000000502'::uuid,
    '00000000-0000-0000-0000-000000000403'::uuid,
    '00000000-0000-0000-0000-000000000401'::uuid,
    'finish_to_start',
    NOW()
  ),
  -- Deployment depends on all features
  (
    '00000000-0000-0000-0000-000000000503'::uuid,
    '00000000-0000-0000-0000-000000000404'::uuid,
    '00000000-0000-0000-0000-000000000402'::uuid,
    'finish_to_start',
    NOW()
  ),
  (
    '00000000-0000-0000-0000-000000000504'::uuid,
    '00000000-0000-0000-0000-000000000404'::uuid,
    '00000000-0000-0000-0000-000000000403'::uuid,
    'finish_to_start',
    NOW()
  );

-- Step 7: Create time entries
-- ============================================================================

INSERT INTO time_entries (
  id,
  task_id,
  user_id,
  start_time,
  end_time,
  duration_minutes,
  billable,
  description,
  created_at,
  updated_at
)
VALUES
  -- Time entry for database migration
  (
    '00000000-0000-0000-0000-000000000600'::uuid,
    '00000000-0000-0000-0000-000000000400'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '1 hour',
    60,
    true,
    'Applied database schema and RLS policies',
    NOW(),
    NOW()
  ),
  -- Time entry for BlockEditor (in progress)
  (
    '00000000-0000-0000-0000-000000000601'::uuid,
    '00000000-0000-0000-0000-000000000401'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() - INTERVAL '3 hours',
    NULL,
    NULL,
    true,
    'Building BlockEditor component with Tiptap',
    NOW(),
    NOW()
  );

-- Step 8: Create custom properties
-- ============================================================================

INSERT INTO custom_properties (
  id,
  company_id,
  entity_type,
  name,
  type,
  options,
  created_at,
  updated_at
)
VALUES
  -- Status property for knowledge pages
  (
    '00000000-0000-0000-0000-000000000700'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'knowledge_page',
    'Status',
    'select',
    jsonb_build_array('Draft', 'In Review', 'Published', 'Archived'),
    NOW(),
    NOW()
  ),
  -- Tags property for knowledge pages
  (
    '00000000-0000-0000-0000-000000000701'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'knowledge_page',
    'Tags',
    'multi_select',
    jsonb_build_array('Documentation', 'Tutorial', 'Reference', 'Feature', 'Bug'),
    NOW(),
    NOW()
  ),
  -- Priority property for tasks
  (
    '00000000-0000-0000-0000-000000000702'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'project_task',
    'Sprint',
    'select',
    jsonb_build_array('Sprint 1', 'Sprint 2', 'Sprint 3', 'Backlog'),
    NOW(),
    NOW()
  );

-- Step 9: Set property values for sample page
-- ============================================================================

INSERT INTO property_values (
  id,
  entity_type,
  entity_id,
  property_id,
  value,
  created_at,
  updated_at
)
VALUES
  -- Status: Published
  (
    '00000000-0000-0000-0000-000000000800'::uuid,
    'knowledge_page',
    '00000000-0000-0000-0000-000000000100'::uuid,
    '00000000-0000-0000-0000-000000000700'::uuid,
    jsonb_build_object('value', 'Published'),
    NOW(),
    NOW()
  ),
  -- Tags: Documentation, Feature
  (
    '00000000-0000-0000-0000-000000000801'::uuid,
    'knowledge_page',
    '00000000-0000-0000-0000-000000000100'::uuid,
    '00000000-0000-0000-0000-000000000701'::uuid,
    jsonb_build_object('values', jsonb_build_array('Documentation', 'Feature')),
    NOW(),
    NOW()
  );

-- Step 10: Create database views
-- ============================================================================

-- Table view for all knowledge pages
INSERT INTO database_views (
  id,
  company_id,
  name,
  type,
  entity_type,
  filters,
  sort_order,
  visible_columns,
  group_by,
  created_at,
  updated_at
)
VALUES
  -- All Pages (Table View)
  (
    '00000000-0000-0000-0000-000000000900'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'All Pages',
    'table',
    'knowledge_page',
    jsonb_build_object(),
    jsonb_build_array(
      jsonb_build_object('column', 'updated_at', 'direction', 'desc')
    ),
    jsonb_build_array('title', 'status', 'tags', 'created_by', 'updated_at'),
    NULL,
    NOW(),
    NOW()
  ),
  -- Published Pages (Table View with Filter)
  (
    '00000000-0000-0000-0000-000000000901'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Published Pages',
    'table',
    'knowledge_page',
    jsonb_build_object(
      'property', 'Status',
      'operator', 'equals',
      'value', 'Published'
    ),
    jsonb_build_array(
      jsonb_build_object('column', 'title', 'direction', 'asc')
    ),
    jsonb_build_array('title', 'tags', 'updated_at'),
    NULL,
    NOW(),
    NOW()
  ),
  -- Project Tasks (Board View - Kanban)
  (
    '00000000-0000-0000-0000-000000000902'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Task Board',
    'board',
    'project_task',
    jsonb_build_object(),
    jsonb_build_array(
      jsonb_build_object('column', 'priority', 'direction', 'desc')
    ),
    jsonb_build_array('title', 'assignee_id', 'due_date', 'priority'),
    'status',
    NOW(),
    NOW()
  ),
  -- Task Timeline (Calendar View)
  (
    '00000000-0000-0000-0000-000000000903'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Task Timeline',
    'calendar',
    'project_task',
    jsonb_build_object(),
    jsonb_build_array(),
    jsonb_build_array('title', 'status', 'assignee_id'),
    NULL,
    NOW(),
    NOW()
  ),
  -- Documentation Gallery
  (
    '00000000-0000-0000-0000-000000000904'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Documentation Gallery',
    'gallery',
    'knowledge_page',
    jsonb_build_object(
      'property', 'Tags',
      'operator', 'contains',
      'value', 'Documentation'
    ),
    jsonb_build_array(
      jsonb_build_object('column', 'title', 'direction', 'asc')
    ),
    jsonb_build_array('title', 'cover_image', 'status'),
    NULL,
    NOW(),
    NOW()
  );

-- Step 11: Create page template
-- ============================================================================

INSERT INTO page_templates (
  id,
  company_id,
  name,
  description,
  entity_type,
  is_public,
  block_structure,
  default_properties,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000001000'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Feature Documentation',
  'Template for documenting new features with code examples and screenshots',
  'knowledge_page',
  true,
  jsonb_build_array(
    jsonb_build_object('type', 'heading', 'content', jsonb_build_object('text', 'Feature Name', 'level', 1)),
    jsonb_build_object('type', 'text', 'content', jsonb_build_object('text', 'Brief description of the feature...')),
    jsonb_build_object('type', 'divider', 'content', jsonb_build_object()),
    jsonb_build_object('type', 'heading', 'content', jsonb_build_object('text', 'Overview', 'level', 2)),
    jsonb_build_object('type', 'list', 'content', jsonb_build_object('items', jsonb_build_array('Key capability 1', 'Key capability 2', 'Key capability 3'), 'ordered', false)),
    jsonb_build_object('type', 'heading', 'content', jsonb_build_object('text', 'Implementation', 'level', 2)),
    jsonb_build_object('type', 'code', 'content', jsonb_build_object('language', 'typescript', 'code', '// Add implementation code here')),
    jsonb_build_object('type', 'heading', 'content', jsonb_build_object('text', 'Screenshots', 'level', 2)),
    jsonb_build_object('type', 'image', 'content', jsonb_build_object('url', '', 'alt', 'Feature screenshot'))
  ),
  jsonb_build_object(
    'Status', 'Draft',
    'Tags', jsonb_build_array('Feature', 'Documentation')
  ),
  NOW(),
  NOW()
);

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Count blocks by type
SELECT
  type,
  COUNT(*) as count
FROM content_blocks
WHERE page_id = '00000000-0000-0000-0000-000000000100'::uuid
GROUP BY type
ORDER BY type;

-- Show all database views
SELECT
  name,
  type,
  entity_type,
  jsonb_array_length(visible_columns) as column_count
FROM database_views
ORDER BY created_at;

-- Show task dependencies
SELECT
  t1.title as task,
  t2.title as depends_on,
  td.dependency_type
FROM task_dependencies td
JOIN project_tasks t1 ON t1.id = td.task_id
JOIN project_tasks t2 ON t2.id = td.depends_on_task_id
ORDER BY t1.title;

-- Show time tracking summary
SELECT
  pt.title,
  COUNT(te.id) as entries,
  SUM(te.duration_minutes) as total_minutes,
  SUM(CASE WHEN te.billable THEN te.duration_minutes ELSE 0 END) as billable_minutes
FROM project_tasks pt
LEFT JOIN time_entries te ON te.task_id = pt.id
GROUP BY pt.id, pt.title
ORDER BY pt.title;

-- ============================================================================
-- Export/Backup Function
-- ============================================================================

CREATE OR REPLACE FUNCTION export_page_as_json(p_page_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'page', (
      SELECT to_jsonb(kp) FROM knowledge_pages kp WHERE kp.id = p_page_id
    ),
    'blocks', (
      SELECT jsonb_agg(to_jsonb(cb) ORDER BY cb.position)
      FROM content_blocks cb
      WHERE cb.page_id = p_page_id
    ),
    'properties', (
      SELECT jsonb_object_agg(
        cp.name,
        pv.value
      )
      FROM property_values pv
      JOIN custom_properties cp ON cp.id = pv.property_id
      WHERE pv.entity_id = p_page_id
      AND pv.entity_type = 'knowledge_page'
    ),
    'exported_at', NOW()
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION export_page_as_json IS 'Export complete page with blocks and properties as JSON';

-- ============================================================================
-- Import Function
-- ============================================================================

CREATE OR REPLACE FUNCTION import_page_from_json(
  p_company_id UUID,
  p_page_data JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_page_id UUID;
  v_block JSONB;
  v_position INTEGER := 0;
BEGIN
  -- Create new page
  INSERT INTO knowledge_pages (
    company_id,
    title,
    icon,
    cover_image,
    created_by,
    created_at,
    updated_at
  )
  VALUES (
    p_company_id,
    p_page_data->'page'->>'title',
    p_page_data->'page'->>'icon',
    p_page_data->'page'->>'cover_image',
    auth.uid(),
    NOW(),
    NOW()
  )
  RETURNING id INTO v_new_page_id;

  -- Import blocks
  FOR v_block IN SELECT * FROM jsonb_array_elements(p_page_data->'blocks')
  LOOP
    INSERT INTO content_blocks (
      page_id,
      type,
      content,
      position,
      created_at,
      updated_at
    )
    VALUES (
      v_new_page_id,
      v_block->>'type',
      v_block->'content',
      v_position,
      NOW(),
      NOW()
    );

    v_position := v_position + 1;
  END LOOP;

  RETURN v_new_page_id;
END;
$$;

COMMENT ON FUNCTION import_page_from_json IS 'Import page from exported JSON';

-- ============================================================================
-- Usage Examples
-- ============================================================================

-- Export sample page to JSON
SELECT export_page_as_json('00000000-0000-0000-0000-000000000100'::uuid);

-- Import would be:
-- SELECT import_page_from_json(
--   '00000000-0000-0000-0000-000000000001'::uuid,
--   '{"page": {...}, "blocks": [...], "properties": {...}}'::jsonb
-- );

-- ============================================================================
-- Success Summary
-- ============================================================================

SELECT
  '✅ Sample page created' as message,
  (SELECT COUNT(*) FROM content_blocks WHERE page_id = '00000000-0000-0000-0000-000000000100') as total_blocks,
  (SELECT COUNT(*) FROM database_views) as total_views,
  (SELECT COUNT(*) FROM project_tasks WHERE project_id = '00000000-0000-0000-0000-000000000300') as total_tasks,
  (SELECT COUNT(*) FROM task_dependencies) as total_dependencies;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
