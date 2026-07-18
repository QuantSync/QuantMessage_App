// li/screens/animations/animated_buttons/llm_model_logo/claude_button.dart
import 'package:flutter/material.dart';

/// Claude Logo/Button Widget - Highly Reusable Component
///
/// This widget provides a customizable Claude-branded button with logo,
/// suitable for integration into any Flutter application.
///
/// Features:
/// - Multiple size variants (small, medium, large, custom)
/// - Different button styles (solid, outline, icon-only, minimal)
/// - Claude branding with proper colors
/// - Smooth animations and hover effects
/// - Full customization support
///
/// Example:
/// ```dart
/// ClaudeButton(
///   onPressed: () => print('Claude button pressed'),
///   size: ClaudeButtonSize.medium,
///   style: ClaudeButtonStyle.solid,
/// )
/// ```

// ============================================================================
// ENUMS
// ============================================================================

/// Button size variants
enum ClaudeButtonSize {
  small,      // 32px
  medium,     // 44px
  large,      // 56px
  extraLarge, // 64px
  custom,     // Use customHeight parameter
}

/// Button style variants
enum ClaudeButtonStyle {
  solid,      // Filled with Claude colors
  outline,    // Border only with transparent background
  minimal,    // No border, just icon/text
  ghost,      // Transparent with hover effect
  iconOnly,   // Just the logo, no text
}

// ============================================================================
// MAIN WIDGET
// ============================================================================

class ClaudeButton extends StatefulWidget {
  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Button label text (optional)
  final String? label;

  /// Button size variant
  final ClaudeButtonSize size;

  /// Button style variant
  final ClaudeButtonStyle style;

  /// Custom button height (used when size is custom)
  final double? customHeight;

  /// Custom button width (optional)
  final double? customWidth;

  /// Custom background color (overrides default)
  final Color? backgroundColor;

  /// Custom text color (overrides default)
  final Color? textColor;

  /// Custom border color (for outline style)
  final Color? borderColor;

  /// Custom border width
  final double borderWidth;

  /// Enable/disable shadow effect
  final bool showShadow;

  /// Enable/disable hover scale animation
  final bool enableHoverAnimation;

  /// Scale factor on hover
  final double hoverScale;

  /// Custom text style
  final TextStyle? textStyle;

  /// Leading icon (optional, before text)
  final IconData? leadingIcon;

  /// Trailing icon (optional, after text)
  final IconData? trailingIcon;

  /// Loading state
  final bool isLoading;

  /// Disabled state
  final bool isDisabled;

  /// Button border radius
  final BorderRadius? borderRadius;

  /// Tooltip text
  final String? tooltip;

  /// Whether to show Claude logo
  final bool showLogo;

  /// Logo size multiplier
  final double logoSize;

  /// Spacing between logo and text
  final double logoSpacing;

  /// On hover callback
  final VoidCallback? onHover;

  /// On focus callback
  final VoidCallback? onFocus;

  const ClaudeButton({
    Key? key,
    required this.onPressed,
    this.label,
    this.size = ClaudeButtonSize.medium,
    this.style = ClaudeButtonStyle.solid,
    this.customHeight,
    this.customWidth,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.showShadow = true,
    this.enableHoverAnimation = true,
    this.hoverScale = 1.05,
    this.textStyle,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.borderRadius,
    this.tooltip,
    this.showLogo = true,
    this.logoSize = 1.0,
    this.logoSpacing = 8.0,
    this.onHover,
    this.onFocus,
  }) : super(key: key);

  @override
  State<ClaudeButton> createState() => _ClaudeButtonState();
}

class _ClaudeButtonState extends State<ClaudeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.hoverScale)
        .animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (widget.isDisabled || !widget.enableHoverAnimation) return;

    setState(() => _isHovered = isHovered);

    if (isHovered) {
      _hoverController.forward();
      widget.onHover?.call();
    } else {
      _hoverController.reverse();
    }
  }

  void _handleFocus(bool isFocused) {
    setState(() => _isFocused = isFocused);
    if (isFocused) {
      widget.onFocus?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final button = _buildButton(isDarkMode);

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(bool isDarkMode) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: widget.isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Focus(
          onKey: (node, event) {
            // Handle keyboard interactions
            return KeyEventResult.ignored;
          },
          onFocusChange: _handleFocus,
          child: GestureDetector(
            onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
            child: Container(
              height: _getHeight(),
              width: widget.customWidth,
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDarkMode),
                border: Border.all(
                  color: _getBorderColor(isDarkMode),
                  width: widget.style == ClaudeButtonStyle.outline ||
                      widget.style == ClaudeButtonStyle.minimal
                      ? widget.borderWidth
                      : 0,
                ),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                boxShadow: _getBoxShadow(isDarkMode),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isDisabled || widget.isLoading
                      ? null
                      : widget.onPressed,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  child: Padding(
                    padding: _getPadding(),
                    child: _buildButtonContent(isDarkMode),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(bool isDarkMode) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getTextColor(isDarkMode),
            ),
          ),
        ),
      );
    }

    final textColor = _getTextColor(isDarkMode);
    final textStyle = widget.textStyle ??
        TextStyle(
          color: textColor,
          fontSize: _getTextSize(),
          fontWeight: FontWeight.w600,
        );

    if (widget.style == ClaudeButtonStyle.iconOnly && widget.showLogo) {
      return Center(child: _buildClaudeLogo(textColor));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingIcon != null)
          Icon(widget.leadingIcon, color: textColor, size: _getIconSize())
        else if (widget.showLogo && widget.style != ClaudeButtonStyle.iconOnly)
          Padding(
            padding: EdgeInsets.only(right: widget.logoSpacing),
            child: _buildClaudeLogo(textColor),
          ),
        if (widget.label != null)
          Text(widget.label!, style: textStyle)
        else if (widget.showLogo && widget.style == ClaudeButtonStyle.iconOnly)
          _buildClaudeLogo(textColor),
        if (widget.trailingIcon != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(widget.trailingIcon, color: textColor, size: _getIconSize()),
          ),
      ],
    );
  }

  Widget _buildClaudeLogo(Color color) {
    final size = _getLogoSize();
    return CustomPaint(
      size: Size(size, size),
      painter: ClaudeLogoPainter(
        color: color,
      ),
    );
  }

  // ========================================================================
  // STYLING HELPERS
  // ========================================================================

  double _getHeight() {
    if (widget.customHeight != null) return widget.customHeight!;

    return switch (widget.size) {
      ClaudeButtonSize.small => 32,
      ClaudeButtonSize.medium => 44,
      ClaudeButtonSize.large => 56,
      ClaudeButtonSize.extraLarge => 64,
      ClaudeButtonSize.custom => 44,
    };
  }

  double _getLogoSize() {
    final baseSize = _getHeight() * 0.5;
    return baseSize * widget.logoSize;
  }

  double _getTextSize() {
    return switch (widget.size) {
      ClaudeButtonSize.small => 12,
      ClaudeButtonSize.medium => 14,
      ClaudeButtonSize.large => 16,
      ClaudeButtonSize.extraLarge => 18,
      ClaudeButtonSize.custom => 14,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      ClaudeButtonSize.small => 14,
      ClaudeButtonSize.medium => 16,
      ClaudeButtonSize.large => 18,
      ClaudeButtonSize.extraLarge => 20,
      ClaudeButtonSize.custom => 16,
    };
  }

  EdgeInsets _getPadding() {
    final horizontalPadding = switch (widget.size) {
      ClaudeButtonSize.small => 12.0,
      ClaudeButtonSize.medium => 16.0,
      ClaudeButtonSize.large => 20.0,
      ClaudeButtonSize.extraLarge => 24.0,
      ClaudeButtonSize.custom => 16.0,
    };

    return EdgeInsets.symmetric(horizontal: horizontalPadding);
  }

  Color _getBackgroundColor(bool isDarkMode) {
    if (widget.isDisabled) {
      return isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    }

    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }

    return switch (widget.style) {
      ClaudeButtonStyle.solid => _isHovered
          ? const Color(0xFF9D4EDD) // Lighter purple on hover
          : const Color(0xFF7B2CBF), // Claude purple
      ClaudeButtonStyle.outline => Colors.transparent,
      ClaudeButtonStyle.minimal => Colors.transparent,
      ClaudeButtonStyle.ghost => _isHovered
          ? Colors.grey.withOpacity(0.1)
          : Colors.transparent,
      ClaudeButtonStyle.iconOnly => Colors.transparent,
    };
  }

  Color _getBorderColor(bool isDarkMode) {
    if (widget.borderColor != null) return widget.borderColor!;

    return switch (widget.style) {
      ClaudeButtonStyle.outline => _isHovered
          ? const Color(0xFF9D4EDD)
          : const Color(0xFF7B2CBF),
      ClaudeButtonStyle.minimal => Colors.transparent,
      ClaudeButtonStyle.ghost => Colors.transparent,
      _ => Colors.transparent,
    };
  }

  Color _getTextColor(bool isDarkMode) {
    if (widget.isDisabled) {
      return isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;
    }

    if (widget.textColor != null) {
      return widget.textColor!;
    }

    return switch (widget.style) {
      ClaudeButtonStyle.solid => Colors.white,
      ClaudeButtonStyle.outline => const Color(0xFF7B2CBF),
      ClaudeButtonStyle.minimal => const Color(0xFF7B2CBF),
      ClaudeButtonStyle.ghost => const Color(0xFF7B2CBF),
      ClaudeButtonStyle.iconOnly => const Color(0xFF7B2CBF),
    };
  }

  List<BoxShadow>? _getBoxShadow(bool isDarkMode) {
    if (!widget.showShadow || widget.style != ClaudeButtonStyle.solid) {
      return null;
    }

    return [
      BoxShadow(
        color: const Color(0xFF7B2CBF).withOpacity(0.3),
        blurRadius: _isHovered ? 12 : 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

// ============================================================================
// CLAUDE LOGO PAINTER
// ============================================================================

class ClaudeLogoPainter extends CustomPainter {
  final Color color;

  ClaudeLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw stylized "C" shape for Claude
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.35;

    // Arc path for the C
    final path = Path();
    path.arcTo(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      1.2, // Start angle
      4.0, // Sweep angle (approximately 230 degrees)
      false,
    );

    canvas.drawPath(path, paint);

    // Optional: Draw accent line
    final accentPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    // Small accent dot/line at the opening
    canvas.drawLine(
      Offset(centerX + radius * 0.8, centerY - radius * 0.6),
      Offset(centerX + radius * 0.9, centerY - radius * 0.4),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(ClaudeLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ============================================================================
// CONVENIENCE CONSTRUCTOR FUNCTIONS
// ============================================================================

/// Quick constructor for solid Claude button
class ClaudeSolidButton extends ClaudeButton {
  ClaudeSolidButton({
    required VoidCallback onPressed,
    String? label,
    ClaudeButtonSize size = ClaudeButtonSize.medium,
    Key? key,
  }) : super(
    key: key,
    onPressed: onPressed,
    label: label,
    size: size,
    style: ClaudeButtonStyle.solid,
  );
}

/// Quick constructor for outline Claude button
class ClaudeOutlineButton extends ClaudeButton {
  ClaudeOutlineButton({
    required VoidCallback onPressed,
    String? label,
    ClaudeButtonSize size = ClaudeButtonSize.medium,
    Key? key,
  }) : super(
    key: key,
    onPressed: onPressed,
    label: label,
    size: size,
    style: ClaudeButtonStyle.outline,
  );
}

/// Quick constructor for icon-only Claude button
class ClaudeIconButton extends ClaudeButton {
  ClaudeIconButton({
    required VoidCallback onPressed,
    ClaudeButtonSize size = ClaudeButtonSize.medium,
    Key? key,
  }) : super(
    key: key,
    onPressed: onPressed,
    size: size,
    style: ClaudeButtonStyle.iconOnly,
    showLogo: true,
  );
}