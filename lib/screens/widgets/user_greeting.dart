// lib/screens/widgets/user_greeting.dart
//
// QuantMessage — UserGreeting Widget
// Displays a time-aware, animated greeting on the Chat Screen empty state.
// Extracted from chat_screen.dart for clean separation of concerns.
// Fully responsive — uses LayoutBuilder + FittedBox + clamp() to adapt
// to any screen width without pixel overflow.
// ------------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../animations/animation_effects/infinity_animation.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TIME-AWARE GREETING DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// Immutable data class carrying all values for a single time-slot greeting.
class _GreetingData {
  final String greeting;
  final String subtitle;
  final Color accentColor;
  const _GreetingData({
    required this.greeting,
    required this.subtitle,
    required this.accentColor,
  });
}

/// Returns the correct [_GreetingData] for the current local hour.
///
/// Slots:
/// * Morning   05:00 – 11:59  amber  #F59E0B
/// * Afternoon 12:00 – 16:59  blue   #3B82F6
/// * Evening   17:00 – 20:59  violet #8B5CF6
/// * Night     21:00 – 04:59  cyan   #06B6D4
_GreetingData _resolveGreeting() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return const _GreetingData(
      greeting: 'Hi, Good Morning! ☀️',
      subtitle: 'Ready to conquer the day? Let\'s get started.',
      accentColor: Color(0xFFF59E0B), // amber
    );
  } else if (hour >= 12 && hour < 17) {
    return const _GreetingData(
      greeting: 'Good Afternoon, Sir! 🧠',
      subtitle: 'Midday hustle mode — what shall we tackle next?',
      accentColor: Color(0xFF3B82F6), // blue
    );
  } else if (hour >= 17 && hour < 21) {
    return const _GreetingData(
      greeting: 'Good Evening! Had Your Tea? ☕',
      subtitle: 'Wind down and let me handle the heavy lifting.',
      accentColor: Color(0xFF8B5CF6), // violet
    );
  } else {
    return const _GreetingData(
      greeting: 'Up Late? Champ! 🌙',
      subtitle: 'The night owls get the best ideas — what\'s on your mind?',
      accentColor: Color(0xFF06B6D4), // cyan
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPEWRITER TEXT WIDGET  (self-contained — no external dep on chat_screen)
// ═══════════════════════════════════════════════════════════════════════════

/// Animates [text] character-by-character with an optional blinking cursor.
class GreetingTypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final Duration cursorSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  final Duration delayBeforeStart;

  const GreetingTypingText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 38),
    this.cursorSpeed = const Duration(milliseconds: 500),
    this.showCursor = true,
    this.onComplete,
    this.delayBeforeStart = Duration.zero,
  });

  @override
  State<GreetingTypingText> createState() => _GreetingTypingTextState();
}

class _GreetingTypingTextState extends State<GreetingTypingText> {
  String _displayed = '';
  int _index = 0;
  bool _cursorVisible = true;
  Timer? _typingTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
    _startCursor();
  }

  void _startTyping() {
    Future.delayed(widget.delayBeforeStart, () {
      if (!mounted) return;
      _typingTimer = Timer.periodic(widget.typingSpeed, (t) {
        if (_index < widget.text.length) {
          if (mounted) {
            setState(() {
              _displayed += widget.text[_index];
              _index++;
            });
          }
        } else {
          t.cancel();
          widget.onComplete?.call();
        }
      });
    });
  }

  void _startCursor() {
    _cursorTimer = Timer.periodic(widget.cursorSpeed, (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(text: _displayed, style: style),
          if (widget.showCursor)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _cursorVisible ? 1.0 : 0.0,
                child: Container(
                  width: 2,
                  height: (style.fontSize ?? 14) * 1.2,
                  color: style.color ?? Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER GREETING — Public widget used by ChatScreen's empty state
// ═══════════════════════════════════════════════════════════════════════════

/// Responsive, time-aware greeting widget for the ChatScreen empty state.
///
/// Usage:
/// ```dart
/// UserGreeting(userName: _userName)
/// ```
///
/// Layout is fully driven by [LayoutBuilder] and [FittedBox] so it adapts
/// to any window width without overflow. All font sizes are clamped between
/// safe minimum and maximum values.
class UserGreeting extends StatelessWidget {
  /// The display name of the signed-in user. Falls back to "there" if null.
  final String? userName;

  const UserGreeting({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final data = _resolveGreeting();

    return LayoutBuilder(
      builder: (context, constraints) {
        // ── Responsive sizes — clamp prevents overflow on narrow screens ──
        final double maxW = constraints.maxWidth;

        // Hero name font: 8 % of width, bounded [22, 44]
        final double nameFontSize = (maxW * 0.08).clamp(22.0, 44.0);

        // Infinity animation canvas: 15 % of width, bounded [50, 90]
        final double animSize = (maxW * 0.15).clamp(50.0, 90.0);

        // Greeting font: 3.5 % of width, bounded [14, 22]
        final double greetFontSize = (maxW * 0.035).clamp(14.0, 22.0);

        // Subtitle font: 2.5 % of width, bounded [11, 15]
        final double subFontSize = (maxW * 0.025).clamp(11.0, 15.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Row: InfinityAnimation  +  Name greeting ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: animSize,
                  height: animSize * 0.5,
                  child: InfinityAnimation(
                    size: animSize,
                    color: data.accentColor,
                    duration: const Duration(seconds: 5),
                  ),
                ),
                const SizedBox(width: 10),
                // FittedBox scales down the text if the Row is too narrow
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '< Hey "${userName ?? 'there'}" >',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFE8E8E8),
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Typewriter greeting (time-sensitive) ──────────────────────
            GreetingTypingText(
              key: ValueKey(data.greeting),
              text: data.greeting,
              showCursor: true,
              style: GoogleFonts.outfit(
                color: data.accentColor,
                fontSize: greetFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 6),

            // ── Subtitle (static, fades naturally via parent FadeTransition) ─
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: subFontSize,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        );
      },
    );
  }
}
