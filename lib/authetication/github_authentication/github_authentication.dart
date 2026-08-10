import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GithubAuthenticationScreen extends StatefulWidget {
  const GithubAuthenticationScreen({super.key});

  @override
  State<GithubAuthenticationScreen> createState() => _GithubAuthenticationScreenState();
}

class _GithubAuthenticationScreenState extends State<GithubAuthenticationScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GitHub Authentication',
                style: GoogleFonts.tinos(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isLogin ? 'Sign in to your account' : 'Create a new account',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Implement actual GitHub Auth logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24292E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLogin ? 'Sign In with GitHub' : 'Sign Up with GitHub',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Sign In",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
