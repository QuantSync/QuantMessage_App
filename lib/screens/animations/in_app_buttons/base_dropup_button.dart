import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BaseDropupButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasTrailingArrow;
  final bool isSelected;
  final Color? iconColor;

  const BaseDropupButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasTrailingArrow = false,
    this.isSelected = false,
    this.iconColor,
  });

  @override
  State<BaseDropupButton> createState() => _BaseDropupButtonState();
}

class _BaseDropupButtonState extends State<BaseDropupButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered || widget.isSelected
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.iconColor ?? Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.hasTrailingArrow)
                const Icon(Icons.chevron_right, color: Colors.white54, size: 20)
              else if (widget.isSelected)
                const Icon(Icons.check, color: Colors.blueAccent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
