import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';

/// Authentication service wrapping Supabase Auth.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Current authenticated user, if any.
  User? get currentUser => _client.auth.currentUser;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google OAuth.
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.ngoapp://login-callback',
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get the current user's role from the profiles table.
  Future<MemberRole> getCurrentUserRole() async {
    if (currentUser == null) return MemberRole.member;

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response == null) return MemberRole.member;
      return MemberRole.fromString(response['role'] as String);
    } catch (e) {
      return MemberRole.member;
    }
  }

  /// Check if current user is admin.
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == MemberRole.admin;
  }

  /// Get the member_id linked to the current user's profile.
  Future<String?> getCurrentMemberId() async {
    if (currentUser == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select('member_id')
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response?['member_id'] as String?;
    } catch (e) {
      return null;
    }
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────

/// Provider for the Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the AuthService.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Stream provider for auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provider for current user.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

/// Future provider for whether the current user is admin.
final isAdminProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).isAdmin();
});

/// Future provider for the current user's role.
final currentUserRoleProvider = FutureProvider<MemberRole>((ref) async {
  return ref.watch(authServiceProvider).getCurrentUserRole();
});
