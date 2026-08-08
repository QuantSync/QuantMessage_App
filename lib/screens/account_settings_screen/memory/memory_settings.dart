// lib/screens/account_settings_screen/memory/memory_settings.dart
//
// Memory section under Customize.

import 'package:flutter/material.dart';
import '../widgets/settings_click_button.dart';
import '../widgets/settings_toggle_button.dart';

class MemorySettings extends StatefulWidget {
  const MemorySettings({super.key});

  @override
  State<MemorySettings> createState() => _MemorySettingsState();
}

class _MemorySettingsState extends State<MemorySettings> {
  bool _memoryEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Memory'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Enable Memory',
          subtitle: 'Quant will learn from your conversations to provide more personalized responses over time.',
          value: _memoryEnabled,
          onChanged: (val) => setState(() => _memoryEnabled = val),
        ),
        
        const SizedBox(height: 28),
        const SettingsSectionTitle(title: 'Manage Memory'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'View memories',
          trailing: SettingsClickButton(
            label: 'View',
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Clear all memories',
          trailing: SettingsClickButton(
            label: 'Clear',
            isDestructive: true,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
