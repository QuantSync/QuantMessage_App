import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;

class AppTheme {
  // ye COLOR PALETTE HAI (High-Contrast Monochrome) tinge ka
  static const Color primaryWhite = Colors.white;
  static const Color accentGrey = Color(0xFFBDBDBD);
  static const Color borderGrey = Color(0xFF424242);
  static const Color surfaceLight = Color(0xFF242424);
  static const Color surfaceMedium = Color(0xFF161616);
  static const Color surfaceDark = Color(0xFF0A0A0A);
  static const Color backgroundBlack = Color(0xFF000000);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white60;

  // Backward Compatibility
  static const Color primaryRed = primaryWhite;
  static const Color redGradientEnd = accentGrey;
  static const Color backgroundBlackAlt = backgroundBlack;

  static ThemeData dark() {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryWhite,
        secondary: primaryWhite,
        surface: surfaceDark,
        background: backgroundBlack,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundBlack,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 2.0,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.orbitron(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: textSecondary),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
      ),
    );
  }
}

class QuantUI {
  // 1. The "System Online" style badge
  static Widget badge({required String text}) {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  static Widget bracketText({
    required String text,
    double fontSize = 24,
    double opacity = 1.0,
    bool isBold = false,
    bool animated = true,
  }) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("< ", style: GoogleFonts.orbitron(fontSize: fontSize, color: Colors.white.withOpacity(0.4))),
        Text(
          text,
          style: GoogleFonts.orbitron(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.white.withOpacity(opacity),
          ),
        ),
        Text(" >", style: GoogleFonts.orbitron(fontSize: fontSize, color: Colors.white.withOpacity(0.4))),
      ],
    );

    return animated ? FadeIn(duration: const Duration(milliseconds: 1500), child: content) : content;
  }

  // 3. action buttton ka design
  static Widget actionButton({
    required String label,
    required VoidCallback onPressed,
    bool primary = true,
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: primary ? Colors.white : Colors.transparent,
        foregroundColor: primary ? Colors.black : Colors.white,
        side: BorderSide(color: primary ? Colors.white : Colors.white30),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ],
      ),
    );
  }

  // 4. Particle Background Effect
  static Widget particleBackground({int count = 20}) {
    return Stack(
      children: List.generate(count, (index) {
        final random = math.Random();
        return Positioned(
          top: random.nextDouble() * 1000,
          left: random.nextDouble() * 500,
          child: FadeIn(
            duration: Duration(milliseconds: 1000 + random.nextInt(2000)),
            child: Container(
              width: random.nextDouble() * 3,
              height: random.nextDouble() * 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }

  static Route createFadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 1000),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }
}