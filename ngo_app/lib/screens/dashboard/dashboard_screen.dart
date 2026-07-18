import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/event.dart';
import '../../services/member_service.dart';
import '../../services/donor_service.dart';
import '../../services/project_service.dart';
import '../../services/event_service.dart';
import '../../services/news_service.dart';

/// Dashboard screen — shows key stats, upcoming events, recent birthdays,
/// and recent news. Serves as the app's main landing page.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
          ref.invalidate(memberCountProvider);
          ref.invalidate(donorCountProvider);
          ref.invalidate(activeProjectCountProvider);
          ref.invalidate(thisMonthEventCountProvider);
          ref.invalidate(totalDonationsProvider);
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(upcomingBirthdaysProvider);
          ref.invalidate(recentNewsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXXL),
          children: [
            const SizedBox(height: AppTheme.spacingSM),

            // Welcome header
            _buildWelcomeHeader(context),
            const SizedBox(height: AppTheme.spacingMD),

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

  Widget _buildWelcomeHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(greetingIcon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d').format(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Grid ─────────────────────────────────────────────────

class _StatsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Members',
                  icon: Icons.people_outline,
                  color: AppTheme.primaryColor,
                  provider: memberCountProvider,
                  onTap: () => context.go(AppRoutes.members),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Donors',
                  icon: Icons.volunteer_activism_outlined,
                  color: AppTheme.secondaryColor,
                  provider: donorCountProvider,
                  onTap: () => context.go(AppRoutes.donors),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Active Projects',
                  icon: Icons.folder_outlined,
                  color: AppTheme.accentColor,
                  provider: activeProjectCountProvider,
                  onTap: () => context.go(AppRoutes.projects),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Month',
                  subtitle: 'Events',
                  icon: Icons.event_outlined,
                  color: const Color(0xFF7C4DFF),
                  provider: thisMonthEventCountProvider,
                  onTap: () => context.push(AppRoutes.calendar),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total Donations card (full width)
          _DonationStatCard(),
        ],
      ),
    );
  }
}

class _StatCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final FutureProvider<int> provider;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueAsync = ref.watch(provider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.textHint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            valueAsync.when(
              data: (value) => Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              loading: () => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 40,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              error: (_, __) => Text(
                '—',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle ?? title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationStatCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalDonationsProvider);

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
                totalAsync.when(
                  data: (total) => Text(
                    '₹${_formatAmount(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  loading: () => Shimmer.fromColors(
                    baseColor: Colors.white24,
                    highlightColor: Colors.white54,
                    child: Container(
                      width: 100,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  error: (_, __) => const Text(
                    '—',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
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
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
            );
          },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
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
                if (event.eventTime != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 2),
                  Text(
                    event.eventTime!,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
      loading: () => Column(
        children: List.generate(
          3,
          (_) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
      ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
      loading: () => Column(
        children: List.generate(
          3,
          (_) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
      ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
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
