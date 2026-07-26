// lib/screens/message_box_pannel/chat_configuration_button.dart
//
// QuantMessage — Chat Configuration Button placed next to the Plus (+) button in MessageBox
// Opens the ChatConfigurationDropdown menu overlay
// ------------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'chat_configuration_dropdown.dart';

class ChatConfigurationButton extends StatefulWidget {
  final String selectedMode;
  final ValueChanged<String>? onModeChanged;
  final bool isHovered;

  const ChatConfigurationButton({
    super.key,
    this.selectedMode = 'Autopilot mode',
    this.onModeChanged,
    required this.isHovered,
  });

  @override
  State<ChatConfigurationButton> createState() => _ChatConfigurationButtonState();
}

class _ChatConfigurationButtonState extends State<ChatConfigurationButton> {
  bool _localHover = false;

  void _openDropdownMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ChatConfigurationDropdown',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return ChatConfigurationDropdown(
          selectedMode: widget.selectedMode,
          onModeSelected: (mode) {
            widget.onModeChanged?.call(mode);
          },
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = widget.isHovered || _localHover;

    return Tooltip(
      message: "Chat Configuration (< Output Choice >)",
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _localHover = true),
        onExit: (_) => setState(() => _localHover = false),
        child: GestureDetector(
          onTap: _openDropdownMenu,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHighlighted
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: isHighlighted ? Colors.white : Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
