import 'package:flutter/material.dart';
import 'base_dropup_button.dart';

class UpgradePlanButton extends StatelessWidget {
  final VoidCallback onTap;

  const UpgradePlanButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BaseDropupButton(
      icon: Icons.arrow_upward_rounded,
      label: "Upgrade plan",
      onTap: onTap,
    );
  }
}
