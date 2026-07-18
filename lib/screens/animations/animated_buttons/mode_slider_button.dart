// lib/screens/animations/animated_buttons/mode_slider_button.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppMode { drive, fly, jet }

class ModeSliderButton extends StatefulWidget {
  final AppMode currentMode;
  final ValueChanged<AppMode> onModeChanged;

  const ModeSliderButton({
    super.key,
    required this.currentMode,//
    required this.onModeChanged,///
  });

  @override
  State<ModeSliderButton> createState() => _ModeSliderButtonState();
}

class _ModeSliderButtonState extends State<ModeSliderButton> {
  bool _isHovered = false;

  final Map<AppMode, String> _labels = {
    AppMode.drive: 'Drive',
    AppMode.fly: 'Fly',
    AppMode.jet: 'Jet',
  };

  final Map<AppMode, IconData> _icons = {
    AppMode.drive: Icons.directions_car_filled_rounded,
    AppMode.fly: Icons.flight_takeoff_rounded,
    AppMode.jet: Icons.rocket_launch_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F5), // Bright whitish grey
          borderRadius: BorderRadius.circular(16), // Boxy but curved
          border: Border.all(
            color: _isHovered ? Colors.black12 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: AppMode.values.map((mode) {
                  final isSelected = widget.currentMode == mode;
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        widget.onModeChanged(mode);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutBack,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icons[mode],
                            size: 12,
                            color: isSelected ? Colors.black87 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _labels[mode]!,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.black87 : Colors.black54,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
