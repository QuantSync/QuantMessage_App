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
  // 🌐 BACKEND API — Dual-Backend Routing (Railway Primary + Render Backup)
  // ═══════════════════════════════════════════════════════════════════════

  /// PRIMARY backend (Railway) — fastest, always tried first.
  /// Reads from .env in dev; falls back to the live Railway URL on Vercel/prod.
  static String get primaryBackendUrl =>
      dotenv.env['RAILWAY_BACKEND_URL'] ??
          'https://web-production-aa98e.up.railway.app';

  /// BACKUP backend (Render) — auto-failover if Railway is down.
  static String get backupBackendUrl =>
      dotenv.env['RENDER_BACKEND_URL'] ??
          'https://quantmessage-backend-backup.onrender.com';

  /// LOCAL backend (development) — localhost fallback.
  static String get localBackendUrl =>
      dotenv.env['LOCAL_BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  /// The canonical chat endpoint path (appended to any base URL).
  static const String chatEndpointPath = '/api/v1/chat';

  /// Backwards-compatible alias (used by UploadService).
  static String get backendUrl => primaryBackendUrl;

  // ═══════════════════════════════════════════════════════════════════════
  // 🛠️ UTILITIES & PLATFORM
  // ═══════════════════════════════════════════════════════════════════════

  /// Platform helper – useful when you need to branch for web vs mobile.
  static bool get isWeb => kIsWeb;

  /// The definitive list of AI Models.
  /// This list is used by ChatScreen, HomeScreen, and MessageBox.
  static List<AiModel> get models => _models;

  /// Internal list (cached for performance)
  /// Model IDs use LiteLLM routing format:
  ///   groq/model-name       → Groq API
  ///   gemini/model-name     → Google Gemini API
  ///   openrouter/org/model  → OpenRouter API
  ///   quantcore/auto        → QuantCore direct httpx path
  static final List<AiModel> _models = [
    // ── NATIVE (QuantCore) ─────────────────────────────────────────────────
    const AiModel(
      name: 'QuantCore Auto',
      id: 'quantcore/auto',
      description: 'QuantMessage proprietary multi-model auto-router. Free. Uses Groq → OpenRouter chain.',
      category: ModelCategory.native,
      supportsVision: false,
      maxContextLength: 131072,
    ),

    // ── FREE (Groq — fastest, generous free quota) ─────────────────────────
    const AiModel(
      name: 'Llama 3.1 8B Instant',
      id: 'groq/llama-3.1-8b-instant',
      description: 'Meta\'s Llama 3.1 8B. Fastest Groq model. Free tier with generous quota.',
      category: ModelCategory.free,
      supportsVision: false,
      maxContextLength: 131072,
    ),
    const AiModel(
      name: 'Llama 3.3 70B Versatile',
      id: 'groq/llama-3.3-70b-versatile',
      description: 'Meta\'s Llama 3.3 70B. Best quality on Groq. Free tier.',
      category: ModelCategory.free,
      supportsVision: false,
      maxContextLength: 131072,
    ),
    const AiModel(
      name: 'Mixtral 8x7B',
      id: 'groq/mixtral-8x7b-32768',
      description: 'Mistral\'s Mixtral MoE model. Great for reasoning. Free tier.',
      category: ModelCategory.free,
      supportsVision: false,
      maxContextLength: 32768,
    ),
    const AiModel(
      name: 'Gemma 2 9B IT',
      id: 'groq/gemma2-9b-it',
      description: 'Google\'s Gemma 2 9B instruction-tuned. Compact and capable. Free tier.',
      category: ModelCategory.free,
      supportsVision: false,
      maxContextLength: 8192,
    ),

    // ── REASONING (Gemini — large context, multimodal) ─────────────────────
    const AiModel(
      name: 'Gemini 2.0 Flash',
      id: 'gemini/gemini-2.0-flash',
      description: 'Google\'s latest multimodal model. Fast, capable, generous free quota.',
      category: ModelCategory.reasoning,
      supportsVision: true,
      maxContextLength: 1048576,
    ),
    const AiModel(
      name: 'Gemini 2.0 Flash Lite',
      id: 'gemini/gemini-2.0-flash-lite',
      description: 'Google\'s ultra-fast, lightweight Gemini 2.0 variant.',
      category: ModelCategory.reasoning,
      supportsVision: true,
      maxContextLength: 1048576,
    ),
    const AiModel(
      name: 'Gemini 1.5 Flash',
      id: 'gemini/gemini-1.5-flash',
      description: 'Google\'s fast 1M-context model. Free tier.',
      category: ModelCategory.reasoning,
      supportsVision: true,
      maxContextLength: 1048576,
    ),
    const AiModel(
      name: 'Gemini 1.5 Pro',
      id: 'gemini/gemini-1.5-pro',
      description: 'Google\'s 1M-context pro model. Excellent for long documents.',
      category: ModelCategory.reasoning,
      supportsVision: true,
      maxContextLength: 2097152,
    ),

    // ── CODING (Premium OpenRouter models) ────────────────────────────────
    const AiModel(
      name: 'QuantMessage 3.5 Sonnet',
      id: 'openrouter/anthropic/claude-3.5-sonnet',
      description: 'QuantSync\'s most capable model. Superior reasoning and coding.',
      category: ModelCategory.coding,
      supportsVision: true,
      maxContextLength: 200000,
    ),
    const AiModel(
      name: 'GPT-4o',
      id: 'openrouter/openai/gpt-4o',
      description: 'OpenAI\'s flagship multimodal model. Best for complex tasks.',
      category: ModelCategory.coding,
      supportsVision: true,
      maxContextLength: 128000,
    ),
    const AiModel(
      name: 'GPT-4o Mini',
      id: 'openrouter/openai/gpt-4o-mini',
      description: 'OpenAI\'s cost-efficient model. Great balance of speed and quality.',
      category: ModelCategory.coding,
      supportsVision: true,
      maxContextLength: 128000,
    ),
    const AiModel(
      name: 'DeepSeek R1',
      id: 'openrouter/deepseek/deepseek-r1',
      description: 'DeepSeek\'s reasoning model. Rivals GPT-o1 on benchmarks.',
      category: ModelCategory.coding,
      supportsVision: false,
      maxContextLength: 65536,
    ),

    // ── ROLEPLAY (Creative / conversational models) ────────────────────────
    const AiModel(
      name: 'DeepSeek Chat',
      id: 'openrouter/deepseek/deepseek-chat',
      description: 'DeepSeek\'s latest chat model. Excellent for creative writing.',
      category: ModelCategory.roleplay,
      supportsVision: false,
      maxContextLength: 65536,
    ),
    const AiModel(
      name: 'Grok 2',
      id: 'openrouter/x-ai/grok-2',
      description: 'xAI\'s Grok 2 with real-time knowledge.',
      category: ModelCategory.roleplay,
      supportsVision: false,
      maxContextLength: 131072,
    ),
    const AiModel(
      name: 'Mistral Nemo',
      id: 'openrouter/mistralai/mistral-nemo',
      description: 'Mistral\'s efficient 12B model. Great multilingual support.',
      category: ModelCategory.roleplay,
      supportsVision: false,
      maxContextLength: 131072,
    ),
    const AiModel(
      name: 'QuantMessage 3 Haiku',
      id: 'openrouter/anthropic/claude-3-haiku',
      description: 'QuantSync\'s fastest QuantMessage. Cost-effective creative companion.',
      category: ModelCategory.roleplay,
      supportsVision: true,
      maxContextLength: 200000,
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
  native,
  free,
  reasoning,
  coding,
  roleplay,
}

// ═══════════════════════════════════════════════════════════════════════════
// AI Model value object
// ═══════════════════════════════════════════════════════════════════════════

class AiModel {
  final String name;           // Display name
  final String id;             // API id
  final String description;    // Short description
  final ModelCategory category;
  final bool supportsVision;   // Can process images
  final int maxContextLength;  // Token limit

  const AiModel({
    required this.name,
    required this.id,
    required this.description,
    this.category = ModelCategory.native,
    this.supportsVision = false,
    this.maxContextLength = 8192,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
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
      description: json['description'] as String? ?? '',
      category: ModelCategory.values.firstWhere(
            (c) => c.name == json['category'],
        orElse: () => ModelCategory.native,
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
