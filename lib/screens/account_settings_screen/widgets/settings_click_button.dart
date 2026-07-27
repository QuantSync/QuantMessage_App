// lib/screens/account_settings_screen/widgets/settings_click_button.dart
//
// Reusable click/action buttons for settings panels.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A standard pill-shaped action button used across settings sections.
class SettingsClickButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isPrimary;
  final IconData? icon;

  const SettingsClickButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isPrimary = false,
    this.icon,
  });

  @override
  State<SettingsClickButton> createState() => _SettingsClickButtonState();
}

class _SettingsClickButtonState extends State<SettingsClickButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.isPrimary) return Colors.white.withOpacity(0.12);
    if (widget.isDestructive) return Colors.redAccent.withOpacity(0.10);
    return Colors.white.withOpacity(0.06);
  }

  Color get _fgColor {
    if (widget.isPrimary) return Colors.white;
    if (widget.isDestructive) return Colors.redAccent;
    return Colors.white.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.icon != null ? 12 : 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.white.withOpacity(0.12)
                  : widget.isDestructive
                      ? Colors.redAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: _fgColor),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  color: _fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width settings row with label + trailing widget.
class SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;

  const SettingsRow({
    super.key,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

/// A section title header for settings pages.
class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// A thin divider for settings sections.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withOpacity(0.06),
      height: 1,
    );
  }
}

/// A pill-shaped value display.
class SettingsPillValue extends StatelessWidget {
  final String text;

  const SettingsPillValue({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white.withOpacity(0.75),
          fontSize: 13,
        ),
      ),
    );
  }
}

/// A multi-segment toggle (e.g., Small | Medium | Large).
class SettingsSegmentToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SettingsSegmentToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((entry) {
          final isActive = entry.key == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.value,
                style: GoogleFonts.outfit(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
