import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/project.dart';
import '../../models/event.dart';
import '../../models/enums.dart';
import '../../services/project_service.dart';
import '../../services/auth_service.dart';
import '../../utils/error_utils.dart';

/// Event folder screen — shows all events for a project/category as
/// date-wise folder cards. Each folder represents one event instance
/// (e.g., a specific Wednesday food donation) with its date, status,
/// photo count, and summary.
class EventFolderScreen extends ConsumerWidget {
  final String projectId;

  const EventFolderScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final eventsAsync = ref.watch(projectEventsProvider(projectId));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Events')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off_outlined, size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text('Category not found', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return _EventFolderBody(
          project: project,
          eventsAsync: eventsAsync,
          isAdmin: isAdmin,
          onDeleteProject: () => _deleteProject(context, ref, project),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Events')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Events')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${project.name}"? This will also delete all associated events and photos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(projectServiceProvider).deleteProject(project.id);
        ref.invalidate(projectListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${project.name}" deleted')));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ErrorUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }
}

class _EventFolderBody extends StatelessWidget {
  final Project project;
  final AsyncValue<List<Event>> eventsAsync;
  final bool isAdmin;
  final VoidCallback onDeleteProject;

  const _EventFolderBody({
    required this.project,
    required this.eventsAsync,
    required this.isAdmin,
    required this.onDeleteProject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header with category info
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: _headerColor,
            foregroundColor: Colors.white,
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/projects/${project.id}/edit'),
                  tooltip: 'Edit Category',
                ),
                PopupMenuButton<String>(
                  onSelected: (v) { if (v == 'delete') onDeleteProject(); },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_headerColor, _headerColor.withValues(alpha: 0.75)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Category icon
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            project.isRecurring ? Icons.repeat : Icons.event,
                            color: Colors.white, size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          project.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Info badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _headerBadge(project.status.displayName),
                            if (project.isRecurring && project.recurrenceSummary.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _headerBadge(project.recurrenceSummary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Description section
          if (project.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: _headerColor.withValues(alpha: 0.6)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.description!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, size: 20, color: _headerColor),
                  const SizedBox(width: 8),
                  Text(
                    'Events',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  eventsAsync.whenOrNull(
                    data: (events) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _headerColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${events.length} event${events.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _headerColor,
                        ),
                      ),
                    ),
                  ) ?? const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // Events list as date folders
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined, size: 48, color: AppTheme.textHint.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No events yet',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add the first event',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Group events by month for visual separation
              final groupedEvents = _groupByMonth(events);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = groupedEvents.entries.elementAt(index);
                    return _MonthSection(
                      monthLabel: entry.key,
                      events: entry.value,
                      headerColor: _headerColor,
                    );
                  },
                  childCount: groupedEvents.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Error loading events: $e'),
                ),
              ),
            ),
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/events/add?projectId=${project.id}'),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            )
          : null,
    );
  }

  Widget _headerBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Map<String, List<Event>> _groupByMonth(List<Event> events) {
    final map = <String, List<Event>>{};
    for (final event in events) {
      final key = DateFormat('MMMM yyyy').format(event.eventDate);
      map.putIfAbsent(key, () => []).add(event);
    }
    return map;
  }

  Color get _headerColor {
    switch (project.status) {
      case ProjectStatus.active: return const Color(0xFF8B1A1A);
      case ProjectStatus.completed: return AppTheme.primaryColor;
      case ProjectStatus.paused: return AppTheme.warningColor;
    }
  }
}

/// A month section with header and date folder tiles.
class _MonthSection extends StatelessWidget {
  final String monthLabel;
  final List<Event> events;
  final Color headerColor;

  const _MonthSection({
    required this.monthLabel,
    required this.events,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              monthLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Event date folders
          ...events.map((event) => _DateFolderTile(
            event: event,
            accentColor: headerColor,
            onTap: () => context.push('/events/${event.id}'),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// A single date folder tile — represents one event instance.
class _DateFolderTile extends StatelessWidget {
  final Event event;
  final Color accentColor;
  final VoidCallback onTap;

  const _DateFolderTile({
    required this.event,
    required this.accentColor,
    required this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final effectiveStatus = event.effectiveStatus;
    final isCompleted = effectiveStatus == EventStatus.completed;
    final isUpcoming = effectiveStatus == EventStatus.upcoming;
    final isCancelled = effectiveStatus == EventStatus.cancelled;

    final dateSub = event.formattedTimeRange.isNotEmpty
        ? '${dateFormat.format(event.eventDate)} · ${event.formattedTimeRange}'
        : dateFormat.format(event.eventDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isCompleted
                    ? AppTheme.successColor.withValues(alpha: 0.15)
                    : isUpcoming
                        ? accentColor.withValues(alpha: 0.12)
                        : AppTheme.textHint.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Date block (like a mini calendar)
                Container(
                  width: 52, height: 56,
                  decoration: BoxDecoration(
                    color: _statusColor(effectiveStatus).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(event.eventDate).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(effectiveStatus),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${event.eventDate.day}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _statusColor(effectiveStatus),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.displayTitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateSub,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Info chips row
                      Row(
                        children: [
                          _infoChip(
                            effectiveStatus.displayName,
                            color: _statusColor(effectiveStatus),
                            icon: _statusIcon(effectiveStatus),
                          ),
                          if (event.beneficiaryCount > 0) ...[
                            const SizedBox(width: 6),
                            _infoChip(
                              '${event.beneficiaryCount} served',
                              color: AppTheme.accentColor,
                              icon: Icons.groups_outlined,
                            ),
                          ],
                          if (event.location != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: _infoChip(
                                event.location!,
                                color: AppTheme.textSecondary,
                                icon: Icons.location_on_outlined,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Folder arrow
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textHint.withValues(alpha: 0.5),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, {required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming: return const Color(0xFF1565C0);
      case EventStatus.completed: return AppTheme.successColor;
      case EventStatus.cancelled: return AppTheme.errorColor;
    }
  }

  IconData _statusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming: return Icons.schedule;
      case EventStatus.completed: return Icons.check_circle_outline;
      case EventStatus.cancelled: return Icons.cancel_outlined;
    }
  }
}
