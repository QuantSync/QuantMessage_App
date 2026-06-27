// lib/screens/animations/animated_dropdown/dropdown_animation.dart

import 'package:flutter/material.dart';


class AnimatedDropdown extends StatefulWidget {
  final Widget child;

  final List<DropdownMenuItemData> items;

  final double dropdownWidth;

  final Color backgroundColor;

  const AnimatedDropdown({
    Key? key,
    required this.child,
    required this.items,
    this.dropdownWidth = 300,
    this.backgroundColor = const Color(0xFF2D2D2D), // Dark theme matching the image
  }) : super(key: key);

  @override
  State<AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<AnimatedDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8), // 8 pixels below the button
              child: Material(
                color: Colors.transparent,
                child: SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1.0, // Expand downwards from the top
                  child: Container(
                    width: widget.dropdownWidth,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items.map((item) {
                          if (item.isDivider) {
                            return Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                              indent: 16,
                              endIndent: 16,
                            );
                          }
                          return _DropdownItemWidget(
                            item: item,
                            onItemTapped: () {
                              if (item.onTap != null) item.onTap!();
                              if (item.closeOnTap) _closeDropdown();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
    _animationController.forward();
  }

  void _closeDropdown() async {
    await _animationController.reverse();
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: widget.child,
      ),
    );
  }
}

class DropdownMenuItemData {
  final String title;
  final String? subtitle;

  final Widget? trailing;

  final Widget? titleTrailing;

  final VoidCallback? onTap;

  final bool closeOnTap;

  final bool isDivider;

  final bool isDisabled;

  DropdownMenuItemData({
    this.title = '',
    this.subtitle,
    this.trailing,
    this.titleTrailing,
    this.onTap,
    this.closeOnTap = true,
    this.isDivider = false,
    this.isDisabled = false,
  });

  factory DropdownMenuItemData.divider() {
    return DropdownMenuItemData(isDivider: true);
  }
}

class _DropdownItemWidget extends StatefulWidget {
  final DropdownMenuItemData item;
  final VoidCallback onItemTapped;

  const _DropdownItemWidget({
    Key? key,
    required this.item,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  State<_DropdownItemWidget> createState() => _DropdownItemWidgetState();
}

class _DropdownItemWidgetState extends State<_DropdownItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!widget.item.isDisabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!widget.item.isDisabled) setState(() => _isHovered = false);
      },
      cursor: widget.item.isDisabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.item.isDisabled ? null : widget.onItemTapped,
        child: Container(
          color: _isHovered
              ? Colors.white.withOpacity(0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            color: widget.item.isDisabled
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.item.titleTrailing != null) ...[
                          const SizedBox(width: 8),
                          widget.item.titleTrailing!,
                        ],
                      ],
                    ),
                    if (widget.item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.item.subtitle!,
                        style: TextStyle(
                          color: widget.item.isDisabled
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.item.trailing != null) ...[
                const SizedBox(width: 12),
                widget.item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}