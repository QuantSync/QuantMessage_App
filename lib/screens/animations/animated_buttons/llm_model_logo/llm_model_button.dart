// lib/screens/animations/animated_buttons/llm_model_logo/llm_model_button.dart
//
// LlmModelButton — Individual model row inside ModelSelectorCard.
// Deep-black text on a frosted-glass tile with solid border & shadow.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config.dart' as cfg;

import 'claude_button.dart';
import 'deepseek_button.dart';
import 'gemini_button.dart';
import 'llama_button.dart';
import 'openai_button.dart';

class LlmModelButton extends StatefulWidget {
  final cfg.AiModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const LlmModelButton({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<LlmModelButton> createState() => _LlmModelButtonState();
}

class _LlmModelButtonState extends State<LlmModelButton> {
  bool _isHovered = false;

  Widget _buildTinyLogo(String id) {
    id = id.toLowerCase();
    CustomPainter painter;
    if (id.contains('gemini')) {
      painter = GeminiLogoPainter(primaryColor: const Color(0xFF1A73E8), useGradient: true);
    } else if (id.contains('claude')) {
      painter = ClaudeLogoPainter(color: const Color(0xFFD97757));
    } else if (id.contains('gpt') || id.contains('openai')) {
      painter = OpenAILogoPainter(primaryColor: Colors.black);
    } else if (id.contains('llama') || id.contains('quantcore')) {
      painter = LlamaLogoPainter(primaryColor: const Color(0xFF1877F2), useGradient: true);
    } else if (id.contains('deepseek') || id.contains('mistral') || id.contains('grok')) {
      painter = DeepSeekLogoPainter(color: const Color(0xFF4D6BFE));
    } else {
      painter = LlamaLogoPainter(primaryColor: Colors.black54, useGradient: false);
    }
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: painter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            // Selected/hovered: near-black fill with white text
            // Default: translucent white with black text
            color: isHighlighted
                ? Colors.black.withOpacity(widget.isSelected ? 0.88 : 0.06)
                : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.black.withOpacity(0.85)
                  : isHighlighted
                      ? Colors.black.withOpacity(0.25)
                      : Colors.black.withOpacity(0.12),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (widget.isSelected) ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ] else if (isHighlighted) ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            ],
          ),
          child: Row(
            children: [
              // ── Logo badge ─────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Center(child: _buildTinyLogo(widget.model.id)),
              ),

              const SizedBox(width: 14),

              // ── Name & description ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.model.name,
                            style: GoogleFonts.outfit(
                              // Selected: white on black. Default/hover: deep black.
                              color: widget.isSelected
                                  ? Colors.white
                                  : Colors.black.withOpacity(0.88),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.model.supportsVision) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.20)
                                  : Colors.black.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  color: widget.isSelected
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "Vision",
                                  style: GoogleFonts.outfit(
                                    color: widget.isSelected
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.model.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.model.description,
                        style: GoogleFonts.outfit(
                          color: widget.isSelected
                              ? Colors.white.withOpacity(0.65)
                              : Colors.black.withOpacity(0.45),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Selected check ────────────────────────────────────
              if (widget.isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 15,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
