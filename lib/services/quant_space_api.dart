// lib/services/quant_space_api.dart
//
// QuantMessage — Backend API client
// Dual-Backend Failover:
//   1. PRIMARY  → Railway  (fastest, always tried first)
//   2. BACKUP   → Render   (auto-failover on Railway down/timeout)
//   3. FALLBACK → Localhost (development only)

import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart' as app_config;

// ── Convenience type aliases for cleaner code ───────
typedef _Dio                       = dio_pkg.Dio;
typedef _BaseOptions               = dio_pkg.BaseOptions;
typedef _Options                   = dio_pkg.Options;
typedef _DioException              = dio_pkg.DioException;
typedef _RequestOptions            = dio_pkg.RequestOptions;
typedef _RequestInterceptorHandler = dio_pkg.RequestInterceptorHandler;
typedef _ErrorInterceptorHandler   = dio_pkg.ErrorInterceptorHandler;

class QuantSpaceApi {
  late final _Dio _dio;

  // ── Derived endpoint URLs ─────────────────────────────────────────────────
  String get _primaryChatUrl  =>
      '${app_config.Config.primaryBackendUrl}${app_config.Config.chatEndpointPath}';
  String get _backupChatUrl   =>
      '${app_config.Config.backupBackendUrl}${app_config.Config.chatEndpointPath}';
  String get _localChatUrl    =>
      '${app_config.Config.localBackendUrl}${app_config.Config.chatEndpointPath}';

  // Legacy getter kept for old code that reads dotenv directly
  String get multiAgentUrl =>
      dotenv.env['MULTI_AGENT_URL'] ?? _localChatUrl;

  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  QuantSpaceApi() {
    _dio = _Dio(
      _BaseOptions(
        baseUrl: '',
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 15),  // shorter for fast failover
        receiveTimeout: const Duration(seconds: 240),
        sendTimeout:    const Duration(seconds: 120),
      ),
    );
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CORE AI INTEGRATION — Dual-Backend Failover
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a structured map with 'response' (string), 'steps' (list),
  /// 'is_guest' (bool), and 'backend_used' (string) for diagnostics.
  ///
  /// Routing waterfall:
  ///   1. Railway (Primary)  — 15 s connect timeout
  ///   2. Render  (Backup)   — 20 s connect timeout
  ///   3. Localhost (Dev)    — final safety net
  Future<Map<String, dynamic>> getAIResponseFull(
    String message,
    String userId, {
    String modelId         = 'groq/llama-3.1-8b-instant',
    String conversationId  = 'default',
    String mode            = 'drive',
  }) async {
    final payload = {
      'message':         message,
      'model_id':        modelId,
      'conversation_id': conversationId,
      'user_id':         userId,
      'mode':            mode,
    };

    // ── 1. PRIMARY: Railway ──────────────────────────────────────────────────
    try {
      debugPrint('[DualBackend] Trying PRIMARY (Railway): $_primaryChatUrl');
      final res = await _dio.post(
        _primaryChatUrl,
        data: payload,
        options: _Options(
          connectTimeout:  const Duration(seconds: 15),
          receiveTimeout:  const Duration(seconds: 240),
        ),
      );
      if (res.data != null && res.data is Map) {
        return _parseResponse(res.data, backendLabel: 'Railway (Primary)');
      }
    } on _DioException catch (e) {
      debugPrint('[DualBackend] PRIMARY failed: ${e.type} — ${e.message}. Trying BACKUP...');
    } catch (e) {
      debugPrint('[DualBackend] PRIMARY unexpected error: $e. Trying BACKUP...');
    }

    // ── 2. BACKUP: Render ────────────────────────────────────────────────────
    try {
      debugPrint('[DualBackend] Trying BACKUP (Render): $_backupChatUrl');
      final res = await _dio.post(
        _backupChatUrl,
        data: payload,
        options: _Options(
          connectTimeout:  const Duration(seconds: 20),
          receiveTimeout:  const Duration(seconds: 240),
        ),
      );
      if (res.data != null && res.data is Map) {
        return _parseResponse(res.data, backendLabel: 'Render (Backup)');
      }
    } on _DioException catch (e) {
      debugPrint('[DualBackend] BACKUP failed: ${e.type} — ${e.message}. Trying LOCALHOST...');
    } catch (e) {
      debugPrint('[DualBackend] BACKUP unexpected error: $e. Trying LOCALHOST...');
    }

    // ── 3. FALLBACK: Localhost (dev / offline) ───────────────────────────────
    try {
      debugPrint('[DualBackend] Trying FALLBACK (Localhost): $_localChatUrl');
      final res = await _dio.post(
        _localChatUrl,
        data: payload,
        options: _Options(
          connectTimeout:  const Duration(seconds: 5),
          receiveTimeout:  const Duration(seconds: 240),
        ),
      );
      if (res.data != null && res.data is Map) {
        return _parseResponse(res.data, backendLabel: 'Localhost (Dev)');
      }
    } on _DioException catch (e) {
      debugPrint('[DualBackend] LOCALHOST also failed: ${e.message}');
      if (e.type == dio_pkg.DioExceptionType.connectionError) {
        return {
          'response': '⚠️ All backends unreachable.\n\n'
              'Please check your internet connection or start the local backend:\n'
              '```\ncd backend\npython main.py\n```',
          'steps': <String>[],
          'is_guest': true,
          'backend_used': 'None — all backends failed',
        };
      }
    } catch (e) {
      debugPrint('[DualBackend] All backends failed: $e');
    }

    return {
      'response': '⚠️ Service temporarily unavailable. Please try again in a moment.',
      'steps': <String>[],
      'is_guest': true,
      'backend_used': 'None — all backends failed',
    };
  }

  /// Parses the raw API response into a standardised result map.
  Map<String, dynamic> _parseResponse(dynamic data, {required String backendLabel}) {
    final text    = data['response']?.toString() ?? 'No response received';
    final steps   = (data['agent_steps'] as List?)?.cast<String>() ?? <String>[];
    final isGuest = data['is_guest'] as bool? ?? false;
    final pathUsed = data['path_used']?.toString() ?? '';
    debugPrint('[DualBackend] SUCCESS via $backendLabel | path=$pathUsed');
    return {
      'response':     text,
      'steps':        steps,
      'is_guest':     isGuest,
      'path_used':    pathUsed,
      'backend_used': backendLabel,
    };
  }

  /// Simple string-only wrapper kept for backward compatibility.
  Future<String> getAIResponse(
    String message,
    String userId, {
    String modelId = 'groq/llama-3.1-8b-instant',
    String conversationId = 'default',
    String mode = 'drive',
  }) async {
    final result = await getAIResponseFull(
      message,
      userId,
      modelId: modelId,
      conversationId: conversationId,
      mode: mode,
    );
    return result['response'] as String;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  MULTIMODAL & FILE HANDLING (Supabase Storage)
  // ──────────────────────────────────────────────────────────────────────────

  /// Uploads a file to Supabase Storage and returns the Public URL
  Future<Map<String, dynamic>> uploadFile(String filePath, {required String conversationId}) async {
    try {
      // 1. Extract the filename from the path
      final fileName = p.basename(filePath);

      // 2. Create a dart:io File object
      final file = File(filePath);

      // 3. Upload to Supabase Storage
      // NOTE: Make sure you have created a bucket named 'attachments' in Supabase Dashboard
      final storage = Supabase.instance.client.storage.from('attachments');

      // We organize files by conversationId to keep the storage clean
      final path = 'conversations/$conversationId/$fileName';

      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // 4. Generate the Public URL to send to the AI model
      final publicUrl = storage.getPublicUrl(path);

      return {
        'url': publicUrl,
        'status': 'success',
        'message': 'File uploaded successfully',
      };
    } catch (e) {
      debugPrint('[QuantSpace API] Upload Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  COMPATIBILITY LAYER (For older parts of the app)
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> chat(String message, {String? model}) async {
    final responseText = await getAIResponse(message, "legacy_session");
    return {
      'content': responseText,
      'conversation_id': 'flowise_session',
    };
  }

  Future<Map<String, dynamic>> chatSimple(String text, {String? model}) async {
    return await chat(text, model: model);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  OTHER UTILITIES
  // ──────────────────────────────────────────────────────────────────────────

  Future<String?> generateImage(String prompt) async {
    final response = await getAIResponse("Generate a high-quality AI image: $prompt", "image_session");

    // Regular expression to find Markdown images [alt](url)
    final RegExp urlRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final Match? match = urlRegex.firstMatch(response);
    return match?.group(1) ?? response;
  }

  void resetSession() {
    debugPrint('[QuantSpace API] Session Reset Requested');
  }

  void dispose() => _dio.close();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Auth Interceptor (Links Supabase Auth to API Requests)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthInterceptor extends dio_pkg.Interceptor {
  @override
  void onRequest(_RequestOptions options, _RequestInterceptorHandler handler) {
    try {
      // Pull the current session from the Supabase singleton initialized in main.dart
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken != null) {
        options.headers['Authorization'] = 'Bearer ${session!.accessToken}';
      }
    } catch (e) {
      debugPrint('[QuantSpace API] Auth Interceptor Error: $e');
    }
    handler.next(options);
  }

  @override
  void onError(_DioException err, _ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('[QuantSpace API] 401 Unauthorized - Session may have expired');
    }
    handler.next(err);
  }
}
