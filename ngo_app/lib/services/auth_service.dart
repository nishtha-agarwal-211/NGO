import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/member.dart';

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
    String? redirectTo;
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        redirectTo = uri.origin;
      }
    } else {
      redirectTo = 'io.supabase.ngoapp://login-callback';
    }

    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
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

  /// Fetch complete user profile data including associated member details.
  Future<UserProfileData?> getCurrentUserProfileData() async {
    final user = currentUser;
    if (user == null) return null;

    MemberRole role = MemberRole.member;
    String? memberId;

    try {
      final profileRes = await _client
          .from('profiles')
          .select('role, member_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRes != null) {
        if (profileRes['role'] != null) {
          role = MemberRole.fromString(profileRes['role'] as String);
        }
        memberId = profileRes['member_id'] as String?;
      }
    } catch (_) {}

    Member? member;
    try {
      if (memberId != null) {
        final memberRes = await _client
            .from('members')
            .select()
            .eq('id', memberId)
            .maybeSingle();
        if (memberRes != null) {
          member = Member.fromJson(memberRes);
        }
      }

      if (member == null && user.email != null && user.email!.isNotEmpty) {
        final memberRes = await _client
            .from('members')
            .select()
            .or('auth_user_id.eq.${user.id},email.eq.${user.email}')
            .limit(1)
            .maybeSingle();
        if (memberRes != null) {
          member = Member.fromJson(memberRes);
        }
      }
    } catch (_) {}

    return UserProfileData(
      user: user,
      role: role,
      member: member,
    );
  }
}

/// Data bundle containing the current user's auth user, role, and linked member profile.
class UserProfileData {
  final User user;
  final MemberRole role;
  final Member? member;

  const UserProfileData({
    required this.user,
    required this.role,
    this.member,
  });

  String get displayName {
    if (member != null && member!.name.isNotEmpty) {
      return member!.name;
    }
    final metaName = user.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.isNotEmpty) {
      return metaName;
    }
    if (user.email != null && user.email!.contains('@')) {
      final prefix = user.email!.split('@').first;
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
    return 'User Profile';
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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

/// Future provider for current user's profile data.
final userProfileProvider = FutureProvider<UserProfileData?>((ref) async {
  return ref.watch(authServiceProvider).getCurrentUserProfileData();
});
