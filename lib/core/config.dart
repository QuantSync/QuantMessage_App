// lib/core/config.dart
//
// Central configuration hub – reads the `.env` file (flutter_dotenv) and
// exposes typed, static getters used throughout the app.
//
// Synchronized with:
// • main.dart (Initialization)
// • quant_space_api.dart (AI Endpoint & API Keys)
// • upload_service.dart (Backend URL & Storage)
// • message_box.dart (Model selection dropdown)
// • chat_screen.dart & home_screen.dart (Model Selection)
// • settings_screen.dart (User Profiles)
// • chat_message.dart & attachment_model.dart (Data Structure)
// ------------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  Config._(); // private constructor – this class is never instantiated

  /// Initialize the .env file.
  /// Call this in main() BEFORE Supabase.initialize().
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
    } catch (e) {
      debugPrint("🚨 Config Error: Could not load .env file. Check if it exists in root.");
    }
  }

  /// True after successful init
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // ═══════════════════════════════════════════════════════════════════════
  // ☁️ SUPABASE CREDENTIALS
  // ═══════════════════════════════════════════════════════════════════════

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// SERVICE_ROLE_KEY should ONLY be used in Edge Functions, never in the Flutter App.
  static String? get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

  /// True if essential Supabase config is present
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty &&
          supabaseUrl != 'https://your-project.supabase.co' &&
          supabaseAnonKey.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════
  // 🤖 FLOWISE AI CREDENTIALS
  // ═══════════════════════════════════════════════════════════════════════

  static String get flowiseUrl =>
      dotenv.env['FLOWISE_URL'] ??
          'https://cloud.flowiseai.com/api/v1/prediction/';

  static String get flowiseApiKey =>
      dotenv.env['FLOWISE_API_KEY'] ?? '';

  /// True if Flowise config is present
  static bool get hasFlowiseConfig =>
      flowiseUrl.isNotEmpty && flowiseApiKey.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════
  // 🌐 BACKEND API (Railway/Custom Server)
  // ═══════════════════════════════════════════════════════════════════════

  /// Used by UploadService for transcription and custom API endpoints.
  static String get backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'https://your-app.up.railway.app/api/v1';

  // ═══════════════════════════════════════════════════════════════════════
  // 🛠️ UTILITIES & PLATFORM
  // ═══════════════════════════════════════════════════════════════════════

  /// Platform helper – useful when you need to branch for web vs mobile.
  static bool get isWeb => kIsWeb;

  /// The definitive list of AI Models.
  /// This list is used by ChatScreen, HomeScreen, and MessageBox.
  static List<AiModel> get models => _models;

  /// Internal list (cached for performance)
  static final List<AiModel> _models = [
    const AiModel(
      name: 'QuantCore 1.0',
      id: 'groq/llama-3.3-70b-versatile',
      icon: '⚡',
      description: 'Groq Llama 3.3 70B, Versatile Quant Expert',
      category: ModelCategory.general,
      supportsVision: false,
      maxContextLength: 131072,
    ),
    const AiModel(
      name: 'Gemini 1.5 Pro',
      id: 'gemini-1.5-pro-002',
      icon: '✨',
      description: 'Google highly capable multimodal model',
      category: ModelCategory.reasoning,
      supportsVision: true,
      maxContextLength: 2097152,
    ),
    const AiModel(
      name: 'Gemini 1.5 Flash',
      id: 'gemini-1.5-flash-8b',
      icon: '⚡',
      description: 'Google fast & versatile multimodal model',
      category: ModelCategory.fast,
      supportsVision: true,
      maxContextLength: 1048576,
    ),
    const AiModel(
      name: 'GPT-4o',
      id: 'openai/gpt-4o',
      icon: '🧠',
      description: 'OpenAI latest multimodal model',
      category: ModelCategory.multimodal,
      supportsVision: true,
      maxContextLength: 128000,
    ),
    const AiModel(
      name: 'Claude 3.5 Sonnet',
      id: 'anthropic/claude-3.5-sonnet:beta',
      icon: '🎭',
      description: "Anthropic's high-quality assistant",
      category: ModelCategory.multimodal,
      supportsVision: true,
      maxContextLength: 200000,
    ),
    const AiModel(
      name: 'Llama 3.1 8B',
      id: 'groq/llama-3.1-8b-instant',
      icon: '🚀',
      description: 'Fast, inexpensive Llama 8B',
      category: ModelCategory.fast,
      supportsVision: false,
      maxContextLength: 8192,
    ),
    const AiModel(
      name: 'Gemma 2 9B',
      id: 'groq/gemma2-9b-it',
      icon: '🔥',
      description: 'Google Gemma 2 via Groq',
      category: ModelCategory.reasoning,
      supportsVision: false,
      maxContextLength: 8192,
    ),
    const AiModel(
      name: 'DeepSeek Chat',
      id: 'deepseek/deepseek-chat',
      icon: '🤖',
      description: 'Open-source-focused large model',
      category: ModelCategory.general,
      supportsVision: false,
      maxContextLength: 64000,
    ),
  ];

  /// Default model (first in list)
  static AiModel get defaultModel => _models.first;

  /// Lookup by name — used in MessageBox model selection
  static AiModel? getModelByName(String name) {
    try {
      return _models.firstWhere((m) => m.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Lookup by id — used in API calls
  static AiModel? getModelById(String id) {
    try {
      return _models.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get models by category — for filtered dropdowns
  static List<AiModel> getModelsByCategory(ModelCategory category) {
    return _models.where((m) => m.category == category).toList();
  }

  /// Get models that support vision — for attachment-aware selection
  static List<AiModel> get visionCapableModels {
    return _models.where((m) => m.supportsVision).toList();
  }

  /// True if a given model name supports image attachments
  static bool modelSupportsVision(String name) {
    final model = getModelByName(name);
    return model?.supportsVision ?? false;
  }

  /// List of all model names (for dropdowns)
  static List<String> get modelNames => _models.map((m) => m.name).toList();

  /// List of all model ids (for API requests)
  static List<String> get modelIds => _models.map((m) => m.id).toList();

  /// Validate that all required env vars are present
  /// Returns a list of missing keys (empty if all good)
  static List<String> validateRequiredConfig() {
    final missing = <String>[];
    if (!hasSupabaseConfig) {
      if (supabaseUrl.isEmpty || supabaseUrl.contains('your-project')) {
        missing.add('SUPABASE_URL');
      }
      if (supabaseAnonKey.isEmpty) {
        missing.add('SUPABASE_ANON_KEY');
      }
    }
    if (!hasFlowiseConfig) {
      if (flowiseUrl.isEmpty) missing.add('FLOWISE_URL');
      if (flowiseApiKey.isEmpty) missing.add('FLOWISE_API_KEY');
    }
    return missing;
  }

  /// True if the app is properly configured to run
  static bool get isReady => validateRequiredConfig().isEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// Model category enum
// ═══════════════════════════════════════════════════════════════════════════

enum ModelCategory {
  general,     // General-purpose (QuantCore, DeepSeek)
  multimodal,  // Vision + text (GPT-4o, Claude)
  fast,        // Low-latency (Llama 8B)
  reasoning,   // Strong reasoning (Mixtral)
}

// ═══════════════════════════════════════════════════════════════════════════
// AI Model value object
// ═══════════════════════════════════════════════════════════════════════════

class AiModel {
  final String name;           // Display name
  final String id;             // API id
  final String icon;           // Emoji icon
  final String description;    // Short description
  final ModelCategory category;
  final bool supportsVision;   // Can process images
  final int maxContextLength;  // Token limit

  const AiModel({
    required this.name,
    required this.id,
    required this.icon,
    required this.description,
    this.category = ModelCategory.general,
    this.supportsVision = false,
    this.maxContextLength = 8192,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'icon': icon,
      'description': description,
      'category': category.name,
      'supportsVision': supportsVision,
      'maxContextLength': maxContextLength,
    };
  }

  /// Reconstruct from JSON
  factory AiModel.fromJson(Map<String, dynamic> json) {
    return AiModel(
      name: json['name'] as String,
      id: json['id'] as String,
      icon: json['icon'] as String? ?? '🤖',
      description: json['description'] as String? ?? '',
      category: ModelCategory.values.firstWhere(
            (c) => c.name == json['category'],
        orElse: () => ModelCategory.general,
      ),
      supportsVision: json['supportsVision'] as bool? ?? false,
      maxContextLength: json['maxContextLength'] as int? ?? 8192,
    );
  }

  /// Equality based on id
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AiModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AiModel($name, $id)';
}
