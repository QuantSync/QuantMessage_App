// lib/services/quant_space_api.dart
//
// QuantMessage — Backend API client (Integrated with Flowise AI & Supabase)
// -----------------------------------------------------------------------

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io'; // IMPORTED: Needed for File
import 'package:path/path.dart' as p; // IMPORTED: Needed for filenames

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Convenience type aliases ───────
typedef _Dio                       = dio_pkg.Dio;
typedef _BaseOptions               = dio_pkg.BaseOptions;
typedef _Options                   = dio_pkg.Options;
typedef _FormData                  = dio_pkg.FormData;
typedef _DioException              = dio_pkg.DioException;
typedef _ResponseBody              = dio_pkg.ResponseBody;
typedef _ResponseType              = dio_pkg.ResponseType;
typedef _RequestOptions            = dio_pkg.RequestOptions;
typedef _RequestInterceptorHandler = dio_pkg.RequestInterceptorHandler;
typedef _ErrorInterceptorHandler   = dio_pkg.ErrorInterceptorHandler;

class QuantSpaceApi {
  late final _Dio _dio;

  // Credentials from .env
  late final String flowiseUrl;
  late final String flowiseApiKey;
  late final String supabaseUrl;

  QuantSpaceApi() {
    flowiseUrl = dotenv.env['FLOWISE_URL'] ?? '';
    flowiseApiKey = dotenv.env['FLOWISE_API_KEY'] ?? '';
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';

    _dio = _Dio(
      _BaseOptions(
        baseUrl: '',
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    _dio.interceptors.add(_AuthInterceptor());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CORE FLOWISE INTEGRATION
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> getAIResponse(String message, String userId) async {
    try {
      final response = await _dio.post(
        flowiseUrl,
        data: {
          "question": message,
          "overrideConfig": {
            "sessionId": userId,
          },
        },
        options: _Options(
          headers: {
            "Authorization": "Bearer $flowiseApiKey",
          },
        ),
      );

      if (response.data is String) {
        return response.data;
      } else if (response.data is Map) {
        return response.data['text'] ?? response.data['content'] ?? response.data.toString();
      }

      return response.data.toString();
    } on _DioException catch (e) {
      debugPrint('[QuantSpace API] Flowise Error: ${e.response?.data ?? e.message}');
      return "🚨 AI Error: ${e.message}";
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  COMPATIBILITY LAYER
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
  //  MULTIMODAL & FILE HANDLING (FIXED)
  // ──────────────────────────────────────────────────────────────────────────

  /// FIXED: Corrected the MultipartFile error by using dart:io File
  Future<Map<String, dynamic>> uploadFile(String filePath, {required String conversationId}) async {
    try {
      // 1. Extract the filename using the path package
      final fileName = p.basename(filePath);

      // 2. Create a standard dart:io File object
      final file = File(filePath);

      // 3. Upload directly to Supabase Storage
      // The Supabase SDK accepts a File object on mobile platforms
      final storage = Supabase.instance.client.storage.from('chat-attachments');

      await storage.upload(
        'attachments/$conversationId/$fileName',
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // 4. Get the Public URL to send to the AI
      final publicUrl = storage.getPublicUrl('attachments/$conversationId/$fileName');

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
  //  OTHER UTILITIES
  // ──────────────────────────────────────────────────────────────────────────

  Future<String?> generateImage(String prompt) async {
    final response = await getAIResponse("Generate a high-quality AI image: $prompt", "image_session");
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
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onError(_DioException err, _ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('[QuantSpace API] 401 Unauthorized');
    }
    handler.next(err);
  }
}
