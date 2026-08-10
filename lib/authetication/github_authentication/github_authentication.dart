import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// Import animations
import '../../screens/animations/planetary_animation/planetary_animation.dart';
import '../../screens/animations/animation_effects/typing_animation.dart';

// Import buttons
import 'signin_github_button.dart';
import 'signup_github_button.dart';

class GithubAuthenticationScreen extends StatefulWidget {
  const GithubAuthenticationScreen({super.key});

  @override
  State<GithubAuthenticationScreen> createState() => _GithubAuthenticationScreenState();
}

class _GithubAuthenticationScreenState extends State<GithubAuthenticationScreen> {
  bool isLogin = true;

  Future<void> _handleAuth() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? 'https://quantmessage-app.vercel.app' : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error authenticating with GitHub: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Make responsive
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
          // Background Planetary Animation
          const Positioned.fill(
            child: PlanetaryAnimation(size: 380),
          ),
          
          // Gradient Overlay for contrast
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xAA000000), // Dark at top
                    Color(0x66000000), // Semi-transparent middle
                    Color(0xDD000000), // Dark at bottom
                  ],
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Fast Typing Animation
                      TypingText(
                        text: '< Github Authentication >',
                        typingSpeed: const Duration(milliseconds: 30),
                        style: GoogleFonts.tinos(
                          fontSize: isDesktop ? 40 : 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Dynamic subtitle
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          isLogin ? 'Sign in to your existing account' : 'Create a new account',
                          key: ValueKey(isLogin),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Glassmorphism Buttons
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isLogin
                            ? SigninGithubButton(
                                key: const ValueKey('signin'),
                                onPressed: _handleAuth,
                              )
                            : SignupGithubButton(
                                key: const ValueKey('signup'),
                                onPressed: _handleAuth,
                              ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Toggle Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: Text(
                          isLogin
                              ? "Don't have an account? Sign Up"
                              : "Already have an account? Sign In",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
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
