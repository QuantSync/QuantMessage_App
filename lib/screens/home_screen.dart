// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the custom buttons
import 'animations/animated_buttons/google_button.dart';
import 'animations/animated_buttons/github_button.dart';
import 'animations/animated_buttons/app_settings_button.dart';
import 'animations/planetary_animation/planetary_animation.dart';


import '../providers/attachment_provider.dart';
import '../providers/navigation_provider.dart';
import 'app_bar.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'incognito_screen.dart';
import 'signin_screen.dart';
import 'settings_screen.dart';
import '../authetication/google_authentication/google_authentication.dart';
import '../authetication/github_authentication/github_authentication.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Pages stay alive in IndexedStack so chat / history state survives tab switches.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Align shared tab index when the shell mounts (splash / auth → home)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationProvider.notifier).goHome();
    });
    _pages = [
      DashboardTab(onStartChat: () => _selectTab(AppTab.chat, bypassAuth: true)),
      const ChatScreen(),
      IncognitoScreen(onExit: () => _selectTab(AppTab.home)),
      const HistoryScreen(embedded: true),
      const SettingsScreen(embedded: true),
    ];
  }

  Future<void> _selectTab(AppTab tab, {bool bypassAuth = false}) async {
    final current = ref.read(navigationProvider);
    if (current == tab && tab != AppTab.settings) return;

    if (!bypassAuth && tab.requiresAuth) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (!mounted) return;
        await Navigator.push(context, smoothPageRoute(const SignInScreen()));
        return;
      }
    }

    // Settings opens as a floating panel — keep the current tab selected
    if (tab == AppTab.settings) {
      await showSettingsPopup(context);
      return;
    }

    ref.read(navigationProvider.notifier).goTo(tab);
  }

  void _onItemSelected(int index) {
    _selectTab(AppTabX.fromIndex(index));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    final currentTab = ref.watch(navigationProvider);
    final currentIndex = currentTab.index;

    // Keep shared model provider warm across tabs
    ref.watch(selectedModelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: isDesktop
          ? Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 80),
                    child: _ShellPageHost(
                      currentIndex: currentIndex,
                      pages: _pages,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: CustomAppBar(
                    selectedIndex: currentIndex,
                    onItemSelected: _onItemSelected,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ShellPageHost(
                      currentIndex: currentIndex,
                      pages: _pages,
                    ),
                  ),
                ),
                CustomAppBar(
                  selectedIndex: currentIndex,
                  onItemSelected: _onItemSelected,
                ),
              ],
            ),
    );
  }
}

/// Keeps all shell pages mounted so chat/history survive tab switches.
class _ShellPageHost extends StatelessWidget {
  final int currentIndex;
  final List<Widget> pages;

  const _ShellPageHost({
    required this.currentIndex,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      sizing: StackFit.expand,
      children: pages,
    );
  }
}

class DashboardTab extends ConsumerStatefulWidget {
  final VoidCallback onStartChat;
  const DashboardTab({super.key, required this.onStartChat});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _gridOpacity;
  late final Animation<double> _gridScale;
  late final Animation<double> _btnOpacity;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _titleOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic)),
    );

    _subtitleOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.08, 0.35, curve: Curves.easeOut));
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.08, 0.38, curve: Curves.easeOutCubic)),
    );

    _gridOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.16, 0.65, curve: Curves.easeOut));
    _gridScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.16, 0.65, curve: Curves.easeOutBack)),
    );

    _btnOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.42, 1.0, curve: Curves.easeOut));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.42, 1.0, curve: Curves.easeOutCubic)),
    );

    _entranceCtrl.forward();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.0, upperBound: 1.0);
    _btnScale = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Planetary Background ──────────────────────────────────────
          const Positioned.fill(
            child: PlanetaryAnimation(size: 380),
          ),
          // ── Dark gradient overlay for contrast ────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xAA000000), // strong dark at top for title
                    Color(0x55000000), // semi-transparent mid section
                    Color(0xBB000000), // dark at bottom for buttons
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Restored smooth scrolling
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // 1. Header & Subtitle
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _titleOpacity,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _ShimmerText(
                                  controller: _shimmerCtrl,
                                  text: "< Welcome to QUANTMESSAGE >",
                                  style: GoogleFonts.tinos(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FadeTransition(
                            opacity: _subtitleOpacity,
                            child: SlideTransition(
                              position: _subtitleSlide,
                              child: Text(
                                "< Messaging in Modern Era >",
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.45),
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 2. Feature Grid (Full 4 Card Grid)
                      FadeTransition(
                        opacity: _gridOpacity,
                        child: ScaleTransition(
                          scale: _gridScale,
                          child: const _FeatureGrid(isCompact: false),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 3. Action Buttons Section
                      FadeTransition(
                        opacity: _btnOpacity,
                        child: SlideTransition(
                          position: _btnSlide,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LaunchChatButton(
                                btnCtrl: _btnCtrl,
                                btnScale: _btnScale,
                                onTap: widget.onStartChat,
                                label: " < GUEST USER >",
                                height: 54,
                              ),
                              const SizedBox(height: 12),
                              // Responsive auth buttons
                              LayoutBuilder(
                                builder: (context, authConstraints) {
                                  final rowWidth = math.min(
                                    340.0,
                                    authConstraints.maxWidth > 0
                                        ? authConstraints.maxWidth
                                        : 340.0,
                                  );
                                  return SizedBox(
                                    width: rowWidth,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GoogleButton(
                                            label: 'Google',
                                            height: 44,
                                            borderRadius: 14,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                smoothPageRoute(
                                                    const GoogleAuthenticationScreen()),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: GithubButton.dark(
                                            label: 'GitHub',
                                            height: 44,
                                            borderRadius: 14,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                smoothPageRoute(
                                                    const GithubAuthenticationScreen()),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              AppSettingsButton(
                                height: 50,
                                width: 230,
                                onPressed: () {
                                  showSettingsPopup(context);
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _LaunchChatButton extends StatelessWidget {
  final AnimationController btnCtrl;
  final Animation<double> btnScale;
  final VoidCallback onTap;
  final String label;
  final double height;

  const _LaunchChatButton({
    required this.btnCtrl,
    required this.btnScale,
    required this.onTap,
    required this.label,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => btnCtrl.forward(),
      onTapUp: (_) async {
        await btnCtrl.reverse();
        onTap();
      },
      onTapCancel: () => btnCtrl.reverse(),
      child: ScaleTransition(
        scale: btnScale,
        child: Container(
          width: 220,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF257BFA)]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: height < 50 ? 15 : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerText extends AnimatedWidget {
  final String text;
  final TextStyle style;
  const _ShimmerText({required AnimationController controller, required this.text, required this.style}) : super(listenable: controller);
  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    final shimmerOffset = t * 3.0 - 1.0;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(-1.5 + shimmerOffset * 2, 0),
        end: Alignment(0.5 + shimmerOffset * 2, 0),
        colors: const [Color(0xFFFFFFFF), Color(0xFFCCCCCC), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFE8E8FF), Color(0xFFFFFFFF)],
        stops: const [0.0, 0.35, 0.48, 0.52, 0.65, 1.0],
      ).createShader(bounds),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

class _FeatureGrid extends StatefulWidget {
  final bool isCompact;
  const _FeatureGrid({this.isCompact = false});

  @override
  State<_FeatureGrid> createState() => _FeatureGridState();
}

class _FeatureGridState extends State<_FeatureGrid> with TickerProviderStateMixin {
  static const _cards = [
    (Icons.auto_awesome, "AI Powered", "Cognitive reasoning for every message."),
    (Icons.lock_outline, "Ultra Private", "End-to-end encryption by default."),
    (Icons.bolt, "Quant Speed", "Instant delivery across the globe."),
    (Icons.blur_on, "Low Latency", "QuantMessage Welcomes You "),
  ];
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _opacities;
  late final List<Animation<Offset>> _slides;
  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_cards.length, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));
    _opacities = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _slides = _ctrls.map((c) => Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();
    for (int i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () { if (mounted) _ctrls[i].forward(); });
    }
  }
  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.isCompact ? 10 : 16,
      runSpacing: widget.isCompact ? 10 : 16,
      alignment: WrapAlignment.center,
      children: List.generate(_cards.length, (i) {
        final (icon, title, desc) = _cards[i];
        return FadeTransition(
          opacity: _opacities[i],
          child: SlideTransition(
            position: _slides[i],
            child: _GlassCard(
              icon: icon,
              title: title,
              desc: desc,
              isCompact: widget.isCompact,
            ),
          ),
        );
      }),
    );
  }
}

class _GlassCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isCompact;

  const _GlassCard({
    required this.icon,
    required this.title,
    required this.desc,
    this.isCompact = false,
  });

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = widget.isCompact ? 140.0 : 160.0;
    final double paddingVal = widget.isCompact ? 12.0 : 18.0;

    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (_, __) {
            final t = _glow.value;
            return AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 140),
              child: SizedBox(
                width: cardWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(paddingVal),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05 + t * 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.10 + t * 0.14)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, color: Colors.white, size: widget.isCompact ? 22 : 28),
                          SizedBox(height: widget.isCompact ? 8 : 12),
                          Text(
                            widget.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.isCompact ? 13 : 15,
                            ),
                          ),
                          SizedBox(height: widget.isCompact ? 4 : 6),
                          Text(
                            widget.desc,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: widget.isCompact ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


