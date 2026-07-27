// lib/screens/account_settings_screen/connectors/connectors_settings.dart
//
// Connectors section under Customize.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';

class ConnectorsSettings extends StatelessWidget {
  const ConnectorsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Integrations'),
        const SizedBox(height: 16),
        _buildConnectedAccount(
          icon: Icons.storage_rounded,
          name: 'Google Drive',
          connected: true,
          color: const Color(0xFF4285F4),
        ),
        const SettingsDivider(),
        _buildConnectedAccount(
          icon: Icons.cloud_outlined,
          name: 'Dropbox',
          connected: false,
          color: const Color(0xFF0061FF),
        ),
      ],
    );
  }

  Widget _buildConnectedAccount({
    required IconData icon,
    required String name,
    required bool connected,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13.5,
              ),
            ),
          ),
          SettingsClickButton(
            label: connected ? 'Connected' : 'Connect',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
