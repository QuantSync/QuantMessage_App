import 'package:flutter/material.dart';
import 'base_dropup_button.dart';

class SettingsButton extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BaseDropupButton(
      icon: Icons.settings_outlined,
      label: "Settings",
      onTap: onTap,
    );
  }
}
