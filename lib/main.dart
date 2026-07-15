// lib/main.dart
// QuantMessage.Ai — App bootstrap (Config, Riverpod, routes)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'core/config.dart' as app_config;
import 'screens/app_bar.dart' show smoothPageRoute;
import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await app_config.Config.init();

  await Supabase.initialize(
    url: app_config.Config.supabaseUrl,
    anonKey: app_config.Config.supabaseAnonKey,
    debug: true,
  );

  if (!app_config.Config.isReady) {
    debugPrint(
      '⚠️ Missing config keys: ${app_config.Config.validateRequiredConfig()}',
    );
  }

  runApp(const ProviderScope(child: QuantSpaceApp()));
}

class QuantSpaceApp extends StatelessWidget {
  const QuantSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantCore.Ai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppTheme.primaryRed,
        scaffoldBackgroundColor: AppTheme.backgroundBlack,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryRed,
          brightness: Brightness.dark,
          surface: AppTheme.surfaceDark,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return smoothPageRoute(const HomeScreen());
          case '/signin':
            return smoothPageRoute(const SignInScreen());
          case '/signup':
            return smoothPageRoute(const SignUpScreen());
          default:
            return null;
        }
      },
    );
  }
}
