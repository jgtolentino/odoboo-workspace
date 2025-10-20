# Quick Start Guide: Activate Notion-Like Workspace

## ✅ Current Status
- Odoo 18.0 is running at http://localhost:8069
- PostgreSQL database is ready
- Docker containers are healthy

## 📋 Step-by-Step Activation

### Step 1: Create Your Database (5 minutes)

1. **Open Browser**: http://localhost:8069

2. **Fill in Database Creation Form**:
   ```
   Master Password: admin
   Database Name: notion_workspace
   Email: admin@example.com
   Password: admin123
   Language: English
   Country: Singapore
   Demo data: ❌ UNCHECK THIS
   ```

3. **Click "Create database"** and wait ~2 minutes

### Step 2: Install Essential Apps for Notion-Like Features (10 minutes)

Once logged in, you'll see the Odoo dashboard. Now install these apps:

#### A. **Knowledge** (Wiki/Pages Feature)
1. Click **Apps** in the top menu
2. Search for "Knowledge"
3. Click **Install** on the "Knowledge" app
4. Wait for installation (~30 seconds)

**What you get:**
- ✅ Hierarchical pages like Notion
- ✅ Rich text editor
- ✅ Article templates
- ✅ Favorites and recent pages
- ✅ Share pages with team

#### B. **Project** (Kanban Boards)
1. In Apps, search for "Project"
2. Click **Install**

**What you get:**
- ✅ Kanban board views (like Notion databases)
- ✅ Task management
- ✅ Multiple views (List, Kanban, Calendar, Gantt)
- ✅ Subtasks and dependencies
- ✅ Team collaboration

#### C. **Documents** (File Management)
1. In Apps, search for "Documents"
2. Click **Install**

**What you get:**
- ✅ Folder structure
- ✅ File upload and preview
- ✅ Tags and filters
- ✅ OCR text extraction
- ✅ Share files with links

#### D. **Website** (Public Pages - Optional)
1. Search for "Website"
2. Click **Install**

**What you get:**
- ✅ Public-facing pages
- ✅ Blog functionality
- ✅ Page builder

### Step 3: Configure Your Notion-Like Workspace (15 minutes)

#### Create Workspace Structure

**1. Knowledge Base Setup**
```
Go to: Knowledge → Create Article

Suggested structure:
📁 Home
├── 📝 Quick Notes
├── ✅ Tasks & Projects
├── 📚 Documentation
│   ├── How-to Guides
│   ├── Processes
│   └── Templates
├── 💼 Team Resources
└── 🎯 Goals & OKRs
```

**2. Project Boards Setup**
```
Go to: Project → Create Project

Create these boards:
- Personal Tasks
- Team Projects
- Ideas & Brainstorming
- Content Calendar
```

**3. Document Folders**
```
Go to: Documents → Create Workspace

Suggested folders:
- Contracts & Legal
- Marketing Assets
- Product Documentation
- Meeting Notes
- Research
```

### Step 4: Start Using Your Notion-Like Workspace

#### Create Your First Page
1. **Knowledge** → **+ New Article**
2. Add title: "Welcome to My Workspace"
3. Use rich text editor:
   - Headings (Ctrl/Cmd + Alt + 1/2/3)
   - **Bold**, *Italic*, Lists
   - Insert images, files, tables
   - @ mention team members
4. Save

#### Create Your First Kanban Board
1. **Project** → Open "Personal Tasks"
2. Click **+ Task** to add cards
3. Drag cards between columns
4. Add due dates, assignees, tags
5. Switch views: Kanban → List → Calendar

#### Upload Files
1. **Documents** → Select folder
2. Click **Upload** or drag & drop files
3. Add tags for easy filtering
4. Preview files directly in browser

## 🎨 Customize Your Workspace

### Make It Look Like Notion

**1. Install Dark Mode** (Optional)
- Apps → Search "Dark Mode"
- Install community module if available

**2. Customize Views**
- Each app allows view customization
- Add/remove fields
- Change colors and layouts
- Create filters and groupings

**3. Create Templates**
- In Knowledge: Save articles as templates
- In Projects: Save project structures as templates

## 📊 Key Features Comparison

| Notion Feature | Odoo Equivalent | How to Access |
|----------------|-----------------|---------------|
| Pages | Knowledge Articles | Knowledge → New Article |
| Databases | Projects/Custom Models | Project → New Board |
| Kanban View | Kanban View | Project → Kanban |
| Table View | List View | Any app → List |
| Calendar | Calendar View | Project → Calendar |
| Gallery | Kanban (with images) | Configure Kanban |
| Timeline | Gantt Chart | Project → Gantt |
| Templates | Article Templates | Knowledge → Templates |
| Sharing | Portal Access | Share → External User |
| Comments | Chatter | Any record → Log Note |
| @ Mentions | User Mentions | Type @ in any text |
| Files | Documents App | Documents → Upload |
| Search | Search Bar | Top-right search |

## 🔥 Pro Tips

### Keyboard Shortcuts
- `Alt + M` - Create new menu (context-dependent)
- `Ctrl/Cmd + K` - Global search
- `Ctrl/Cmd + /` - Show shortcuts
- `/` in text editor - Quick commands (if enabled)

### Best Practices
1. **Use tags** everywhere for better organization
2. **Create templates** for recurring page types
3. **Set up favorites** for quick access
4. **Use @ mentions** to notify team members
5. **Enable activities** for follow-ups and reminders

### Power User Features
- **Filters**: Create saved filters for common views
- **Favorites**: Star frequently used items
- **Activities**: Schedule follow-ups on any record
- **Custom Views**: Create personalized views
- **Export/Import**: Bulk operations via Excel

## 🚀 Next Steps

Once you're comfortable with the basics:

1. **Explore Automation**
   - Apps → Search "Automation"
   - Create automated workflows

2. **Install More Apps**
   - Survey (for forms)
   - Calendar (for scheduling)
   - Contacts (for CRM)
   - Email Marketing
   - Social Media

3. **Customize Further**
   - Studio module (paid) for custom fields
   - Create custom apps
   - Integrate with external tools

## 📱 Mobile Access

Odoo has mobile apps:
- **iOS**: Download "Odoo" from App Store
- **Android**: Download "Odoo" from Play Store
- Login with: http://localhost:8069 (or your domain)

## ❓ Need Help?

### Access Odoo Documentation
- Settings → Documentation
- Or visit: https://www.odoo.com/documentation/18.0/

### Common Issues

**Can't login?**
- Check username: admin@example.com
- Reset password via Odoo interface

**App not showing?**
- Make sure you're in "Apps" view
- Remove default filters
- Update Apps List: Apps → Update Apps List

**Performance slow?**
- Restart containers: `docker-compose restart`
- Check logs: `docker-compose logs -f odoo`

## 🎯 Your Workspace is Ready!

You now have a powerful Notion-like workspace with:
- ✅ Wiki/Knowledge base
- ✅ Kanban boards
- ✅ Multiple database views
- ✅ File management
- ✅ Team collaboration
- ✅ Rich text editing
- ✅ Templates
- ✅ Mobile access

**Start building at**: http://localhost:8069

Enjoy your Odoo-powered Notion workspace! 🎉
