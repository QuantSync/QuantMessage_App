// lib/screens/animations/animation_effects/extended_info.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class ExtendedInfoButton extends StatefulWidget {
  final Widget child;/// Text displayed inside the info card.
  final String label;

  final double cardWidth;

  final double cardHeight;

  final Duration animationDuration;

  const ExtendedInfoButton({
    Key? key,
    required this.child,
    required this.label,
    this.cardWidth = 200,
    this.cardHeight = 80,
    this.animationDuration = const Duration(milliseconds: 250),
  }) : super(key: key);

  @override
  State<ExtendedInfoButton> createState() => _ExtendedInfoButtonState();
}

class _ExtendedInfoButtonState extends State<ExtendedInfoButton> {
  OverlayEntry? _overlayEntry;

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final screenSize = MediaQuery.of(context).size;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full‑screen blur backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0)),
            ),
          ),
          // 3‑D card on the right side
          Positioned(
            top: (screenSize.height - widget.cardHeight) / 2,
            right: 20,
            child: _buildGlassCard(),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildGlassCard() {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) => _removeOverlay(),
      child: AnimatedOpacity(
        opacity: _overlayEntry != null ? 1.0 : 0.0,
        duration: widget.animationDuration,
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(-0.15), // subtle 3‑D tilt
          child: Container(
            width: widget.cardWidth,
            height: widget.cardHeight,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showOverlay(),
      onExit: (_) => _removeOverlay(),
      child: GestureDetector(
        onTapDown: (_) => _showOverlay(),
        onTapUp: (_) => _removeOverlay(),
        onTapCancel: () => _removeOverlay(),
        child: widget.child,
      ),
    );
  }
}