import 'package:flutter/material.dart';
import 'base_dropup_button.dart';

class LanguageButton extends StatelessWidget {
  final VoidCallback onTap;

  const LanguageButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BaseDropupButton(
      icon: Icons.language,
      label: "Language",
      hasTrailingArrow: true,
      onTap: onTap,
    );
  }
}
