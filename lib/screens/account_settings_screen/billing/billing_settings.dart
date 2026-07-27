// lib/screens/account_settings_screen/billing/billing_settings.dart
//
// Billing section — Subscription plan, usage, payment method.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';

class BillingSettings extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const BillingSettings({super.key, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Subscription'),
        const SizedBox(height: 16),

        // Current plan card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Plan',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade for unlimited access',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SettingsClickButton(
                label: 'Upgrade',
                isPrimary: true,
                onTap: onUpgrade ?? () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        const SettingsSectionTitle(title: 'Usage'),
        const SizedBox(height: 16),

        _UsageBar(label: 'Messages', used: 42, total: 100),
        const SizedBox(height: 12),
        _UsageBar(label: 'File uploads', used: 3, total: 10),
        const SizedBox(height: 12),
        _UsageBar(label: 'API calls', used: 0, total: 50),

        const SizedBox(height: 28),
        const SettingsSectionTitle(title: 'Payment Method'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card_rounded,
                  color: Colors.white.withOpacity(0.45), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No payment method added',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ),
              SettingsClickButton(label: 'Add', onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final int used;
  final int total;

  const _UsageBar({
    required this.label,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.65), fontSize: 13),
            ),
            Text(
              '$used / $total',
              style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: ratio > 0.8
                    ? Colors.redAccent
                    : const Color(0xFF4A9EFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
