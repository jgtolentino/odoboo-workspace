# Project Management & Alerts Guide - Odoo 18 + OCA

## 🎯 Overview

Your Odoo 18 installation includes comprehensive project management and notification capabilities through native modules and OCA extensions.

---

## 📊 Installed Project Management Modules

### ✅ **Core Odoo Modules (Already Active)**

#### 1. **Project** (`project`)
**Status**: ✅ Installed
**Features**:
- Task creation and assignment
- Kanban, list, and Gantt views
- Project stages and workflows
- Task dependencies and subtasks
- Time tracking and deadlines
- Project templates
- Collaboration and file attachments

**Access**: Apps → Project

#### 2. **Project Todo** (`project_todo`)
**Status**: ✅ Installed
**Features**:
- Personal to-do lists
- Memos and quick notes
- Integration with main project tasks
- Priority management

**Access**: Apps → Project → My To-Do

#### 3. **Calendar** (`calendar`)
**Status**: ✅ Installed
**Features**:
- Meeting scheduling
- Calendar views (day/week/month)
- Event reminders
- Team availability tracking
- Integration with tasks and projects

**Access**: Apps → Calendar

#### 4. **Mail** (`mail`)
**Status**: ✅ Installed
**Features**:
- **Chatter**: Activity feeds on every record
- Internal messaging and discussions
- Email gateway integration
- Follower notifications
- Activity scheduling
- Real-time chat

**Access**: Built into every module (bottom of records)

---

## 🔔 Alert & Notification System

### **Current Alert Capabilities**

#### 1. **Chatter Notifications** (Built-in)
- **Real-time notifications** when:
  - You're mentioned (@username)
  - Tasks assigned to you
  - Followers get updates on records
  - Comments added to tasks/projects
  - Status changes on followed items

**How to use**:
- Click on any project/task
- Scroll to bottom → See "Chatter" section
- Click "Log note" for internal updates
- Click "Send message" for notifications

#### 2. **Activity Reminders**
- Schedule activities with deadlines
- Get notifications for:
  - Overdue activities
  - Today's activities
  - Upcoming deadlines

**How to use**:
- On any task → Click "Schedule Activity"
- Choose: Call, Email, Meeting, To-Do
- Set deadline → Odoo will notify you

#### 3. **Email Notifications**
- **Automatic emails** for:
  - Task assignments
  - Deadline approaching
  - Stage changes
  - Comments from followers

**Configure**: Settings → Technical → Email Servers

#### 4. **SMS Notifications** (`project_sms`)
**Status**: ✅ Installed
**Features**:
- Text message alerts on stage changes
- Task assignment notifications
- Critical deadline reminders

**Configure**: Settings → Technical → SMS Gateway

---

## 🚀 Available OCA Modules for Advanced Alerts

### **Ready to Install** (Currently uninstalled)

#### 1. **Mail Gateway** (`mail_gateway`)
**Purpose**: Base module for external communication gateways
**Use case**: Connect Telegram, WhatsApp, or custom channels

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i mail_gateway --stop-after-init
```

#### 2. **Mail Notification with History** (`mail_notification_with_history`)
**Purpose**: Include previous chatter discussion in email notifications
**Use case**: Recipients get full context in email alerts

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i mail_notification_with_history --stop-after-init
```

#### 3. **Mail Gateway Telegram** (`mail_gateway_telegram`)
**Purpose**: Telegram bot notifications
**Use case**: Get task updates in Telegram

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i mail_gateway,mail_gateway_telegram --stop-after-init
```

#### 4. **Mail Gateway WhatsApp** (`mail_gateway_whatsapp`)
**Purpose**: WhatsApp business notifications
**Use case**: Send task alerts via WhatsApp

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i mail_gateway,mail_gateway_whatsapp --stop-after-init
```

#### 5. **Project Task Add Very High Priority** (`project_task_add_very_high`)
**Purpose**: Extra priority levels (High, Very High)
**Use case**: Better priority classification

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i project_task_add_very_high --stop-after-init
```

#### 6. **Project Timeline** (`project_timeline`)
**Purpose**: Timeline/Gantt view for projects
**Use case**: Visual project planning

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i project_timeline --stop-after-init
```

#### 7. **Project Stakeholder** (`project_stakeholder`)
**Purpose**: Manage project stakeholders and their roles
**Use case**: Notify different stakeholder groups

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i project_stakeholder --stop-after-init
```

---

## 📋 Project Management Workflows

### **1. Basic Task Management**

#### Create a Project:
1. Apps → Project → Create
2. Name: "AI Development Workflow"
3. Configure stages: To Do → In Progress → Review → Done
4. Add team members
5. Set visibility (public/private)

#### Create Tasks:
1. Open project → Tasks tab → Create
2. Fill in:
   - Task name
   - Assignees
   - Priority (⭐⭐⭐)
   - Deadline
   - Tags
   - Description
3. Click "Save"

#### Track Progress:
- **Kanban view**: Drag-and-drop between stages
- **List view**: Bulk edit and filters
- **Calendar view**: See deadlines visually
- **Gantt view**: Project timeline (requires timeline module)

### **2. Collaboration Features**

#### Follow Tasks:
- Click "Follow" button on any task
- Receive notifications for all updates
- Unfollow anytime

#### Assign Multiple People:
- Task → Assignees field → Add multiple users
- Everyone gets notified

#### Subtasks:
- Task → Subtasks tab → Add subtask
- Track dependencies
- Block parent task until subtasks complete

#### File Attachments:
- Task → Attachments tab
- Drag & drop files
- Shared with all followers

### **3. Time Tracking**

#### Manual Logging:
- Task → Timesheets tab
- Add time entry
- Description of work done

#### Timer:
- Task → Click "Start Timer"
- Work on task
- Click "Stop Timer" → Auto-logs time

---

## 🔧 Notification Configuration

### **Email Notifications**

#### System-wide Settings:
1. Settings → General Settings → Discuss
2. Enable "External Email Servers"
3. Configure outgoing email:
   - SMTP server
   - Port (587 for TLS)
   - Username/password
4. Test connection

#### User Preferences:
1. Your profile → Preferences
2. Notification settings:
   - Handle by Emails
   - Handle in Odoo
   - No notification
3. Set frequency:
   - Instantly
   - Daily summary
   - Weekly summary

### **Activity Notifications**

#### Auto-Reminders:
- Settings → Technical → Automation → Scheduled Actions
- Create reminder automation:
  - Trigger: Time-based
  - Condition: Activity deadline approaching
  - Action: Send email/SMS

#### Manual Follow-up:
- Any record → Schedule Activity
- Set reminder date
- Choose notification method

### **SMS Notifications** (Requires SMS Gateway)

#### Setup:
1. Settings → Technical → SMS → SMS Gateway
2. Choose provider (Twilio, Vonage, etc.)
3. Enter API credentials
4. Test connection

#### Configure Alerts:
1. Project → Settings
2. Enable "SMS Notifications on Stage Move"
3. Configure which stages trigger SMS

---

## 🎨 Custom Alert Scenarios

### **Scenario 1: Deadline Approaching Alerts**

**Goal**: Notify task owner 24 hours before deadline

**Setup**:
1. Settings → Technical → Automation
2. Create automated action:
   - Model: Project Task
   - Trigger: Time-based
   - Trigger Date: 1 day before deadline
   - Action: Send Email
   - Template: "Deadline Approaching - {{object.name}}"

### **Scenario 2: Overdue Task Escalation**

**Goal**: Notify project manager of overdue tasks

**Setup**:
1. Settings → Technical → Automation
2. Create automated action:
   - Model: Project Task
   - Trigger: Time-based (daily)
   - Condition: `deadline < today AND stage != 'done'`
   - Action: Create Activity for project manager

### **Scenario 3: Task Assignment Notification**

**Goal**: Email + Telegram notification on task assignment

**Prerequisites**: Install `mail_gateway` and `mail_gateway_telegram`

**Setup**:
1. Install Telegram gateway module
2. Configure Telegram bot
3. Settings → Technical → Automation
4. Create automated action:
   - Model: Project Task
   - Trigger: On Update
   - Condition: `user_ids changed`
   - Action: Send via Telegram gateway

### **Scenario 4: Stage Change Alerts**

**Goal**: Notify stakeholders when task moves to "Review"

**Setup**:
1. Task → Stage = "Review"
2. Automated action:
   - Trigger: On Update
   - Condition: `stage_id == 'review'`
   - Action: Send notification to followers

---

## 📊 Dashboard & Reporting

### **Built-in Views**

#### My Tasks Dashboard:
- Apps → Project → My Tasks
- Filter: My Tasks, Today, This Week, Overdue
- Quick access to assigned tasks

#### Project Overview:
- Apps → Project → Select project
- Reporting tab:
  - Task analysis
  - Burndown chart
  - Time spent per user
  - Milestone tracking

#### Activity Dashboard:
- Apps → Discuss → Activities
- See all pending activities across modules
- Filter by type, deadline, user

### **Custom Dashboards**

#### Create Dashboard:
1. Apps → Dashboards → Create
2. Add widgets:
   - My Open Tasks (list)
   - Overdue Tasks (kanban)
   - This Week's Deadlines (calendar)
   - Project Progress (graph)
3. Share with team

---

## 🔌 Integration Capabilities

### **External Tool Integration**

#### GitHub/GitLab:
- Module: `project_task_pull_request`
- Link tasks to PRs
- Auto-update task status from PR status

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i project_task_pull_request --stop-after-init
```

#### Email Inbox Integration:
- Module: `project_mail_plugin`
- Turn emails into tasks
- Log email conversations in chatter

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i project_mail_plugin --stop-after-init
```

#### Calendar Sync:
- Google Calendar: `google_calendar`
- Microsoft Calendar: `microsoft_calendar`
- Sync Odoo events with external calendars

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i google_calendar --stop-after-init
```

---

## 🛠️ Advanced OCA Project Modules

### **Project Organization**

#### Project Templates (`project_template`)
- Create reusable project templates
- Predefined stages, tasks, and milestones
- Quick project setup

#### Project Type (`project_type`)
- Categorize projects (Development, Marketing, Support)
- Custom workflows per type

#### Project Parent (`project_parent`)
- Create project hierarchies
- Sub-projects and parent projects
- Rolled-up reporting

### **Task Management**

#### Project Task Code (`project_task_code`)
- Auto-generate task codes (PROJ-001, PROJ-002)
- Better task referencing

#### Project Key (`project_key`)
- JIRA-like project keys (AI-001, DEV-042)
- Consistent task numbering

#### Project Task Description Template (`project_task_description_template`)
- Predefined task description templates
- Standardized documentation

### **Advanced Features**

#### Project Scrum (`project_scrum`)
- Agile/Scrum methodology support
- Sprints, backlogs, burndown charts
- Story points and velocity

**Install**:
```bash
docker exec -i odoo18 odoo -d odoboo_local -i project_scrum --stop-after-init
```

#### Project Timeline HR Timesheet (`project_timeline_hr_timesheet`)
- Visual progress on timeline
- Time tracking integration
- Resource allocation view

---

## 📱 Mobile Access

### **Odoo Mobile App**
1. Download "Odoo" from App Store/Play Store
2. Connect to your instance: `http://your-server:8069`
3. Login with credentials
4. Access Projects module
5. Get push notifications for:
   - Task assignments
   - Mentions
   - Deadlines
   - Comments

---

## 🚨 Recommended Alert Setup

### **For Individual Contributors**

1. ✅ Enable email notifications (instant)
2. ✅ Follow all assigned tasks
3. ✅ Set daily activity digest
4. ✅ Enable browser notifications (Odoo web)

### **For Project Managers**

1. ✅ Follow all project tasks
2. ✅ Install `project_stakeholder` for role management
3. ✅ Create automation for overdue task escalation
4. ✅ Set up weekly summary report
5. ✅ Install `project_timeline` for Gantt view

### **For Teams**

1. ✅ Install `mail_notification_with_history` (context in emails)
2. ✅ Configure shared project dashboards
3. ✅ Set up Telegram/WhatsApp gateway for urgent alerts
4. ✅ Create task templates for common work
5. ✅ Enable time tracking

---

## 📦 Quick Install: Full Alert Stack

Install all recommended alert and notification modules:

```bash
# Install communication gateways
docker exec -i odoo18 odoo -d odoboo_local \
  -i mail_gateway,mail_notification_with_history \
  --stop-after-init

# Install project enhancements
docker exec -i odoo18 odoo -d odoboo_local \
  -i project_task_add_very_high,project_timeline,project_stakeholder,project_scrum \
  --stop-after-init

# Install integrations
docker exec -i odoo18 odoo -d odoboo_local \
  -i project_task_pull_request,project_mail_plugin,google_calendar \
  --stop-after-init

# Restart to apply
docker-compose -f docker-compose.local.yml restart odoo
```

---

## 🔗 Access Your Setup

**Odoo Web Interface**: http://localhost:8069
**Login**: jgtolentino_rn@yahoo.com
**Password**: Postgres_26

**Quick Start**:
1. Login to Odoo
2. Apps → Project
3. Create your first project
4. Add tasks and start collaborating!

---

## 📚 Additional Resources

- **Odoo Official Docs**: https://www.odoo.com/documentation/18.0/
- **OCA GitHub**: https://github.com/OCA/
- **Project Module Docs**: https://www.odoo.com/documentation/18.0/applications/services/project.html
- **Mail Module Docs**: https://www.odoo.com/documentation/18.0/developer/reference/backend/mail.html

---

**Next Steps**: Explore the modules, install additional OCA enhancements based on your workflow needs, and configure automated alerts for your AI development projects!
