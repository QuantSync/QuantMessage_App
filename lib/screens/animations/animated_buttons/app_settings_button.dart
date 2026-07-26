import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSettingsButton extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;
  final double height;
  final double width;
  final double borderRadius;

  const AppSettingsButton({
    super.key,
    this.onPressed,
    this.height = 48,
    this.width = 220,
    this.borderRadius = 15,
  });

  @override
  ConsumerState<AppSettingsButton> createState() => _AppSettingsButtonState();
}

class _AppSettingsButtonState extends ConsumerState<AppSettingsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) async {
          await _ctrl.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final isPressed = _ctrl.status == AnimationStatus.forward ||
                _ctrl.value > 0.5;
            return Transform.scale(
              scale: _scale.value,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        border: Border.all(
                          color: isPressed
                              ? Colors.purpleAccent.withOpacity(0.6)
                              : (_isHovered
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.white.withOpacity(0.20)),
                          width: isPressed ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          if (_isHovered || isPressed)
                            BoxShadow(
                              color: isPressed
                                  ? Colors.purpleAccent.withOpacity(0.35)
                                  : Colors.white.withOpacity(0.12),
                              blurRadius: isPressed ? 16 : 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedRotation(
                              turns: _isHovered ? 0.25 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: widget.height < 46 ? 18 : 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "App Settings",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: widget.height < 46 ? 15 : 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
