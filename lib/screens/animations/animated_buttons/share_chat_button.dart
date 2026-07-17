// lib/screens/animations/animated_buttons/share_chat_button.dart

import 'package:flutter/material.dart';

class ShareChatButton extends StatefulWidget {
  final VoidCallback onTap;

  const ShareChatButton({super.key, required this.onTap});

  @override
  State<ShareChatButton> createState() => _ShareChatButtonState();
}

class _ShareChatButtonState extends State<ShareChatButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.forward(),
        onTapUp: (_) async {
          await _scaleCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleCtrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? Colors.white30 : Colors.white10,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Text(
              "Share",
              style: TextStyle(
                color: _isHovered ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
