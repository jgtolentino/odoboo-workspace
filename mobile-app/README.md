# Odoo Mobile App - Flutter

Cross-platform mobile app for Odoo 18+ with project management, task tracking, and @mention support.

## Tech Stack
- **Flutter 3.x** - Cross-platform framework
- **odoo_rpc** - Odoo JSON-RPC client
- **Provider** - State management
- **Firebase** - Push notifications (optional)

## Features
- ✅ Odoo authentication with session management
- ✅ Project and task management
- ✅ Kanban board with drag-and-drop
- ✅ @mention support in chatter
- ✅ Real-time notifications
- ✅ Offline mode with local caching
- ✅ File attachments
- ✅ Activity tracking

## Quick Start

```bash
# Install Flutter dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Build for production
flutter build apk --release
flutter build ios --release
```

## Configuration

Edit `lib/config/odoo_config.dart`:

```dart
static const String baseUrl = 'http://YOUR_IP:8069';
static const String database = 'odoboo_local';
```

## Odoo Setup

1. Enable CORS in Odoo (for development)
2. Configure `web.base.url` system parameter
3. Ensure JSON-RPC endpoint is accessible

## Architecture

```
lib/
├── main.dart                    # App entry point
├── config/
│   └── odoo_config.dart        # Odoo connection config
├── services/
│   ├── odoo_service.dart       # Odoo RPC client
│   ├── auth_service.dart       # Authentication
│   └── notification_service.dart # Push notifications
├── models/
│   ├── project.dart            # Project model
│   ├── task.dart               # Task model
│   └── user.dart               # User model
├── screens/
│   ├── login_screen.dart       # Login page
│   ├── dashboard_screen.dart   # Main dashboard
│   ├── projects_screen.dart    # Project list
│   ├── tasks_screen.dart       # Task Kanban board
│   ├── task_detail_screen.dart # Task details + chatter
│   └── profile_screen.dart     # User profile
├── widgets/
│   ├── kanban_card.dart        # Task card widget
│   ├── chatter_widget.dart     # Chatter component
│   └── mention_input.dart      # @mention input
└── providers/
    ├── auth_provider.dart      # Auth state
    ├── project_provider.dart   # Projects state
    └── task_provider.dart      # Tasks state
```
