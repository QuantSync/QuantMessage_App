import 'package:flutter/material.dart';
import '../animations/animated_buttons/llm_model_logo/gemini_button.dart';
import '../animations/animated_buttons/llm_model_logo/claude_button.dart';
import '../animations/animated_buttons/llm_model_logo/openai_button.dart';
import '../animations/animated_buttons/llm_model_logo/llama_button.dart';
import '../animations/animated_buttons/llm_model_logo/deepseek_button.dart';

class ModelLogo extends StatelessWidget {
  final String modelId;
  final double size;

  const ModelLogo({
    super.key,
    required this.modelId,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final id = modelId.toLowerCase();
    CustomPainter painter;
    if (id.contains('gemini')) {
      painter = GeminiLogoPainter(primaryColor: Colors.blue, useGradient: true);
    } else if (id.contains('claude')) {
      painter = ClaudeLogoPainter(color: const Color(0xFFD97757));
    } else if (id.contains('gpt') || id.contains('openai')) {
      painter = OpenAILogoPainter(primaryColor: Colors.white);
    } else if (id.contains('llama') || id.contains('quantcore')) {
      painter = LlamaLogoPainter(primaryColor: const Color(0xFF1877F2), useGradient: true);
    } else if (id.contains('deepseek') || id.contains('mistral') || id.contains('grok')) {
      painter = DeepSeekLogoPainter(color: const Color(0xFF4D6BFE));
    } else {
      painter = LlamaLogoPainter(primaryColor: Colors.grey, useGradient: false);
    }

    return CustomPaint(
      size: Size(size, size),
      painter: painter,
    );
  }
}
