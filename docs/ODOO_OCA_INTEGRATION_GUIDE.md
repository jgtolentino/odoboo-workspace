# Odoo/OCA Integration with Current Stack

Guide for integrating Odoo/OCA module patterns into Supabase + DigitalOcean + Vercel architecture.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Current Stack (NO Full Odoo Installation)                   │
├─────────────────────────────────────────────────────────────┤
│ Frontend: Vercel (React/Next.js)                            │
│ Backend: Supabase Edge Functions + DigitalOcean App Platform│
│ Database: Supabase PostgreSQL                                │
│ Storage: Supabase Storage + DO Spaces                       │
│ Backups: Snapshooter (DigitalOcean Add-on)                  │
└─────────────────────────────────────────────────────────────┘
         ▲
         │ Adopts Patterns From
         │
┌─────────────────────────────────────────────────────────────┐
│ Odoo/OCA Module Patterns (NOT Full Installation)            │
├─────────────────────────────────────────────────────────────┤
│ • Database schemas (models)                                  │
│ • Business logic patterns (RPC functions)                    │
│ • UI/UX conventions (forms, lists, kanban)                   │
│ • Security models (RLS policies = Odoo record rules)         │
│ • Workflow patterns (state machines, approvals)              │
│ • Report templates (PDF generation)                          │
└─────────────────────────────────────────────────────────────┘
```

**Key Principle**: Use Odoo/OCA **patterns and schemas**, NOT full Odoo installation.

---

## OCA Module Patterns → Current Stack Mapping

### 1. **Knowledge Management** (OCA `document_page`)

**Odoo Pattern**:
```python
# odoo/addons/document_page/models/document_page.py
class DocumentPage(models.Model):
    _name = 'document.page'
    _description = 'Documentation Page'

    name = fields.Char('Title', required=True)
    content = fields.Html('Content')
    parent_id = fields.Many2one('document.page', 'Parent Page')
    child_ids = fields.One2many('document.page', 'parent_id', 'Child Pages')
```

**Your Implementation** (Supabase):
```sql
-- supabase/migrations/20251019_knowledge_base.sql
CREATE TABLE knowledge_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT, -- Markdown or HTML
  parent_id UUID REFERENCES knowledge_articles(id),
  author_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable full-text search
CREATE INDEX idx_knowledge_articles_content ON knowledge_articles
  USING gin(to_tsvector('english', title || ' ' || content));

-- RLS Policies (equivalent to Odoo record rules)
ALTER TABLE knowledge_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all articles" ON knowledge_articles
  FOR SELECT USING (true);

CREATE POLICY "Users can edit their own articles" ON knowledge_articles
  FOR UPDATE USING (auth.uid() = author_id);
```

**Edge Function** (Supabase):
```typescript
// supabase/functions/knowledge-api/index.ts
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Search articles (like Odoo search_read)
  const { data: articles } = await supabase
    .from('knowledge_articles')
    .select('*')
    .textSearch('title', req.query.get('q'))

  return new Response(JSON.stringify(articles))
})
```

---

### 2. **Project Management** (Odoo `project`)

**Odoo Pattern**:
```python
# odoo/addons/project/models/project.py
class Project(models.Model):
    _name = 'project.project'

    name = fields.Char('Name', required=True)
    task_ids = fields.One2many('project.task', 'project_id', 'Tasks')
    user_id = fields.Many2one('res.users', 'Project Manager')
```

**Your Implementation**:
```sql
-- supabase/migrations/20251019_projects.sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  manager_id UUID REFERENCES auth.users(id),
  state TEXT DEFAULT 'draft' CHECK (state IN ('draft', 'active', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE project_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES auth.users(id),
  state TEXT DEFAULT 'todo' CHECK (state IN ('todo', 'in_progress', 'done', 'blocked')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  deadline TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Kanban view support (like Odoo's kanban)
CREATE INDEX idx_tasks_kanban ON project_tasks(project_id, state, priority);
```

**Frontend** (React component like Odoo's Kanban view):
```typescript
// components/ProjectKanban.tsx
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd'

export function ProjectKanban({ tasks }: { tasks: Task[] }) {
  const columns = {
    todo: tasks.filter(t => t.state === 'todo'),
    in_progress: tasks.filter(t => t.state === 'in_progress'),
    done: tasks.filter(t => t.state === 'done')
  }

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      {Object.entries(columns).map(([state, stateTasks]) => (
        <Droppable key={state} droppableId={state}>
          {(provided) => (
            <div ref={provided.innerRef} {...provided.droppableProps}>
              {stateTasks.map((task, index) => (
                <Draggable key={task.id} draggableId={task.id} index={index}>
                  {(provided) => (
                    <TaskCard task={task} provided={provided} />
                  )}
                </Draggable>
              ))}
            </div>
          )}
        </Droppable>
      ))}
    </DragDropContext>
  )
}
```

---

### 3. **Document Management** (Odoo `documents`)

**Odoo Pattern**: Centralized file storage with tags, folders, and permissions

**Your Implementation**:
```sql
-- supabase/migrations/20251019_documents.sql
CREATE TABLE document_folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  parent_id UUID REFERENCES document_folders(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  folder_id UUID REFERENCES document_folders(id),
  storage_path TEXT NOT NULL, -- Supabase Storage path
  mime_type TEXT,
  size_bytes BIGINT,
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE document_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  color TEXT DEFAULT '#3b82f6'
);

CREATE TABLE document_tag_rel (
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES document_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, tag_id)
);

-- RLS for document access
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own documents" ON documents
  FOR SELECT USING (owner_id = auth.uid());
```

**Storage Integration** (Supabase Storage):
```typescript
// supabase/functions/document-upload/index.ts
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const formData = await req.formData()
  const file = formData.get('file') as File

  // Upload to Supabase Storage
  const { data: uploadData, error: uploadError } = await supabase.storage
    .from('documents')
    .upload(`${crypto.randomUUID()}/${file.name}`, file)

  if (uploadError) throw uploadError

  // Create document record
  const { data: document } = await supabase
    .from('documents')
    .insert({
      name: file.name,
      storage_path: uploadData.path,
      mime_type: file.type,
      size_bytes: file.size,
      owner_id: req.user.id
    })
    .select()
    .single()

  return new Response(JSON.stringify(document))
})
```

---

### 4. **Expense Management** (Odoo `hr_expense`)

**Odoo Pattern**: Receipt upload → OCR → Approval workflow

**Your Implementation** (Already exists!):
```sql
-- Existing: OCR service on DigitalOcean App Platform
-- Existing: supabase tables for expenses

-- Add approval workflow (like Odoo's approval)
CREATE TABLE expense_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID REFERENCES expenses(id),
  approver_id UUID REFERENCES auth.users(id),
  state TEXT DEFAULT 'pending' CHECK (state IN ('pending', 'approved', 'rejected')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- State machine (like Odoo's state field)
ALTER TABLE expenses ADD COLUMN state TEXT DEFAULT 'draft'
  CHECK (state IN ('draft', 'submitted', 'approved', 'paid', 'rejected'));
```

---

## Snapshooter Integration (DigitalOcean Add-on)

**What is Snapshooter?**: Automated backup service for databases and volumes on DigitalOcean.

### Setup Snapshooter for Supabase + DO

1. **Install via DigitalOcean Marketplace**:
```bash
# Visit: https://marketplace.digitalocean.com/add-ons/snapshooter
# Click "Install on DigitalOcean"
# Connect to your DO account
```

2. **Configure Supabase Backups**:
```yaml
# Snapshooter will backup:
- Supabase PostgreSQL (via connection string)
- DigitalOcean Spaces (document storage)
- App Platform volumes (if any)

# Backup Schedule:
retention:
  daily: 7 days
  weekly: 4 weeks
  monthly: 12 months
```

3. **Backup Supabase via pg_dump**:
```bash
# Snapshooter can run this command on schedule
pg_dump "postgres://postgres.spdtwktxdalcfigzeqrz:SHWYXDMFAwXI1drT@aws-1-us-east-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --format=custom \
  --file=supabase_backup_$(date +%Y%m%d).dump

# Upload to DO Spaces
s3cmd put supabase_backup_*.dump s3://your-backup-bucket/
```

4. **Automate with GitHub Actions**:
```yaml
# .github/workflows/database-backup.yml
name: Database Backup

on:
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM UTC

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Backup Supabase Database
        run: |
          pg_dump "${{ secrets.POSTGRES_URL }}" \
            --format=custom \
            --file=backup_$(date +%Y%m%d).dump

      - name: Upload to Snapshooter
        run: |
          curl -X POST "https://api.snapshooter.com/v1/backups" \
            -H "Authorization: Bearer ${{ secrets.SNAPSHOOTER_API_KEY }}" \
            -F "file=@backup_$(date +%Y%m%d).dump"
```

---

## Full Integration Architecture

```
┌────────────────────────────────────────────────────────────────┐
│ Frontend (Vercel)                                               │
│ • React/Next.js with Odoo-style UI components                   │
│ • Kanban boards, Form views, List views                         │
│ • TailwindCSS + shadcn/ui (Odoo-like design system)             │
└────────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ API Layer (Supabase Edge Functions)                             │
│ • RPC functions (like Odoo's @api.model methods)                │
│ • Business logic + validations                                   │
│ • Integration with external services                             │
└────────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ Database (Supabase PostgreSQL)                                  │
│ • Odoo-style schemas (models)                                    │
│ • RLS policies (equivalent to record rules)                      │
│ • Full-text search, materialized views                           │
└────────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ Storage Layer                                                    │
│ • Supabase Storage: Small files, user uploads                   │
│ • DO Spaces: Large files, backups                               │
└────────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ Backups (Snapshooter)                                            │
│ • Automated daily/weekly/monthly backups                         │
│ • Point-in-time recovery                                         │
│ • Cross-region replication                                       │
└────────────────────────────────────────────────────────────────┘
```

---

## OCA Modules to Adopt (Patterns Only)

### High Priority
1. **`document_page`** → Knowledge base (see above)
2. **`queue_job`** → Background task processing (use task_queue)
3. **`auditlog`** → Change tracking (enhance secret_access_log pattern)
4. **`base_user_role`** → Role-based access (RLS policies)
5. **`web_responsive`** → Mobile-first UI patterns

### Medium Priority
6. **`mail_tracking`** → Email/notification tracking
7. **`partner_contact_department`** → Contact management
8. **`web_widget_color`** → Color picker components
9. **`report_xlsx`** → Excel export functionality
10. **`attachment_preview`** → File preview in browser

### Low Priority
11. **`fetchmail`** → Email integration
12. **`web_timeline`** → Timeline/Gantt charts
13. **`website_form_builder`** → Dynamic form creation

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
```bash
# Create database schemas from Odoo patterns
supabase db push

# Deploy Edge Functions for business logic
supabase functions deploy knowledge-api --project-ref spdtwktxdalcfigzeqrz
supabase functions deploy document-upload --project-ref spdtwktxdalcfigzeqrz

# Setup Snapshooter backups
# Visit: https://marketplace.digitalocean.com/add-ons/snapshooter
```

### Phase 2: UI Components (Week 3-4)
```bash
# Create Odoo-style React components
npx shadcn-ui@latest add form
npx shadcn-ui@latest add table
npx shadcn-ui@latest add dialog

# Build Kanban, List, Form views
# Pattern: components/odoo-style/
```

### Phase 3: Business Logic (Week 5-6)
```bash
# Implement workflows, state machines
# Add approval processes
# Create report templates
```

### Phase 4: Integration (Week 7-8)
```bash
# Connect to external APIs
# Setup automated backups
# Performance optimization
```

---

## Key Advantages Over Full Odoo

1. **Cost**: $20/month vs $200+/month for Odoo hosting
2. **Performance**: Supabase edge functions are faster than Odoo Python
3. **Scalability**: Auto-scaling with Supabase + DO App Platform
4. **Modern Stack**: React/TypeScript vs Odoo's QWeb templates
5. **AI-Native**: Built-in MCP support for Claude Desktop
6. **No Python Runtime**: Deno Edge Functions (faster cold starts)

---

## Next Steps

1. ✅ Supabase Vault configured
2. ✅ Edge Functions deployed
3. ✅ Platform management APIs documented
4. ⏳ Create knowledge_articles table (Odoo document_page pattern)
5. ⏳ Setup Snapshooter backup automation
6. ⏳ Build Kanban component (Odoo project pattern)
7. ⏳ Implement state machine workflows

Would you like me to start implementing any of these Odoo/OCA patterns?
