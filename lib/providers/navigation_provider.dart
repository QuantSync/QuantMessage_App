// lib/providers/navigation_provider.dart
// Shared tab navigation — keeps AppBar, HomeScreen, and deep links in sync.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canonical tabs in the main shell (order must match AppBar + HomeScreen pages).
enum AppTab {
  home,
  chat,
  incognito,
  history,
  settings,
}

extension AppTabX on AppTab {
  int get index => AppTab.values.indexOf(this);

  static AppTab fromIndex(int index) {
    if (index < 0 || index >= AppTab.values.length) return AppTab.home;
    return AppTab.values[index];
  }

  String get label {
    switch (this) {
      case AppTab.home:
        return 'Home';
      case AppTab.chat:
        return 'Chat';
      case AppTab.incognito:
        return 'Incognito';
      case AppTab.history:
        return 'History';
      case AppTab.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.home:
        return Icons.home_rounded;
      case AppTab.chat:
        return Icons.chat_bubble_rounded;
      case AppTab.incognito:
        return Icons.visibility_off_rounded;
      case AppTab.history:
        return Icons.history_rounded;
      case AppTab.settings:
        return Icons.settings_rounded;
    }
  }

  /// Tabs that require an authenticated Supabase session.
  bool get requiresAuth =>
      this == AppTab.chat || this == AppTab.history;
}

class NavigationNotifier extends StateNotifier<AppTab> {
  NavigationNotifier() : super(AppTab.home);

  void goTo(AppTab tab) {
    if (state == tab) return;
    state = tab;
  }

  void goToIndex(int index) => goTo(AppTabX.fromIndex(index));

  void goHome() => goTo(AppTab.home);
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, AppTab>(
  (ref) => NavigationNotifier(),
);

final navigationIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider).index;
});
