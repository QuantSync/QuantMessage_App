// lib/providers/auth_provider.dart
//
// Central Riverpod provider for Supabase auth state.
// Any widget can watch `authUserProvider` to reactively respond to
// sign-in / sign-out events without manually subscribing to streams.
// ----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Raw session provider — true when a Supabase session exists.
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the current Supabase [User], or null if not authenticated.
/// Automatically rebuilds all watchers on sign-in / sign-out.
final authUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});

/// Convenience provider — true when the user is fully authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. Profile service — upserts the user profile on first OAuth login.
//    Called once from the auth screen immediately after signedIn fires.
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Called right after a successful OAuth sign-in.
  /// Creates or updates the `profiles` row so settings / history link to it.
  static Future<void> upsertProfileOnLogin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Pull display name from OAuth provider metadata (GitHub sends 'name' or
    // 'user_name'; Google sends 'full_name').
    final meta = user.userMetadata ?? {};
    final name = (meta['full_name'] as String?)?.trim() ??
        (meta['name'] as String?)?.trim() ??
        (meta['user_name'] as String?)?.trim() ??
        user.email?.split('@').first ??
        'User';

    final avatarUrl = (meta['avatar_url'] as String?) ?? '';

    try {
      await _supabase.from('profiles').upsert(
        {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': name,
          'avatar_url': avatarUrl,
          'onboarding_complete': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id', // update on re-login; insert on first login
      );

      // Also stamp the user metadata so ChatScreen picks up the name instantly.
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'full_name': name,
          'onboarding_complete': true,
        }),
      );
    } catch (e) {
      // Non-fatal — profile may already exist with RLS restrictions.
      // The session itself is valid; the user can still use the app.
    }
  }
}
