import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/donor.dart';
import '../models/donation.dart';
import '../models/enums.dart';
import '../config/constants.dart';
import 'auth_service.dart';

/// Service for donor CRUD operations and donation tracking via Supabase.
class DonorService {
  final SupabaseClient _client;

  DonorService(this._client);

  /// Fetch all donors, ordered by name.
  Future<List<Donor>> getDonors({
    String? searchQuery,
    DonorType? typeFilter,
  }) async {
    var query = _client
        .from(AppConstants.donorsTable)
        .select();

    if (typeFilter != null) {
      query = query.eq('donor_type', typeFilter.dbValue);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query = query.or('name.ilike.$term,mobile.ilike.$term,email.ilike.$term');
    }

    final response = await query.order('name', ascending: true);
    return (response as List).map((json) => Donor.fromJson(json)).toList();
  }

  /// Fetch a single donor by ID.
  Future<Donor?> getDonorById(String id) async {
    final response = await _client
        .from(AppConstants.donorsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Donor.fromJson(response);
  }

  /// Create a new donor.
  Future<Donor> createDonor(Donor donor) async {
    final response = await _client
        .from(AppConstants.donorsTable)
        .insert(donor.toJson())
        .select()
        .single();

    return Donor.fromJson(response);
  }

  /// Update an existing donor.
  Future<Donor> updateDonor(Donor donor) async {
    final response = await _client
        .from(AppConstants.donorsTable)
        .update(donor.toJson())
        .eq('id', donor.id)
        .select()
        .single();

    return Donor.fromJson(response);
  }

  /// Delete a donor permanently.
  Future<void> deleteDonor(String id) async {
    await _client
        .from(AppConstants.donorsTable)
        .delete()
        .eq('id', id);
  }

  /// Get all donations for a specific donor.
  Future<List<Donation>> getDonorDonations(String donorId) async {
    final response = await _client
        .from(AppConstants.donationsTable)
        .select('*, projects(name), events(title)')
        .eq('donor_id', donorId)
        .order('donation_date', ascending: false);

    return (response as List).map((json) => Donation.fromJson(json)).toList();
  }

  /// Get total donation amount for a donor.
  Future<double> getDonorTotalDonated(String donorId) async {
    final response = await _client
        .from(AppConstants.donationsTable)
        .select('amount')
        .eq('donor_id', donorId)
        .eq('donation_type', 'cash');

    double total = 0;
    for (final row in (response as List)) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Create a new donation.
  Future<Donation> createDonation(Donation donation) async {
    final response = await _client
        .from(AppConstants.donationsTable)
        .insert(donation.toJson())
        .select()
        .single();

    return Donation.fromJson(response);
  }

  /// Delete a donation.
  Future<void> deleteDonation(String id) async {
    await _client
        .from(AppConstants.donationsTable)
        .delete()
        .eq('id', id);
  }

  /// Get total donor count.
  Future<int> getDonorCount() async {
    final response = await _client
        .from(AppConstants.donorsTable)
        .select('id');

    return (response as List).length;
  }

  /// Get total donations amount (all donors).
  Future<double> getTotalDonations() async {
    final response = await _client
        .from(AppConstants.donationsTable)
        .select('amount')
        .eq('donation_type', 'cash');

    double total = 0;
    for (final row in (response as List)) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Find a donor by mobile number (for auto-create flow in event donations).
  Future<Donor?> findByMobile(String mobile) async {
    final response = await _client
        .from(AppConstants.donorsTable)
        .select()
        .eq('mobile', mobile)
        .maybeSingle();

    if (response == null) return null;
    return Donor.fromJson(response);
  }

  /// Check if a mobile number already exists (for duplicate detection).
  Future<bool> isMobileNumberTaken(String mobile, {String? excludeDonorId}) async {
    var query = _client
        .from(AppConstants.donorsTable)
        .select('id')
        .eq('mobile', mobile);

    if (excludeDonorId != null) {
      query = query.neq('id', excludeDonorId);
    }

    final response = await query.limit(1);
    return (response as List).isNotEmpty;
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────

/// Provider for the DonorService.
final donorServiceProvider = Provider<DonorService>((ref) {
  return DonorService(ref.watch(supabaseClientProvider));
});

/// Parameters for donor list query.
class DonorListParams {
  final String? searchQuery;
  final DonorType? typeFilter;

  const DonorListParams({this.searchQuery, this.typeFilter});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonorListParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          typeFilter == other.typeFilter;

  @override
  int get hashCode => searchQuery.hashCode ^ typeFilter.hashCode;
}

/// Future provider for the donor list.
final donorListProvider = FutureProvider.family<List<Donor>, DonorListParams>((ref, params) async {
  return ref.watch(donorServiceProvider).getDonors(
    searchQuery: params.searchQuery,
    typeFilter: params.typeFilter,
  );
});

/// Future provider for a single donor.
final donorDetailProvider = FutureProvider.family<Donor?, String>((ref, donorId) async {
  return ref.watch(donorServiceProvider).getDonorById(donorId);
});

/// Future provider for a donor's donations.
final donorDonationsProvider = FutureProvider.family<List<Donation>, String>((ref, donorId) async {
  return ref.watch(donorServiceProvider).getDonorDonations(donorId);
});

/// Future provider for a donor's total donated.
final donorTotalDonatedProvider = FutureProvider.family<double, String>((ref, donorId) async {
  return ref.watch(donorServiceProvider).getDonorTotalDonated(donorId);
});

/// Future provider for donor count.
final donorCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(donorServiceProvider).getDonorCount();
});

/// Future provider for total donations.
final totalDonationsProvider = FutureProvider<double>((ref) async {
  return ref.watch(donorServiceProvider).getTotalDonations();
});
