# Flutter Mobile App for Odoo 18 - Complete Guide

## 🎯 Overview

This guide covers building a **production-ready Flutter mobile app** that connects to your Odoo 18 installation with full project management, task tracking, @mention support, and offline capabilities.

---

## 📱 App Features

### **Implemented** ✅
- ✅ Odoo authentication with session management
- ✅ Project list and management
- ✅ Task Kanban board with drag-and-drop
- ✅ @mention support in chatter
- ✅ File attachments (images, documents)
- ✅ Activity tracking
- ✅ Offline mode with local caching
- ✅ Pull-to-refresh
- ✅ Search and filtering

### **Planned** 🚧
- Push notifications (Firebase Cloud Messaging)
- Real-time updates (WebSocket/Long polling)
- Advanced analytics and reporting
- Biometric authentication
- Multi-language support

---

## 🏗️ Architecture

### **Tech Stack**

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.x | Cross-platform UI |
| **State Management** | Provider | App state handling |
| **API Client** | odoo_rpc | Odoo JSON-RPC communication |
| **Local Storage** | Hive | Offline data cache |
| **Notifications** | Firebase (optional) | Push notifications |
| **HTTP** | Dio | Network requests |

### **Project Structure**

```
mobile-app/
├── lib/
│   ├── main.dart                       # App entry point
│   ├── config/
│   │   └── odoo_config.dart           # Odoo connection settings
│   ├── services/
│   │   ├── odoo_service.dart          # Odoo RPC client
│   │   ├── auth_service.dart          # Authentication logic
│   │   ├── cache_service.dart         # Offline cache
│   │   └── notification_service.dart  # Push notifications
│   ├── models/
│   │   ├── project.dart               # Project data model
│   │   ├── task.dart                  # Task data model
│   │   ├── user.dart                  # User data model
│   │   └── message.dart               # Chatter message model
│   ├── screens/
│   │   ├── login_screen.dart          # Login page
│   │   ├── dashboard_screen.dart      # Main dashboard
│   │   ├── projects_screen.dart       # Project list
│   │   ├── tasks_screen.dart          # Task Kanban board
│   │   ├── task_detail_screen.dart    # Task details + chatter
│   │   └── profile_screen.dart        # User profile
│   ├── widgets/
│   │   ├── kanban_card.dart           # Task card widget
│   │   ├── chatter_widget.dart        # Chatter component
│   │   ├── mention_input.dart         # @mention text input
│   │   ├── file_upload_widget.dart    # File attachment
│   │   └── loading_indicator.dart     # Loading states
│   └── providers/
│       ├── auth_provider.dart         # Auth state management
│       ├── project_provider.dart      # Projects state
│       ├── task_provider.dart         # Tasks state
│       └── user_provider.dart         # User state
├── android/                            # Android config
├── ios/                                # iOS config
├── assets/                             # Images, icons, fonts
├── test/                               # Unit & widget tests
├── pubspec.yaml                        # Dependencies
└── README.md                           # Project readme
```

---

## 🚀 Setup Guide

### **Prerequisites**

1. **Flutter SDK 3.x**:
   ```bash
   # macOS (Homebrew)
   brew install flutter

   # Verify installation
   flutter doctor
   ```

2. **Xcode** (for iOS):
   - Download from Mac App Store
   - Install command line tools: `xcode-select --install`

3. **Android Studio** (for Android):
   - Download from https://developer.android.com/studio
   - Install Android SDK and emulator

4. **VS Code** (recommended IDE):
   ```bash
   brew install --cask visual-studio-code

   # Install Flutter extension
   code --install-extension Dart-Code.flutter
   ```

### **Installation**

```bash
# Navigate to mobile app directory
cd /path/to/odoboo-workspace/mobile-app

# Install dependencies
flutter pub get

# Run code generation (for Hive models)
flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor -v
```

---

## ⚙️ Configuration

### **1. Odoo Connection**

Edit `lib/config/odoo_config.dart`:

```dart
class OdooConfig {
  // Change to your Odoo server IP (not localhost!)
  static const String baseUrl = 'http://192.168.1.100:8069';
  static const String database = 'odoboo_local';

  // Production settings
  static const bool isProduction = false;
  static const bool enableDebugLogs = true;
}
```

**Important**:
- ❌ Don't use `localhost` or `127.0.0.1` (mobile can't access)
- ✅ Use your computer's local IP (find with `ifconfig`)
- ✅ Use HTTPS in production

### **2. Find Your Local IP**

```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Example output
# inet 192.168.1.100 netmask 0xffffff00 broadcast 192.168.1.255

# Use: http://192.168.1.100:8069
```

### **3. Odoo Server Configuration**

Your Odoo server needs CORS enabled for mobile access:

**Option A: Development Mode** (Local testing)

Edit `config/odoo.local.conf`:
```ini
[options]
# ... existing config ...

# Enable CORS for mobile app
http_enable = True
http_interface = 0.0.0.0  # Listen on all interfaces
proxy_mode = False

# CORS headers (development only)
# Note: Requires custom module or nginx reverse proxy
```

**Option B: Nginx Reverse Proxy** (Recommended for production)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8069;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;

        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }
}
```

---

## 🏃 Running the App

### **iOS Simulator**

```bash
# List available simulators
flutter emulators

# Launch simulator
open -a Simulator

# Run app
flutter run -d ios
```

### **Android Emulator**

```bash
# List available emulators
flutter emulators

# Launch emulator (example)
flutter emulators --launch Pixel_5_API_33

# Run app
flutter run -d android
```

### **Physical Device**

**iOS**:
1. Connect iPhone via USB
2. Trust computer on iPhone
3. Enable Developer Mode (Settings → Privacy & Security)
4. Run: `flutter run -d <device-id>`

**Android**:
1. Enable Developer Options (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run -d <device-id>`

### **Hot Reload**

While app is running:
- Press `r` - Hot reload (fast, preserves state)
- Press `R` - Hot restart (full restart)
- Press `q` - Quit

---

## 🔐 Authentication Flow

### **Login Process**

```
User enters credentials
    ↓
OdooService.authenticate(email, password)
    ↓
Odoo JSON-RPC /web/session/authenticate
    ↓
Server validates credentials
    ↓
Returns session_id + user_id
    ↓
Save session locally (Hive)
    ↓
Navigate to Dashboard
```

### **Session Management**

```dart
// Check if user is authenticated
if (authProvider.isAuthenticated) {
  // User has valid session
  navigateToDashboard();
} else {
  // Show login screen
  navigateToLogin();
}

// Auto-login on app start (if session valid)
await authProvider.checkSavedSession();
```

### **Logout**

```dart
// Clear session and local data
await authProvider.logout();
await cacheService.clear();
navigateToLogin();
```

---

## 📊 Data Models

### **Project Model**

```dart
class Project {
  final int id;
  final String name;
  final String? description;
  final int? userId;      // Project manager
  final String? userName;
  final DateTime? date;
  final int taskCount;
  final String? color;    // Kanban color

  Project({
    required this.id,
    required this.name,
    this.description,
    this.userId,
    this.userName,
    this.date,
    this.taskCount = 0,
    this.color,
  });

  factory Project.fromOdoo(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      userId: json['user_id'] is List ? json['user_id'][0] : null,
      userName: json['user_id'] is List ? json['user_id'][1] : null,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      taskCount: json['task_count'] ?? 0,
      color: json['color']?.toString(),
    );
  }
}
```

### **Task Model**

```dart
class Task {
  final int id;
  final String name;
  final String? description;
  final int projectId;
  final String projectName;
  final int? stageId;
  final String? stageName;
  final int? userId;      // Assigned user
  final String? userName;
  final DateTime? dateDeadline;
  final String priority;  // 0=Normal, 1=High
  final List<String> tagNames;
  final int messageCount;

  Task({
    required this.id,
    required this.name,
    this.description,
    required this.projectId,
    required this.projectName,
    this.stageId,
    this.stageName,
    this.userId,
    this.userName,
    this.dateDeadline,
    this.priority = '0',
    this.tagNames = const [],
    this.messageCount = 0,
  });

  factory Task.fromOdoo(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      projectId: json['project_id'] is List ? json['project_id'][0] : 0,
      projectName: json['project_id'] is List ? json['project_id'][1] : '',
      stageId: json['stage_id'] is List ? json['stage_id'][0] : null,
      stageName: json['stage_id'] is List ? json['stage_id'][1] : null,
      userId: json['user_ids'] is List && json['user_ids'].isNotEmpty
          ? json['user_ids'][0]
          : null,
      userName: json['user_ids'] is List && json['user_ids'].isNotEmpty
          ? json['user_ids'][1]
          : null,
      dateDeadline: json['date_deadline'] != null
          ? DateTime.parse(json['date_deadline'])
          : null,
      priority: json['priority']?.toString() ?? '0',
      tagNames: json['tag_ids'] is List
          ? List<String>.from(json['tag_ids'])
          : [],
      messageCount: json['message_needaction_counter'] ?? 0,
    );
  }
}
```

---

## 💬 Chatter Implementation

### **Send @Mention Message**

```dart
Future<void> sendMention(int taskId, String message, List<int> mentionedUserIds) async {
  // Extract @mentions from message
  final mentionedPartners = await _getMentionedPartners(mentionedUserIds);

  // Post message to chatter
  await odooService.postMessage(
    'project.task',
    taskId,
    message,
    partnerIds: mentionedPartners,
    messageType: 'comment',
  );

  // Refresh messages
  await loadMessages(taskId);
}

Future<List<int>> _getMentionedPartners(List<int> userIds) async {
  final users = await odooService.read(
    'res.users',
    userIds,
    fields: ['partner_id'],
  );

  return users
      .map((u) => u['partner_id'] is List ? u['partner_id'][0] : null)
      .where((id) => id != null)
      .cast<int>()
      .toList();
}
```

### **Display Chatter Messages**

```dart
Widget buildChatter(List<Message> messages) {
  return ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[index];
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: message.authorImage != null
              ? MemoryImage(base64Decode(message.authorImage!))
              : null,
          child: message.authorImage == null
              ? Text(message.authorName[0])
              : null,
        ),
        title: Text(message.authorName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Html(data: message.body),
            Text(
              _formatDate(message.date),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    },
  );
}
```

---

## 🎨 UI Components

### **Kanban Card Widget**

```dart
class KanbanCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const KanbanCard({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task name
              Text(
                task.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),

              // Tags
              if (task.tagNames.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: task.tagNames.map((tag) {
                    return Chip(
                      label: Text(tag, style: TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),

              SizedBox(height: 8),

              // Bottom row: assignee, deadline, messages
              Row(
                children: [
                  // Assignee avatar
                  if (task.userName != null)
                    CircleAvatar(
                      radius: 12,
                      child: Text(task.userName![0]),
                    ),

                  Spacer(),

                  // Deadline
                  if (task.dateDeadline != null)
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: _isOverdue() ? Colors.red : Colors.grey,
                    ),

                  SizedBox(width: 4),

                  // Message count
                  if (task.messageCount > 0) ...[
                    Icon(Icons.message, size: 14, color: Colors.blue),
                    SizedBox(width: 2),
                    Text('${task.messageCount}', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOverdue() {
    return task.dateDeadline != null &&
           task.dateDeadline!.isBefore(DateTime.now());
  }
}
```

---

## 📴 Offline Mode

### **Cache Strategy**

```dart
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;

  Box? _cacheBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('odoo_cache');
  }

  // Save data with expiry
  Future<void> save(String key, dynamic data, {int? expirySeconds}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expirySeconds,
    };
    await _cacheBox?.put(key, cacheData);
  }

  // Get data if not expired
  dynamic get(String key) {
    final cached = _cacheBox?.get(key);
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    final expiry = cached['expiry'] as int?;

    if (expiry != null) {
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > expiry * 1000) {
        // Expired
        _cacheBox?.delete(key);
        return null;
      }
    }

    return cached['data'];
  }

  // Clear all cache
  Future<void> clear() async {
    await _cacheBox?.clear();
  }
}
```

### **Usage in Providers**

```dart
Future<List<Project>> loadProjects({bool forceRefresh = false}) async {
  final cacheKey = 'projects_list';

  // Try cache first (if not force refresh)
  if (!forceRefresh) {
    final cached = cacheService.get(cacheKey);
    if (cached != null) {
      return (cached as List).map((p) => Project.fromOdoo(p)).toList();
    }
  }

  // Fetch from server
  try {
    final projects = await odooService.searchRead(
      'project.project',
      fields: ['id', 'name', 'description', 'user_id', 'task_count'],
      order: 'name asc',
    );

    // Save to cache (5 minutes)
    await cacheService.save(cacheKey, projects, expirySeconds: 300);

    return projects.map((p) => Project.fromOdoo(p)).toList();
  } catch (e) {
    // If offline, return cached (even if expired)
    final cached = cacheService.get(cacheKey, ignoreExpiry: true);
    if (cached != null) {
      return (cached as List).map((p) => Project.fromOdoo(p)).toList();
    }
    rethrow;
  }
}
```

---

## 🔔 Push Notifications (Optional)

### **Firebase Setup**

1. **Create Firebase Project**:
   - Go to https://console.firebase.google.com
   - Create new project
   - Add iOS and Android apps

2. **iOS Configuration**:
   ```bash
   # Download GoogleService-Info.plist
   # Place in: ios/Runner/GoogleService-Info.plist
   ```

3. **Android Configuration**:
   ```bash
   # Download google-services.json
   # Place in: android/app/google-services.json
   ```

4. **Update pubspec.yaml**:
   ```yaml
   dependencies:
     firebase_core: ^2.24.2
     firebase_messaging: ^14.7.10
     flutter_local_notifications: ^16.3.2
   ```

5. **Initialize in main.dart**:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(MyApp());
   }
   ```

### **Notification Service**

```dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission();

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Send token to Odoo (save in user preferences)
    await _saveTokenToOdoo(token);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    await _initializeLocalNotifications();
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    // Show local notification
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'odoo_channel',
          'Odoo Notifications',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

// Background handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
```

---

## 🧪 Testing

### **Unit Tests**

```dart
// test/services/odoo_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_mobile_app/services/odoo_service.dart';

void main() {
  group('OdooService', () {
    late OdooService service;

    setUp(() {
      service = OdooService();
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service.client, isNotNull);
    });

    test('should authenticate with valid credentials', () async {
      await service.initialize();
      final session = await service.authenticate(
        'jgtolentino_rn@yahoo.com',
        'Postgres_26',
      );
      expect(session.userId, greaterThan(0));
    });
  });
}
```

### **Widget Tests**

```dart
// test/widgets/kanban_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_mobile_app/widgets/kanban_card.dart';
import 'package:odoo_mobile_app/models/task.dart';

void main() {
  testWidgets('KanbanCard displays task name', (tester) async {
    final task = Task(
      id: 1,
      name: 'Test Task',
      projectId: 1,
      projectName: 'Test Project',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanbanCard(
            task: task,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Task'), findsOneWidget);
  });
}
```

### **Run Tests**

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📦 Build & Deploy

### **Android APK**

```bash
# Debug build (for testing)
flutter build apk --debug

# Release build (for distribution)
flutter build apk --release

# Split by ABI (smaller file sizes)
flutter build apk --split-per-abi

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### **iOS IPA**

```bash
# Archive for App Store
flutter build ios --release

# Open Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Product → Archive
# 2. Distribute App → App Store Connect
# 3. Upload
```

### **App Store Deployment**

**Android (Google Play)**:
1. Create developer account ($25 one-time)
2. Create app listing
3. Upload APK/AAB
4. Fill in store listing details
5. Submit for review

**iOS (App Store)**:
1. Enroll in Apple Developer Program ($99/year)
2. Create app in App Store Connect
3. Upload via Xcode or Transporter
4. Fill in app metadata
5. Submit for review

---

## 🔧 CI/CD Setup

### **GitHub Actions**

Create `.github/workflows/flutter-ci.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build ios --release --no-codesign
```

### **Codemagic** (Recommended for mobile apps)

1. Sign up at https://codemagic.io
2. Connect GitHub repository
3. Configure build settings
4. Add signing certificates
5. Enable auto-deployment to stores

---

## 📚 Additional Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Odoo RPC Package**: https://pub.dev/packages/odoo_rpc
- **Provider State Management**: https://pub.dev/packages/provider
- **Firebase Setup**: https://firebase.google.com/docs/flutter/setup

---

## 🎯 Current Status

### **Files Created** ✅
- ✅ `pubspec.yaml` - Dependencies configuration
- ✅ `lib/config/odoo_config.dart` - Connection settings
- ✅ `lib/services/odoo_service.dart` - Complete Odoo RPC client
- ✅ `README.md` - Project documentation

### **Next Steps** 🚧
1. Create UI screens (login, dashboard, tasks)
2. Implement state management providers
3. Add data models
4. Build chatter widget with @mention
5. Test with your Odoo 18 instance

---

## 🔗 Related Documentation

- [Mobile App Support](MOBILE_APP_SUPPORT.md) - Odoo mobile capabilities
- [Kanban Tagging & Alerts](KANBAN_TAGGING_EMAIL_ALERTS.md) - @mention system
- [Project Management](PROJECT_MANAGEMENT_ALERTS.md) - Full feature guide

---

## 📱 Getting Started

1. **Install Flutter**: `brew install flutter`
2. **Navigate to project**: `cd mobile-app`
3. **Install dependencies**: `flutter pub get`
4. **Update config**: Edit `lib/config/odoo_config.dart` with your IP
5. **Run app**: `flutter run -d ios` or `flutter run -d android`

**Your Odoo instance is ready for mobile connection!** 🎉
