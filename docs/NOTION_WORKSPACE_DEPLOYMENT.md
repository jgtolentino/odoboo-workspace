# Notion Workspace Deployment Checklist

**Priority**: ASAP Deployment
**Status**: Ready for implementation
**Timeline**: 2-3 days for MVP
**Date**: 2025-10-19

---

## Executive Summary

Deploy Notion-style workspace with block-based editor, database views, and real-time collaboration.

**Key Features**:
- ✅ Block-based content editor (9 block types)
- ✅ Database views (table, board, calendar, gallery, list)
- ✅ Task dependencies & time tracking
- ✅ Custom properties (metadata system)
- ✅ Real-time collaboration
- ✅ Page templates

**Current State**:
- ✅ Database schema exists (`scripts/09_notion_workspace_schema.sql`)
- ✅ Roadmap exists (`docs/Notion-Workspace-Roadmap.md`)
- ⚠️ Frontend components need creation
- ⚠️ Schema needs migration to Supabase

---

## Required Database Modules

### 1. Content Blocks System ✅
**Table**: `content_blocks`
**Purpose**: Block-based editor foundation
**Block Types**:
- `text` - Rich text paragraphs
- `heading` - H1, H2, H3 headings
- `list` - Ordered/unordered lists
- `table` - Data tables
- `embed` - External content (YouTube, Figma, etc.)
- `code` - Syntax-highlighted code blocks
- `image` - Image uploads
- `file` - File attachments
- `divider` - Visual separators
- `quote` - Blockquotes

**Schema Status**: ✅ Exists in `09_notion_workspace_schema.sql`

### 2. Database Views ✅
**Table**: `database_views`
**Purpose**: Notion-style database views
**View Types**:
- `table` - Spreadsheet-like grid
- `board` - Kanban boards
- `calendar` - Timeline view
- `gallery` - Card-based gallery
- `list` - Compact list view

**Features**:
- Filters (JSONB configuration)
- Sort orders (multi-column)
- Visible columns (column selection)
- Group by (aggregation)

**Schema Status**: ✅ Exists in `09_notion_workspace_schema.sql`

### 3. Task Dependencies ✅
**Table**: `task_dependencies`
**Purpose**: Project management with task relationships
**Dependency Types**:
- `blocks` - Task A blocks Task B
- `finish_to_start` - Task B starts when A finishes
- `start_to_start` - Task B starts when A starts
- `finish_to_finish` - Task B finishes when A finishes

**Features**:
- Circular dependency prevention
- Critical path calculation
- Gantt chart support

**Schema Status**: ✅ Exists in `09_notion_workspace_schema.sql`

### 4. Time Tracking ✅
**Table**: `time_entries`
**Purpose**: Time tracking for tasks and projects
**Features**:
- Real-time timer (start/end timestamps)
- Duration calculation (minutes)
- Billable/non-billable tracking
- User assignment
- Task association

**Schema Status**: ✅ Exists in `09_notion_workspace_schema.sql`

### 5. Custom Properties ✅
**Tables**: `custom_properties`, `property_values`
**Purpose**: Metadata system for dynamic fields
**Property Types**:
- `text` - Text input
- `number` - Numeric values
- `date` - Date picker
- `select` - Single select dropdown
- `multi_select` - Multiple selection
- `person` - User assignment
- `file` - File attachment
- `checkbox` - Boolean toggle
- `url` - URL validation
- `email` - Email validation
- `phone` - Phone number

**Schema Status**: ✅ Exists in `09_notion_workspace_schema.sql`

### 6. Page Templates ✅
**Table**: `page_templates`
**Purpose**: Quick page creation with predefined layouts
**Features**:
- Template library
- Block structure definition
- Custom property defaults
- Entity type targeting (knowledge_page, project_task, vendor_document)

**Schema Status**: ✅ Exists in `09_notion_workspace_schema.sql`

---

## Required Frontend Components

### Phase 1: Core Editor (Days 1-2)

#### 1.1 Block Editor Components
**Location**: `app/components/editor/`
**Status**: ⚠️ Needs creation

**Components to Build**:
```typescript
// app/components/editor/BlockEditor.tsx
// Main editor container with drag-and-drop

// app/components/editor/blocks/
├── TextBlock.tsx          // Rich text with formatting
├── HeadingBlock.tsx       // H1/H2/H3 with slash command
├── ListBlock.tsx          // Bullet/numbered lists
├── TableBlock.tsx         // Inline tables
├── EmbedBlock.tsx         // YouTube, Figma, etc.
├── CodeBlock.tsx          // Syntax highlighting
├── ImageBlock.tsx         // Image upload + resize
├── FileBlock.tsx          // File attachments
├── DividerBlock.tsx       // Visual separator
└── QuoteBlock.tsx         // Blockquotes
```

**Dependencies**:
- `@tiptap/react` - Rich text editing
- `@tiptap/starter-kit` - Basic formatting
- `@dnd-kit/core` - Drag and drop
- `react-syntax-highlighter` - Code blocks
- Supabase Storage - File uploads

**Priority**: 🔴 Critical (MVP requirement)

#### 1.2 Block Toolbar
**Location**: `app/components/editor/BlockToolbar.tsx`
**Features**:
- Drag handle
- Block type selector
- Delete block
- Duplicate block
- Move up/down

**Priority**: 🔴 Critical

#### 1.3 Slash Command Palette
**Location**: `app/components/editor/SlashCommand.tsx`
**Features**:
- `/` to open command menu
- Fuzzy search for block types
- Keyboard navigation
- Quick block insertion

**Priority**: 🟡 Important (Week 2)

### Phase 2: Database Views (Day 3)

#### 2.1 View Switcher
**Location**: `app/components/views/`
**Status**: ⚠️ Needs creation

**Components to Build**:
```typescript
// app/components/views/
├── TableView.tsx          // Spreadsheet grid
├── BoardView.tsx          // Kanban columns
├── CalendarView.tsx       // Monthly calendar
├── GalleryView.tsx        // Card gallery
├── ListView.tsx           // Compact list
└── ViewSwitcher.tsx       // View type selector
```

**Features**:
- View configuration (filters, sorts, columns)
- View persistence (save to `database_views` table)
- Quick view switching
- View sharing (company-wide)

**Dependencies**:
- `@tanstack/react-table` - Table view
- `@hello-pangea/dnd` - Board view (Kanban)
- `react-big-calendar` - Calendar view
- Tailwind CSS - Styling

**Priority**: 🟡 Important (MVP can ship with Table view only)

#### 2.2 Filters & Sorting
**Location**: `app/components/views/FilterBar.tsx`
**Features**:
- Filter builder UI
- Multi-column sorting
- Filter presets
- AND/OR logic

**Priority**: 🟢 Nice-to-have (Week 3)

### Phase 3: Real-time Collaboration (Day 3)

#### 3.1 Presence Indicators
**Location**: `app/components/collaboration/`
**Status**: ⚠️ Needs creation

**Components to Build**:
```typescript
// app/components/collaboration/
├── PresenceAvatars.tsx    // Who's viewing
├── CursorTracking.tsx     // Live cursors
├── SelectionHighlight.tsx // Show selections
└── CommentThread.tsx      // Inline comments
```

**Dependencies**:
- Supabase Realtime (broadcast channel)
- `@supabase/realtime-js` - Presence API

**Priority**: 🟢 Nice-to-have (can ship without)

---

## Deployment Steps (In Order)

### Step 1: Database Migration ✅
**Estimated Time**: 15 minutes
**Commands**:
```bash
# Navigate to project root
cd /Users/tbwa/Documents/GitHub/odoboo-workspace-temp

# Apply Notion workspace schema
psql "$POSTGRES_URL" -f scripts/09_notion_workspace_schema.sql

# Verify tables created
psql "$POSTGRES_URL" -c "\dt"
```

**Validation**:
```sql
-- Check all tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'content_blocks',
  'database_views',
  'task_dependencies',
  'time_entries',
  'custom_properties',
  'property_values',
  'page_templates'
);

-- Should return 7 rows
```

**Success Criteria**: All 7 tables exist in database

### Step 2: RLS Policies ✅
**Estimated Time**: 30 minutes
**File**: Create `scripts/10_notion_workspace_rls.sql`

**Policies to Create**:
```sql
-- content_blocks: Users can only access blocks in their company
ALTER TABLE content_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY content_blocks_select ON content_blocks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM knowledge_pages kp
      WHERE kp.id = content_blocks.page_id
      AND kp.company_id = ops.jwt_company_id()
    )
  );

CREATE POLICY content_blocks_insert ON content_blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM knowledge_pages kp
      WHERE kp.id = content_blocks.page_id
      AND kp.company_id = ops.jwt_company_id()
    )
  );

CREATE POLICY content_blocks_update ON content_blocks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM knowledge_pages kp
      WHERE kp.id = content_blocks.page_id
      AND kp.company_id = ops.jwt_company_id()
    )
  );

CREATE POLICY content_blocks_delete ON content_blocks
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM knowledge_pages kp
      WHERE kp.id = content_blocks.page_id
      AND kp.company_id = ops.jwt_company_id()
    )
  );

-- database_views: Company-scoped access
ALTER TABLE database_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY database_views_all ON database_views
  FOR ALL
  TO authenticated
  USING (company_id = ops.jwt_company_id())
  WITH CHECK (company_id = ops.jwt_company_id());

-- task_dependencies: Access via project_tasks
ALTER TABLE task_dependencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY task_dependencies_all ON task_dependencies
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM project_tasks pt
      WHERE pt.id = task_dependencies.task_id
      AND pt.company_id = ops.jwt_company_id()
    )
  );

-- time_entries: User can see own + company entries
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY time_entries_all ON time_entries
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM project_tasks pt
      WHERE pt.id = time_entries.task_id
      AND pt.company_id = ops.jwt_company_id()
    )
  );

-- custom_properties: Company-scoped
ALTER TABLE custom_properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY custom_properties_all ON custom_properties
  FOR ALL
  TO authenticated
  USING (company_id = ops.jwt_company_id())
  WITH CHECK (company_id = ops.jwt_company_id());

-- property_values: Access via entity
ALTER TABLE property_values ENABLE ROW LEVEL SECURITY;

CREATE POLICY property_values_all ON property_values
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM custom_properties cp
      WHERE cp.id = property_values.property_id
      AND cp.company_id = ops.jwt_company_id()
    )
  );

-- page_templates: Public read, company write
ALTER TABLE page_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY page_templates_select ON page_templates
  FOR SELECT
  TO authenticated
  USING (is_public = true OR company_id = ops.jwt_company_id());

CREATE POLICY page_templates_insert ON page_templates
  FOR INSERT
  TO authenticated
  WITH CHECK (company_id = ops.jwt_company_id());

CREATE POLICY page_templates_update ON page_templates
  FOR UPDATE
  TO authenticated
  USING (company_id = ops.jwt_company_id());

CREATE POLICY page_templates_delete ON page_templates
  FOR DELETE
  TO authenticated
  USING (company_id = ops.jwt_company_id());
```

**Command**:
```bash
psql "$POSTGRES_URL" -f scripts/10_notion_workspace_rls.sql
```

**Success Criteria**: All policies created without errors

### Step 3: Frontend Component Creation ⚠️
**Estimated Time**: 2 days
**Location**: `app/components/`

**Day 1 Tasks**:
1. Install dependencies:
```bash
npm install @tiptap/react @tiptap/starter-kit @dnd-kit/core @tanstack/react-table react-syntax-highlighter
npm install -D @types/react-syntax-highlighter
```

2. Create `BlockEditor.tsx` (main editor container)
3. Create basic block components (TextBlock, HeadingBlock)
4. Create BlockToolbar
5. Integrate with existing pages

**Day 2 Tasks**:
1. Create remaining block types (ListBlock, TableBlock, CodeBlock, ImageBlock)
2. Add drag-and-drop functionality
3. Create TableView component
4. Connect to Supabase (CRUD operations)

**Success Criteria**:
- ✅ Can create page with blocks
- ✅ Can edit and delete blocks
- ✅ Can switch between block types
- ✅ Can save to database
- ✅ Can view in table view

### Step 4: Supabase Realtime Setup ⚠️
**Estimated Time**: 2 hours
**File**: `app/lib/supabase/realtime.ts`

**Configuration**:
```typescript
import { createClient } from '@/lib/supabase/client';

export function setupRealtimeSubscription(pageId: string, onUpdate: (payload: any) => void) {
  const supabase = createClient();

  const channel = supabase
    .channel(`page:${pageId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'content_blocks',
        filter: `page_id=eq.${pageId}`
      },
      onUpdate
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}
```

**Success Criteria**:
- ✅ Real-time updates when blocks change
- ✅ Multiple users see changes instantly

### Step 5: Vercel Deployment ✅
**Estimated Time**: 30 minutes
**Commands**:
```bash
# Build locally first
npm run build

# Deploy to Vercel
vercel --prod

# Verify deployment
curl https://odoboo-workspace.vercel.app/health
```

**Environment Variables** (Vercel dashboard):
```bash
NEXT_PUBLIC_SUPABASE_URL=https://spdtwktxdalcfigzeqrz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
```

**Success Criteria**:
- ✅ Production deployment accessible
- ✅ No build errors
- ✅ Environment variables configured

### Step 6: Testing & Validation ✅
**Estimated Time**: 1 hour

**Test Checklist**:
```markdown
## Block Editor Tests
- [ ] Create new page
- [ ] Add text block
- [ ] Add heading block
- [ ] Add list block
- [ ] Add code block with syntax highlighting
- [ ] Add image block (upload file)
- [ ] Drag blocks to reorder
- [ ] Delete blocks
- [ ] Undo/redo operations

## Database View Tests
- [ ] Switch to table view
- [ ] Add custom property
- [ ] Filter by property value
- [ ] Sort by multiple columns
- [ ] Save view configuration
- [ ] Load saved view

## Real-time Tests
- [ ] Open same page in 2 browsers
- [ ] Edit block in browser 1
- [ ] Verify update appears in browser 2 within 500ms
- [ ] Check presence indicators

## Performance Tests
- [ ] Page load < 2.5s (TTI)
- [ ] Block editor input latency < 100ms
- [ ] Search response < 500ms
```

**Success Criteria**: All tests pass

---

## Dependencies & Prerequisites

### Infrastructure ✅
- ✅ **Supabase Project**: spdtwktxdalcfigzeqrz (configured)
- ✅ **DigitalOcean**: $5/month App Platform (healthy)
- ✅ **Vercel**: Hobby tier (free, connected to GitHub)
- ✅ **Supabase Storage**: File uploads enabled

### Authentication ✅
- ✅ **Supabase Auth**: Email/password configured
- ✅ **RLS Policies**: Company-scoped access
- ✅ **JWT Claims**: `ops.jwt_company_id()` function exists

### Database ✅
- ✅ **PostgreSQL**: Supabase managed (14.x)
- ✅ **Extensions**: pgvector, pg_cron, uuid-ossp
- ✅ **Connection Pooler**: Port 6543 (enabled)

### Frontend ⚠️
- ✅ **Next.js 15**: App Router configured
- ✅ **TypeScript**: Strict mode enabled
- ✅ **Tailwind CSS**: Configured with shadcn/ui
- ⚠️ **Tiptap**: Need to install
- ⚠️ **React Table**: Need to install
- ⚠️ **DnD Kit**: Need to install

---

## Rollout Plan

### Phase 1: MVP (Days 1-3) 🔴 CRITICAL
**Features**:
- ✅ Database schema deployed
- ✅ Basic block editor (text, heading, list)
- ✅ Table view (single view type)
- ✅ CRUD operations (create, read, update, delete)
- ✅ RLS policies enforced

**Success Metrics**:
- Can create and edit pages with blocks
- Can view pages in table format
- Real-time updates working
- Deployed to production

### Phase 2: Enhanced UX (Week 2) 🟡 IMPORTANT
**Features**:
- All block types (code, image, embed, table)
- Drag-and-drop reordering
- Slash command palette
- Board view (Kanban)
- Calendar view
- Filters and sorting

**Success Metrics**:
- All 9 block types functional
- Drag-and-drop smooth (<100ms)
- Command palette responsive
- Multiple views working

### Phase 3: Collaboration (Week 3) 🟢 NICE-TO-HAVE
**Features**:
- Real-time presence indicators
- Live cursor tracking
- Inline comments
- Page templates
- Time tracking UI

**Success Metrics**:
- Presence indicators show active users
- Cursors visible in real-time
- Comments persistent
- Templates functional

---

## Cost Analysis

### Current Infrastructure
| Service | Cost | Usage | Status |
|---------|------|-------|--------|
| **Supabase Free Tier** | $0/mo | Database + Storage + Realtime | ✅ Active |
| **Vercel Hobby** | $0/mo | Frontend hosting | ✅ Active |
| **DigitalOcean App Platform** | $5/mo | ChatGPT plugin | ✅ Healthy |
| **Total** | **$5/mo** | **All services** | **Optimized** |

### Scalability Thresholds
- **Supabase Free**: 500MB database, 1GB storage, 2GB bandwidth
- **When to Upgrade** ($25/month):
  - Database > 500MB
  - Storage > 1GB
  - Bandwidth > 2GB/month
  - Need >100 concurrent users

### Performance Targets
- **Page Load**: < 2.5s (Time to Interactive)
- **Editor Latency**: < 100ms (typing lag)
- **Search**: < 500ms (full-text search)
- **Real-time**: < 500ms (collaborative updates)

---

## Risk Mitigation

### Technical Risks

#### Risk 1: Performance Degradation
**Risk**: Block editor becomes sluggish with large pages
**Mitigation**:
- Virtual scrolling for long pages (react-window)
- Lazy loading for images and embeds
- Debounced saves (300ms delay)
- Optimistic UI updates

**Monitoring**:
```typescript
// app/lib/monitoring/performance.ts
export function trackEditorPerformance() {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (entry.name === 'editor-input-latency' && entry.duration > 100) {
        console.warn('Editor latency exceeded 100ms:', entry.duration);
      }
    }
  });
  observer.observe({ entryTypes: ['measure'] });
}
```

#### Risk 2: Real-time Sync Conflicts
**Risk**: Concurrent edits cause data conflicts
**Mitigation**:
- Operational Transformation (OT) or CRDT for text
- Block-level locking (edit mode per block)
- Conflict resolution UI (show both versions)
- Last-write-wins for metadata

**Implementation**:
```typescript
// app/lib/collaboration/conflict-resolution.ts
export function resolveBlockConflict(local: Block, remote: Block) {
  if (local.updated_at > remote.updated_at) {
    return { winner: 'local', loser: 'remote' };
  } else {
    return { winner: 'remote', loser: 'local' };
  }
}
```

#### Risk 3: Storage Limits (Supabase Free Tier)
**Risk**: 1GB storage limit exceeded by file uploads
**Mitigation**:
- Image compression (WebP format, <500KB)
- File upload limits (10MB per file)
- Storage usage monitoring
- Upgrade plan when 80% full

**Monitoring**:
```sql
-- Check storage usage
SELECT
  SUM(metadata->>'size')::bigint / 1024 / 1024 AS storage_mb,
  1024 AS limit_mb,
  (SUM(metadata->>'size')::bigint / 1024 / 1024 * 100 / 1024) AS usage_percent
FROM storage.objects;
```

### Business Risks

#### Risk 1: User Adoption
**Risk**: Users prefer existing tools (Notion, Confluence)
**Mitigation**:
- Focus on Notion-like UX (familiar interface)
- Import from Notion (future feature)
- Odoo integration (unique value prop)
- Free tier (no switching cost)

#### Risk 2: Feature Parity Gap
**Risk**: Missing features vs Notion
**Mitigation**:
- Start with MVP (80/20 rule)
- Prioritize based on user feedback
- Rapid iteration (weekly releases)
- Notion feature matrix (track gaps)

---

## Success Criteria

### MVP Launch (Day 3)
- [ ] Database schema deployed to Supabase
- [ ] RLS policies enforced on all tables
- [ ] Block editor functional (text, heading, list blocks)
- [ ] Table view showing pages
- [ ] CRUD operations working
- [ ] Real-time updates functional
- [ ] Deployed to Vercel production
- [ ] No critical bugs

### Week 2 (Enhanced UX)
- [ ] All 9 block types functional
- [ ] Drag-and-drop reordering smooth
- [ ] Slash command palette responsive
- [ ] Board view (Kanban) working
- [ ] Filters and sorting implemented
- [ ] Performance targets met (< 100ms latency)

### Week 3 (Collaboration)
- [ ] Real-time presence indicators
- [ ] Live cursor tracking
- [ ] Inline comments working
- [ ] Page templates functional
- [ ] Time tracking UI complete

---

## Next Steps

### Immediate Actions (Today)

1. **Apply Database Migration** (15 min):
```bash
psql "$POSTGRES_URL" -f scripts/09_notion_workspace_schema.sql
```

2. **Create RLS Policies** (30 min):
```bash
# Create scripts/10_notion_workspace_rls.sql
# Apply to database
psql "$POSTGRES_URL" -f scripts/10_notion_workspace_rls.sql
```

3. **Install Dependencies** (5 min):
```bash
npm install @tiptap/react @tiptap/starter-kit @dnd-kit/core @tanstack/react-table react-syntax-highlighter
npm install -D @types/react-syntax-highlighter
```

### Tomorrow (Day 2)

4. **Create BlockEditor Component** (4 hours):
   - `app/components/editor/BlockEditor.tsx`
   - `app/components/editor/blocks/TextBlock.tsx`
   - `app/components/editor/blocks/HeadingBlock.tsx`
   - `app/components/editor/BlockToolbar.tsx`

5. **Integrate with Existing Pages** (2 hours):
   - Update `app/notion-demo/page.tsx`
   - Add block editor to knowledge pages

### Day 3

6. **Complete Remaining Blocks** (4 hours):
   - ListBlock, CodeBlock, ImageBlock
   - TableView component
   - Connect to Supabase

7. **Deploy to Production** (1 hour):
   - Build and test locally
   - Deploy to Vercel
   - Validate deployment

---

**Last Updated**: 2025-10-19
**Owner**: Claude Code
**Priority**: 🔴 CRITICAL (ASAP deployment)
**Status**: ✅ Ready for implementation
