import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../in_app_buttons/settings_button.dart';
import '../in_app_buttons/language_button.dart';
import '../in_app_buttons/upgrade_plan.dart';
import '../in_app_buttons/get_extensions.dart';
import '../in_app_buttons/base_dropup_button.dart';
import 'language_dropup.dart';
import '../../pricing_screen/pricing_screen.dart';

class AccountDropupMenu extends StatelessWidget {
  final String email;
  final VoidCallback onLogout;

  const AccountDropupMenu({
    super.key,
    required this.email,
    required this.onLogout,
  });

  void _showLanguageMenu(BuildContext context, RenderBox renderBox) {
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    
    // Position it just to the right of the current menu
    showLanguageDropup(
      context,
      RelativeRect.fromLTRB(
        position.dx + size.width + 8,
        position.dy,
        position.dx + size.width + 300,
        position.dy + size.height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Email)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              email,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // First Group
          SettingsButton(onTap: () {
            Navigator.pop(context);
            // Navigator.push to settings screen
          }),
          
          Builder(
            builder: (ctx) {
              return LanguageButton(onTap: () {
                final RenderBox box = ctx.findRenderObject() as RenderBox;
                _showLanguageMenu(context, box);
              });
            }
          ),
          
          BaseDropupButton(
            icon: Icons.help_outline,
            label: "Get help",
            onTap: () {
              Navigator.pop(context);
            },
          ),
          
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 16),
          
          // Second Group
          UpgradePlanButton(onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (c, a1, a2) => const PricingScreen(),
                transitionsBuilder: (c, a1, a2, child) {
                  return FadeTransition(opacity: a1, child: child);
                },
              ),
            );
          }),
          
          GetExtensionsButton(onTap: () {
            Navigator.pop(context);
          }),
          
          BaseDropupButton(
            icon: Icons.info_outline,
            label: "Learn more",
            hasTrailingArrow: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 16),
          
          // Logout
          BaseDropupButton(
            icon: Icons.logout,
            label: "Log out",
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

void showAccountDropup(BuildContext context, RelativeRect position, String email, VoidCallback onLogout) {
  showMenu(
    context: context,
    position: position,
    color: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: [
      CustomPopupMenuItem(
        child: AccountDropupMenu(email: email, onLogout: onLogout),
      ),
    ],
  );
}
