import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/event.dart';
import '../../services/dashboard_service.dart';
import '../../services/member_service.dart';
import '../../services/event_service.dart';
import '../../services/news_service.dart';
import '../../widgets/shimmer_widgets.dart';

/// Dashboard screen — shows key stats, upcoming events, recent birthdays,
/// and recent news. Serves as the app's main landing page.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'श्री श्याम सेवा समिति',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.push(AppRoutes.calendar),
            tooltip: 'Calendar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(upcomingBirthdaysProvider);
          ref.invalidate(recentNewsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXXL),
          children: [
            const SizedBox(height: AppTheme.spacingSM),

            // Stats cards
            _StatsGrid(),
            const SizedBox(height: AppTheme.spacingLG),

            // Upcoming Events
            _SectionHeader(
              title: 'Upcoming Events',
              icon: Icons.event,
              actionLabel: 'Calendar',
              onAction: () => context.push(AppRoutes.calendar),
            ),
            _UpcomingEventsSection(),
            const SizedBox(height: AppTheme.spacingLG),

            // Upcoming Birthdays
            _SectionHeader(
              title: 'Upcoming Birthdays',
              icon: Icons.cake_outlined,
              actionLabel: 'All Members',
              onAction: () => context.go(AppRoutes.members),
            ),
            _UpcomingBirthdaysSection(),
            const SizedBox(height: AppTheme.spacingLG),

            // Recent News
            _SectionHeader(
              title: 'Recent News',
              icon: Icons.newspaper_outlined,
              actionLabel: 'All News',
              onAction: () => context.go(AppRoutes.news),
            ),
            _RecentNewsSection(),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    final date = DateFormat('EEE, MMM d').format(DateTime.now());
    if (hour < 12) return '☀️ Good Morning · $date';
    if (hour < 17) return '☀️ Good Afternoon · $date';
    return '🌙 Good Evening · $date';
  }
}

// ─── Stats Grid ─────────────────────────────────────────────────

class _StatsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: statsAsync.when(
        data: (stats) => Column(
          children: [
            // Row 1: 3 compact stat cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Members',
                    icon: Icons.people_outline,
                    color: AppTheme.primaryColor,
                    value: stats.memberCount,
                    onTap: () => context.go(AppRoutes.members),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Donors',
                    icon: Icons.volunteer_activism_outlined,
                    color: AppTheme.secondaryColor,
                    value: stats.donorCount,
                    onTap: () => context.go(AppRoutes.donors),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Projects',
                    icon: Icons.folder_outlined,
                    color: AppTheme.accentColor,
                    value: stats.activeProjectCount,
                    onTap: () => context.go(AppRoutes.projects),
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 2: Events card + Donations card
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'This Month',
                    subtitle: 'Events',
                    icon: Icons.event_outlined,
                    color: const Color(0xFF7C4DFF),
                    value: stats.thisMonthEvents,
                    onTap: () => context.push(AppRoutes.calendar),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _DonationStatCard(totalDonations: stats.totalDonations),
                ),
              ],
            ),
          ],
        ),
        loading: () => Column(
          children: [
            Row(
              children: [
                const Expanded(child: ShimmerCard(height: 90)),
                const SizedBox(width: 10),
                const Expanded(child: ShimmerCard(height: 90)),
                const SizedBox(width: 10),
                const Expanded(child: ShimmerCard(height: 90)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(child: ShimmerCard(height: 80)),
                const SizedBox(width: 10),
                const Expanded(flex: 2, child: ShimmerCard(height: 80)),
              ],
            ),
          ],
        ),
        error: (_, __) => const Center(
          child: Text('Could not load stats. Pull to refresh.'),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final int value;
  final VoidCallback? onTap;
  final bool compact;

  const _StatCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.adaptiveCardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: compact ? 16 : 20),
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: compact ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle ?? title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: compact ? 11 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationStatCard extends StatelessWidget {
  final double totalDonations;

  const _DonationStatCard({required this.totalDonations});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.warmGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Donations',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatAmount(totalDonations)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.donors),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }
}

// ─── Section Header ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Upcoming Events Section ────────────────────────────────────

class _UpcomingEventsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyCard(
            context,
            icon: Icons.event_available,
            message: 'No upcoming events',
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            itemCount: events.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(
                event: event,
                onTap: () => context.push('/events/${event.id}'),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          itemCount: 3,
          itemBuilder: (context, index) => const ShimmerCard(),
        ),
      ),
      error: (_, __) => _buildEmptyCard(
        context,
        icon: Icons.error_outline,
        message: 'Could not load events',
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final daysUntil = event.eventDate
        .difference(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.adaptiveCardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: daysUntil == 0
                        ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                        : AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysUntil == 0
                        ? 'Today'
                        : daysUntil == 1
                            ? 'Tomorrow'
                            : dateFormat.format(event.eventDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysUntil == 0
                          ? AppTheme.secondaryDark
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (daysUntil > 1)
                  Text(
                    '${daysUntil}d',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              event.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),

            // Project + time
            Row(
              children: [
                if (event.projectName != null) ...[
                  Icon(Icons.folder_outlined,
                      size: 14, color: AppTheme.accentColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.projectName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentColor,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
                if (event.formattedTimeRange.isNotEmpty || event.eventTime != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 2),
                  Text(
                    event.formattedTimeRange.isNotEmpty
                        ? event.formattedTimeRange
                        : event.eventTime!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming Birthdays Section ─────────────────────────────────

class _UpcomingBirthdaysSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdaysAsync = ref.watch(upcomingBirthdaysProvider);

    return birthdaysAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return _buildEmptyCard(
            context,
            icon: Icons.cake_outlined,
            message: 'No upcoming birthdays this week',
          );
        }

        return Column(
          children: members.take(5).map((member) {
            final days = member.daysUntilBirthday;
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.adaptiveCardShadow(context),
              ),
              child: ListTile(
                onTap: () => context.push('/members/${member.id}'),
                leading: CircleAvatar(
                  backgroundColor: days == 0
                      ? AppTheme.secondaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: days == 0
                      ? const Text('🎂', style: TextStyle(fontSize: 20))
                      : Text(
                          member.initials,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  member.dateOfBirth != null
                      ? DateFormat('MMM d').format(member.dateOfBirth!)
                      : '',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: days == 0
                        ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                        : AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    days == 0
                        ? 'Today! 🎉'
                        : days == 1
                            ? 'Tomorrow'
                            : 'In $days days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: days == 0
                          ? AppTheme.secondaryDark
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const ShimmerListColumn(itemCount: 3),
      error: (_, __) => _buildEmptyCard(
        context,
        icon: Icons.error_outline,
        message: 'Could not load birthdays',
      ),
    );
  }
}

// ─── Recent News Section ────────────────────────────────────────

class _RecentNewsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(recentNewsProvider);

    return newsAsync.when(
      data: (newsItems) {
        if (newsItems.isEmpty) {
          return _buildEmptyCard(
            context,
            icon: Icons.newspaper_outlined,
            message: 'No recent news',
          );
        }

        return Column(
          children: newsItems.take(3).map((newsItem) {
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.adaptiveCardShadow(context),
              ),
              child: ListTile(
                onTap: () => context.push('/news/${newsItem.id}'),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: newsItem.isVideo
                        ? Colors.red.withValues(alpha: 0.1)
                        : AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    newsItem.isVideo
                        ? Icons.play_circle_outline
                        : Icons.article_outlined,
                    color: newsItem.isVideo ? Colors.red : AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  newsItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${newsItem.sourceName} · ${DateFormat('MMM d').format(newsItem.publishedDate)}',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textHint,
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const ShimmerListColumn(itemCount: 3),
      error: (_, __) => _buildEmptyCard(
        context,
        icon: Icons.error_outline,
        message: 'Could not load news',
      ),
    );
  }
}

// ─── Helper ─────────────────────────────────────────────────────

Widget _buildEmptyCard(
  BuildContext context, {
  required IconData icon,
  required String message,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
    padding: const EdgeInsets.all(AppTheme.spacingLG),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      boxShadow: AppTheme.adaptiveCardShadow(context),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppTheme.textHint),
        const SizedBox(width: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
        ),
      ],
    ),
  );
}
