// lib/screens/account_settings_screen/time_and_focus/time_and_focus_settings.dart
//
// Time and focus section matching Claude settings reference.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/settings_click_button.dart';

class TimeAndFocusSettings extends StatefulWidget {
  const TimeAndFocusSettings({super.key});

  @override
  State<TimeAndFocusSettings> createState() => _TimeAndFocusSettingsState();
}

class _TimeAndFocusSettingsState extends State<TimeAndFocusSettings> {
  final List<String> _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final Set<int> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle(title: 'Time and focus'),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Break reminders',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get a nudge to take a break from Claude. You can snooze or adjust anytime.',
                    style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Row(
              children: [
                _buildDropdown(),
                const SizedBox(width: 12),
                _buildDropdown(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        const SettingsDivider(),
        const SizedBox(height: 32),
        Text(
          'Quiet hours',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Set time limits for Claude. You can dismiss or adjust anytime.',
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(_days.length, (index) {
            final isSelected = _selectedDays.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(index);
                  } else {
                    _selectedDays.add(index);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    _days[index],
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '-',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }
}
