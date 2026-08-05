// lib/screens/account_settings_screen/general/profile/profile_settings.dart
//
// Profile section matching QuantMessage settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/settings_click_button.dart';
import '../../widgets/settings_toggle_button.dart';
import '../../../animations/animated_buttons/theme_switcher_button.dart';
import '../../../animations/animated_buttons/motion_selector_button.dart';
import '../widgets/language_selector_card.dart';

class ProfileSettings extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final TextEditingController nameController;
  final VoidCallback? onAvatarTap;
  final ValueChanged<String>? onNameSaved;
  final List<Color> themeColors;
  final int selectedColorIndex;

  const ProfileSettings({
    super.key,
    this.userProfile,
    required this.nameController,
    this.onAvatarTap,
    this.onNameSaved,
    this.themeColors = const [],
    this.selectedColorIndex = 0,
  });

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final TextEditingController _instructionsCtrl = TextEditingController();
  final TextEditingController _whatToCallCtrl = TextEditingController();
  String _workDescription = 'Other';
  bool _responseCompletions = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Profile'),
        const SizedBox(height: 24),
        SettingsRow(
          label: 'Avatar',
          trailing: GestureDetector(
            onTap: widget.onAvatarTap,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6B8065), // Olive green from screenshot
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.spa, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Full name',
          trailing: Container(
            width: 200,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: TextField(
              controller: widget.nameController,
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: widget.onNameSaved,
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'What should QuantMessage call you?',
          trailing: Container(
            width: 200,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: TextField(
              controller: widget.nameController,
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: widget.onNameSaved,
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'What best describes your work?',
          trailing: GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _workDescription,
                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Instructions for QuantMessage',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 12.5, height: 1.4),
            children: [
              const TextSpan(text: 'QuantMessage will keep these in mind across chats and Cowork within '),
              TextSpan(
                text: 'QuantSync\'s guidelines',
                style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withOpacity(0.7)),
              ),
              const TextSpan(text: '. '),
              TextSpan(
                text: 'Learn more',
                style: TextStyle(decoration: TextDecoration.underline, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _instructionsCtrl,
            maxLines: null,
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'e.g. keep explanations brief and to the point',
              hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.3), fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Preferences'),
        const SizedBox(height: 24),
        SettingsRow(
          label: 'Appearance',
          trailing: const ThemeSwitcherButton(),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Chat font',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QuantSync Sans',
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 16),
            ],
          ),
        ),
        const SettingsDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motion',
                    style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reduce animation in streaming responses and other interface elements.',
                    style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
              const MotionSelectorButton(),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Voice'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Language',
          trailing: LanguageSelectorCard(
            currentLanguage: 'English',
            onLanguageChanged: (lang) {
              // Implementation for changing language
            },
          ),
        ),
        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Notifications'),
        const SizedBox(height: 16),
        SettingsToggleButton(
          label: 'Response completions',
          subtitle: 'Get notified when QuantMessage has finished a response. Useful for long-running tasks.',
          value: _responseCompletions,
          onChanged: (val) => setState(() => _responseCompletions = val),
        ),
      ],
    );
  }

  Widget _buildAppearanceIcon(IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),//
      ),
    );
  }
}
