// lib/screens/account_settings_screen/privacy/privacy_settings.dart
//
// Privacy section under Settings.

import 'package:flutter/material.dart';
import '../widgets/settings_click_button.dart';
import '../widgets/settings_toggle_button.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  bool _dataCollection = false;
  bool _incognitoMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Privacy & Data'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Data collection',
          subtitle: 'Allow QuantSync to use your data to improve models.',
          value: _dataCollection,
          onChanged: (val) => setState(() => _dataCollection = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Incognito mode by default',
          subtitle: 'Start new chats in incognito mode automatically.',
          value: _incognitoMode,
          onChanged: (val) => setState(() => _incognitoMode = val),
        ),
        const SizedBox(height: 28),
        const SettingsSectionTitle(title: 'Data Management'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Clear chat history',
          trailing: SettingsClickButton(
            label: 'Clear',
            isDestructive: true,
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Export data',
          trailing: SettingsClickButton(
            label: 'Export',
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
