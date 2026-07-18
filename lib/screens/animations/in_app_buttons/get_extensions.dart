import 'package:flutter/material.dart';
import 'base_dropup_button.dart';

class GetExtensionsButton extends StatelessWidget {
  final VoidCallback onTap;

  const GetExtensionsButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BaseDropupButton(
      icon: Icons.download_for_offline_outlined,
      label: "Get apps and extensions",
      onTap: onTap,
    );
  }
}
