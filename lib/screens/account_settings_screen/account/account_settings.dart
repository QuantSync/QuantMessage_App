// lib/screens/account_settings_screen/account/account_settings.dart
//
// Account section — Email, Password, 2FA, Danger zone.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';
import '../widgets/settings_toggle_button.dart';

class AccountSettings extends StatefulWidget {
  final String? userEmail;
  final VoidCallback? onChangePassword;
  final VoidCallback? onEnable2FA;
  final VoidCallback? onDeleteAccount;

  const AccountSettings({
    super.key,
    this.userEmail,
    this.onChangePassword,
    this.onEnable2FA,
    this.onDeleteAccount,
  });

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Account'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Email',
          trailing: Text(
            widget.userEmail ?? 'Not available',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Password',
          trailing: SettingsClickButton(
            label: 'Change',
            onTap: widget.onChangePassword ?? () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Two-factor authentication',
          trailing: SettingsClickButton(
            label: 'Enable',
            onTap: widget.onEnable2FA ?? () {},
          ),
        ),

        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Sessions'),
        const SizedBox(height: 16),
        Text(
          'Active sessions',
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Icon(Icons.computer_rounded,
                  color: Colors.white.withOpacity(0.5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current device',
                      style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.75), fontSize: 13),
                    ),
                    Text(
                      'Last active: Now',
                      style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.35), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2ECC71),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const SettingsSectionTitle(title: 'Danger Zone'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Delete account',
          trailing: SettingsClickButton(
            label: 'Delete',
            isDestructive: true,
            onTap: widget.onDeleteAccount ?? () {},
          ),
        ),
      ],
    );
  }
}
