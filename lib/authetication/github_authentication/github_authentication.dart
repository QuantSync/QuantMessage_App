import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import animations
import '../../screens/animations/planetary_animation/planetary_animation.dart';
import '../../screens/animations/animation_effects/typing_animation.dart';
import '../../screens/home_screen.dart';

// Import auth service
import '../../providers/auth_provider.dart';

// Import buttons
import 'signin_github_button.dart';
import 'signup_github_button.dart';

class GithubAuthenticationScreen extends ConsumerStatefulWidget {
  const GithubAuthenticationScreen({super.key});

  @override
  ConsumerState<GithubAuthenticationScreen> createState() => _GithubAuthenticationScreenState();
}

class _GithubAuthenticationScreenState extends ConsumerState<GithubAuthenticationScreen> {
  bool isLogin = true;
  bool _isLoading = false;

  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        // 1. Upsert profile in Supabase (creates row for new users, updates for returning).
        await AuthService.upsertProfileOnLogin();

        if (!mounted) return;

        // 2. Mark which OAuth provider was used so the greeting card can display it.
        ref.read(lastAuthProviderProvider.notifier).state = 'github';

        // 3. Signal that this is a fresh login — chat screen will show the greeting card.
        ref.read(freshLoginProvider.notifier).state = true;

        // 4. Navigate to HomeScreen, clear the entire back-stack.
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: child,
            ),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // For web: redirect back to the Vercel app which Supabase then resolves.
      // For mobile: use null so Supabase uses the deep-link scheme.
      final redirectTo = kIsWeb
          ? 'https://quantmessage-app.vercel.app'
          : null;

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: redirectTo,
      );
      // On Web: the page will redirect away to GitHub — nothing more to do here.
      // On Mobile: the OS returns to the app via deep link → onAuthStateChange fires.
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error authenticating with GitHub: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ── Planetary Background ───────────────────────────────────────
          const Positioned.fill(
            child: PlanetaryAnimation(size: 380),
          ),

          // ── Dark Gradient Overlay ─────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Color(0x55000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── Foreground Content ────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 120 : 28.0,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // GitHub Octocat / Brand icon
                      const _GitHubBrandIcon(),

                      const SizedBox(height: 28),

                      // Fast Typing Title
                      TypingText(
                        text: '< Github Authentication >',
                        typingSpeed: const Duration(milliseconds: 28),
                        style: GoogleFonts.tinos(
                          fontSize: isDesktop ? 36 : 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Animated subtitle switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          isLogin
                              ? 'Sign in to your existing account'
                              : 'Create a brand new account',
                          key: ValueKey(isLogin),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            color: Colors.grey[400],
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Auth Button (Sign In / Sign Up) ────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            )),
                            child: child,
                          ),
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(color: Colors.white70),
                              )
                            : isLogin
                                ? SigninGithubButton(
                                    key: const ValueKey('signin'),
                                    onPressed: _handleAuth,
                                  )
                                : SignupGithubButton(
                                    key: const ValueKey('signup'),
                                    onPressed: _handleAuth,
                                  ),
                      ),

                      const SizedBox(height: 28),

                      // ── Toggle Sign In / Sign Up ───────────────────────
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => isLogin = !isLogin),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          isLogin
                              ? "Don't have an account?  Sign Up →"
                              : "Already have an account?  Sign In →",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Info note ─────────────────────────────────────
                      Text(
                        'Both Sign In & Sign Up use the same GitHub flow.\nSupabase automatically creates your account on first login.',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: Colors.white24,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
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

// ── GitHub Brand Icon Widget ─────────────────────────────────────────────────
class _GitHubBrandIcon extends StatelessWidget {
  const _GitHubBrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.10),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.code_rounded, // GitHub-ish icon (no official GitHub icon in Material)
        color: Colors.white,
        size: 36,
      ),
    );
  }
}
