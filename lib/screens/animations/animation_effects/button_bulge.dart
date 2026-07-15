// lib/screens/animations/animation_effects/button_bulge.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

enum BulgeStyle { glass, solidWhite, card }

class ButtonBulge extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final BulgeStyle style;
  final double hoverScale;
  final double? borderRadius;

  const ButtonBulge({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.style = BulgeStyle.glass,
    this.hoverScale = 1.14,
    this.borderRadius,
  });

  @override
  State<ButtonBulge> createState() => _ButtonBulgeState();
}

class _ButtonBulgeState extends State<ButtonBulge> {
  bool _hovered = false;
  bool _clicked = false;

  void _onEnter(PointerEnterEvent _) => setState(() => _hovered = true);
  void _onExit(PointerExitEvent _) => setState(() => _hovered = false);

  void _onTap() {
    setState(() => _clicked = true);
    widget.onPressed?.call();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _clicked = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _hovered ? widget.hoverScale : 1.0;
    final isSolid = widget.style == BulgeStyle.solidWhite;
    final isCard = widget.style == BulgeStyle.card;
    final radius = widget.borderRadius ?? (isSolid ? 10.0 : (isCard ? 16.0 : 6.0));

    final Color backgroundColor = isSolid
        ? Colors.white
        : (isCard
            ? const Color(0xFF0A0A0A) // AppTheme.surfaceDark / high contrast black
            : ((_hovered || _clicked)
                ? Colors.white
                : const Color(0xFF2A2A2A).withValues(alpha: 0.65)));

    final Color textColor = isSolid
        ? Colors.black
        : (isCard
            ? Colors.white
            : ((_hovered || _clicked) ? Colors.black : Colors.white70));

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: isSolid
            ? null
            : Border.all(
                color: isCard
                    ? ((_hovered || _clicked)
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.12))
                    : ((_hovered || _clicked)
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.18)),
                width: isCard ? 1.5 : 1,
              ),
        boxShadow: (_hovered || _clicked)
            ? [
                BoxShadow(
                  color: isCard
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.25),
                  blurRadius: isCard ? 24 : 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.outfit(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        child: widget.child,
      ),
    );

    Widget result = isSolid
        ? content
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: content,
            ),
          );

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: widget.onPressed != null
          ? GestureDetector(
              onTap: _onTap,
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: result,
              ),
            )
          : AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: result,
            ),
    );
  }
}

