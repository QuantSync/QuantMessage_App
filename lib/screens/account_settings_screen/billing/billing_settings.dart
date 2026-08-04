// lib/screens/account_settings_screen/billing/billing_settings.dart
//
// Billing section matching Claude settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../screens/pricing_screen/pricing_screen.dart';
import '../../app_bar.dart' show smoothPageRoute;

class BillingSettings extends StatelessWidget {
  const BillingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.hub_outlined, color: Colors.white.withOpacity(0.9), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free plan',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try Claude',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    smoothPageRoute(const PricingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Upgrade plan',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem('Chat on web, iOS, Android, and on your desktop'),
        _buildFeatureItem('Generate code and visualize data'),
        _buildFeatureItem('Write, edit, and create content'),
        _buildFeatureItem('Ability to search the web'),
        _buildFeatureItem('Memory across conversations'),
        _buildFeatureItem('Create files and execute code'),
        _buildFeatureItem('Unlock more from Claude with desktop extensions'),
        _buildFeatureItem('Connect Slack and Google Workspace services'),
        _buildFeatureItem('Integrate any context or tool through connectors with remote MCP'),
        _buildFeatureItem('Extended thinking for complex work'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.white.withOpacity(0.5), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
