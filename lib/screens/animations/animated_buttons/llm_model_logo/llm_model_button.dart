import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config.dart' as cfg;

class LlmModelButton extends StatefulWidget {
  final cfg.AiModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const LlmModelButton({
    Key? key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<LlmModelButton> createState() => _LlmModelButtonState();
}

class _LlmModelButtonState extends State<LlmModelButton> {
  bool _isHovered = false;

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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.model.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold, // Solid bold bright white text
                            ),
                          ),
                        ),
                        if (widget.model.supportsVision) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    if (widget.model.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.model.description,
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
