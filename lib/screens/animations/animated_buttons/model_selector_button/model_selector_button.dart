import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModelSelectorButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ModelSelectorButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<ModelSelectorButton> createState() => _ModelSelectorButtonState();
}

class _ModelSelectorButtonState extends State<ModelSelectorButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Turn greenish white on press, highlight on hover
    final Color effectiveBgColor = _isPressed
        ? const Color(0xFFD4EED8) // Darker Greenish white for visibility on light bg
        : (_isHovered ? Colors.white : const Color(0xFFF0F0F5)); // Bright whitish grey

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? Colors.black12
                    : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Model",
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black87,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
