// lib/screens/account_settings_screen/skills/skills_settings.dart
//
// Skills section under Customize.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';

class SkillsSettings extends StatelessWidget {
  const SkillsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Skills'),
        const SizedBox(height: 16),
        Text(
          'Manage custom skills and specialized tasks that Quant can perform.',
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.psychology_alt_outlined, color: Colors.white.withOpacity(0.4), size: 48),
                const SizedBox(height: 16),
                Text(
                  'No skills configured',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create custom skills to give Quant specialized abilities for your workflow.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                SettingsClickButton(
                  label: 'Create Skill',
                  isPrimary: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
