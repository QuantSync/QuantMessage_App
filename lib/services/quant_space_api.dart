// lib/services/quant_space_api.dart
//
// QuantMessage — Backend API client (v5.0)
// Dual-Backend Failover:
//   1. PRIMARY  → Railway  (fastest, always tried first)
//   2. BACKUP   → Render   (auto-failover on Railway down/timeout)
//   3. FALLBACK → Localhost (development only)
//
// v5.0: Added multimodal attachment support
//   • getAIResponseFull() accepts optional attachments list
//   • sendMultimodalMessage() sends real files via multipart/form-data
//   • Existing text-only callers are fully backward compatible

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart' as app_config;
import '../core/attachment_model.dart';

// ── Convenience type aliases ──────────────────────────────────────────────
typedef _Dio                       = dio_pkg.Dio;
typedef _BaseOptions               = dio_pkg.BaseOptions;
typedef _Options                   = dio_pkg.Options;
typedef _DioException              = dio_pkg.DioException;
typedef _RequestOptions            = dio_pkg.RequestOptions;
typedef _RequestInterceptorHandler = dio_pkg.RequestInterceptorHandler;
typedef _ErrorInterceptorHandler   = dio_pkg.ErrorInterceptorHandler;

class QuantSpaceApi {
  late final _Dio _dio;

  // ── Derived endpoint URLs ───────────────────────────────────────────────
  String get _primaryChatUrl =>
      '${app_config.Config.primaryBackendUrl}${app_config.Config.chatEndpointPath}';
  String get _backupChatUrl =>
      '${app_config.Config.backupBackendUrl}${app_config.Config.chatEndpointPath}';
  String get _localChatUrl =>
      '${app_config.Config.localBackendUrl}${app_config.Config.chatEndpointPath}';

  String get _primaryMultimodalUrl =>
      '${app_config.Config.primaryBackendUrl}/api/v1/chat/multimodal';
  String get _backupMultimodalUrl =>
      '${app_config.Config.backupBackendUrl}/api/v1/chat/multimodal';
  String get _localMultimodalUrl =>
      '${app_config.Config.localBackendUrl}/api/v1/chat/multimodal';

  // Legacy getter kept for old code that reads dotenv directly
  String get multiAgentUrl =>
      dotenv.env['MULTI_AGENT_URL'] ?? _localChatUrl;

  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  QuantSpaceApi() {
    _dio = _Dio(
      _BaseOptions(
        baseUrl: '',
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 240),
        sendTimeout:    const Duration(seconds: 120),
      ),
    );
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CORE AI INTEGRATION — Text Chat (with optional inline attachments)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a structured map with 'response', 'steps', 'is_guest',
  /// 'path_used', and 'backend_used' for diagnostics.
  ///
  /// [attachments] — optional list of Attachment objects. Files that are
  /// already uploaded to Supabase are sent as their public URL embedded in
  /// the message text. Files with local bytes are base64-encoded and sent
  /// as inline attachments in the JSON payload.
  Future<Map<String, dynamic>> getAIResponseFull(
    String message,
    String userId, {
    String modelId        = 'groq/llama-3.1-8b-instant',
    String conversationId = 'default',
    String mode           = 'drive',
    List<Attachment>? attachments,
  }) async {
    // Serialize any non-URL attachments as base64 inline payloads
    final inlineAttachments = <Map<String, String>>[];
    String messageWithUrls = message;

    if (attachments != null) {
      for (final att in attachments) {
        if (att.url != null && att.url!.isNotEmpty) {
          // Already on Supabase — append the URL to the message text
          messageWithUrls += '\n\nAttachment: ${att.url}';
        } else if (att.bytes != null) {
          // Encode raw bytes as base64 for inline transfer
          inlineAttachments.add({
            'filename':    att.filename,
            'mime_type':   att.mimeType,
            'content_b64': base64Encode(att.bytes!),
          });
        }
      }
    }

    final payload = {
      'message':         messageWithUrls,
      'model_id':        modelId,
      'conversation_id': conversationId,
      'user_id':         userId,
      'mode':            mode,
      if (inlineAttachments.isNotEmpty) 'attachments': inlineAttachments,
    };

    // ── 1. PRIMARY: Railway ──────────────────────────────────────────────
    try {
      debugPrint('[DualBackend] Trying PRIMARY (Railway): $_primaryChatUrl');
      final res = await _dio.post(
        _primaryChatUrl,
        data: payload,
        options: _Options(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 240),
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

    // ── 2. BACKUP: Render ────────────────────────────────────────────────
    try {
      debugPrint('[DualBackend] Trying BACKUP (Render): $_backupChatUrl');
      final res = await _dio.post(
        _backupChatUrl,
        data: payload,
        options: _Options(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 240),
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

    // ── 3. FALLBACK: Localhost (dev / offline) ───────────────────────────
    try {
      debugPrint('[DualBackend] Trying FALLBACK (Localhost): $_localChatUrl');
      final res = await _dio.post(
        _localChatUrl,
        data: payload,
        options: _Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 240),
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

  // ──────────────────────────────────────────────────────────────────────────
  //  MULTIMODAL — Send real files via multipart/form-data
  // ──────────────────────────────────────────────────────────────────────────

  /// Sends a message + actual files to the /api/v1/chat/multimodal endpoint.
  /// Use this when you have File objects on disk (mobile/desktop).
  /// On web, use getAIResponseFull() with bytes-based attachments instead.
  Future<Map<String, dynamic>> sendMultimodalMessage({
    required String message,
    required String userId,
    String modelId        = 'groq/llama-3.1-8b-instant',
    String conversationId = 'default',
    String mode           = 'drive',
    List<File> files      = const [],
  }) async {
    // Build a FormData with fields + file parts
    final formDataFields = {
      'message':         message,
      'model_id':        modelId,
      'conversation_id': conversationId,
      'user_id':         userId,
      'mode':            mode,
    };

    final fileParts = <dio_pkg.MultipartFile>[];
    for (final file in files) {
      final bytes    = await file.readAsBytes();
      final filename = p.basename(file.path);
      fileParts.add(dio_pkg.MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ));
    }

    final formData = dio_pkg.FormData.fromMap({
      ...formDataFields,
      if (fileParts.isNotEmpty) 'files': fileParts,
    });

    // Try primary → backup → local, same pattern as text chat
    for (final entry in [
      ('PRIMARY',   _primaryMultimodalUrl,  15),
      ('BACKUP',    _backupMultimodalUrl,    20),
      ('LOCALHOST', _localMultimodalUrl,      5),
    ]) {
      final (label, url, connectSec) = entry;
      try {
        debugPrint('[Multimodal] Trying $label: $url');
        final res = await _dio.post(
          url,
          data: formData,
          options: _Options(
            contentType:    'multipart/form-data',
            connectTimeout: Duration(seconds: connectSec),
            receiveTimeout: const Duration(seconds: 300),
          ),
        );
        if (res.data != null && res.data is Map) {
          return _parseResponse(res.data, backendLabel: label);
        }
      } on _DioException catch (e) {
        debugPrint('[Multimodal] $label failed: ${e.type} — ${e.message}');
      } catch (e) {
        debugPrint('[Multimodal] $label unexpected error: $e');
      }
    }

    return {
      'response': '⚠️ Multimodal service unavailable. Please try again.',
      'steps': <String>[],
      'is_guest': true,
      'backend_used': 'None — all backends failed',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PARSE RESPONSE
  // ──────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseResponse(dynamic data, {required String backendLabel}) {
    final text     = data['response']?.toString() ?? 'No response received';
    final steps    = (data['agent_steps'] as List?)?.cast<String>() ?? <String>[];
    final isGuest  = data['is_guest'] as bool? ?? false;
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

  // ──────────────────────────────────────────────────────────────────────────
  //  SIMPLE TEXT WRAPPER (backward compatible)
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> getAIResponse(
    String message,
    String userId, {
    String modelId        = 'groq/llama-3.1-8b-instant',
    String conversationId = 'default',
    String mode           = 'drive',
  }) async {
    final result = await getAIResponseFull(
      message,
      userId,
      modelId:        modelId,
      conversationId: conversationId,
      mode:           mode,
    );
    return result['response'] as String;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  SUPABASE STORAGE UPLOAD
  // ──────────────────────────────────────────────────────────────────────────

  /// Uploads a file to Supabase Storage and returns the Public URL.
  Future<Map<String, dynamic>> uploadFile(String filePath, {required String conversationId}) async {
    try {
      final fileName = p.basename(filePath);
      final file     = File(filePath);
      final storage  = Supabase.instance.client.storage.from('attachments');
      final path     = 'conversations/$conversationId/$fileName';

      await storage.upload(path, file, fileOptions: const FileOptions(upsert: true));
      final publicUrl = storage.getPublicUrl(path);

      return {
        'url':     publicUrl,
        'status':  'success',
        'message': 'File uploaded successfully',
      };
    } catch (e) {
      debugPrint('[QuantSpace API] Upload Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  COMPATIBILITY LAYER
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> chat(String message, {String? model}) async {
    final responseText = await getAIResponse(message, "legacy_session");
    return {
      'content':         responseText,
      'conversation_id': 'flowise_session',
    };
  }

  Future<Map<String, dynamic>> chatSimple(String text, {String? model}) async =>
      await chat(text, model: model);

  // ──────────────────────────────────────────────────────────────────────────
  //  UTILITIES
  // ──────────────────────────────────────────────────────────────────────────

  Future<String?> generateImage(String prompt) async {
    final response = await getAIResponse(
      "Generate a high-quality AI image: $prompt",
      "image_session",
    );
    final urlRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final match    = urlRegex.firstMatch(response);
    return match?.group(1) ?? response;
  }

  void resetSession() => debugPrint('[QuantSpace API] Session Reset Requested');
  void dispose()      => _dio.close();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Auth Interceptor
// ─────────────────────────────────────────────────────────────────────────────
class _AuthInterceptor extends dio_pkg.Interceptor {
  @override
  void onRequest(_RequestOptions options, _RequestInterceptorHandler handler) {
    try {
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
