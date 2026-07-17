// lib/screens/animations/animation_effects/coming_soon_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComingSoonCard extends StatefulWidget {
  final String modeName;
  final VoidCallback onClose;

  const ComingSoonCard({
    super.key,
    required this.modeName,
    required this.onClose,
  });

  @override
  State<ComingSoonCard> createState() => _ComingSoonCardState();
}

class _ComingSoonCardState extends State<ComingSoonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred background
          GestureDetector(
            onTap: _close,
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10 * _opacityAnimation.value,
                    sigmaY: 10 * _opacityAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.5 * _opacityAnimation.value),
                  ),
                );
              },
            ),
          ),
          
          // Card
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E).withValues(alpha: 0.7), // Dark glassmorphism base
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              Icon(
                                widget.modeName.toLowerCase() == 'fly'
                                    ? Icons.flight_takeoff_rounded
                                    : Icons.rocket_launch_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${widget.modeName.toUpperCase()} MODE\nCOMING SOON',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'We are working hard to bring you the next generation of QuantMessage capabilities.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                          
                          // Close Button
                          Positioned(
                            top: -10,
                            right: -10,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _close,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
