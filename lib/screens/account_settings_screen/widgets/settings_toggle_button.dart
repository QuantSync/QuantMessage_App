// lib/screens/account_settings_screen/widgets/settings_toggle_button.dart
//
// Reusable animated toggle switch for settings panels.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium animated toggle switch with label + optional subtitle.
class SettingsToggleButton extends StatefulWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SettingsToggleButton({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<SettingsToggleButton> createState() => _SettingsToggleButtonState();
}

class _SettingsToggleButtonState extends State<SettingsToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _thumbPosition;
  late Animation<Color?> _trackColor;

  static const _activeColor = Color(0xFF4A9EFF);
  static const _inactiveColor = Color(0xFF3A3A3A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.value ? 1.0 : 0.0,
    );
    _thumbPosition = Tween<double>(begin: 2, end: 20).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _trackColor = ColorTween(begin: _inactiveColor, end: _activeColor).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant SettingsToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.enabled
                  ? () => widget.onChanged(!widget.value)
                  : null,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return Container(
                    width: 42,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _trackColor.value,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: _thumbPosition.value,
                          top: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact inline toggle (no label) for embedding in custom rows.
class MiniToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MiniToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FittedBox(
        child: Switch(
          value: value,
          activeColor: const Color(0xFF4A9EFF),
          activeTrackColor: const Color(0xFF4A9EFF).withOpacity(0.4),
          inactiveThumbColor: Colors.white70,
          inactiveTrackColor: const Color(0xFF3A3A3A),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
