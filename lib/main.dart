// lib/main.dart
// QuantMessage.Ai — isme sare states configured hain (Config, Riverpod, routes)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'core/config.dart' as app_config;
import 'screens/app_bar.dart' show smoothPageRoute;
import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/pricing_screen/pricing_screen.dart';
import 'providers/theme_provider.dart';


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

class QuantSpaceApp extends ConsumerWidget {
  const QuantSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'QuantMessage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return smoothPageRoute(const HomeScreen());
          case '/signin':
            return smoothPageRoute(const SignInScreen());
          case '/signup':
            return smoothPageRoute(const SignUpScreen());
          case '/pricing':
            return smoothPageRoute(const PricingScreen());
          default:
            return null;
        }
      },
    );
  }
}
