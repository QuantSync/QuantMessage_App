import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageItemButton extends StatefulWidget {
  final String languageName;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageItemButton({
    super.key,
    required this.languageName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<LanguageItemButton> createState() => _LanguageItemButtonState();
}

class _LanguageItemButtonState extends State<LanguageItemButton> {
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
            color: _isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.languageName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check,
                  color: Colors.blueAccent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
