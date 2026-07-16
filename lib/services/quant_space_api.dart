// lib/services/quant_space_api.dart
//
// QuantMessage — Backend API client (Integrated with Flowise AI & Supabase)

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Convenience type aliases for cleaner code ───────
typedef _Dio                       = dio_pkg.Dio;
typedef _BaseOptions               = dio_pkg.BaseOptions;
typedef _Options                   = dio_pkg.Options;
typedef _FormData                  = dio_pkg.FormData;
typedef _DioException              = dio_pkg.DioException;
typedef _RequestOptions            = dio_pkg.RequestOptions;
typedef _RequestInterceptorHandler = dio_pkg.RequestInterceptorHandler;
typedef _ErrorInterceptorHandler   = dio_pkg.ErrorInterceptorHandler;

class QuantSpaceApi {
  late final _Dio _dio;

  // ye vo credentails hgain jo env file se pull kiye hain
  // Local python backend url
  String get multiAgentUrl => dotenv.env['MULTI_AGENT_URL'] ?? 'http://127.0.0.1:8000/api/v1/chat';
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  QuantSpaceApi() {
    _dio = _Dio(
      _BaseOptions(
        baseUrl: '', // We use full URLs for different endpoints
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    // Attach the Supabase Auth Interceptor to all Dio requests
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CORE AI INTEGRATION (4-Agent Pipeline Backend)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a structured map with 'response' (string) and 'steps' (list).
  Future<Map<String, dynamic>> getAIResponseFull(
    String message,
    String userId, {
    String modelId = 'groq/llama-3.1-8b-instant',
    String conversationId = 'default',
    String mode = 'drive',
  }) async {
    try {
      final response = await _dio.post(
        multiAgentUrl,
        data: {
          'message': message,
          'model_id': modelId,
          'conversation_id': conversationId,
          'user_id': userId,
          'mode': mode,
        },
      );

      if (response.data != null && response.data is Map) {
        final text    = response.data['response']?.toString() ?? 'No response received';
        final steps   = (response.data['agent_steps'] as List?)?.cast<String>() ?? [];
        final isGuest = response.data['is_guest'] as bool? ?? false;
        return {'response': text, 'steps': steps, 'is_guest': isGuest};
      }
      return {'response': response.data.toString(), 'steps': <String>[], 'is_guest': false};
    } on _DioException catch (e) {
      debugPrint('[QuantSpace API] Backend Error: ${e.response?.data ?? e.message}');
      if (e.type == dio_pkg.DioExceptionType.connectionError &&
          multiAgentUrl.contains('127.0.0.1')) {
        return {
          'response': '🚨 Cannot connect to the local backend.\n\n'
              'Please make sure the Python server is running:\n'
              '```\ncd backend\npython main.py\n```',
          'steps': <String>[],
        };
      }
      return {'response': '🚨 AI Error: ${e.message ?? "Unknown error"}', 'steps': <String>[]};
    } catch (e) {
      debugPrint('[QuantSpace API] Unexpected Error: $e');
      return {'response': '🚨 System Error: $e', 'steps': <String>[]};
    }
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
