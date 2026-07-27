// lib/screens/account_settings_screen/general/profile/profile_settings.dart
//
// Profile section — Avatar, Full name, Display name, Instructions for Quant.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/settings_click_button.dart';
import '../../widgets/settings_toggle_button.dart';

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
  String _workDescription = 'Other';

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = widget.themeColors.isNotEmpty
        ? widget.themeColors[widget.selectedColorIndex]
        : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Profile'),
        const SizedBox(height: 16),

        // Avatar
        SettingsRow(
          label: 'Avatar',
          trailing: GestureDetector(
            onTap: widget.onAvatarTap,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [avatarColor, avatarColor.withOpacity(0.5)],
                ),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipOval(
                child: widget.userProfile?['avatar_url'] != null
                    ? Image.network(widget.userProfile!['avatar_url'],
                        fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          widget.userProfile?['full_name']?[0] ?? 'U',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SettingsDivider(),

        // Full name
        SettingsRow(
          label: 'Full name',
          trailing: Container(
            width: 180,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: widget.nameController,
              style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.75), fontSize: 13),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, size: 14, color: Colors.white54),
                  onPressed: () =>
                      widget.onNameSaved?.call(widget.nameController.text),
                ),
              ),
            ),
          ),
        ),
        const SettingsDivider(),

        // What should Quant call you?
        SettingsRow(
          label: 'What should Quant call you?',
          trailing: Container(
            width: 180,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                widget.userProfile?['full_name'] ?? 'Not set',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        const SettingsDivider(),

        // What best describes your work?
        SettingsRow(
          label: 'What best describes your work?',
          trailing: GestureDetector(
            onTap: () {
              // Could show a bottom sheet / dropdown
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _workDescription,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.4), size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Instructions for Quant
        Text(
          'Instructions for Quant',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quant will keep these in mind across chats and Cowork within QuantSync\'s guidelines. Learn more',
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.38),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _instructionsCtrl,
            maxLines: null,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText:
                  'e.g. when learning new concepts, I find analogies particularly helpful',
              hintStyle: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.22),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
