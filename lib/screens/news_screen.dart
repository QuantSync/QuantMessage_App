// lib/screens/news_screen.dart
// QuanTrade — Coming Soon · Powered by QuantSync

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'news_screen/quantrade_animation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NewsScreen  ←  repurposed as QuanTrade "Coming Soon" landing page
// ─────────────────────────────────────────────────────────────────────────────

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  // ── entrance ──────────────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── slow orb drift ────────────────────────────────────────────────────────
  late final AnimationController _orbCtrl;

  // ── ticker tape ───────────────────────────────────────────────────────────
  late final AnimationController _tickerCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.055),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    _tickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _orbCtrl.dispose();
    _tickerCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Animated floating orbs
          Positioned.fill(
            child: QtAnimatedBackground(ctrl: _orbCtrl),
          ),
          // Page content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildScrollBody(mobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(58),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: AppBar(
            backgroundColor: Colors.black.withOpacity(0.52),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white60, size: 17),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const QtCandleLogo(size: 20),
                const SizedBox(width: 8),
                Text(
                  'QuanTrade',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 7),
                const QtStatusBadge(),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Divider(
                height: 0.5,
                thickness: 0.5,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SCROLL BODY ───────────────────────────────────────────────────────────

  Widget _buildScrollBody(bool mobile) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: mobile ? 24 : 32)),

        // Hero
        SliverToBoxAdapter(child: _HeroSection(mobile: mobile)),

        SliverToBoxAdapter(child: SizedBox(height: mobile ? 22 : 30)),

        // Ticker tape
        SliverToBoxAdapter(child: QtTickerTape(ctrl: _tickerCtrl)),

        SliverToBoxAdapter(child: SizedBox(height: mobile ? 24 : 32)),

        // Feature cards
        SliverToBoxAdapter(child: _FeatureSection(mobile: mobile)),

        SliverToBoxAdapter(child: SizedBox(height: mobile ? 24 : 32)),

        // CTA banner
        SliverToBoxAdapter(child: _CtaBanner(mobile: mobile)),

        SliverToBoxAdapter(child: SizedBox(height: mobile ? 24 : 32)),

        // Footer
        const SliverToBoxAdapter(child: _Footer()),

        const SliverToBoxAdapter(child: SizedBox(height: 56)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool mobile;
  const _HeroSection({required this.mobile});

  @override
  Widget build(BuildContext context) {
    final hPad = mobile ? 20.0 : 32.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "COMING SOON · QUANTSYNC" pill badge
          QtStaggeredEntrance(
            delayMs: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00D4AA).withOpacity(0.26),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing green dot
                  _GreenDot(),
                  const SizedBox(width: 7),
                  Text(
                    'COMING SOON  ·  QUANTSYNC',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF00D4AA),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: mobile ? 18 : 22),

          // Main headline
          QtStaggeredEntrance(
            delayMs: 120,
            child: Text(
              'Do more with QuanTrade,\neverywhere you trade',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: mobile ? 25 : 34,
                fontWeight: FontWeight.w800,
                height: 1.17,
                letterSpacing: -0.6,
              ),
            ),
          ),

          SizedBox(height: mobile ? 12 : 16),

          // Sub-headline
          QtStaggeredEntrance(
            delayMs: 240,
            child: Text(
              'AI-powered market intelligence, real-time signals\nand portfolio analytics — built for serious traders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.46),
                fontSize: mobile ? 13 : 15,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pulsing green dot widget
class _GreenDot extends StatefulWidget {
  @override
  State<_GreenDot> createState() => _GreenDotState();
}

class _GreenDotState extends State<_GreenDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF00D4AA).withOpacity(_pulse.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.5 * _pulse.value),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Feature Section  (main card + 2 smaller cards — Claude Code layout)
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureSection extends StatelessWidget {
  final bool mobile;
  const _FeatureSection({required this.mobile});

  @override
  Widget build(BuildContext context) {
    final hPad = mobile ? 14.0 : 22.0;
    final mainCard   = _MainFeatureCard(mobile: mobile);
    const smallCard1 = _SmallFeatureCard(
      title: 'Portfolio Analytics',
      body: 'Track positions, P&L, and risk metrics across all your portfolios in one unified dashboard.',
      icon: Icons.pie_chart_outline_rounded,
      accentColor: Color(0xFF3B82F6),
      buttonLabel: 'Notify Me',
      delayMs: 400,
    );
    const smallCard2 = _SmallFeatureCard(
      title: 'Market Signals · Pro',
      body: 'Real-time AI signals covering equities, crypto, commodities, and forex markets.',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFFF59E0B),
      buttonLabel: 'Upgrade',
      isPro: true,
      delayMs: 520,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: mobile
          ? Column(children: [
              mainCard,
              const SizedBox(height: 12),
              smallCard1,
              const SizedBox(height: 12),
              smallCard2,
            ])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 54, child: mainCard),
                const SizedBox(width: 12),
                const Expanded(
                  flex: 46,
                  child: Column(children: [
                    smallCard1,
                    SizedBox(height: 12),
                    smallCard2,
                  ]),
                ),
              ],
            ),
    );
  }
}

// ── Main Feature Card ("QuanTrade Terminal") ──────────────────────────────────

class _MainFeatureCard extends StatelessWidget {
  final bool mobile;
  const _MainFeatureCard({required this.mobile});

  @override
  Widget build(BuildContext context) {
    return QtStaggeredEntrance(
      delayMs: 280,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.04),
              blurRadius: 48,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top panel: title + description + buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                  mobile ? 18 : 20, 20, mobile ? 18 : 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      const Icon(Icons.candlestick_chart_rounded,
                          color: Color(0xFF00D4AA), size: 19),
                      const SizedBox(width: 8),
                      Text(
                        'QuanTrade Terminal',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyse, trade, and manage risk from your\nterminal or mobile — all in one place.',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary button
                  QtPrimaryButton(
                    label: 'Get Early Access',
                    onTap: () {},
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'Or try it in',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.28),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Platform chips — 2 per row on mobile
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      QtPlatformChip(
                          icon: Icons.terminal_rounded, label: 'Terminal'),
                      QtPlatformChip(
                          icon: Icons.phone_android_rounded, label: 'Mobile'),
                      QtPlatformChip(
                          icon: Icons.web_rounded, label: 'Web App'),
                      QtPlatformChip(
                          icon: Icons.desktop_windows_rounded,
                          label: 'Desktop'),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // Terminal mock panel — from animation file
            const QtTerminalPanel(),
          ],
        ),
      ),
    );
  }
}

// ── Small Feature Card ─────────────────────────────────────────────────────

class _SmallFeatureCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color accentColor;
  final String buttonLabel;
  final bool isPro;
  final int delayMs;

  const _SmallFeatureCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accentColor,
    required this.buttonLabel,
    required this.delayMs,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return QtStaggeredEntrance(
      delayMs: delayMs,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: accentColor.withOpacity(0.30),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.jetBrainsMono(
                        color: accentColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.46),
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            QtSecondaryButton(
              label: buttonLabel,
              accentColor: accentColor,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CTA Banner
// ─────────────────────────────────────────────────────────────────────────────

class _CtaBanner extends StatelessWidget {
  final bool mobile;
  const _CtaBanner({required this.mobile});

  @override
  Widget build(BuildContext context) {
    final hPad = mobile ? 14.0 : 22.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: QtStaggeredEntrance(
        delayMs: 620,
        child: QtPulseScale(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 20 : 32,
              vertical: 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4AA).withOpacity(0.09),
                  const Color(0xFF3B82F6).withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: Color(0xFF00D4AA), size: 38),
                const SizedBox(height: 14),
                Text(
                  'QuanTrade is almost here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: mobile ? 19 : 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to access AI-powered market insights,\nsignals, and portfolio tools for serious investors.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: mobile ? 12.5 : 14,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 22),
                QtPrimaryButton(
                  label: 'Join the Waitlist',
                  onTap: () {},
                  icon: Icons.arrow_forward_rounded,
                  fullWidth: mobile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Footer
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return QtStaggeredEntrance(
      delayMs: 740,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by  ',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.22),
              fontSize: 11.5,
            ),
          ),
          QtCandleLogo(
            size: 14,
            color: Colors.white.withOpacity(0.38),
          ),
          const SizedBox(width: 5),
          Text(
            'QuantSync',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.38),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

