// lib/screens/animations/animated_dropdown/profile_account_overlay.dart
//
// QuantMessage — Profile account menu overlay.
// Opens to the RIGHT of the profile icon (LayerLink-anchored),
// blurs the background via parent callback, and supports Settings + Language sub-menu.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../settings_screen.dart';
import '../../pricing_screen/pricing_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════════

class ProfileAccountOverlay {
  static OverlayEntry? _entry;

  /// Show the account menu anchored to [layerLink].
  ///
  /// [profileIconSize] – size of the profile icon widget (used for vertical centering).
  /// [email]          – user's email shown at the top of the card.
  /// [onSignOut]      – called when the user taps "Log out".
  /// [onOpened]       – called when the overlay is inserted (start blur).
  /// [onClosed]       – called when the overlay is removed (stop blur).
  static void show({
    required BuildContext context,
    required LayerLink layerLink,
    required Size profileIconSize,
    required String email,
    required VoidCallback onSignOut,
    VoidCallback? onOpened,
    VoidCallback? onClosed,
  }) {
    if (_entry != null) {
      _dismiss(onClosed);
      return;
    }

    _entry = OverlayEntry(
      builder: (_) => _ProfileAccountOverlayWidget(
        layerLink: layerLink,
        profileIconSize: profileIconSize,
        email: email,
        onSignOut: onSignOut,
        onClose: () => _dismiss(onClosed),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    onOpened?.call();
  }

  static void dismiss({VoidCallback? onClosed}) => _dismiss(onClosed);

  static void _dismiss(VoidCallback? onClosed) {
    _entry?.remove();
    _entry = null;
    onClosed?.call();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Internal overlay widget
// ═══════════════════════════════════════════════════════════════════

class _ProfileAccountOverlayWidget extends StatefulWidget {
  final LayerLink layerLink;
  final Size profileIconSize;
  final String email;
  final VoidCallback onSignOut;
  final VoidCallback onClose;

  const _ProfileAccountOverlayWidget({
    required this.layerLink,
    required this.profileIconSize,
    required this.email,
    required this.onSignOut,
    required this.onClose,
  });

  @override
  State<_ProfileAccountOverlayWidget> createState() =>
      _ProfileAccountOverlayWidgetState();
}

class _ProfileAccountOverlayWidgetState
    extends State<_ProfileAccountOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  // Controls whether the language sub-panel is showing inside this overlay
  bool _showingLanguage = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _closeAnimated() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  void _openSettings() {
    _closeAnimated().then((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => const SettingsScreen(),
          transitionsBuilder: (c, a1, a2, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });
  }

  void _openLanguage() {
    setState(() => _showingLanguage = true);
  }

  void _closeLanguage() {
    if (mounted) setState(() => _showingLanguage = false);
  }

  void _openUpgradePlan() {
    _closeAnimated().then((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => const PricingScreen(),
          transitionsBuilder: (c, a1, a2, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Card appears to the right of the sidebar (offset from the profile icon anchor)
    // Horizontal offset: full width of sidebar (52px) + 8px gap
    const double sidebarWidth = 52.0;
    const double cardWidth = 300.0;
    const double gap = 8.0;

    return Stack(
      children: [
        // ── Tap-outside to close ──────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeAnimated,
            child: const SizedBox.expand(),
          ),
        ),

        // ── Backdrop blur ─────────────────────────────────────────────
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),

        // ── Account card ──────────────────────────────────────────────
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          // Position to the right of the sidebar, vertically aligned near bottom
          offset: Offset(
            sidebarWidth + gap,
            // Align bottom of card with bottom of profile icon + some offset
            -(380 - widget.profileIconSize.height),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.bottomLeft,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardWidth,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: _showingLanguage
                        ? _LanguageCardInline(
                            onClose: _closeLanguage,
                            onDismissAll: _closeAnimated,
                          )
                        : _AccountMenuCard(
                            email: widget.email,
                            onSettings: _openSettings,
                            onLanguage: _openLanguage,
                            onUpgradePlan: _openUpgradePlan,
                            onLogout: () {
                              _closeAnimated().then((_) {
                                widget.onSignOut();
                              });
                            },
                            onClose: _closeAnimated,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Account menu card content
// ═══════════════════════════════════════════════════════════════════

class _AccountMenuCard extends StatelessWidget {
  final String email;
  final VoidCallback onSettings;
  final VoidCallback onLanguage;
  final VoidCallback onUpgradePlan;
  final VoidCallback onLogout;
  final VoidCallback onClose;

  const _AccountMenuCard({
    required this.email,
    required this.onSettings,
    required this.onLanguage,
    required this.onUpgradePlan,
    required this.onLogout,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(4, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Email header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Text(
                email,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            _Divider(),

            // ── Group 1 ───────────────────────────────────────────
            _MenuRow(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: onSettings,
            ),
            _MenuRow(
              icon: Icons.language_outlined,
              label: 'Language',
              trailing: const Icon(Icons.chevron_right,
                  color: Colors.white38, size: 18),
              onTap: onLanguage,
            ),
            _MenuRow(
              icon: Icons.help_outline_rounded,
              label: 'Get help',
              onTap: onClose, // no-op for now, closes menu
            ),

            _Divider(),

            // ── Group 2 ───────────────────────────────────────────
            _MenuRow(
              icon: Icons.arrow_upward_rounded,
              label: 'Upgrade plan',
              onTap: onUpgradePlan,
            ),
            _MenuRow(
              icon: Icons.extension_outlined,
              label: 'Get apps and extensions',
              onTap: onClose,
            ),
            _MenuRow(
              icon: Icons.info_outline_rounded,
              label: 'Learn more',
              trailing: const Icon(Icons.chevron_right,
                  color: Colors.white38, size: 18),
              onTap: onClose,
            ),

            _Divider(),

            // ── Logout ───────────────────────────────────────────
            _MenuRow(
              icon: Icons.logout_rounded,
              label: 'Log out',
              onTap: onLogout,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Language card shown inline (replaces the account card in the same slot)
// ═══════════════════════════════════════════════════════════════════

class _LanguageCardInline extends StatefulWidget {
  final VoidCallback onClose;        // go back to account card
  final Future<void> Function() onDismissAll; // close everything

  const _LanguageCardInline({
    required this.onClose,
    required this.onDismissAll,
  });

  @override
  State<_LanguageCardInline> createState() => _LanguageCardInlineState();
}

class _LanguageCardInlineState extends State<_LanguageCardInline> {
  String _selected = 'English (United States)';

  static const List<String> _languages = [
    'English (United States)',
    'Français (France)',
    'Deutsch (Deutschland)',
    'हिन्दी (भारत)',
    'Indonesia (Indonesia)',
    'Italiano (Italia)',
    '日本語 (日本)',
    '한국어 (대한민국)',
    'Português (Brasil)',
    'Español (Latinoamérica)',
    'Español (España)',
  ];

  void _pick(String lang) {
    setState(() => _selected = lang);
    // Dismiss and show "coming soon" for non-English choices
    if (lang != 'English (United States)') {
      widget.onDismissAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(4, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: Colors.white54),
                    onPressed: widget.onClose,
                    tooltip: 'Back',
                    splashRadius: 18,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Language',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _Divider(),
            // Language list — constrained height with scroll
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _languages.length,
                itemBuilder: (_, i) {
                  final lang = _languages[i];
                  final isSelected = lang == _selected;
                  return _LanguageRow(
                    label: lang,
                    isSelected: isSelected,
                    onTap: () => _pick(lang),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Small reusable row widgets
// ═══════════════════════════════════════════════════════════════════

class _MenuRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          color: _hovered
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white70, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguageRow> createState() => _LanguageRowState();
}

class _LanguageRowState extends State<_LanguageRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _hovered
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_rounded,
                    color: Colors.blueAccent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.10),
      );
}
