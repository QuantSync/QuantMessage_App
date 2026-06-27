// lib/screens/animations/animation_effects/button_bulge.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class ButtonBulge extends StatefulWidget {
  final Widget child;

  final VoidCallback? onPressed;

  final double? width;

  final double? height;

  const ButtonBulge({
    Key? key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
  }) : super(key: key);

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
    if (widget.onPressed != null) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _hovered ? 1.07 : 1.0;

    final Color backgroundColor = _clicked
        ? Colors.white
        : Colors.white.withOpacity(0.2);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(

                width: widget.width,

                height: widget.height,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: backgroundColor,

                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}