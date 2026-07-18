import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../in_app_buttons/language_item_button.dart';
import '../animation_effects/language_support.dart';

class LanguageDropupMenu extends StatefulWidget {
  const LanguageDropupMenu({super.key});

  @override
  State<LanguageDropupMenu> createState() => _LanguageDropupMenuState();
}

class _LanguageDropupMenuState extends State<LanguageDropupMenu> {
  String _selectedLanguage = "English (United States)";

  final List<String> _languages = [
    "English (United States)",
    "Français (France)",
    "Deutsch (Deutschland)",
    "हिन्दी (भारत)",
    "Indonesia (Indonesia)",
    "Italiano (Italia)",
    "日本語 (日本)",
    "한국어 (대한민국)",
    "Português (Brasil)",
    "Español (Latinoamérica)",
    "Español (España)"
  ];

  void _onLanguageSelected(String lang) {
    setState(() {
      _selectedLanguage = lang;
    });
    // Trigger coming soon card for any language
    Navigator.of(context).pop();
    LanguageSupportCard.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          return LanguageItemButton(
            languageName: lang,
            isSelected: lang == _selectedLanguage,
            onTap: () => _onLanguageSelected(lang),
          );
        },
      ),
    );
  }
}

void showLanguageDropup(BuildContext context, RelativeRect position) {
  showMenu(
    context: context,
    position: position,
    color: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: [
      CustomPopupMenuItem(
        child: const LanguageDropupMenu(),
      ),
    ],
  );
}

class CustomPopupMenuItem extends PopupMenuEntry<Never> {
  final Widget child;
  const CustomPopupMenuItem({super.key, required this.child});

  @override
  double get height => 0;

  @override
  bool represents(Never? value) => false;

  @override
  State<CustomPopupMenuItem> createState() => _CustomPopupMenuItemState();
}

class _CustomPopupMenuItemState extends State<CustomPopupMenuItem> {
  @override
  Widget build(BuildContext context) => widget.child;
}
