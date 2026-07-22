import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';
import '../models/enums.dart';
import '../config/constants.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

/// Service for member CRUD operations via Supabase.
class MemberService {
  final SupabaseClient _client;

  MemberService(this._client);

  /// Fetch all members, ordered by name.
  Future<List<Member>> getMembers({
    String? searchQuery,
    MemberRole? roleFilter,
    bool? isActive,
  }) async {
    var query = _client
        .from(AppConstants.membersTable)
        .select();

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    if (roleFilter != null) {
      query = query.eq('role', roleFilter.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query = query.or('name.ilike.$term,mobile.ilike.$term,email.ilike.$term');
    }

    final response = await query.order('name', ascending: true);

    return (response as List).map((json) => Member.fromJson(json)).toList();
  }

  /// Fetch a single member by ID.
  Future<Member?> getMemberById(String id) async {
    final response = await _client
        .from(AppConstants.membersTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Member.fromJson(response);
  }

  /// Create a new member.
  Future<Member> createMember(Member member) async {
    final response = await _client
        .from(AppConstants.membersTable)
        .insert(member.toJson())
        .select()
        .single();

    return Member.fromJson(response);
  }

  /// Update an existing member.
  Future<Member> updateMember(Member member) async {
    final response = await _client
        .from(AppConstants.membersTable)
        .update(member.toJson())
        .eq('id', member.id)
        .select()
        .single();

    return Member.fromJson(response);
  }

  /// Delete a member (soft-delete by setting is_active = false).
  Future<void> deactivateMember(String id) async {
    await _client
        .from(AppConstants.membersTable)
        .update({'is_active': false})
        .eq('id', id);
  }

  /// Hard-delete a member (permanent).
  Future<void> deleteMember(String id) async {
    await _client
        .from(AppConstants.membersTable)
        .delete()
        .eq('id', id);
  }

  /// Get members with upcoming birthdays within N days.
  Future<List<Member>> getUpcomingBirthdays({int withinDays = 7}) async {
    // Fetch all active members who have a DOB set, then filter client-side
    // (Supabase/Postgres date comparison for recurring dates is complex,
    //  and with a few thousand members this is acceptable)
    final response = await _client
        .from(AppConstants.membersTable)
        .select()
        .eq('is_active', true)
        .not('date_of_birth', 'is', null)
        .order('date_of_birth', ascending: true);

    final members = (response as List).map((json) => Member.fromJson(json)).toList();
    return members.where((m) => m.isBirthdayWithin(withinDays)).toList()
      ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
  }

  /// Get members with upcoming anniversaries within N days.
  Future<List<Member>> getUpcomingAnniversaries({int withinDays = 7}) async {
    final response = await _client
        .from(AppConstants.membersTable)
        .select()
        .eq('is_active', true)
        .not('wedding_anniversary', 'is', null)
        .order('wedding_anniversary', ascending: true);

    final members = (response as List).map((json) => Member.fromJson(json)).toList();
    return members.where((m) => m.isAnniversaryWithin(withinDays)).toList();
  }

  /// Upload a member profile photo and return the public URL.
  Future<String> uploadProfilePhoto(String memberId, XFile file) async {
    final storagePath = SupabaseConfig.memberPhotoPath(memberId);
    final bytes = await file.readAsBytes();

    await _client.storage
        .from(SupabaseConfig.memberPhotosBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final url = _client.storage
        .from(SupabaseConfig.memberPhotosBucket)
        .getPublicUrl(storagePath);

    return url;
  }

  /// Get total member count.
  Future<int> getMemberCount() async {
    final response = await _client
        .from(AppConstants.membersTable)
        .select('id')
        .eq('is_active', true);

    return (response as List).length;
  }

  /// Check if a mobile number already exists (for another member).
  Future<bool> isMobileNumberTaken(String mobile, {String? excludeMemberId}) async {
    var query = _client
        .from(AppConstants.membersTable)
        .select('id')
        .eq('mobile', mobile);

    if (excludeMemberId != null) {
      query = query.neq('id', excludeMemberId);
    }

    final response = await query.limit(1);
    return (response as List).isNotEmpty;
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────

/// Provider for the MemberService.
final memberServiceProvider = Provider<MemberService>((ref) {
  return MemberService(ref.watch(supabaseClientProvider));
});

/// Future provider for the full member list.
final memberListProvider = FutureProvider.family<List<Member>, MemberListParams>((ref, params) async {
  return ref.watch(memberServiceProvider).getMembers(
    searchQuery: params.searchQuery,
    roleFilter: params.roleFilter,
    isActive: params.isActive,
  );
});

/// Future provider for a single member.
final memberDetailProvider = FutureProvider.family<Member?, String>((ref, memberId) async {
  return ref.watch(memberServiceProvider).getMemberById(memberId);
});

/// Future provider for upcoming birthdays.
final upcomingBirthdaysProvider = FutureProvider<List<Member>>((ref) async {
  return ref.watch(memberServiceProvider).getUpcomingBirthdays();
});

/// Future provider for upcoming anniversaries.
final upcomingAnniversariesProvider = FutureProvider<List<Member>>((ref) async {
  return ref.watch(memberServiceProvider).getUpcomingAnniversaries();
});

/// Future provider for member count.
final memberCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(memberServiceProvider).getMemberCount();
});

/// Parameters for member list query.
class MemberListParams {
  final String? searchQuery;
  final MemberRole? roleFilter;
  final bool? isActive;

  const MemberListParams({
    this.searchQuery,
    this.roleFilter,
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberListParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          roleFilter == other.roleFilter &&
          isActive == other.isActive;

  @override
  int get hashCode => searchQuery.hashCode ^ roleFilter.hashCode ^ isActive.hashCode;
}
