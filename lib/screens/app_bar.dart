// lib/screens/app_bar.dart
// QuantMessage — Custom navigation bar (tab shell sync)

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import 'news_screen.dart';

/// Canonical nav items — must stay aligned with [AppTab] / HomeScreen pages.
List<NavItem> get appNavItems => AppTab.values
    .map((tab) => NavItem(icon: tab.icon, label: tab.label, tab: tab))
    .toList();

class CustomAppBar extends ConsumerStatefulWidget {
  /// Called when the user picks a tab. HomeScreen handles auth + page switch.
  final ValueChanged<int> onItemSelected;

  /// Optional override; defaults to [navigationProvider] index.
  final int? selectedIndex;

  const CustomAppBar({
    super.key,
    required this.onItemSelected,
    this.selectedIndex,
  });

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends ConsumerState<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indicatorCtrl;

  @override
  void initState() {
    super.initState();
    _indicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..value = 1.0;
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    final current = widget.selectedIndex ?? ref.read(navigationIndexProvider);
    if (current == index) return;
    _indicatorCtrl.forward(from: 0);
    widget.onItemSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    final navItems = appNavItems;
    final watched = ref.watch(navigationIndexProvider);
    final int rawIndex = widget.selectedIndex ?? watched;
    final int safeIndex =
        rawIndex < 0
            ? 0
            : (rawIndex >= navItems.length ? navItems.length - 1 : rawIndex);

    // Total items in vertical nav: navItems + 1 News button
    // Each item occupies: 56px (button) + 12px (vertical padding × 2) = 68px
    const double itemExtent = 68.0;
    final int totalItems = navItems.length + 1; // +1 for News

    return Padding(
      padding: EdgeInsets.only(
        top: isDesktop ? 20 : 0,
        bottom: isDesktop ? 20 : 12,
        right: isDesktop ? 12 : 12,
        left: isDesktop ? 0 : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 22 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: isDesktop ? 68 : double.infinity,
            height: isDesktop ? double.infinity : 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(isDesktop ? 22 : 28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isDesktop
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      // Use actual nav bar height for precise pill placement
                      final navHeight = constraints.maxHeight;
                      final totalNavHeight = itemExtent * totalItems;
                      // Center offset of the items column within the nav bar
                      final columnStart = (navHeight - totalNavHeight) / 2;
                      // Pill top = start of column + (index * itemExtent) + centering within item
                      final pillTop = columnStart + (safeIndex * itemExtent) +
                          (itemExtent - 52) / 2;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Smooth sliding selection pill (desktop vertical)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            left: 8,
                            top: pillTop,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                          ),
                          _buildVerticalNav(navItems, safeIndex, _handleTap),
                        ],
                      );
                    },
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Smooth sliding selection pill (mobile horizontal)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: _horizontalPillLeft(
                            screenWidth, navItems.length, safeIndex),
                        top: 10,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                      _buildHorizontalNav(
                          context, navItems, safeIndex, _handleTap),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Calculates the horizontal pill left offset for mobile nav.
  double _horizontalPillLeft(double screenWidth, int count, int index) {
    // Nav bar width = screenWidth - left(12) - right(12) = screenWidth - 24
    // Each slot width = (screenWidth - 24) / count
    // Pill is centered within its slot: slot * index + (slot - 44) / 2
    final slotWidth = (screenWidth - 24) / count;
    return slotWidth * index + (slotWidth - 44) / 2;
  }

  Widget _buildHorizontalNav(
    BuildContext context,
    List<NavItem> items,
    int selectedIndex,
    ValueChanged<int> onTap,
  ) {
    return Row(
      children: [
        ...List.generate(items.length, (index) {
          return Expanded(
            child: _NavButton(
              item: items[index],
              isSelected: selectedIndex == index,
              onTap: () => onTap(index),
              isVertical: false,
            ),
          );
        }),
        // News route button — does NOT change the active tab index
        const _NewsIconButton(isVertical: false),
      ],
    );
  }

  Widget _buildVerticalNav(
    List<NavItem> items,
    int selectedIndex,
    ValueChanged<int> onTap,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(items.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _NavButton(
              item: items[index],
              isSelected: selectedIndex == index,
              onTap: () => onTap(index),
              isVertical: true,
            ),
          );
        }),
        // News route button — does NOT change the active tab index
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: _NewsIconButton(isVertical: true),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// News route button (standalone — does not touch navigation provider)
// ═══════════════════════════════════════════════════════════════════════════

class _NewsIconButton extends StatefulWidget {
  final bool isVertical;
  const _NewsIconButton({required this.isVertical});

  @override
  State<_NewsIconButton> createState() => _NewsIconButtonState();
}

class _NewsIconButtonState extends State<_NewsIconButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _openNews() {
    Navigator.of(context).push(smoothPageRoute(const NewsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // For horizontal nav: use Expanded to fill same space as other tabs.
    // For vertical nav: caller wraps in Padding, so just return the button.
    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.forward(),
        onTapUp: (_) async {
          await _scaleCtrl.reverse();
          _openNews();
        },
        onTapCancel: () => _scaleCtrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: widget.isVertical ? 56 : 64,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Tooltip(
                message: 'News',
                preferBelow: false,
                waitDuration: const Duration(milliseconds: 400),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 0.85 : 0.45,
                  child: const Icon(
                    Icons.newspaper_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.isVertical ? button : Expanded(child: button);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Nav button
// ═══════════════════════════════════════════════════════════════════════════

class _NavButton extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isVertical;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isVertical,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.forward(),
        onTapUp: (_) async {
          await _scaleCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleCtrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: widget.isVertical ? 56 : 64,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Tooltip(
                message: widget.item.label,
                preferBelow: false,
                waitDuration: const Duration(milliseconds: 400),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isSelected ? 1.0 : (_isHovered ? 0.85 : 0.45),
                  child: Icon(
                    widget.item.icon,
                    color: highlight ? Colors.white : Colors.white70,
                    size: widget.isSelected ? 24 : 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════════

class NavItem {
  final IconData icon;
  final String label;
  final AppTab tab;

  const NavItem({
    required this.icon,
    required this.label,
    required this.tab,
  });
}

/// Shared fade+slide transition for non-tab routes (SignIn, etc.).
PageRouteBuilder smoothPageRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
