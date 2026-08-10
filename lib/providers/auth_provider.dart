// lib/providers/auth_provider.dart
//
// Central Riverpod provider for Supabase auth state.
// Any widget can watch `authUserProvider` to reactively respond to
// sign-in / sign-out events without manually subscribing to streams.
// ----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Raw auth stream — broadcasts the current User on every auth event.
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
// 2. Last auth provider — tracks which OAuth provider was used ("github" /
//    "google" / "email"). Used by the greeting card to display the correct
//    provider name to the user.
// ─────────────────────────────────────────────────────────────────────────────

final lastAuthProviderProvider = StateProvider<String>((ref) => 'github');

// ─────────────────────────────────────────────────────────────────────────────
// 3. Fresh login flag — true for exactly one session after OAuth completes.
//    Chat screen reads this to decide whether to show the greeting card.
//    Cleared after the greeting card is shown.
// ─────────────────────────────────────────────────────────────────────────────

final freshLoginProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// 4. Profile service — upserts the user profile on first OAuth login.
//    Called once from the auth screen immediately after signedIn fires.
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Called right after a successful OAuth sign-in.
  /// Creates or updates the `profiles` row so settings / history link to it.
  /// Returns true if this is a brand-new account (no existing profile row).
  static Future<bool> upsertProfileOnLogin({String provider = 'github'}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Pull display name from OAuth provider metadata.
    // GitHub sends 'name' or 'user_name'; Google sends 'full_name'.
    final meta = user.userMetadata ?? {};
    final name = (meta['full_name'] as String?)?.trim() ??
        (meta['name'] as String?)?.trim() ??
        (meta['user_name'] as String?)?.trim() ??
        user.email?.split('@').first ??
        'User';

    final avatarUrl = (meta['avatar_url'] as String?) ?? '';

    bool isNewUser = false;

    try {
      // Check if the profile already exists
      final existing = await _supabase
          .from('profiles')
          .select('id, onboarding_complete')
          .eq('id', user.id)
          .maybeSingle();

      isNewUser = existing == null;

      await _supabase.from('profiles').upsert(
        {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': name,
          'avatar_url': avatarUrl,
          'auth_provider': provider,  // Track auth method (github/google)
          'is_guest': false,
          'onboarding_complete': existing?['onboarding_complete'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );

      // Stamp user metadata so ChatScreen picks up the name instantly.
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'full_name': name,
          'auth_provider': provider,
          // Keep onboarding_complete from existing value; don't overwrite
          // a returning user's completed state.
          if (isNewUser) 'onboarding_complete': false,
        }),
      );
    } catch (e) {
      // Non-fatal — the session is still valid.
    }

    return isNewUser;
  }

  /// Creates a guest profile record in the profiles table so that backend
  /// foreign key constraints are satisfied when guest users send messages.
  /// Safe to call repeatedly — uses upsert to avoid duplicates.
  static Future<void> ensureGuestProfile() async {
    try {
      await _supabase.from('profiles').upsert(
        {
          'id': 'guest_user',
          'full_name': 'Guest',
          'auth_provider': 'guest',
          'is_guest': true,
          'onboarding_complete': false,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e) {
      // Non-fatal — guest mode still works even if this fails.
      debugPrint('[AuthService] ensureGuestProfile error (non-fatal): \$e');
    }
  }

  /// Saves workspace name and chat section name to the profiles table.
  static Future<void> saveWorkspaceDetails({
    required String workspaceName,
    required String chatSectionName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'workspace_name': workspaceName,
        'chat_section_name': chatSectionName,
        'onboarding_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      await _supabase.auth.updateUser(
        UserAttributes(data: {
          'workspace_name': workspaceName,
          'chat_section_name': chatSectionName,
          'onboarding_complete': true,
        }),
      );
    } catch (e) {
      // Non-fatal
    }
  }
}
