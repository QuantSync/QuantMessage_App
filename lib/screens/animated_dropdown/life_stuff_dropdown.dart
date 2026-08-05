// lib/screens/animated_dropdown/life_stuff_dropdown.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const List<String> _lifeStuffPrompts = [
  'Create morning routines',
  'Explore productivity systems',
  'Manage my time better',
  'Improve my habits',
  'Create a personal budget',
];

class LifeStuffDropdown extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onQuerySelected;
  final bool isMobile;

  const LifeStuffDropdown({
    super.key,
    required this.onClose,
    required this.onQuerySelected,
    this.isMobile = false,
  });

  @override
  State<LifeStuffDropdown> createState() => _LifeStuffDropdownState();
}

class _LifeStuffDropdownState extends State<LifeStuffDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = widget.isMobile
        ? MediaQuery.of(context).size.width - 32
        : 420.0;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24).withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.isMobile ? 14 : 16,
                      widget.isMobile ? 10 : 12,
                      widget.isMobile ? 8 : 10,
                      widget.isMobile ? 6 : 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.coffee_outlined,
                          size: widget.isMobile ? 13 : 14,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Life stuff',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: widget.isMobile ? 11 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: widget.isMobile ? 14 : 15,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                  ..._lifeStuffPrompts.asMap().entries.map((e) {
                    final isLast = e.key == _lifeStuffPrompts.length - 1;
                    return _PromptTile(
                      label: e.value,
                      isMobile: widget.isMobile,
                      isLast: isLast,
                      onTap: () => widget.onQuerySelected(e.value),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isMobile;
  final bool isLast;

  const _PromptTile({
    required this.label,
    required this.onTap,
    this.isMobile = false,
    this.isLast = false,
  });

  @override
  State<_PromptTile> createState() => _PromptTileState();
}

class _PromptTileState extends State<_PromptTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: widget.isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  )
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 14 : 16,
            vertical: widget.isMobile ? 9 : 11,
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
              color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.82),
              fontSize: widget.isMobile ? 12 : 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
