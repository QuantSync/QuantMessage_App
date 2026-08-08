// lib/screens/news_screen/quantrade_animation.dart
// QuanTrade — Animated Widgets & Painters
// All reusable animated components for the QuanTrade Coming Soon page.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 1 · BACKGROUND — Floating radial orbs
// ═══════════════════════════════════════════════════════════════════════════

class QtAnimatedBackground extends StatelessWidget {
  final AnimationController ctrl;
  const QtAnimatedBackground({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 600;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        return RepaintBoundary(
          child: Stack(
            children: [
            // Top-left teal orb
            Positioned(
              top: -80 + t * 30,
              left: mobile ? -40 + t * 15 : -60 + t * 20,
              child: _Orb(
                size: mobile ? size.width * 0.85 : size.width * 0.55,
                color: const Color(0xFF00D4AA).withOpacity(0.055),
              ),
            ),
            // Top-right blue orb
            Positioned(
              top: size.height * 0.15 - t * 20,
              right: mobile
                  ? -size.width * 0.35 + t * 12
                  : -size.width * 0.18 + t * 15,
              child: _Orb(
                size: mobile ? size.width * 0.70 : size.width * 0.42,
                color: const Color(0xFF3B82F6).withOpacity(0.040),
              ),
            ),
            // Bottom centre purple orb
            Positioned(
              bottom: -60 + t * 25,
              left: size.width * 0.15,
              child: _Orb(
                size: mobile ? size.width * 0.65 : size.width * 0.45,
                color: const Color(0xFF8B5CF6).withOpacity(0.030),
              ),
            ),
          ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 2 · TICKER TAPE — Scrolling live market tickers
// ═══════════════════════════════════════════════════════════════════════════

const kQtTickers = <_TickerData>[
  _TickerData('AAPL',  '+1.24%', true),
  _TickerData('TSLA',  '-0.87%', false),
  _TickerData('BTC',   '+3.12%', true),
  _TickerData('ETH',   '+1.95%', true),
  _TickerData('NVDA',  '+2.45%', true),
  _TickerData('GOLD',  '-0.32%', false),
  _TickerData('SPY',   '+0.78%', true),
  _TickerData('QQQ',   '+1.02%', true),
  _TickerData('AMZN',  '-0.44%', false),
  _TickerData('MSFT',  '+0.66%', true),
  _TickerData('NIFTY', '+0.55%', true),
  _TickerData('EUR/USD','-0.21%', false),
];

class _TickerData {
  final String symbol;
  final String change;
  final bool up;
  const _TickerData(this.symbol, this.change, this.up);
}

class QtTickerTape extends StatelessWidget {
  final AnimationController ctrl;
  const QtTickerTape({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRect(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => CustomPaint(
              painter: _TickerPainter(t: ctrl.value),
              size: Size(MediaQuery.of(context).size.width, 36),
            ),
          ),
        ),
      ),
    );
  }
}

class _TickerPainter extends CustomPainter {
  final double t;
  const _TickerPainter({required this.t});

  static const double _itemW = 138.0;

  @override
  void paint(Canvas canvas, Size size) {
    final totalW = kQtTickers.length * _itemW;
    final offset = -(t * totalW) % totalW;

    for (int rep = -1; rep <= (size.width / totalW).ceil() + 1; rep++) {
      for (int i = 0; i < kQtTickers.length; i++) {
        final x = offset + rep * totalW + i * _itemW;
        if (x > size.width + 20 || x < -_itemW - 20) continue;
        _drawItem(canvas, size, kQtTickers[i], x);
      }
    }
  }

  void _drawItem(Canvas canvas, Size size, _TickerData td, double x) {
    const upColor   = Color(0xFF00D4AA);
    const downColor = Color(0xFFFF5F6D);
    final color     = td.up ? upColor : downColor;
    final centerY   = size.height / 2;

    // Symbol
    final symPainter = TextPainter(
      text: TextSpan(
        text: td.symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    symPainter.paint(canvas, Offset(x + 4, centerY - 13));

    // Change
    final chgPainter = TextPainter(
      text: TextSpan(
        text: td.change,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    chgPainter.paint(canvas, Offset(x + 4, centerY + 1));

    // Separator dot
    canvas.drawCircle(
      Offset(x + _itemW - 6, centerY - 1),
      1.8,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_TickerPainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 3 · TERMINAL MOCK PANEL
// ═══════════════════════════════════════════════════════════════════════════

enum _LineType { command, success, normal }

class _TermLine {
  final String text;
  final _LineType type;
  const _TermLine(this.text, this.type);
}

class QtTerminalPanel extends StatefulWidget {
  const QtTerminalPanel({super.key});

  @override
  State<QtTerminalPanel> createState() => _QtTerminalPanelState();
}

class _QtTerminalPanelState extends State<QtTerminalPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;

  static const _lines = <_TermLine>[
    _TermLine('> Scanning market for momentum signals...', _LineType.command),
    _TermLine('✓ Found 12 high-confidence setups',         _LineType.success),
    _TermLine('✓ Risk/reward filtered: 4 entries',         _LineType.success),
    _TermLine('✓ Portfolio correlation checked',            _LineType.success),
    _TermLine('  Entry: NVDA · \$142.50 · SL: \$138.00',  _LineType.normal),
  ];

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF090909),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window chrome
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const _WinDot(color: Color(0xFFFF5F57)),
                const SizedBox(width: 5),
                const _WinDot(color: Color(0xFFFFBD2E)),
                const SizedBox(width: 5),
                const _WinDot(color: Color(0xFF28C840)),
                const Spacer(),
                Text(
                  'quantrade · terminal',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withOpacity(0.28),
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._lines.map(_buildLine),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _blinkCtrl,
                  builder: (_, __) => Row(
                    children: [
                      Text(
                        '* Analysing signals...',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF00D4AA).withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Opacity(
                        opacity: _blinkCtrl.value,
                        child: Container(
                          width: 6,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(_TermLine line) {
    Color c;
    switch (line.type) {
      case _LineType.command: c = Colors.white.withOpacity(0.82); break;
      case _LineType.success: c = const Color(0xFF00D4AA); break;
      case _LineType.normal:  c = Colors.white.withOpacity(0.50); break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        line.text,
        style: GoogleFonts.jetBrainsMono(
          color: c, fontSize: 10, height: 1.55,
        ),
      ),
    );
  }
}

class _WinDot extends StatelessWidget {
  final Color color;
  const _WinDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 9, height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 4 · CANDLESTICK LOGO GLYPH
// ═══════════════════════════════════════════════════════════════════════════

class QtCandleLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const QtCandleLogo({super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.1,
      height: size,
      child: CustomPaint(
        painter: _CandlePainter(
          color: color ?? const Color(0xFF00D4AA),
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final Color color;
  const _CandlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = color
      ..style  = PaintingStyle.fill;

    final wickPaint = Paint()
      ..color       = color.withOpacity(0.50)
      ..strokeWidth = 1.1
      ..strokeCap   = StrokeCap.round;

    // Three candle bodies (left: short, mid: tall, right: medium)
    final bodies = <Rect>[
      Rect.fromLTWH(0,        h * 0.38, w * 0.27, h * 0.52),
      Rect.fromLTWH(w * 0.37, h * 0.10, w * 0.27, h * 0.78),
      Rect.fromLTWH(w * 0.73, h * 0.22, w * 0.27, h * 0.62),
    ];

    for (final r in bodies) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        bodyPaint,
      );
    }

    // Wicks
    void wick(double cx, double top, double bottom) {
      canvas.drawLine(Offset(cx, top), Offset(cx, bottom), wickPaint);
    }

    wick(w * 0.135, h * 0.14, h * 0.38);
    wick(w * 0.135, h * 0.90, h * 0.97);

    wick(w * 0.505, h * 0.02, h * 0.10);
    wick(w * 0.505, h * 0.88, h * 0.96);

    wick(w * 0.865, h * 0.06, h * 0.22);
    wick(w * 0.865, h * 0.84, h * 0.96);
  }

  @override
  bool shouldRepaint(_CandlePainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 5 · STATUS BADGE (pulsing "SOON" pill)
// ═══════════════════════════════════════════════════════════════════════════

class QtStatusBadge extends StatefulWidget {
  const QtStatusBadge({super.key});

  @override
  State<QtStatusBadge> createState() => _QtStatusBadgeState();
}

class _QtStatusBadgeState extends State<QtStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF00D4AA).withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00D4AA)
                .withOpacity(0.22 * _pulse.value),
            width: 0.8,
          ),
        ),
        child: Text(
          'SOON',
          style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFF00D4AA)
                .withOpacity(0.55 + 0.45 * _pulse.value),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 6 · STAGGERED ENTRANCE ANIMATION wrapper
// ═══════════════════════════════════════════════════════════════════════════

class QtStaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const QtStaggeredEntrance({
    super.key,
    required this.child,
    required this.delayMs,
  });

  @override
  State<QtStaggeredEntrance> createState() => _QtStaggeredEntranceState();
}

class _QtStaggeredEntranceState extends State<QtStaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.09),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 7 · BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

/// Primary button — white fill, black text, glowing shadow.
class QtPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool fullWidth;

  const QtPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.fullWidth = false,
  });

  @override
  State<QtPrimaryButton> createState() => _QtPrimaryButtonState();
}

class _QtPrimaryButtonState extends State<QtPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _scaleCtrl.reverse(),
        onTapUp:   (_) {
          _scaleCtrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _scaleCtrl.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withOpacity(0.88)
                  : Colors.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Colors.white
                      .withOpacity(_hovered ? 0.22 : 0.12),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 7),
                  Icon(widget.icon, size: 16, color: Colors.black87),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button — outlined, accent-coloured on hover.
class QtSecondaryButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final bool fullWidth;

  const QtSecondaryButton({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  State<QtSecondaryButton> createState() => _QtSecondaryButtonState();
}

class _QtSecondaryButtonState extends State<QtSecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown:   (_) => _scaleCtrl.reverse(),
        onTapUp:     (_) { _scaleCtrl.forward(); widget.onTap(); },
        onTapCancel: ()  => _scaleCtrl.forward(),
        child: ScaleTransition(
          scale: _scaleCtrl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.accentColor.withOpacity(0.11)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? widget.accentColor.withOpacity(0.50)
                    : Colors.white.withOpacity(0.14),
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: _hovered
                        ? widget.accentColor
                        : Colors.white.withOpacity(0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 13,
                  color: _hovered
                      ? widget.accentColor
                      : Colors.white.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 8 · PLATFORM CHIP
// ═══════════════════════════════════════════════════════════════════════════

class QtPlatformChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QtPlatformChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  State<QtPlatformChip> createState() => _QtPlatformChipState();
}

class _QtPlatformChipState extends State<QtPlatformChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withOpacity(0.20)
                  : Colors.white.withOpacity(0.09),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: Colors.white
                    .withOpacity(_hovered ? 0.88 : 0.55),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  color: Colors.white
                      .withOpacity(_hovered ? 0.88 : 0.55),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION 9 · PULSE SCALE animation wrapper (for CTA banner)
// ═══════════════════════════════════════════════════════════════════════════

class QtPulseScale extends StatefulWidget {
  final Widget child;
  const QtPulseScale({super.key, required this.child});

  @override
  State<QtPulseScale> createState() => _QtPulseScaleState();
}

class _QtPulseScaleState extends State<QtPulseScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.018)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
