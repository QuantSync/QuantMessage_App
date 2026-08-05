// lib/screens/account_settings_screen/account/account_settings.dart
//
// Account section matching QuantMessage settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';

class AccountSettings extends StatefulWidget {
  final String? userEmail;
  final VoidCallback? onDeleteAccount;

  const AccountSettings({
    super.key,
    this.userEmail,
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
        const SizedBox(height: 24),
        SettingsRow(
          label: 'Log out of all devices',
          trailing: SettingsClickButton(
            label: 'Log out',
            onTap: () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Delete your account',
          trailing: SettingsClickButton(
            label: 'Delete account',
            isPrimary: true,
            onTap: widget.onDeleteAccount ?? () {},
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          label: 'Organization ID',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '5692ecf5-9864-495a-9983-cff4ffdd815c',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Trusted devices'),
        const SizedBox(height: 6),
        Text(
          'Devices that can control your local machine through remote sessions.',
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildTableHeader(['Device', 'Added']),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'No trusted devices.',
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.4), fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 48),
        const SettingsSectionTitle(title: 'Active sessions'),
        const SizedBox(height: 16),
        _buildTableHeader(['Device', 'Location', 'Created', 'Updated']),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Text(
                      'Chrome ...',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3A68),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Current',
                        style: GoogleFonts.outfit(color: const Color(0xFF5B99DB), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text('Delhi, Delhi, IN', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ),
              Expanded(
                flex: 3,
                child: Text('Jul 16, 2026, 3:09 AM', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ),
              Expanded(
                flex: 3,
                child: Text('Aug 4, 2026, 12:36 PM', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ),
            ],
          ),
        ),
        const SettingsDivider(),
      ],
    );
  }

  Widget _buildTableHeader(List<String> columns) {
    return Column(
      children: [
        Row(
          children: columns.asMap().entries.map((entry) {
            final flex = entry.key == 0 ? 3 : (columns.length > 2 ? (entry.key == 1 ? 2 : 3) : 3);
            return Expanded(
              flex: flex,
              child: Text(
                entry.value,
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.white.withOpacity(0.1), height: 1),
      ],
    );
  }
}
