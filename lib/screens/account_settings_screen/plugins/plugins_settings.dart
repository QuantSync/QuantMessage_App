// lib/screens/account_settings_screen/plugins/plugins_settings.dart
//
// Plugins section under Customize.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';
import '../widgets/settings_toggle_button.dart';

class PluginsSettings extends StatefulWidget {
  const PluginsSettings({super.key});

  @override
  State<PluginsSettings> createState() => _PluginsSettingsState();
}

class _PluginsSettingsState extends State<PluginsSettings> {
  bool _enablePlugins = true;
  bool _allowThirdParty = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Plugins'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Enable Plugins',
          subtitle: 'Allow Quant to use external tools during conversation.',
          value: _enablePlugins,
          onChanged: (val) => setState(() => _enablePlugins = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Third-party plugins',
          subtitle: 'Allow unverified community plugins.',
          value: _allowThirdParty,
          onChanged: (val) => setState(() => _allowThirdParty = val),
        ),
        
        const SizedBox(height: 28),
        const SettingsSectionTitle(title: 'Installed Plugins'),
        const SizedBox(height: 16),
        _buildPluginItem(
          name: 'Web Browsing',
          description: 'Allows Quant to search the internet for current events.',
          icon: Icons.public,
          enabled: true,
        ),
        const SettingsDivider(),
        _buildPluginItem(
          name: 'Code Interpreter',
          description: 'Run Python code in a secure sandbox.',
          icon: Icons.code,
          enabled: true,
        ),
      ],
    );
  }

  Widget _buildPluginItem({
    required String name,
    required String description,
    required IconData icon,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SettingsClickButton(label: enabled ? 'Disable' : 'Enable', onTap: () {}),
        ],
      ),
    );
  }
}
