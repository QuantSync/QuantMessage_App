// li/screens/animations/animated_buttons/llm_model_logo/deepseek_button.dart

import 'package:flutter/material.dart';

/// A reusable button widget featuring the DeepSeek logo.
///
/// This button can be customized with various properties and is designed
/// to be easily integrated into any screen or component.
class DeepSeekButton extends StatelessWidget {
  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Text label displayed on the button.
  final String text;

  /// Background color of the button.
  final Color backgroundColor;

  /// Text color of the button.
  final Color textColor;

  /// Size of the DeepSeek logo.
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

  const DeepSeekButton({
    super.key,
    required this.onPressed,
    this.text = 'Chat with DeepSeek',
    this.backgroundColor = const Color(0xFF4D8AFF),
    this.textColor = Colors.white,
    this.logoSize = 24.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = 12.0,
    this.isLoading = false,
    this.customLogo,
    this.elevation = 2.0,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final Color effectiveBg = isDisabled
        ? backgroundColor.withOpacity(0.5)
        : backgroundColor;

    final Widget logoWidget = customLogo ??
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: CustomPaint(
            painter: DeepSeekLogoPainter(
              color: textColor,
            ),
          ),
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isDisabled
                ? null
                : [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
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
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws the DeepSeek logo (a stylized blue whale tail).
///
/// This creates a circular wave-like pattern that resembles the DeepSeek branding.
class DeepSeekLogoPainter extends CustomPainter {
  final Color color;

  DeepSeekLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double centerX = w / 2;
    final double centerY = h / 2;

    // Draw the main circular outline (ring)
    final Paint ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12;

    canvas.drawCircle(
      Offset(centerX, centerY),
      w * 0.44,
      ringPaint,
    );

    // Draw the whale tail / wave pattern in the center
    final Path wavePath = Path();

    // Create a stylized wave/tail design
    wavePath.moveTo(centerX - w * 0.18, centerY);
    wavePath.quadraticBezierTo(
      centerX - w * 0.10, centerY - h * 0.15,
      centerX, centerY - h * 0.05,
    );
    wavePath.quadraticBezierTo(
      centerX + w * 0.10, centerY + h * 0.05,
      centerX + w * 0.18, centerY,
    );
    wavePath.quadraticBezierTo(
      centerX + w * 0.10, centerY - h * 0.10,
      centerX + w * 0.05, centerY - h * 0.15,
    );
    wavePath.quadraticBezierTo(
      centerX, centerY - h * 0.20,
      centerX - w * 0.05, centerY - h * 0.15,
    );
    wavePath.quadraticBezierTo(
      centerX - w * 0.10, centerY - h * 0.10,
      centerX - w * 0.18, centerY,
    );
    wavePath.close();

    canvas.drawPath(wavePath, paint);

    // Add a small dot in the center (eye-like detail)
    canvas.drawCircle(
      Offset(centerX, centerY + h * 0.05),
      w * 0.04,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant DeepSeekLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
