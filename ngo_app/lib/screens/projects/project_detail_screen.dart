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
import '../../utils/error_utils.dart';

/// Full project detail screen with events list, recurrence info, and campaign progress.
class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final eventsAsync = ref.watch(projectEventsProvider(projectId));

    return Scaffold(
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off_outlined, size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text('Project not found', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          return _ProjectDetailBody(
            project: project,
            eventsAsync: eventsAsync,
            onDelete: () => _deleteProject(context, ref, project),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/add?projectId=$projectId'),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.name}"? This will also delete all associated events.'),
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

class _ProjectDetailBody extends StatelessWidget {
  final Project project;
  final AsyncValue<List<Event>> eventsAsync;
  final VoidCallback onDelete;

  const _ProjectDetailBody({
    required this.project,
    required this.eventsAsync,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: _statusColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/projects/${project.id}/edit'),
            ),
            PopupMenuButton<String>(
              onSelected: (v) { if (v == 'delete') onDelete(); },
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
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_statusColor, _statusColor.withValues(alpha: 0.7)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        project.isRecurring ? Icons.repeat : Icons.trending_up,
                        color: Colors.white, size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project.name,
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${project.status.displayName} · ${project.projectType.displayName}',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Description
                if (project.description != null) ...[
                  _buildSectionHeader('Description'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Text(
                      project.description!,
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Details card
                _buildSectionHeader('Details'),
                const SizedBox(height: 8),
                _buildDetailsCard(),
                const SizedBox(height: 24),

                // Recurrence info
                if (project.isRecurring) ...[
                  _buildSectionHeader('Recurrence'),
                  const SizedBox(height: 8),
                  _buildRecurrenceCard(),
                  const SizedBox(height: 24),
                ],

                // Campaign goal
                if (project.goalDescription != null || project.targetAmount != null) ...[
                  _buildSectionHeader('Campaign Goal'),
                  const SizedBox(height: 8),
                  _buildCampaignCard(),
                  const SizedBox(height: 24),
                ],

                // Events
                _buildSectionHeader('Events'),
                const SizedBox(height: 12),
                _buildEventsList(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.category_outlined, 'Category', project.category ?? 'Not set'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Start Date',
              DateFormat('MMM d, yyyy').format(project.startDate)),
          if (project.endDate != null)
            _buildInfoRow(Icons.event_outlined, 'End Date',
                DateFormat('MMM d, yyyy').format(project.endDate!)),
          if (project.targetBeneficiaryCount != null)
            _buildInfoRow(Icons.groups_outlined, 'Target Beneficiaries',
                '${project.targetBeneficiaryCount}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              project.recurrenceSummary,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.goalDescription != null) ...[
            Text(
              project.goalDescription!,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          if (project.targetAmount != null)
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: AppTheme.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Target: ₹${project.targetAmount!.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context) {
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Icon(Icons.event_outlined, size: 40, color: AppTheme.textHint),
                const SizedBox(height: 12),
                Text('No events yet', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return Column(
          children: events.map((event) => _EventTile(
            event: event,
            onTap: () => context.push('/events/${event.id}'),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Color get _statusColor {
    switch (project.status) {
      case ProjectStatus.active: return AppTheme.successColor;
      case ProjectStatus.completed: return AppTheme.primaryColor;
      case ProjectStatus.paused: return AppTheme.warningColor;
    }
  }
}

class _EventTile extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                // Date column
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _eventStatusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(event.eventDate).toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _eventStatusColor),
                      ),
                      Text(
                        '${event.eventDate.day}',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _eventStatusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.displayTitle,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.status.displayName,
                        style: GoogleFonts.inter(fontSize: 12, color: _eventStatusColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _eventStatusColor {
    switch (event.status) {
      case EventStatus.upcoming: return AppTheme.secondaryColor;
      case EventStatus.completed: return AppTheme.successColor;
      case EventStatus.cancelled: return AppTheme.errorColor;
    }
  }
}
