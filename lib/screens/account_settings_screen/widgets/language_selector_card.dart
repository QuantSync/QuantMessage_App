import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageSelectorCard extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  const LanguageSelectorCard({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<LanguageSelectorCard> createState() => _LanguageSelectorCardState();
}

class _LanguageSelectorCardState extends State<LanguageSelectorCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;

  final List<String> _languages = [
    'English',
    'English (India)',
    'English (United Kingdom)',
    'Chinese (Simplified)',
    'Cantonese',
    'French',
    'French (Canada)',
    'German',
    'Portuguese',
    'Russian',
    'Spanish',
    'Turkish',
    'Ukrainian',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _toggleExpand,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.currentLanguage,
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.top(8),
            width: 220,
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = lang == widget.currentLanguage;
                return InkWell(
                  onTap: () {
                    widget.onLanguageChanged(lang);
                    _toggleExpand();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isSelected 
                        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
                        : Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang,
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
