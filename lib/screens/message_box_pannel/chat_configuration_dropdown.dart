// lib/screens/message_box_pannel/chat_configuration_dropdown.dart
//
// QuantMessage — Output Choice / Chat Configuration Dropdown Menu
// Solid Grey background with solid shadow effect, fully responsive
// ------------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatConfigurationDropdown extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeSelected;
  final VoidCallback onClose;

  const ChatConfigurationDropdown({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
    required this.onClose,
  });

  static const List<Map<String, dynamic>> _modes = [
    {
      'title': 'Autopilot mode',
      'subtitle': 'Automatic mode routing & optimal balance',
      'icon': Icons.auto_mode_rounded,
      'accent': Color(0xFF6366F1),
    },
    {
      'title': 'Deep Search Mode',
      'subtitle': 'Exhaustive research & step-by-step analysis',
      'icon': Icons.manage_search_rounded,
      'accent': Color(0xFF3B82F6),
    },
    {
      'title': 'Quick Answers mode',
      'subtitle': 'Fast, concise responses for instant answers',
      'icon': Icons.bolt_rounded,
      'accent': Color(0xFF10B981),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Clickable Backdrop to Dismiss Dropdown ───────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),

          // ── Positioned / Centered Dropdown Card ──────────────────────────
          Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (screenSize.width * 0.90).clamp(280.0, 360.0),
                    maxHeight: screenSize.height * 0.80,
                  ),
                  child: _buildGreyDropdownCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreyDropdownCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Solid grey background as specified
        color: const Color(0xFF28282A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        // Heavy solid shadow effect as specified
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 36,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Heading: "< Output Choice >" ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF212123),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "< Output Choice >",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Mode Options List ───────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _modes.map((mode) {
                    final String title = mode['title'] as String;
                    final String subtitle = mode['subtitle'] as String;
                    final IconData icon = mode['icon'] as IconData;
                    final Color accent = mode['accent'] as Color;
                    final bool isSelected = (selectedMode.toLowerCase() == title.toLowerCase()) ||
                        (selectedMode.isEmpty && title == 'Autopilot mode');

                    return _ModeOptionTile(
                      title: title,
                      subtitle: subtitle,
                      icon: icon,
                      accentColor: accent,
                      isSelected: isSelected,
                      onTap: () {
                        onModeSelected(title);
                        onClose();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile Option Widget ────────────────────────────────────────────────────────

class _ModeOptionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModeOptionTile> createState() => _ModeOptionTileState();
}

class _ModeOptionTileState extends State<_ModeOptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.18)
                : (_isHovered ? Colors.white.withValues(alpha: 0.07) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.15) : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.accentColor.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected ? widget.accentColor : Colors.white70,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        color: widget.isSelected ? Colors.white : Colors.white70,
                        fontSize: 13.5,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Selection checkmark indicator
              if (widget.isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  color: widget.accentColor,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
