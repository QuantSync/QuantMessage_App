// lib/screens/animations/animated_buttons/upgrade_plan_button.dart
// Glass grey "Free Plan : Upgrade ?" button with ButtonBulge 3D hover scale.

import 'package:flutter/material.dart';
import '../animation_effects/button_bulge.dart';

class UpgradePlanButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const UpgradePlanButton({
    super.key,
    this.onPressed,
    this.label = 'Free Plan : Upgrade ?',
  });

  @override
  Widget build(BuildContext context) {
    return ButtonBulge(
      onPressed: onPressed,
      style: BulgeStyle.glass,
      borderRadius: 6.0, // Boxy look with curved edges
      width: 165,
      height: 34,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
