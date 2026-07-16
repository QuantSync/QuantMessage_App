// lib/screens/animations/animated_buttons/solid_plan_button.dart
// Solid white CTA and glass/outlined buttons with ButtonBulge 3D hover scale.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animation_effects/button_bulge.dart';

class SolidPlanButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final bool outlined;

  const SolidPlanButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return ButtonBulge(
        style: BulgeStyle.glass,
        width: width ?? double.infinity,
        height: 44,
        onPressed: onPressed,
        borderRadius: 10,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ButtonBulge(
      style: BulgeStyle.solidWhite,
      width: width ?? double.infinity,
      height: 44,
      onPressed: onPressed,
      borderRadius: 10,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
