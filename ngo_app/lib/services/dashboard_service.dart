import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

/// Dashboard statistics fetched in a single RPC round-trip.
class DashboardStats {
  final int memberCount;
  final int donorCount;
  final int activeProjectCount;
  final int thisMonthEvents;
  final double totalDonations;

  const DashboardStats({
    required this.memberCount,
    required this.donorCount,
    required this.activeProjectCount,
    required this.thisMonthEvents,
    required this.totalDonations,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      donorCount: (json['donor_count'] as num?)?.toInt() ?? 0,
      activeProjectCount: (json['active_project_count'] as num?)?.toInt() ?? 0,
      thisMonthEvents: (json['this_month_events'] as num?)?.toInt() ?? 0,
      totalDonations: (json['total_donations'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Single provider for all dashboard scalar stats.
///
/// Calls the `get_dashboard_stats` Postgres RPC, returning all five
/// metrics in one round-trip instead of five separate queries.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client.rpc('get_dashboard_stats');
  return DashboardStats.fromJson(response as Map<String, dynamic>);
});
