// li/screens/animations/animated_buttons/llm_model_logo/llama_button.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A reusable button widget featuring the detailed Llama logo.
///
/// The Llama logo is Meta's AI brand - a stylized llama head with
/// distinctive long ears and a friendly, modern look.
class LlamaButton extends StatelessWidget {
  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Text label displayed on the button.
  final String text;

  /// Background color of the button.
  final Color backgroundColor;

  /// Text color of the button.
  final Color textColor;

  /// Size of the Llama logo.
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

  const LlamaButton({
    super.key,
    required this.onPressed,
    this.text = 'Chat with Llama',
    this.backgroundColor = const Color(0xFF1877F2),
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

    final Widget logoWidget = customLogo ?? _buildLlamaLogo();

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
                    Color(0xFF1877F2), // Meta Blue
                    Color(0xFF42A5F5), // Lighter Blue
                    Color(0xFF7C4DFF), // Purple
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
                    ? (gradientColors?.first ?? const Color(0xFF1877F2))
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

  Widget _buildLlamaLogo() {
    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: CustomPaint(
        painter: LlamaLogoPainter(
          primaryColor: useGradient
              ? (gradientColors?.first ?? const Color(0xFF1877F2))
              : textColor,
          useGradient: useGradient,
        ),
      ),
    );
  }
}

/// Custom painter that draws the detailed Llama logo.
///
/// The Llama logo features a stylized llama head with long pointed ears,
/// a friendly face, and a circular background - representing Meta's AI.
class LlamaLogoPainter extends CustomPainter {
  final Color primaryColor;
  final bool useGradient;

  LlamaLogoPainter({
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

    // 1. Draw circular background
    final Paint bgPaint = Paint()
      ..style = PaintingStyle.fill;

    if (useGradient) {
      bgPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF1877F2),
          Color(0xFF42A5F5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      ));
    } else {
      // Semi-transparent version of the primary color
      bgPaint.color = primaryColor.withOpacity(0.15);
    }

    canvas.drawCircle(Offset(centerX, centerY), radius * 0.95, bgPaint);

    // 2. Draw the Llama head
    final Paint llamaPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (useGradient) {
      llamaPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF1877F2),
          Color(0xFF7C4DFF),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      ));
    } else {
      llamaPaint.color = primaryColor;
    }

    // Draw llama head shape (rounded rectangle face)
    final Path llamaHead = _createLlamaHead(
      centerX: centerX,
      centerY: centerY,
      width: radius * 1.4,
      height: radius * 1.5,
    );
    canvas.drawPath(llamaHead, llamaPaint);

    // 3. Draw the ears (long pointed)
    final Path leftEar = _createLlamaEar(
      centerX: centerX - radius * 0.35,
      centerY: centerY - radius * 0.45,
      length: radius * 0.85,
      width: radius * 0.30,
      isLeft: true,
    );
    canvas.drawPath(leftEar, llamaPaint);

    final Path rightEar = _createLlamaEar(
      centerX: centerX + radius * 0.35,
      centerY: centerY - radius * 0.45,
      length: radius * 0.85,
      width: radius * 0.30,
      isLeft: false,
    );
    canvas.drawPath(rightEar, llamaPaint);

    // 4. Draw inner ear detail (lighter color)
    final Paint innerEarPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (useGradient ? const Color(0xFF42A5F5) : primaryColor)
          .withOpacity(0.5);

    final Path leftInnerEar = _createLlamaEar(
      centerX: centerX - radius * 0.35,
      centerY: centerY - radius * 0.55,
      length: radius * 0.60,
      width: radius * 0.18,
      isLeft: true,
      isInner: true,
    );
    canvas.drawPath(leftInnerEar, innerEarPaint);

    final Path rightInnerEar = _createLlamaEar(
      centerX: centerX + radius * 0.35,
      centerY: centerY - radius * 0.55,
      length: radius * 0.60,
      width: radius * 0.18,
      isLeft: false,
      isInner: true,
    );
    canvas.drawPath(rightInnerEar, innerEarPaint);

    // 5. Draw the eyes (white circles with dark pupils)
    final Paint eyeWhitePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    final Paint pupilPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = useGradient
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF1A1A1A);

    // Left eye
    final double eyeY = centerY - radius * 0.15;
    final double eyeOffsetX = radius * 0.22;
    final double eyeRadius = radius * 0.13;

    canvas.drawCircle(
      Offset(centerX - eyeOffsetX, eyeY),
      eyeRadius,
      eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(centerX - eyeOffsetX + radius * 0.04, eyeY + radius * 0.02),
      eyeRadius * 0.55,
      pupilPaint,
    );

    // Right eye
    canvas.drawCircle(
      Offset(centerX + eyeOffsetX, eyeY),
      eyeRadius,
      eyeWhitePaint,
    );
    canvas.drawCircle(
      Offset(centerX + eyeOffsetX + radius * 0.04, eyeY + radius * 0.02),
      eyeRadius * 0.55,
      pupilPaint,
    );

    // 6. Draw the snout/muzzle area
    final Paint snoutPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.95);

    final Path snoutPath = Path();
    final double snoutY = centerY + radius * 0.20;
    final double snoutWidth = radius * 0.55;
    final double snoutHeight = radius * 0.35;

    snoutPath.moveTo(centerX - snoutWidth / 2, snoutY);
    snoutPath.quadraticBezierTo(
      centerX - snoutWidth / 2, snoutY + snoutHeight,
      centerX, snoutY + snoutHeight,
    );
    snoutPath.quadraticBezierTo(
      centerX + snoutWidth / 2, snoutY + snoutHeight,
      centerX + snoutWidth / 2, snoutY,
    );
    snoutPath.quadraticBezierTo(
      centerX, snoutY - snoutHeight * 0.15,
      centerX - snoutWidth / 2, snoutY,
    );
    snoutPath.close();

    canvas.drawPath(snoutPath, snoutPaint);

    // 7. Draw the nose (two small dots)
    final Paint nosePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = useGradient
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF1A1A1A);

    final double noseY = snoutY + snoutHeight * 0.35;
    final double noseOffset = radius * 0.10;

    canvas.drawCircle(
      Offset(centerX - noseOffset, noseY),
      radius * 0.05,
      nosePaint,
    );
    canvas.drawCircle(
      Offset(centerX + noseOffset, noseY),
      radius * 0.05,
      nosePaint,
    );

    // 8. Draw a friendly smile
    final Paint smilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round
      ..color = useGradient
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF1A1A1A);

    final Path smilePath = Path();
    final double smileY = snoutY + snoutHeight * 0.75;
    final double smileWidth = radius * 0.35;

    smilePath.moveTo(centerX - smileWidth, smileY);
    smilePath.quadraticBezierTo(
      centerX, smileY + smileWidth * 0.20,
      centerX + smileWidth, smileY,
    );

    canvas.drawPath(smilePath, smilePaint);
  }

  /// Creates the rounded llama head shape.
  Path _createLlamaHead({
    required double centerX,
    required double centerY,
    required double width,
    required double height,
  }) {
    final Path path = Path();
    final double left = centerX - width / 2;
    final double right = centerX + width / 2;
    final double top = centerY - height / 2;
    final double bottom = centerY + height / 2;
    final double cornerRadius = width * 0.40;

    // Rounded rectangle with extra rounding at the bottom
    path.moveTo(left + cornerRadius, top);
    path.lineTo(right - cornerRadius, top);
    path.quadraticBezierTo(right, top, right, top + cornerRadius);
    path.lineTo(right, bottom - cornerRadius * 0.6);
    path.quadraticBezierTo(
      right, bottom,
      right - cornerRadius * 0.6, bottom,
    );
    path.lineTo(left + cornerRadius * 0.6, bottom);
    path.quadraticBezierTo(
      left, bottom,
      left, bottom - cornerRadius * 0.6,
    );
    path.lineTo(left, top + cornerRadius);
    path.quadraticBezierTo(left, top, left + cornerRadius, top);
    path.close();
    return path;
  }

  /// Creates a pointed ear shape.
  Path _createLlamaEar({
    required double centerX,
    required double centerY,
    required double length,
    required double width,
    required bool isLeft,
    bool isInner = false,
  }) {
    final Path path = Path();
    final double tipY = centerY - length;
    final double baseY = centerY + length * 0.2;
    final double baseWidth = width;
    final double curve = isLeft ? -width * 0.2 : width * 0.2;

    if (isInner) {
      // Inner ear is smaller and simpler
      path.moveTo(centerX, tipY);
      path.quadraticBezierTo(
        centerX + curve * 0.3, centerY - length * 0.3,
        centerX - baseWidth * 0.4, baseY,
      );
      path.lineTo(centerX + baseWidth * 0.4, baseY);
      path.quadraticBezierTo(
        centerX - curve * 0.3, centerY - length * 0.3,
        centerX, tipY,
      );
    } else {
      // Outer ear is a pointed shape
      path.moveTo(centerX, tipY);
      path.quadraticBezierTo(
        centerX + curve, centerY - length * 0.4,
        centerX - baseWidth * 0.5, baseY,
      );
      path.quadraticBezierTo(
        centerX, baseY + length * 0.1,
        centerX + baseWidth * 0.5, baseY,
      );
      path.quadraticBezierTo(
        centerX - curve, centerY - length * 0.4,
        centerX, tipY,
      );
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant LlamaLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.useGradient != useGradient;
  }
}



