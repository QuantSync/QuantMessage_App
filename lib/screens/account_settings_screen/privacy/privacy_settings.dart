// lib/screens/account_settings_screen/privacy/privacy_settings.dart
//
// Privacy section matching QuantMessage settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';
import '../widgets/settings_toggle_button.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  bool _locationMetadata = true;
  bool _improveModels = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Privacy'),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
            children: [
              const TextSpan(text: 'QuantSync believes in transparent data practices. Learn how your information is protected when using QuantSync products, and visit our '),
              TextSpan(
                text: 'Privacy Center',
                style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withOpacity(0.8)),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withOpacity(0.8)),
              ),
              const TextSpan(text: ' for more details.'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildExpandableRow('How we protect your data'),
        const SettingsDivider(),
        _buildExpandableRow('How we use your data'),
        const SettingsDivider(),
        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Preferences'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Location metadata',
          subtitle: 'Allow QuantMessage to use coarse location metadata (city/region) to improve product experiences. Learn more.',
          value: _locationMetadata,
          onChanged: (val) => setState(() => _locationMetadata = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Help improve our AI models',
          subtitle: 'Allow the use of your chats and coding sessions to train and improve QuantSync AI models. Learn more.',
          value: _improveModels,
          onChanged: (val) => setState(() => _improveModels = val),
        ),
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Your data'),
        const SizedBox(height: 24),
        SettingsRow(
          label: 'Export data',
          trailing: SettingsClickButton(
            label: 'Export data',
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Shared chats',
          trailing: SettingsClickButton(
            label: 'Manage',
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Shared artifacts',
          trailing: SettingsClickButton(
            label: 'Manage',
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Uploaded files',
          trailing: SettingsClickButton(
            label: 'Manage',
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Memory preferences',
          trailing: SettingsClickButton(
            label: 'Manage',
            icon: Icons.open_in_new_rounded,
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
      ],
    );
  }

  Widget _buildExpandableRow(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }
}
