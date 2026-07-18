import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A reusable button widget featuring the detailed Gemini logo.
///
/// The Gemini logo is Google's AI brand - a four-pointed star/spark
/// with a gradient that flows from blue to purple to pink.
class GeminiButton extends StatelessWidget {
  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Text label displayed on the button.
  final String text;

  /// Background color of the button.
  final Color backgroundColor;

  /// Text color of the button.
  final Color textColor;

  /// Size of the Gemini logo.
  final double logoSize;

  /// Overall padding around the button content.
  final EdgeInsetsGeometry padding;

  /// Border radius of the button.
  final double borderRadius;

  /// Whether to show a loading indicator instead of the text.
  final bool isLoading;

  /// Custom widget to display instead of the default logo.
  final Widget? customLogo;

  /// Elevation of the button.
  final double elevation;

  /// Whether the button takes the full width of its parent.
  final bool fullWidth;

  /// Whether to use a gradient background instead of solid color.
  final bool useGradient;

  /// Gradient colors when [useGradient] is true.
  final List<Color>? gradientColors;

  const GeminiButton({
    super.key,
    required this.onPressed,
    this.text = 'Chat with Gemini',
    this.backgroundColor = const Color(0xFF1A73E8),
    this.textColor = Colors.white,
    this.logoSize = 24.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = 12.0,
    this.isLoading = false,
    this.customLogo,
    this.elevation = 2.0,
    this.fullWidth = false,
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final Color effectiveBg = isDisabled
        ? backgroundColor.withOpacity(0.5)
        : backgroundColor;

    final Widget logoWidget = customLogo ?? _buildGeminiLogo();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: useGradient ? null : effectiveBg,
            gradient: useGradient
                ? LinearGradient(
              colors: gradientColors ??
                  const [
                    Color(0xFF4285F4), // Google Blue
                    Color(0xFF9B72CB), // Purple
                    Color(0xFFE91E63), // Pink
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isDisabled
                ? null
                : [
              BoxShadow(
                color: (useGradient
                    ? (gradientColors?.first ?? const Color(0xFF4285F4))
                    : backgroundColor)
                    .withOpacity(0.3),
                blurRadius: elevation * 4,
                offset: Offset(0, elevation),
              ),
            ],
          ),
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                logoWidget,
                const SizedBox(width: 10),
                if (isLoading)
                  SizedBox(
                    width: logoSize - 4,
                    height: logoSize - 4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeminiLogo() {
    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: CustomPaint(
        painter: GeminiLogoPainter(
          primaryColor: useGradient
              ? (gradientColors?.first ?? const Color(0xFF4285F4))
              : textColor,
          useGradient: useGradient,
        ),
      ),
    );
  }
}

/// Custom painter that draws the detailed Gemini logo.
///
/// The Gemini logo is a four-pointed star/spark with elegant curves
/// and a beautiful gradient flowing from blue to purple to pink.
class GeminiLogoPainter extends CustomPainter {
  final Color primaryColor;
  final bool useGradient;

  GeminiLogoPainter({
    required this.primaryColor,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double centerX = w / 2;
    final double centerY = h / 2;
    final double radius = math.min(w, h) / 2;

    // Create the main four-pointed star path (Gemini spark)
    final Path starPath = _createGeminiStarPath(
      centerX: centerX,
      centerY: centerY,
      outerRadius: radius * 0.95,
      innerRadius: radius * 0.32,
    );

    // Create the gradient shader
    final Paint starPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (useGradient) {
      starPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF4285F4), // Google Blue
          Color(0xFF9B72CB), // Purple
          Color(0xFFE91E63), // Pink
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      ));
    } else {
      starPaint.color = primaryColor;
    }

    // Draw the main star/spark shape
    canvas.drawPath(starPath, starPaint);

    // Add the smaller inner sparkle (the characteristic "twinkle")
    final Path innerSparklePath = _createGeminiStarPath(
      centerX: centerX + radius * 0.35,
      centerY: centerY - radius * 0.35,
      outerRadius: radius * 0.22,
      innerRadius: radius * 0.08,
    );

    final Paint sparklePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = useGradient ? const Color(0xFF4285F4) : primaryColor;

    canvas.drawPath(innerSparklePath, sparklePaint);

    // ✅ FIXED LINE: Add a third tiny sparkle for extra detail
    // Using cascade operator to modify the color property of sparklePaint
    final Path tinySparklePath = _createGeminiStarPath(
      centerX: centerX - radius * 0.30,
      centerY: centerY + radius * 0.30,
      outerRadius: radius * 0.12,
      innerRadius: radius * 0.04,
    );

    // ✅ FIX: Call withOpacity on the Color, not the Paint
    canvas.drawPath(
      tinySparklePath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = sparklePaint.color.withOpacity(0.7),
    );
  }

  /// Creates a four-pointed star path (the iconic Gemini spark shape).
  Path _createGeminiStarPath({
    required double centerX,
    required double centerY,
    required double outerRadius,
    required double innerRadius,
  }) {
    final Path path = Path();
    const int numPoints = 4; // Four-pointed star
    final double angleStep = (2 * math.pi) / (numPoints * 2);

    // Start at the top point
    path.moveTo(
      centerX,
      centerY - outerRadius,
    );

    // Draw curves between each outer and inner point
    for (int i = 0; i < numPoints * 2; i++) {
      final double angle = -math.pi / 2 + (i * angleStep);
      final double radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);

      if (i == 0) {
        continue;
      }

      final double controlRadius = (outerRadius + innerRadius) / 2;
      final double controlAngle = angle - (angleStep / 2);
      final double controlX = centerX + controlRadius * math.cos(controlAngle);
      final double controlY = centerY + controlRadius * math.sin(controlAngle);

      path.quadraticBezierTo(controlX, controlY, x, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant GeminiLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.useGradient != useGradient;
  }
}
