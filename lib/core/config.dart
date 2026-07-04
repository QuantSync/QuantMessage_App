// lib/core/config.dart
//
// Central configuration hub – reads the `.env` file (flutter_dotenv) and
// exposes typed, static getters used throughout the app.
//
// Integrated with:
// • Supabase credentials (url, anon key, service role)
// • Flowise AI credentials (url, api key)
// • AI model definitions for the UI
// • Platform helper (web vs mobile)

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  Config._(); // private constructor – this class is never instantiated

  // Initialise the .env file – call this once in main() before any other code runs.
  static Future<void> init() async {
    await dotenv.load(fileName: ".env"); // loads .env from the project root
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ☁️ SUPABASE CREDENTIALS
  // ──────────────────────────────────────────────────────────────────────────

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://example.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String? get supabaseServiceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
  static String? get supabaseJwtSecret => dotenv.env['SUPABASE_JWT_SECRET'];

  // ──────────────────────────────────────────────────────────────────────────
  // 🤖 FLOWISE AI CREDENTIALS (Added for Multi-Agent Integration)
  // ──────────────────────────────────────────────────────────────────────────

  static String get flowiseUrl =>
      dotenv.env['FLOWISE_URL'] ?? 'https://cloud.flowiseai.com/api/v1/prediction/';

  static String get flowiseApiKey =>
      dotenv.env['FLOWISE_API_KEY'] ?? '';

  // ──────────────────────────────────────────────────────────────────────────
  // 🛠️ UTILITIES
  // ──────────────────────────────────────────────────────────────────────────

  // Platform helper – useful when you need to branch for web vs mobile.
  static bool get isWeb => kIsWeb;

  // Default AI‑model list – typed for safety and easy consumption in the UI.
  static const List<AiModel> models = [
    AiModel(
        name: 'QuantCore 1.0',
        id: 'groq/llama-3.1-70b-versatile',
        icon: '⚡',
        description: 'Groq Llama 3.1 70B, Versatile Quant Expert'),
    AiModel(
        name: 'GPT‑4o',
        id: 'openai/gpt-4o',
        icon: '🧠',
        description: 'OpenAI latest multimodal model'),
    AiModel(
        name: 'Claude 3.5 Sonnet',
        id: 'openrouter/anthropic/claude-3.5-sonnet',
        icon: '🎭',
        description: 'Anthropic’s high‑quality assistant'),
    AiModel(
        name: 'Llama 3.1 8B',
        id: 'groq/llama-3.1-8b-instant',
        icon: '🚀',
        description: 'Fast, inexpensive Llama 8B'),
    AiModel(
        name: 'Mixtral 8x7B',
        id: 'groq/mixtral-8x7b-32768',
        icon: '🔥',
        description: 'Mixture‑of‑experts, great reasoning'),
    AiModel(
        name: 'DeepSeek Chat',
        id: 'openrouter/deepseek/deepseek-chat',
        icon: '🤖',
        description: 'Open‑source‑focused large model'),
  ];
}

// Simple value‑object that describes an AI model – makes the UI type‑safe.
class AiModel {
  final String name;
  final String id;
  final String icon;
  final String description;

  const AiModel({
    required this.name,
    required this.id,
    required this.icon,
    required this.description,
  });
}
