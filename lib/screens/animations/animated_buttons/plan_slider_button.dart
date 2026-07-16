// lib/screens/animations/animated_buttons/plan_slider_button.dart
// Glass pill toggle: Individual | Team

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animation_effects/button_bulge.dart';

enum PlanSegment { individual, team }

class PlanSliderButton extends StatelessWidget {
  final PlanSegment selected;
  final ValueChanged<PlanSegment> onChanged;

  const PlanSliderButton({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonBulge(
      style: BulgeStyle.glass,
      borderRadius: 12,
      onPressed: null, // Handled internally by segments
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final half = constraints.maxWidth / 2;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: selected == PlanSegment.individual ? 0 : half,
                  top: 0,
                  bottom: 0,
                  width: half,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _SegmentTap(
                        label: 'Individual',
                        isSelected: selected == PlanSegment.individual,
                        onTap: () => onChanged(PlanSegment.individual),
                      ),
                    ),
                    Expanded(
                      child: _SegmentTap(
                        label: 'Team',
                        isSelected: selected == PlanSegment.team,
                        onTap: () => onChanged(PlanSegment.team),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentTap extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTap({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
