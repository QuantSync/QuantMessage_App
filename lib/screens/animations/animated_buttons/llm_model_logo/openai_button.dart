// li/screens/animations/animated_buttons/llm_model_logo/openai_button.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A reusable button widget featuring the detailed OpenAI logo.
///
/// The OpenAI logo is a six-petal flower-like spiral made of interconnected
/// hexagonal segments, representing the neural network concept.
class OpenAIButton extends StatelessWidget {
  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Text label displayed on the button.
  final String text;

  /// Background color of the button.
  final Color backgroundColor;

  /// Text color of the button.
  final Color textColor;

  /// Size of the OpenAI logo.
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

  const OpenAIButton({
    super.key,
    required this.onPressed,
    this.text = 'ChatGPT',
    this.backgroundColor = const Color(0xFF10A37F),
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

    final Widget logoWidget = customLogo ?? _buildOpenAILogo();

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
                    Color(0xFF10A37F), // OpenAI Teal
                    Color(0xFF1A7F64), // Darker Teal
                    Color(0xFF0E906F), // Lighter Teal
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
                    ? (gradientColors?.first ?? const Color(0xFF10A37F))
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

  Widget _buildOpenAILogo() {
    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: CustomPaint(
        painter: OpenAILogoPainter(
          primaryColor: useGradient
              ? (gradientColors?.first ?? const Color(0xFF10A37F))
              : textColor,
          useGradient: useGradient,
        ),
      ),
    );
  }
}

/// Custom painter that draws the detailed OpenAI logo.
///
/// The OpenAI logo is a stylized six-petal flower/hexagonal spiral pattern.
/// It's composed of interconnected rounded segments that form a
/// continuous loop, symbolizing the continuous learning of AI.
class OpenAILogoPainter extends CustomPainter {
  final Color primaryColor;
  final bool useGradient;

  OpenAILogoPainter({
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

    // Save canvas state
    canvas.save();
    canvas.translate(centerX, centerY);

    // Rotate slightly for that perfect OpenAI logo look
    canvas.rotate(math.pi / 12);

    final Paint petalPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (useGradient) {
      petalPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF10A37F),
          Color(0xFF0E906F),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(
        center: Offset.zero,
        radius: radius,
      ));
    } else {
      petalPaint.color = primaryColor;
    }

    // Draw 6 petals arranged in a hexagonal pattern
    const int numPetals = 6;
    final double petalLength = radius * 0.85;
    final double petalWidth = radius * 0.32;

    for (int i = 0; i < numPetals; i++) {
      canvas.save();
      final double angle = (i * 2 * math.pi) / numPetals;
      canvas.rotate(angle);

      // Draw a single petal pointing up
      final Path petalPath = _createPetal(
        length: petalLength,
        width: petalWidth,
      );

      // Position the petal to start from center
      canvas.translate(0, radius * 0.15);
      canvas.drawPath(petalPath, petalPaint);

      canvas.restore();
    }

    canvas.restore();

    // Draw a subtle inner circle for depth (optional)
    final Paint innerCirclePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (useGradient ? const Color(0xFF10A37F) : primaryColor)
          .withOpacity(0.0); // Transparent - just for layering

    canvas.drawCircle(Offset(centerX, centerY), radius * 0.15, innerCirclePaint);
  }

  /// Creates a single petal shape - rounded teardrop/leaf form.
  Path _createPetal({
    required double length,
    required double width,
  }) {
    final Path path = Path();

    // Start at the bottom (near center)
    path.moveTo(0, 0);

    // Right curve going up
    path.cubicTo(
      width * 0.5, -length * 0.1, // Control point 1
      width * 0.55, -length * 0.6, // Control point 2
      width * 0.15, -length * 0.95, // End point (tip)
    );

    // Curve to top tip
    path.cubicTo(
      width * 0.05, -length * 1.0,
      -width * 0.05, -length * 1.0,
      -width * 0.15, -length * 0.95,
    );

    // Left curve coming back down
    path.cubicTo(
      -width * 0.55, -length * 0.6,
      -width * 0.5, -length * 0.1,
      0, 0,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant OpenAILogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.useGradient != useGradient;
  }
}
