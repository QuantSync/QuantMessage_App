// lib/screens/account_settings_screen/quantcode/quantcode_settings.dart
//
// QuantCode (Advanced) section. Replaces "Claude Code".

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';
import '../widgets/settings_toggle_button.dart';

class QuantCodeSettings extends StatefulWidget {
  const QuantCodeSettings({super.key});

  @override
  State<QuantCodeSettings> createState() => _QuantCodeSettingsState();
}

class _QuantCodeSettingsState extends State<QuantCodeSettings> {
  bool _highContrast = false;
  bool _classifySessions = true;
  bool _switchModels = true;
  bool _createPullRequests = false;
  bool _autofixPullRequests = false;
  int _transcriptTextSize = 1; // 0=Small, 1=Medium, 2=Large
  int _transcriptWidth = 0; // 0=Narrow, 1=Medium, 2=Wide

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promo banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QuantCode',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quant understands your codebase and helps you build, debug, and ship faster. Upgrade your plan to get started.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SettingsClickButton(
                      label: 'Upgrade to Max or Pro ↗',
                      isPrimary: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Dummy illustration mimicking the code window from the screenshot
              Container(
                width: 140,
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _dot(Colors.red),
                        const SizedBox(width: 4),
                        _dot(Colors.orange),
                        const SizedBox(width: 4),
                        _dot(Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '> Fix the auth bug in signup flow',
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF4A9EFF),
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '* Noodling...',
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFE27457),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Appearance'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'High-contrast dark theme',
          subtitle: 'Use a darker, near-black background when dark mode is on.',
          value: _highContrast,
          onChanged: (val) => setState(() => _highContrast = val),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Transcript text size',
          trailing: SettingsSegmentToggle(
            options: const ['Small', 'Medium', 'Large'],
            selectedIndex: _transcriptTextSize,
            onChanged: (val) => setState(() => _transcriptTextSize = val),
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Transcript width',
          trailing: SettingsSegmentToggle(
            options: const ['Narrow', 'Medium', 'Wide'],
            selectedIndex: _transcriptWidth,
            onChanged: (val) => setState(() => _transcriptWidth = val),
          ),
        ),

        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'General'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Classify session states',
          subtitle: 'Allow Quant to automatically classify sessions as blocked, ready for review, or done.',
          value: _classifySessions,
          onChanged: (val) => setState(() => _classifySessions = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Switch models when a message is flagged',
          subtitle: 'Automatically switch to a different model to keep chatting when safety measures flag a message.',
          value: _switchModels,
          onChanged: (val) => setState(() => _switchModels = val),
        ),

        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Pull requests'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Branch prefix',
          trailing: Container(
            width: 140,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              'quant',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Create pull requests automatically',
          subtitle: 'When Quant pushes changes to a branch, it automatically opens a pull request without asking first.',
          value: _createPullRequests,
          onChanged: (val) => setState(() => _createPullRequests = val),
        ),
        const SettingsDivider(),
        SettingsToggleButton(
          label: 'Autofix pull requests',
          subtitle: 'When you create a pull request, Quant automatically monitors it for CI failures and review comments.',
          value: _autofixPullRequests,
          onChanged: (val) => setState(() => _autofixPullRequests = val),
        ),
        
        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'QuantCode (CLI, Desktop, IDE)'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Delete sessions stored by QuantSync',
          trailing: SettingsClickButton(
            label: 'Delete...',
            isDestructive: true,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
