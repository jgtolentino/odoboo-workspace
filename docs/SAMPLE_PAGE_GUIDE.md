# Notion Workspace Sample Page - User Guide

**Sample Page**: OdoBoo Workspace - Feature Showcase
**Purpose**: Demonstrates all Notion-style features with full schema
**Date**: 2025-10-19

---

## Overview

The sample page (`scripts/11_notion_sample_page.sql`) creates a complete demonstration of the Notion workspace with:

- ✅ **16 content blocks** (all 9 block types)
- ✅ **5 database views** (table, board, calendar, gallery, list)
- ✅ **5 project tasks** with dependencies
- ✅ **2 time entries** (completed + in-progress)
- ✅ **3 custom properties** (Status, Tags, Sprint)
- ✅ **1 page template** (Feature Documentation)
- ✅ **Export/Import functions** (backup and restore)

---

## Installation

### Step 1: Apply Sample Data

```bash
# Navigate to project root
cd /Users/tbwa/Documents/GitHub/odoboo-workspace-temp

# Apply sample page
psql "$POSTGRES_URL" -f scripts/11_notion_sample_page.sql
```

**Expected Output**:
```
✅ Sample page created
total_blocks: 16
total_views: 5
total_tasks: 5
total_dependencies: 5
```

### Step 2: Verify Installation

```sql
-- Check content blocks
SELECT type, COUNT(*) as count
FROM content_blocks
WHERE page_id = '00000000-0000-0000-0000-000000000100'
GROUP BY type
ORDER BY type;

-- Expected output:
--  type     | count
-- ----------+-------
--  code     |  1
--  divider  |  1
--  embed    |  1
--  file     |  1
--  heading  |  6
--  image    |  1
--  list     |  1
--  quote    |  1
--  table    |  1
--  text     |  1
```

### Step 3: View Sample Page

**Page ID**: `00000000-0000-0000-0000-000000000100`

**URL**: `https://odoboo-workspace.vercel.app/pages/00000000-0000-0000-0000-000000000100`

---

## Block Types Demonstrated

### 1. Heading Block (6 instances)
**Purpose**: Section headers with 3 levels

**Examples**:
```json
{
  "text": "Welcome to OdoBoo Workspace",
  "level": 1
}
```

**Block IDs**:
- `...0200` - H1: Welcome to OdoBoo Workspace
- `...0203` - H2: Key Features
- `...0206` - H2: Code Example: Block Editor Hook
- `...0208` - H2: Performance Benchmarks
- `...0210` - H2: Architecture Diagram
- `...0212` - H2: Screenshot: Dashboard View
- `...0214` - H2: Documentation Files

**Use Cases**: Page structure, table of contents, organization

### 2. Text Block (1 instance)
**Purpose**: Rich text paragraphs with formatting

**Example**:
```json
{
  "text": "This is a comprehensive demonstration...",
  "formatting": [
    {
      "type": "bold",
      "start": 0,
      "end": 15
    }
  ]
}
```

**Block ID**: `...0201`

**Supported Formatting**:
- Bold, italic, underline
- Strikethrough
- Inline code
- Hyperlinks
- Text color

### 3. List Block (1 instance)
**Purpose**: Bullet or numbered lists

**Example**:
```json
{
  "items": [
    "📝 Block-based editor with 9 block types",
    "📊 Database views (table, board, calendar...)",
    "⏱️ Time tracking with real-time timers"
  ],
  "ordered": false
}
```

**Block ID**: `...0204`

**Features**:
- Unordered (bullets) or ordered (numbers)
- Nested lists (via parent_block_id)
- Emoji support

### 4. Quote Block (1 instance)
**Purpose**: Callout boxes and blockquotes

**Example**:
```json
{
  "text": "OdoBoo Workspace combines the best of Notion's UX...",
  "author": "OdoBoo Team"
}
```

**Block ID**: `...0205`

**Use Cases**: Pull quotes, testimonials, important notes

### 5. Code Block (1 instance)
**Purpose**: Syntax-highlighted code

**Example**:
```json
{
  "language": "typescript",
  "code": "export function useBlockEditor(pageId: string) { ... }"
}
```

**Block ID**: `...0207`

**Supported Languages**:
- TypeScript, JavaScript
- Python, SQL
- Bash, YAML, JSON
- And 100+ more via react-syntax-highlighter

### 6. Table Block (1 instance)
**Purpose**: Inline data tables

**Example**:
```json
{
  "headers": ["Metric", "Target", "Current", "Status"],
  "rows": [
    ["Page Load (TTI)", "< 2.5s", "2.1s", "✅ Pass"],
    ["Editor Latency", "< 100ms", "85ms", "✅ Pass"]
  ]
}
```

**Block ID**: `...0209`

**Features**:
- Dynamic columns
- Cell formatting
- Sortable headers (future)

### 7. Embed Block (1 instance)
**Purpose**: External content (Figma, YouTube, etc.)

**Example**:
```json
{
  "url": "https://www.figma.com/embed?...",
  "type": "figma",
  "width": 800,
  "height": 600
}
```

**Block ID**: `...0211`

**Supported Types**:
- Figma mockups
- YouTube videos
- Google Drive files
- Miro boards
- CodePen demos

### 8. Image Block (1 instance)
**Purpose**: Image uploads with captions

**Example**:
```json
{
  "url": "/screenshots/dashboard-view.png",
  "alt": "OdoBoo Dashboard - Table View with Filters",
  "width": 1200,
  "height": 800,
  "caption": "Dashboard showing table view..."
}
```

**Block ID**: `...0213`

**Features**:
- Resize and crop
- Alt text for accessibility
- Captions
- Storage in Supabase Storage

### 9. File Block (1 instance)
**Purpose**: File attachments

**Example**:
```json
{
  "url": "/docs/NOTION_WORKSPACE_DEPLOYMENT.md",
  "filename": "NOTION_WORKSPACE_DEPLOYMENT.md",
  "size": 45678,
  "type": "text/markdown",
  "uploaded_at": "2025-10-19T..."
}
```

**Block ID**: `...0215`

**Supported Types**: PDF, DOCX, XLSX, ZIP, any file type

### 10. Divider Block (1 instance)
**Purpose**: Visual separator

**Block ID**: `...0202`

**Use Cases**: Section breaks, visual organization

---

## Database Views

### 1. All Pages (Table View)
**View ID**: `...0900`
**Type**: table
**Entity**: knowledge_page

**Configuration**:
```json
{
  "filters": {},
  "sort_order": [{"column": "updated_at", "direction": "desc"}],
  "visible_columns": ["title", "status", "tags", "created_by", "updated_at"]
}
```

**Use Case**: Default view for all knowledge pages

### 2. Published Pages (Filtered Table)
**View ID**: `...0901`
**Type**: table
**Entity**: knowledge_page

**Configuration**:
```json
{
  "filters": {
    "property": "Status",
    "operator": "equals",
    "value": "Published"
  },
  "sort_order": [{"column": "title", "direction": "asc"}],
  "visible_columns": ["title", "tags", "updated_at"]
}
```

**Use Case**: Public-facing documentation

### 3. Task Board (Kanban View)
**View ID**: `...0902`
**Type**: board
**Entity**: project_task

**Configuration**:
```json
{
  "group_by": "status",
  "visible_columns": ["title", "assignee_id", "due_date", "priority"]
}
```

**Columns**:
- Pending
- In Progress
- Completed

**Use Case**: Agile project management

### 4. Task Timeline (Calendar View)
**View ID**: `...0903`
**Type**: calendar
**Entity**: project_task

**Use Case**: Sprint planning and deadline tracking

### 5. Documentation Gallery
**View ID**: `...0904`
**Type**: gallery
**Entity**: knowledge_page

**Configuration**:
```json
{
  "filters": {
    "property": "Tags",
    "operator": "contains",
    "value": "Documentation"
  },
  "visible_columns": ["title", "cover_image", "status"]
}
```

**Use Case**: Visual documentation browser

---

## Custom Properties

### 1. Status (Select)
**Property ID**: `...0700`
**Entity Type**: knowledge_page
**Type**: select

**Options**:
- Draft
- In Review
- Published
- Archived

**Use Case**: Content workflow management

### 2. Tags (Multi-Select)
**Property ID**: `...0701`
**Entity Type**: knowledge_page
**Type**: multi_select

**Options**:
- Documentation
- Tutorial
- Reference
- Feature
- Bug

**Use Case**: Content categorization

### 3. Sprint (Select)
**Property ID**: `...0702`
**Entity Type**: project_task
**Type**: select

**Options**:
- Sprint 1
- Sprint 2
- Sprint 3
- Backlog

**Use Case**: Sprint planning

---

## Task Dependencies

### Dependency Graph

```
Database Migration (completed)
  ↓ finish_to_start
BlockEditor Component (in_progress)
  ↓ finish_to_start
  ├─→ TableView Component (pending)
  └─→ Supabase Realtime (pending)
      ↓ finish_to_start
      Deploy to Production (pending)
```

### Dependency Types

1. **finish_to_start**: Task B starts when Task A finishes (most common)
2. **start_to_start**: Task B starts when Task A starts (parallel tasks)
3. **finish_to_finish**: Task B finishes when Task A finishes (synchronized completion)
4. **blocks**: Task A blocks Task B (hard dependency)

---

## Time Tracking

### Active Entries

| Task | User | Start | End | Duration | Billable | Description |
|------|------|-------|-----|----------|----------|-------------|
| Database Migration | demo@odoboo.com | 2h ago | 1h ago | 60 min | ✅ Yes | Applied schema and RLS |
| BlockEditor Component | demo@odoboo.com | 3h ago | **RUNNING** | **TBD** | ✅ Yes | Building with Tiptap |

### Time Tracking Features

- ⏱️ Real-time timer (start/stop)
- 📊 Automatic duration calculation
- 💰 Billable/non-billable tracking
- 👤 User assignment
- 📝 Activity descriptions
- 📈 Timesheet analytics

---

## Export/Import Functions

### Export Page to JSON

**Function**: `export_page_as_json(p_page_id UUID)`

**Usage**:
```sql
-- Export sample page
SELECT export_page_as_json('00000000-0000-0000-0000-000000000100'::uuid);
```

**Output**:
```json
{
  "page": {
    "id": "00000000-0000-0000-0000-000000000100",
    "company_id": "00000000-0000-0000-0000-000000000001",
    "title": "OdoBoo Workspace - Feature Showcase",
    "icon": "🚀",
    "created_at": "2025-10-19T..."
  },
  "blocks": [
    {
      "id": "00000000-0000-0000-0000-000000000200",
      "type": "heading",
      "content": {"text": "Welcome to OdoBoo Workspace", "level": 1},
      "position": 0
    }
    // ... all 16 blocks
  ],
  "properties": {
    "Status": "Published",
    "Tags": ["Documentation", "Feature"]
  },
  "exported_at": "2025-10-19T..."
}
```

**Use Cases**:
- Backup pages
- Version control
- Migration to other instances
- Sharing templates

### Import Page from JSON

**Function**: `import_page_from_json(p_company_id UUID, p_page_data JSONB)`

**Usage**:
```sql
-- Import from exported JSON
SELECT import_page_from_json(
  '00000000-0000-0000-0000-000000000001'::uuid,
  '{"page": {...}, "blocks": [...], "properties": {...}}'::jsonb
);
```

**Returns**: New page ID

**Use Cases**:
- Restore from backup
- Duplicate pages
- Import templates
- Cross-company sharing

### Backup Workflow

```bash
# 1. Export page to JSON file
psql "$POSTGRES_URL" -t -A -c "
  SELECT export_page_as_json('00000000-0000-0000-0000-000000000100'::uuid)
" > backup/page_$(date +%Y%m%d_%H%M%S).json

# 2. Create ZIP archive (the "zipper file" you requested)
zip -r backup_$(date +%Y%m%d_%H%M%S).zip backup/*.json

# 3. Restore from JSON
PAGE_DATA=$(cat backup/page_20251019_120000.json)
psql "$POSTGRES_URL" -c "
  SELECT import_page_from_json(
    '00000000-0000-0000-0000-000000000001'::uuid,
    '$PAGE_DATA'::jsonb
  )
"
```

---

## Page Template

### Feature Documentation Template

**Template ID**: `...1000`
**Entity Type**: knowledge_page
**Public**: Yes

**Structure**:
1. H1: Feature Name
2. Text: Brief description
3. Divider
4. H2: Overview
5. List: Key capabilities (3 items)
6. H2: Implementation
7. Code: TypeScript example
8. H2: Screenshots
9. Image: Feature screenshot

**Default Properties**:
- Status: Draft
- Tags: Feature, Documentation

**Usage**:
```sql
-- Create new page from template
INSERT INTO knowledge_pages (company_id, title, created_by, created_at, updated_at)
VALUES ('your-company-id', 'New Feature', auth.uid(), NOW(), NOW())
RETURNING id;

-- Apply template structure
-- (Frontend will handle this via template selector)
```

---

## Frontend Integration

### Loading Sample Page

**React Component**:
```typescript
'use client';

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { BlockEditor } from '@/components/editor/BlockEditor';

export default function SamplePage() {
  const [blocks, setBlocks] = useState([]);
  const supabase = createClient();

  useEffect(() => {
    const loadPage = async () => {
      const { data } = await supabase
        .from('content_blocks')
        .select('*')
        .eq('page_id', '00000000-0000-0000-0000-000000000100')
        .order('position');

      setBlocks(data || []);
    };

    loadPage();
  }, []);

  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">
        🚀 OdoBoo Workspace - Feature Showcase
      </h1>
      <BlockEditor blocks={blocks} pageId="00000000-0000-0000-0000-000000000100" />
    </div>
  );
}
```

### Real-time Updates

**Subscription Setup**:
```typescript
useEffect(() => {
  const channel = supabase
    .channel('page:00000000-0000-0000-0000-000000000100')
    .on('postgres_changes', {
      event: '*',
      schema: 'public',
      table: 'content_blocks',
      filter: 'page_id=eq.00000000-0000-0000-0000-000000000100'
    }, (payload) => {
      console.log('Block changed:', payload);
      // Refresh blocks
    })
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}, []);
```

---

## Testing Checklist

### Block Types
- [ ] View all 16 blocks in sample page
- [ ] Edit text block
- [ ] Change heading level
- [ ] Reorder blocks (drag-and-drop)
- [ ] Add new block (slash command)
- [ ] Delete block
- [ ] Syntax highlighting in code block
- [ ] Embed renders correctly
- [ ] Image loads with caption
- [ ] File download works

### Database Views
- [ ] Switch between table/board/calendar/gallery/list
- [ ] Filter by Status property
- [ ] Filter by Tags (multi-select)
- [ ] Sort by updated_at
- [ ] Group tasks by status (board view)
- [ ] View tasks in calendar by due_date
- [ ] Save view configuration
- [ ] Share view with team

### Task Management
- [ ] View task dependencies graph
- [ ] Calculate critical path
- [ ] Start time tracker for task
- [ ] Stop timer (calculate duration)
- [ ] View timesheet summary
- [ ] Filter billable vs non-billable time

### Export/Import
- [ ] Export sample page to JSON
- [ ] Create ZIP backup
- [ ] Import page from JSON
- [ ] Verify all blocks preserved
- [ ] Verify properties preserved

### Real-time
- [ ] Open page in 2 browsers
- [ ] Edit block in browser 1
- [ ] Verify update in browser 2 (< 500ms)
- [ ] Check presence indicators
- [ ] Test cursor tracking (future)

---

## Next Steps

### 1. Apply Database Schema

```bash
# First time setup
psql "$POSTGRES_URL" -f scripts/09_notion_workspace_schema.sql

# Then apply sample data
psql "$POSTGRES_URL" -f scripts/11_notion_sample_page.sql
```

### 2. Build Frontend Components

```bash
# Install dependencies
npm install @tiptap/react @tiptap/starter-kit @dnd-kit/core @tanstack/react-table react-syntax-highlighter

# Create BlockEditor component
mkdir -p app/components/editor/blocks
touch app/components/editor/BlockEditor.tsx
touch app/components/editor/blocks/{TextBlock,HeadingBlock,ListBlock}.tsx
```

### 3. Test Sample Page

```bash
# Start dev server
npm run dev

# Open browser
open http://localhost:3000/pages/00000000-0000-0000-0000-000000000100
```

### 4. Deploy to Production

```bash
# Build
npm run build

# Deploy to Vercel
vercel --prod

# Verify
curl https://odoboo-workspace.vercel.app/health
```

---

## Troubleshooting

### Issue: Blocks not loading

**Symptoms**: Empty page, no blocks visible

**Solution**:
```sql
-- Check if blocks exist
SELECT COUNT(*) FROM content_blocks WHERE page_id = '00000000-0000-0000-0000-000000000100';

-- If 0, re-run script
\i scripts/11_notion_sample_page.sql
```

### Issue: RLS policy blocking access

**Symptoms**: "new row violates row-level security policy"

**Solution**:
```sql
-- Check if user has company_id
SELECT auth.uid(), ops.jwt_company_id();

-- If NULL, set company_id in JWT claims
UPDATE auth.users SET raw_app_meta_data = jsonb_set(
  COALESCE(raw_app_meta_data, '{}'::jsonb),
  '{company_id}',
  '"00000000-0000-0000-0000-000000000001"'::jsonb
)
WHERE id = auth.uid();
```

### Issue: Export function fails

**Symptoms**: "function export_page_as_json does not exist"

**Solution**:
```bash
# Re-run script to create functions
psql "$POSTGRES_URL" -f scripts/11_notion_sample_page.sql
```

---

**Last Updated**: 2025-10-19
**Sample Page ID**: `00000000-0000-0000-0000-000000000100`
**Total Blocks**: 16
**Total Views**: 5
**Total Tasks**: 5
