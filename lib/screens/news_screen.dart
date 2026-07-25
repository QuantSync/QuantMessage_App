// lib/screens/news_screen.dart
// QuantMessage — News Screen (Coming soon placeholder)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

// ---------------------------------------------------------------------------
// NewsScreen
// ---------------------------------------------------------------------------

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      extendBodyBehindAppBar: true,
      appBar: _buildNewsAppBar(context),
      body: Stack(
        children: [
          const Positioned.fill(child: _NewsBackground()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: const _NewsContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildNewsAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.65),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '< ',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                  TextSpan(
                    text: 'NEWS',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  TextSpan(
                    text: ' >',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _NewsContent extends StatelessWidget {
  const _NewsContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 16)),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'LATEST UPDATES',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Placeholder shimmer cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _NewsPlaceholderCard(index: index),
            childCount: 4,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(child: _ComingSoonBanner()),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder card
// ---------------------------------------------------------------------------

class _NewsPlaceholderCard extends StatefulWidget {
  final int index;
  const _NewsPlaceholderCard({required this.index});

  @override
  State<_NewsPlaceholderCard> createState() => _NewsPlaceholderCardState();
}

class _NewsPlaceholderCardState extends State<_NewsPlaceholderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  static const List<double> _widths = [0.72, 0.55, 0.65, 0.48];
  static const List<String> _tags = ['AI', 'Tech', 'Research', 'Updates'];
  static const List<Color> _tagColors = [
    Color(0xFF2ECC71),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tag = _tags[widget.index % _tags.length];
    final tagColor = _tagColors[widget.index % _tagColors.length];
    final lineW = _widths[widget.index % _widths.length];

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (ctx, _) {
        final t = _shimmerCtrl.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: tagColor.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.outfit(
                        color: tagColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _shimmerBar(context, 0.22, 10, t),
                ],
              ),
              const SizedBox(height: 12),
              _shimmerBar(context, lineW, 14, t),
              const SizedBox(height: 6),
              _shimmerBar(context, lineW * 0.75, 14, t),
              const SizedBox(height: 10),
              _shimmerBar(context, 0.88, 10, t),
              const SizedBox(height: 4),
              _shimmerBar(context, 0.6, 10, t),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBar(
      BuildContext context, double widthFraction, double height, double t) {
    final screenW = MediaQuery.of(context).size.width;
    return Container(
      width: (screenW - 80) * widthFraction,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + t * 3.0, 0),
          end: Alignment(0.5 + t * 3.0, 0),
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coming soon banner
// ---------------------------------------------------------------------------

class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2ECC71).withValues(alpha: 0.08),
              const Color(0xFF06B6D4).withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2ECC71).withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.newspaper_rounded,
              color: Color(0xFF2ECC71),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              '< COMING SOON >',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Curated AI & tech news will appear here.\nStay tuned for the live feed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background glows
// ---------------------------------------------------------------------------

class _NewsBackground extends StatelessWidget {
  const _NewsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2ECC71).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
