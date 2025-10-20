# Mobile Apps for Notion-Style Workspace

**Complete guide to mobile access for your Odoo 18 Notion-style workspace**

---

## 📱 Overview

Your Notion-style workspace supports **two mobile approaches**:

| Approach | Setup Time | Features | Best For |
|----------|-----------|----------|----------|
| **PWA (Progressive Web App)** | 5 min | 80% native feel | Quick deployment |
| **Flutter Native App** | 2-3 days | 100% native + offline | Production apps |

Both approaches give full access to:
- ✅ Kanban task board
- ✅ Calendar events
- ✅ Evidence repository (DMS)
- ✅ Knowledge base (wiki)
- ✅ Chatter messaging
- ✅ File attachments

---

## 🎯 Comparison: PWA vs Native App

### Progressive Web App (PWA)

**Advantages:**
- ✅ **Instant deployment** - No app store submission
- ✅ **Auto-updates** - Users always on latest version
- ✅ **Cross-platform** - Works on iOS, Android, desktop
- ✅ **No installation needed** - Runs in browser
- ✅ **Small size** - ~1-2 MB
- ✅ **Single codebase** - Same as web version

**Limitations:**
- ⚠️ Limited offline support (browser cache only)
- ⚠️ No native push notifications on iOS
- ⚠️ Reduced hardware access (camera, biometrics)
- ⚠️ Must have network for initial load

**When to use:**
- Quick deployment needed
- Users already familiar with web interface
- Limited development resources
- Don't need deep OS integration

### Flutter Native App

**Advantages:**
- ✅ **Full native performance** - Compiled to native code
- ✅ **Complete offline mode** - Local database with sync
- ✅ **Native push notifications** - iOS + Android
- ✅ **Full hardware access** - Camera, biometrics, GPS
- ✅ **App store presence** - Professional image
- ✅ **Better UX** - Native navigation, gestures

**Limitations:**
- ⚠️ Development time (2-3 days initial setup)
- ⚠️ App store approval process (1-2 weeks)
- ⚠️ Must maintain separate codebase
- ⚠️ Updates require app store review

**When to use:**
- Production deployment
- Need offline access
- Want app store presence
- Professional/enterprise use case

---

## 🚀 Option 1: PWA Setup (5 minutes)

### **What You Get**

A progressive web app that:
- Installs to home screen like native app
- Works offline (cached pages)
- Full-screen mode
- Responsive mobile UI
- Fast loading

### **Prerequisites**

Already installed in your workspace setup:
```python
# OCA modules (already installed)
'web_pwa_oca'       # PWA support
'web_responsive'    # Mobile-responsive UI
'web_notify'        # Toast notifications
```

### **Step 1: Enable PWA**

SSH into your server:

```bash
ssh root@188.166.237.231

# Verify PWA module is installed
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
pwa_module = env['ir.module.module'].search([('name', '=', 'web_pwa_oca')])
print(f"PWA Module: {pwa_module.state}")
exit()
ODOO_SHELL
```

**Expected output:** `PWA Module: installed`

### **Step 2: Configure PWA Settings**

```bash
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
# Update PWA configuration
IrConfigParam = env['ir.config_parameter']

# PWA settings
IrConfigParam.set_param('web_pwa.manifest_name', 'Compliance Workspace')
IrConfigParam.set_param('web_pwa.manifest_short_name', 'Compliance')
IrConfigParam.set_param('web_pwa.manifest_description', 'Notion-style workspace for compliance and project management')
IrConfigParam.set_param('web_pwa.manifest_background_color', '#FFFFFF')
IrConfigParam.set_param('web_pwa.manifest_theme_color', '#875A7B')
IrConfigParam.set_param('web_pwa.manifest_start_url', '/web')
IrConfigParam.set_param('web_pwa.manifest_icon_url', '/web/static/img/logo.png')

env.cr.commit()
print("✓ PWA configured")
exit()
ODOO_SHELL
```

### **Step 3: Install on Mobile Device**

**iOS (Safari):**
1. Open **https://insightpulseai.net:8069** in Safari
2. Tap the **Share** button (square with arrow)
3. Scroll and tap **"Add to Home Screen"**
4. Name it "Compliance Workspace"
5. Tap **Add**
6. Icon appears on home screen

**Android (Chrome):**
1. Open **https://insightpulseai.net:8069** in Chrome
2. Tap the **three dots** menu
3. Tap **"Add to Home screen"**
4. Name it "Compliance Workspace"
5. Tap **Add**
6. Icon appears on home screen

### **Step 4: Verify PWA Features**

Once installed:
- ✅ Opens in full-screen (no browser bar)
- ✅ Has custom icon on home screen
- ✅ Splash screen on launch
- ✅ Works offline (cached pages)
- ✅ Responsive mobile layout

### **PWA Features Available**

| Feature | iOS Safari | Android Chrome |
|---------|------------|----------------|
| **Home screen icon** | ✅ | ✅ |
| **Full-screen mode** | ✅ | ✅ |
| **Offline cache** | ✅ | ✅ |
| **Push notifications** | ❌ | ✅ |
| **Background sync** | ❌ | ✅ |
| **Add to homescreen prompt** | Manual | Auto |

---

## 🏗️ Option 2: Flutter Native App

### **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (DART)                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │  Presentation  │  │  State Mgmt    │  │  Services    │  │
│  │  (UI Screens)  │  │  (Providers)   │  │  (API/DB)    │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
│         ↓                   ↓                    ↓          │
│  • Login Screen      • AuthProvider       • OdooService    │
│  • Dashboard         • ProjectProvider    • CacheService   │
│  • Tasks Kanban      • TaskProvider       • NotifService   │
│  • Task Detail       • ChatProvider       • FileService    │
│  • Calendar          • UserProvider       • SyncService    │
│  • Knowledge Pages   • CalendarProvider                    │
│  • Documents         • DocumentProvider                    │
│  • Profile                                                  │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                     DATA LAYER                                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Models     │  │  Local DB    │  │  API Client      │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│  • Task          │  • Hive          │  • odoo_rpc          │
│  • Project       │  • SQLite        │  • JSON-RPC          │
│  • User          │  • Cache         │  • HTTP/HTTPS        │
│  • Message       │                  │  • WebSocket         │
│  • Document      │                  │                      │
│  • Event         │                  │                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              ↕
                    ODOO 18 JSON-RPC API
                 (insightpulseai.net:8069)
```

### **Component Breakdown**

#### **1. Screens (UI Layer)**

| Screen | Purpose | Odoo Models |
|--------|---------|-------------|
| **LoginScreen** | Email/password auth | res.users |
| **DashboardScreen** | Overview, recent tasks | project.task, calendar.event |
| **ProjectsScreen** | Project list | project.project |
| **TasksScreen** | Kanban board | project.task, project.task.type |
| **TaskDetailScreen** | Task details + chatter | project.task, mail.message |
| **CalendarScreen** | Events calendar | calendar.event |
| **KnowledgeScreen** | Wiki pages | document.page |
| **DocumentsScreen** | File repository | dms.document, dms.directory |
| **ProfileScreen** | User settings | res.users |

#### **2. Services (Business Logic)**

**OdooService** (`lib/services/odoo_service.dart`)
- JSON-RPC communication with Odoo
- Authentication and session management
- CRUD operations (create, read, update, delete)
- Search and filtering
- Chatter messaging
- File uploads

**Key Methods:**
```dart
// Authentication
Future<OdooSession> authenticate(String email, String password)
Future<void> logout()

// Generic CRUD
Future<List<Map>> searchRead(String model, {domain, fields, limit})
Future<int> create(String model, Map<String, dynamic> values)
Future<bool> write(String model, List<int> ids, Map values)
Future<bool> unlink(String model, List<int> ids)

// Chatter
Future<int> postMessage(String model, int recordId, String body)
Future<List<Map>> getMessages(String model, int recordId)

// Files
Future<int> uploadAttachment(String model, int recordId, String fileName, bytes)
```

**CacheService** (`lib/services/cache_service.dart`)
- Local data persistence with Hive
- Offline mode support
- Cache expiry management
- Sync queue for offline changes

**NotificationService** (`lib/services/notification_service.dart`)
- Firebase Cloud Messaging integration
- Local notifications
- Deep linking from notifications

**SyncService** (`lib/services/sync_service.dart`)
- Background sync
- Conflict resolution
- Queue offline changes

#### **3. State Management (Providers)**

**AuthProvider**
```dart
class AuthProvider extends ChangeNotifier {
  OdooSession? _session;
  User? _currentUser;
  bool _isAuthenticated = false;

  Future<void> login(String email, String password);
  Future<void> logout();
  Future<void> checkSavedSession();
}
```

**TaskProvider**
```dart
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  Map<int, List<Task>> _tasksByStage = {};

  Future<void> loadTasks(int projectId);
  Future<void> createTask(Map<String, dynamic> values);
  Future<void> updateTask(int taskId, Map values);
  Future<void> moveTask(int taskId, int newStageId);
  Future<void> deleteTask(int taskId);
}
```

**ChatProvider**
```dart
class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  List<User> _mentionableUsers = [];

  Future<void> loadMessages(String model, int recordId);
  Future<void> sendMessage(String body, List<int> mentionedUserIds);
  Future<void> uploadFile(File file);
}
```

#### **4. Data Models**

**Task Model** (`lib/models/task.dart`)
```dart
class Task {
  final int id;
  final String name;
  final String? description;
  final int projectId;
  final String projectName;
  final int? stageId;
  final String? stageName;
  final int? userId;
  final DateTime? dateDeadline;
  final String priority;
  final List<String> tagNames;

  // Custom fields from Notion workspace
  final String? evidenceUrl;        // x_evidence_url
  final String? complianceArea;     // x_area
  final int? knowledgePageId;       // x_knowledge_page_id
  final String? approvalStatus;     // x_approval_status

  Task.fromOdoo(Map<String, dynamic> json);
  Map<String, dynamic> toOdoo();
}
```

**Document Model** (`lib/models/document.dart`)
```dart
class Document {
  final int id;
  final String name;
  final int directoryId;
  final String? url;
  final String? mimetype;
  final List<String> tagNames;
  final int? ownerId;

  // Custom fields
  final int? taskId;               // x_task_id
  final String? complianceArea;    // x_compliance_area

  Document.fromOdoo(Map<String, dynamic> json);
}
```

**KnowledgePage Model** (`lib/models/knowledge_page.dart`)
```dart
class KnowledgePage {
  final int id;
  final String name;
  final int? parentId;
  final String content;            // HTML content
  final List<String> tagNames;
  final String? summary;

  // Custom fields
  final List<int> relatedTaskIds;  // x_task_ids
  final String? pageType;          // x_page_type

  KnowledgePage.fromOdoo(Map<String, dynamic> json);
}
```

### **App Features**

#### **1. Task Management**

**Kanban Board:**
- Drag-and-drop between stages
- Color-coded tags
- Priority indicators
- Assignee avatars
- Due date badges (red if overdue)
- Message count badges

```dart
// Move task to new stage
await taskProvider.moveTask(taskId, newStageId);
```

**Task Details:**
- Full description (HTML)
- Chatter messages
- File attachments
- Related evidence documents
- Linked knowledge pages
- Activity timeline

**Quick Actions:**
- Mark as done
- Assign to me
- Set deadline
- Add tags
- @mention team members

#### **2. Calendar Integration**

**Features:**
- Month/week/day views
- Regulatory deadlines highlighted
- Color-coded by event type
- Add to device calendar
- Reminders/alarms

**Event Types:**
- Tax Deadlines (red)
- Finance Meetings (blue)
- Procurement (green)
- Statutory Deadlines (orange)
- Board Meetings (purple)

#### **3. Evidence Repository (DMS)**

**Browse Documents:**
- Folder tree navigation
- Search by name/tags
- Filter by compliance area
- Sort by date/name/type

**Document Actions:**
- View (PDF, images inline)
- Download
- Share externally
- Link to tasks
- Add tags

**Upload Files:**
- Take photo (camera)
- Select from gallery
- Pick from files
- Automatic OCR (if enabled)

#### **4. Knowledge Base (Wiki)**

**Browse Pages:**
- Tree navigation
- Search full-text
- Filter by tags/type
- Recent pages
- Favorites

**Page Display:**
- Rendered HTML
- Code syntax highlighting
- Tables, lists, images
- Internal links
- Related tasks shown

**Page Actions:**
- Edit (rich text editor)
- Create sub-page
- Add to favorites
- Share link
- Print/export

#### **5. Chatter & Messaging**

**Features:**
- @mention users (autocomplete)
- Reply to messages
- Like/react
- File attachments
- Push notifications
- Read receipts (if mail_tracking installed)

**@Mention Implementation:**
```dart
class MentionInput extends StatefulWidget {
  final Function(String message, List<int> mentionedUsers) onSend;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Type @ to mention...',
      ),
      onChanged: (text) {
        // Detect @mention trigger
        if (text.endsWith('@')) {
          _showUserSelector();
        }
      },
    );
  }

  void _showUserSelector() {
    // Show bottom sheet with user list
    showModalBottomSheet(
      context: context,
      builder: (context) => UserSelectorSheet(
        onUserSelected: (user) {
          _insertMention(user);
        },
      ),
    );
  }
}
```

#### **6. Offline Mode**

**What Works Offline:**
- ✅ View cached tasks
- ✅ View cached documents
- ✅ View knowledge pages
- ✅ Create new tasks (queued)
- ✅ Edit existing tasks (queued)
- ✅ Write chatter messages (queued)
- ✅ View calendar events

**Sync Strategy:**
```dart
class SyncService {
  Future<void> syncWhenOnline() async {
    if (!await _hasInternet()) return;

    // 1. Upload queued changes
    await _uploadQueuedChanges();

    // 2. Download server updates
    await _downloadUpdates();

    // 3. Resolve conflicts
    await _resolveConflicts();

    // 4. Update local cache
    await _updateCache();
  }

  Future<void> _uploadQueuedChanges() async {
    final queue = await _db.getQueuedChanges();
    for (final change in queue) {
      try {
        await _executeChange(change);
        await _db.markAsSynced(change.id);
      } catch (e) {
        // Keep in queue, retry later
        await _db.incrementRetryCount(change.id);
      }
    }
  }
}
```

#### **7. Push Notifications**

**Notification Types:**
- Task assigned to you
- @mentioned in chatter
- Task deadline approaching
- Approval request
- Task overdue

**Setup (Firebase):**
```dart
class NotificationService {
  Future<void> initialize() async {
    // Request permission
    await FirebaseMessaging.instance.requestPermission();

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();

    // Save to Odoo (user preferences)
    await odooService.write('res.users', [userId], {
      'x_fcm_token': token,
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });
  }
}
```

### **File Structure**

```
mobile-app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── config/
│   │   ├── odoo_config.dart           # Odoo server settings
│   │   ├── theme.dart                 # App theme/colors
│   │   └── constants.dart             # App constants
│   │
│   ├── services/
│   │   ├── odoo_service.dart          # ✅ Odoo RPC client
│   │   ├── auth_service.dart          # Authentication
│   │   ├── cache_service.dart         # Offline cache
│   │   ├── sync_service.dart          # Background sync
│   │   ├── notification_service.dart  # Push notifications
│   │   └── file_service.dart          # File upload/download
│   │
│   ├── models/
│   │   ├── task.dart                  # Task data model
│   │   ├── project.dart               # Project model
│   │   ├── user.dart                  # User model
│   │   ├── message.dart               # Chatter message
│   │   ├── document.dart              # DMS document
│   │   ├── knowledge_page.dart        # Knowledge page
│   │   ├── calendar_event.dart        # Calendar event
│   │   └── stage.dart                 # Task stage
│   │
│   ├── providers/
│   │   ├── auth_provider.dart         # Auth state
│   │   ├── project_provider.dart      # Projects state
│   │   ├── task_provider.dart         # Tasks state
│   │   ├── chat_provider.dart         # Chatter state
│   │   ├── document_provider.dart     # Documents state
│   │   ├── knowledge_provider.dart    # Knowledge pages state
│   │   ├── calendar_provider.dart     # Calendar state
│   │   └── user_provider.dart         # User state
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── splash_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── projects/
│   │   │   ├── projects_screen.dart
│   │   │   └── project_detail_screen.dart
│   │   ├── tasks/
│   │   │   ├── tasks_screen.dart      # Kanban board
│   │   │   └── task_detail_screen.dart
│   │   ├── calendar/
│   │   │   └── calendar_screen.dart
│   │   ├── knowledge/
│   │   │   ├── knowledge_screen.dart
│   │   │   └── page_detail_screen.dart
│   │   ├── documents/
│   │   │   ├── documents_screen.dart
│   │   │   └── document_viewer_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   │
│   ├── widgets/
│   │   ├── kanban/
│   │   │   ├── kanban_card.dart
│   │   │   ├── kanban_column.dart
│   │   │   └── kanban_board.dart
│   │   ├── chatter/
│   │   │   ├── chatter_widget.dart
│   │   │   ├── message_item.dart
│   │   │   └── mention_input.dart
│   │   ├── common/
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   ├── empty_state.dart
│   │   │   └── search_bar.dart
│   │   └── files/
│   │       ├── file_upload_widget.dart
│   │       └── file_picker_widget.dart
│   │
│   └── utils/
│       ├── date_utils.dart            # Date formatting
│       ├── color_utils.dart           # Color helpers
│       ├── validators.dart            # Form validation
│       └── html_renderer.dart         # HTML to Flutter widgets
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   └── splash.png
│   └── icons/
│       └── app_icon.png
│
├── android/                           # Android config
├── ios/                               # iOS config
├── test/                              # Tests
├── pubspec.yaml                       # ✅ Dependencies
└── README.md
```

### **Dependencies** (pubspec.yaml)

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter

  # Odoo API
  odoo_rpc: ^0.5.0                    # ✅ Odoo RPC client

  # State Management
  provider: ^6.1.1                    # ✅ State management

  # HTTP & Networking
  http: ^1.1.0
  dio: ^5.4.0

  # Local Storage
  shared_preferences: ^2.2.2          # Simple key-value
  hive: ^2.2.3                        # ✅ NoSQL database
  hive_flutter: ^1.1.0

  # UI Components
  cached_network_image: ^3.3.1        # Image caching
  flutter_slidable: ^3.0.1            # Swipe actions
  pull_to_refresh: ^2.0.0             # Pull-to-refresh
  flutter_spinkit: ^5.2.0             # Loading animations

  # Files & Media
  image_picker: ^1.0.7                # Camera/gallery
  file_picker: ^6.1.1                 # File selection
  path_provider: ^2.1.2               # File paths

  # Push Notifications
  firebase_core: ^2.24.2              # Firebase SDK
  firebase_messaging: ^14.7.10        # FCM
  flutter_local_notifications: ^16.3.2 # Local notifs

  # Rich Text
  flutter_markdown: ^0.6.18           # Markdown rendering
  flutter_quill: ^9.0.0               # Rich text editor
  flutter_html: ^3.0.0                # HTML rendering

  # Utilities
  intl: ^0.18.1                       # Internationalization
  uuid: ^4.3.3                        # UUID generation
  logger: ^2.0.2                      # Logging
```

---

## 🎯 Mobile App Features for Notion Workspace

### **Tasks & Projects**

| Feature | PWA | Native | Notes |
|---------|-----|--------|-------|
| View Kanban board | ✅ | ✅ | |
| Drag-and-drop | ✅ | ✅ | |
| Create task | ✅ | ✅ | |
| Edit task | ✅ | ✅ | |
| Assign users | ✅ | ✅ | |
| Set deadlines | ✅ | ✅ | |
| Add tags | ✅ | ✅ | |
| Filter/search | ✅ | ✅ | |
| Link evidence | ✅ | ✅ | Custom field: x_evidence_url |
| Link knowledge | ✅ | ✅ | Custom field: x_knowledge_page_id |
| Approval workflow | ✅ | ✅ | Custom field: x_approval_status |
| Offline create | ❌ | ✅ | Queue for sync |
| Offline edit | ❌ | ✅ | Queue for sync |

### **Calendar**

| Feature | PWA | Native | Notes |
|---------|-----|--------|-------|
| View calendar | ✅ | ✅ | Month/week/day |
| Regulatory deadlines | ✅ | ✅ | BIR, SSS, etc. |
| Add event | ✅ | ✅ | |
| Edit event | ✅ | ✅ | |
| Add attendees | ✅ | ✅ | |
| Set reminders | ✅ | ✅ | |
| Sync to device | ❌ | ✅ | iOS/Android calendar |
| Push reminders | ❌ | ✅ | Firebase |

### **Evidence Repository (DMS)**

| Feature | PWA | Native | Notes |
|---------|-----|--------|-------|
| Browse folders | ✅ | ✅ | |
| Search documents | ✅ | ✅ | |
| View PDF | ✅ | ✅ | Inline viewer |
| View images | ✅ | ✅ | |
| Upload files | ✅ | ✅ | |
| Take photo | ⚠️ | ✅ | Limited on PWA |
| Download | ✅ | ✅ | |
| Tag documents | ✅ | ✅ | |
| Link to tasks | ✅ | ✅ | Custom field: x_task_id |
| Offline view | ⚠️ | ✅ | Cached files |

### **Knowledge Base**

| Feature | PWA | Native | Notes |
|---------|-----|--------|-------|
| Browse pages | ✅ | ✅ | |
| View page | ✅ | ✅ | HTML rendering |
| Search pages | ✅ | ✅ | |
| Create page | ✅ | ✅ | |
| Edit page | ✅ | ✅ | Rich text editor |
| View related tasks | ✅ | ✅ | Custom field: x_task_ids |
| Page types | ✅ | ✅ | SOP, guide, policy, etc. |
| Offline view | ⚠️ | ✅ | Cached pages |

### **Chatter & Messaging**

| Feature | PWA | Native | Notes |
|---------|-----|--------|-------|
| View messages | ✅ | ✅ | |
| Post message | ✅ | ✅ | |
| @mention users | ✅ | ✅ | Autocomplete |
| File attachments | ✅ | ✅ | |
| Email notifications | ✅ | ✅ | Via Odoo |
| Push notifications | ❌ | ✅ | Firebase FCM |
| Read receipts | ✅ | ✅ | If mail_tracking installed |
| Typing indicator | ❌ | ✅ | WebSocket required |

---

## 🚀 Quick Start

### **PWA (5 minutes)**

1. **Verify module installed:**
```bash
ssh root@188.166.237.231
docker exec -i odoo18 odoo shell -d odoo_production << 'ODOO_SHELL'
pwa = env['ir.module.module'].search([('name', '=', 'web_pwa_oca')])
print(f"Status: {pwa.state}")
exit()
ODOO_SHELL
```

2. **Open on mobile:** https://insightpulseai.net:8069

3. **Install to home screen** (instructions above)

4. **Done!** Use like native app

### **Flutter App (First Time Setup)**

1. **Install Flutter:**
```bash
brew install flutter
flutter doctor
```

2. **Clone and setup:**
```bash
cd /path/to/odoboo-workspace/mobile-app
flutter pub get
```

3. **Configure Odoo connection:**
```dart
// Edit lib/config/odoo_config.dart
static const String baseUrl = 'https://insightpulseai.net:8069';
static const String database = 'odoo_production';
```

4. **Run on device:**
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

5. **Login:**
- Email: your-email@company.com
- Password: your-odoo-password

---

## 📱 Recommended Approach

**For immediate deployment:** Use PWA
- ✅ Ready now (already installed)
- ✅ No development needed
- ✅ Works on all devices
- ✅ Auto-updates

**For production deployment:** Build Flutter app
- ✅ Better performance
- ✅ Full offline support
- ✅ Professional appearance
- ✅ App store presence

**Hybrid approach:**
1. **Week 1:** Deploy PWA for immediate mobile access
2. **Month 1:** Develop Flutter app in parallel
3. **Month 2:** Test Flutter app with pilot users
4. **Month 3:** Release to app stores
5. **Ongoing:** Maintain both (users can choose)

---

## 📚 Additional Resources

- **PWA Module Docs:** https://github.com/OCA/web/tree/18.0/web_pwa_oca
- **Flutter Guide:** `/docs/FLUTTER_MOBILE_APP_GUIDE.md`
- **Mobile Setup:** `/docs/MOBILE_APP_SUPPORT.md`
- **Odoo RPC:** https://pub.dev/packages/odoo_rpc

---

## ✅ Summary

You have **two mobile options** ready to deploy:

**Option 1: PWA** ✅ Already installed, use immediately
**Option 2: Flutter** 🚧 2-3 days development, production-ready

Both give full access to your Notion-style workspace:
- ✅ Kanban tasks
- ✅ Calendar events
- ✅ Evidence repository
- ✅ Knowledge base
- ✅ Chatter messaging

**Ready to use now:** Open **https://insightpulseai.net:8069** on your phone!
