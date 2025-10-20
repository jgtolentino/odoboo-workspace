/// Odoo Connection Configuration
class OdooConfig {
  // Server Configuration
  static const String baseUrl = 'http://192.168.1.100:8069'; // Change to your IP
  static const String database = 'odoboo_local';

  // API Endpoints
  static const String jsonRpcEndpoint = '/jsonrpc';
  static const String webEndpoint = '/web';

  // Authentication
  static const int sessionTimeout = 3600; // 1 hour in seconds
  static const bool enableAutoLogin = true;

  // Features
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = false; // Set true when Firebase configured
  static const bool enableFileUpload = true;
  static const int maxFileUploadSize = 10 * 1024 * 1024; // 10MB

  // Cache Settings
  static const int cacheExpiry = 300; // 5 minutes in seconds
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB

  // UI Settings
  static const int tasksPerPage = 20;
  static const int projectsPerPage = 15;
  static const Duration refreshInterval = Duration(minutes: 5);

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Development/Production Toggle
  static const bool isProduction = false;
  static const bool enableDebugLogs = !isProduction;

  // Get full URL
  static String get fullUrl => '$baseUrl$jsonRpcEndpoint';
  static String get webUrl => '$baseUrl$webEndpoint';

  // Validate configuration
  static bool isConfigValid() {
    return baseUrl.isNotEmpty &&
           database.isNotEmpty &&
           !baseUrl.contains('localhost') && // Mobile can't access localhost
           !baseUrl.contains('127.0.0.1');
  }

  // Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'baseUrl': baseUrl,
      'database': database,
      'isProduction': isProduction,
      'offlineMode': enableOfflineMode,
      'pushNotifications': enablePushNotifications,
      'configValid': isConfigValid(),
    };
  }
}
