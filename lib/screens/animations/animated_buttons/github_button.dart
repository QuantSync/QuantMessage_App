import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ============================================================
/// GithubButton
/// ============================================================
/// A reusable, modern glassmorphism "GitHub" button with a
/// pulsing glow animation behind the mark + label, available in
/// two variants:
///
///   GithubButtonVariant.light  -> white glass, black text/logo,
///                                 soft green glow (matches the
///                                 classic light GitHub look)
///   GithubButtonVariant.dark   -> deep black glass, white
///                                 text/logo, cool glow accent
///
/// Includes:
///   - a stylized Octocat mark, drawn in code (no image asset)
///   - a soft pulsing glow behind the icon + text
///   - a letter-by-letter text reveal animation on first appear
///   - a looping shimmer sweep across the glass surface
///   - a gentle press/scale animation on tap
///
/// HOW TO USE ON ANOTHER SCREEN:
/// -----------------------------------------------------------
/// 1. Copy this file into your project (e.g. lib/widgets/).
/// 2. Import it wherever you need a GitHub button:
///
///      import 'github_button.dart';
///
/// 3. Drop it into your widget tree:
///
///      GithubButton.light(onPressed: () {})
///      GithubButton.dark(onPressed: () {})
///
/// 4. Customize if needed:
///
///      GithubButton(
///        variant: GithubButtonVariant.dark,
///        label: 'Continue with GitHub',
///        width: 280,
///        height: 56,
///        glowColor: const Color(0xFF7C3AED),
///        onPressed: () {},
///      )
/// ============================================================

enum GithubButtonVariant { light, dark }

class GithubButton extends StatefulWidget {
  final GithubButtonVariant variant;
  final String label;
  final double? width;
  final double height;
  final double borderRadius;

  /// Overrides the default glow color for the chosen variant.
  final Color? glowColor;

  final VoidCallback? onPressed;

  const GithubButton({
    Key? key,
    this.variant = GithubButtonVariant.light,
    this.label = 'GitHub',
    this.width,
    this.height = 56,
    this.borderRadius = 18,
    this.glowColor,
    this.onPressed,
  }) : super(key: key);

  /// White glass, black text/logo, soft green glow.
  const GithubButton.light({
    Key? key,
    String label = 'GitHub',
    double? width,
    double height = 56,
    double borderRadius = 18,
    Color? glowColor,
    VoidCallback? onPressed,
  }) : this(
    key: key,
    variant: GithubButtonVariant.light,
    label: label,
    width: width,
    height: height,
    borderRadius: borderRadius,
    glowColor: glowColor,
    onPressed: onPressed,
  );

  /// Deep black glass, white text/logo, cool glow accent.
  const GithubButton.dark({
    Key? key,
    String label = 'GitHub',
    double? width,
    double height = 56,
    double borderRadius = 18,
    Color? glowColor,
    VoidCallback? onPressed,
  }) : this(
    key: key,
    variant: GithubButtonVariant.dark,
    label: label,
    width: width,
    height: height,
    borderRadius: borderRadius,
    glowColor: glowColor,
    onPressed: onPressed,
  );

  @override
  State<GithubButton> createState() => _GithubButtonState();
}

class _GithubButtonState extends State<GithubButton>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _glowController;
  late final AnimationController _shimmerController;
  late final Animation<double> _iconScale;

  bool _pressed = false;

  bool get _isLight => widget.variant == GithubButtonVariant.light;

  Color get _fgColor => _isLight ? const Color(0xFF0D1117) : Colors.white;

  Color get _glowColor =>
      widget.glowColor ?? (_isLight ? const Color(0xFF3FB950) : const Color(0xFF7C3AED));

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _iconScale = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glassBase = _isLight ? Colors.white : Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                final pulse = 0.5 + 0.5 * math.sin(_glowController.value * 2 * math.pi);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.width,
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        glassBase.withOpacity(_isLight ? (_pressed ? 0.92 : 0.86) : (_pressed ? 0.92 : 0.86)),
                        glassBase.withOpacity(_isLight ? 0.60 : 0.70),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: _isLight
                          ? Colors.black.withOpacity(0.08)
                          : Colors.white.withOpacity(0.12),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor.withOpacity(0.28 + 0.22 * pulse),
                        blurRadius: 26 + 14 * pulse,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(_isLight ? 0.10 : 0.5),
                        blurRadius: _pressed ? 8 : 18,
                        offset: Offset(0, _pressed ? 3 : 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Looping shimmer sweep across the glass surface.
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) => CustomPaint(
                              painter: _ShimmerPainter(
                                _shimmerController.value,
                                tint: _isLight ? Colors.white : Colors.white,
                                strength: _isLight ? 0.30 : 0.10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _glowingIcon(pulse),
                          const SizedBox(width: 14),
                          _glowingText(pulse),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowingIcon(double pulse) {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, _) {
        return Transform.scale(
          scale: 0.4 + (0.6 * _iconScale.value),
          child: SizedBox(
            width: 26,
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft blurred glow copy of the mark.
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 4 + 3 * pulse,
                    sigmaY: 4 + 3 * pulse,
                  ),
                  child: Opacity(
                    opacity: 0.55 + 0.25 * pulse,
                    child: CustomPaint(
                      size: const Size(26, 26),
                      painter: _OctocatPainter(_glowColor),
                    ),
                  ),
                ),
                // Crisp mark on top.
                CustomPaint(
                  size: const Size(26, 26),
                  painter: _OctocatPainter(_fgColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _glowingText(double pulse) {
    final chars = widget.label.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(chars.length, (i) {
        final start = math.min(0.55, (i / chars.length) * 0.6);
        final end = math.min(1.0, start + 0.45);
        final reveal = CurvedAnimation(
          parent: _introController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: reveal,
          builder: (context, _) {
            final value = reveal.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 8),
                child: Text(
                  chars[i] == ' ' ? '\u00A0' : chars[i],
                  style: TextStyle(
                    color: _fgColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: _glowColor.withOpacity(0.55 + 0.35 * pulse),
                        blurRadius: 10 + 8 * pulse,
                      ),
                      Shadow(
                        color: _glowColor.withOpacity(0.25 + 0.2 * pulse),
                        blurRadius: 20 + 14 * pulse,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Draws a simplified, stylized Octocat mark: a rounded head,
/// two pointed ears, and a curved arm sweeping to the lower
/// right - a flat silhouette rendition, drawn entirely in code.
class _OctocatPainter extends CustomPainter {
  final Color color;

  const _OctocatPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Head
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.42, h * 0.48),
      width: w * 0.64,
      height: h * 0.64,
    ));

    // Left ear
    path.addPath(
      Path()
        ..moveTo(w * 0.18, h * 0.24)
        ..lineTo(w * 0.30, h * 0.04)
        ..lineTo(w * 0.40, h * 0.26)
        ..close(),
      Offset.zero,
    );

    // Right ear
    path.addPath(
      Path()
        ..moveTo(w * 0.46, h * 0.26)
        ..lineTo(w * 0.56, h * 0.04)
        ..lineTo(w * 0.66, h * 0.24)
        ..close(),
      Offset.zero,
    );

    // Curved arm / paw sweeping to the bottom right
    path.addPath(
      Path()
        ..moveTo(w * 0.56, h * 0.64)
        ..cubicTo(w * 0.70, h * 0.60, w * 0.82, h * 0.68, w * 0.90, h * 0.82)
        ..cubicTo(w * 0.95, h * 0.91, w * 0.86, h * 0.98, w * 0.77, h * 0.92)
        ..cubicTo(w * 0.68, h * 0.86, w * 0.63, h * 0.75, w * 0.55, h * 0.72)
        ..close(),
      Offset.zero,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OctocatPainter oldDelegate) => oldDelegate.color != color;
}

/// Paints a soft diagonal shine band sweeping across the button.
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color tint;
  final double strength;

  const _ShimmerPainter(this.progress, {required this.tint, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width * 0.4;
    final travel = size.width + bandWidth * 2;
    final dx = -bandWidth + travel * progress;

    final path = Path()
      ..moveTo(dx, size.height)
      ..lineTo(dx + bandWidth * 0.5, 0)
      ..lineTo(dx + bandWidth, 0)
      ..lineTo(dx + bandWidth * 0.5, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tint.withOpacity(0.0),
          tint.withOpacity(strength),
          tint.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(dx, 0, bandWidth, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}