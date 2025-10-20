import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:logger/logger.dart';
import '../config/odoo_config.dart';

/// Odoo RPC Service - Handles all Odoo API communication
class OdooService {
  static final OdooService _instance = OdooService._internal();
  factory OdooService() => _instance;
  OdooService._internal();

  final Logger _logger = Logger();
  OdooClient? _client;
  OdooSession? _session;

  bool get isAuthenticated => _session != null && _session!.id != -1;
  OdooSession? get session => _session;
  OdooClient? get client => _client;

  /// Initialize Odoo client
  Future<void> initialize() async {
    try {
      _client = OdooClient(OdooConfig.baseUrl);
      _logger.i('Odoo client initialized: ${OdooConfig.baseUrl}');
    } catch (e) {
      _logger.e('Failed to initialize Odoo client', error: e);
      rethrow;
    }
  }

  /// Authenticate with Odoo
  Future<OdooSession> authenticate(String email, String password) async {
    try {
      if (_client == null) {
        await initialize();
      }

      _session = await _client!.authenticate(
        OdooConfig.database,
        email,
        password,
      );

      _logger.i('Authentication successful for $email');
      _logger.d('Session ID: ${_session!.id}, User ID: ${_session!.userId}');

      return _session!;
    } catch (e) {
      _logger.e('Authentication failed for $email', error: e);
      rethrow;
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    try {
      _session = null;
      _client = null;
      _logger.i('Logged out successfully');
    } catch (e) {
      _logger.e('Logout failed', error: e);
    }
  }

  /// Generic RPC call
  Future<dynamic> call(
    String model,
    String method, {
    List<dynamic>? args,
    Map<String, dynamic>? kwargs,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated. Please login first.');
    }

    try {
      final result = await _client!.callKw({
        'model': model,
        'method': method,
        'args': args ?? [],
        'kwargs': kwargs ?? {},
      });

      _logger.d('RPC Call: $model.$method - Success');
      return result;
    } catch (e) {
      _logger.e('RPC Call failed: $model.$method', error: e);
      rethrow;
    }
  }

  /// Search records
  Future<List<int>> search(
    String model, {
    List<dynamic>? domain,
    int? limit,
    int offset = 0,
    String? order,
  }) async {
    final result = await call(
      model,
      'search',
      kwargs: {
        'domain': domain ?? [],
        'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
      },
    );

    return List<int>.from(result);
  }

  /// Read records
  Future<List<Map<String, dynamic>>> read(
    String model,
    List<int> ids, {
    List<String>? fields,
  }) async {
    final result = await call(
      model,
      'read',
      args: [ids],
      kwargs: {
        if (fields != null) 'fields': fields,
      },
    );

    return List<Map<String, dynamic>>.from(result);
  }

  /// Search and read in one call
  Future<List<Map<String, dynamic>>> searchRead(
    String model, {
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
    int offset = 0,
    String? order,
  }) async {
    final result = await call(
      model,
      'search_read',
      kwargs: {
        'domain': domain ?? [],
        if (fields != null) 'fields': fields,
        if (limit != null) 'limit': limit,
        'offset': offset,
        if (order != null) 'order': order,
      },
    );

    return List<Map<String, dynamic>>.from(result);
  }

  /// Create record
  Future<int> create(
    String model,
    Map<String, dynamic> values,
  ) async {
    final result = await call(
      model,
      'create',
      args: [values],
    );

    return result as int;
  }

  /// Update record
  Future<bool> write(
    String model,
    List<int> ids,
    Map<String, dynamic> values,
  ) async {
    final result = await call(
      model,
      'write',
      args: [ids, values],
    );

    return result as bool;
  }

  /// Delete record
  Future<bool> unlink(
    String model,
    List<int> ids,
  ) async {
    final result = await call(
      model,
      'unlink',
      args: [ids],
    );

    return result as bool;
  }

  /// Get user info
  Future<Map<String, dynamic>> getUserInfo() async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    final users = await read(
      'res.users',
      [_session!.userId],
      fields: ['id', 'name', 'login', 'email', 'image_128', 'company_id'],
    );

    return users.first;
  }

  /// Send message to chatter
  Future<int> postMessage(
    String model,
    int recordId,
    String body, {
    List<int>? partnerIds,
    String messageType = 'comment',
  }) async {
    return await call(
      model,
      'message_post',
      kwargs: {
        'body': body,
        'message_type': messageType,
        if (partnerIds != null) 'partner_ids': partnerIds,
      },
    );
  }

  /// Get chatter messages
  Future<List<Map<String, dynamic>>> getMessages(
    String model,
    int recordId, {
    int? limit,
  }) async {
    final record = await read(
      model,
      [recordId],
      fields: ['message_ids'],
    );

    final messageIds = List<int>.from(record.first['message_ids'] ?? []);

    if (messageIds.isEmpty) return [];

    // Get messages with limit
    final messagesToFetch = limit != null
        ? messageIds.take(limit).toList()
        : messageIds;

    return await read(
      'mail.message',
      messagesToFetch,
      fields: [
        'id',
        'body',
        'author_id',
        'date',
        'message_type',
        'subtype_id',
        'attachment_ids',
      ],
    );
  }

  /// Upload attachment
  Future<int> uploadAttachment(
    String model,
    int recordId,
    String fileName,
    List<int> fileBytes,
  ) async {
    return await create(
      'ir.attachment',
      {
        'name': fileName,
        'datas': fileBytes,
        'res_model': model,
        'res_id': recordId,
      },
    );
  }

  /// Check connection
  Future<bool> checkConnection() async {
    try {
      if (_client == null) {
        await initialize();
      }

      // Try to get server version
      final result = await _client!.getServerVersion();
      _logger.i('Server version: $result');
      return true;
    } catch (e) {
      _logger.e('Connection check failed', error: e);
      return false;
    }
  }
}
