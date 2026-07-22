import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/project.dart';
import '../../models/enums.dart';
import '../../services/project_service.dart';
import '../../services/auth_service.dart';

/// Events screen — shows project categories as folder cards.
/// Each card represents a category (e.g., Wednesday Food Donation, Health Camps).
/// Tapping a card opens the date-wise folder view for that category.
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchController = TextEditingController();
  ProjectStatus? _statusFilter;
  ProjectType? _typeFilter;
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ProjectListParams get _currentParams => ProjectListParams(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilter: _statusFilter,
        typeFilter: _typeFilter,
      );

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    ref.invalidate(projectListProvider);
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        ref.invalidate(projectListProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectListAsync = ref.watch(projectListProvider(_currentParams));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
              )
            : const Text('Events'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: (_statusFilter != null || _typeFilter != null) ? AppTheme.secondaryColor : null,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                setState(() { _statusFilter = null; _typeFilter = null; });
              } else if (value.startsWith('status_')) {
                final name = value.replaceFirst('status_', '');
                setState(() => _statusFilter = name == 'all' ? null : ProjectStatus.fromString(name));
              } else if (value.startsWith('type_')) {
                final name = value.replaceFirst('type_', '');
                setState(() => _typeFilter = name == 'all' ? null : ProjectType.fromString(name));
              }
              ref.invalidate(projectListProvider);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear Filters')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'status_all', child: Text('All Statuses', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              ...ProjectStatus.values.map((s) => PopupMenuItem(
                    value: 'status_${s.name}',
                    child: Row(
                      children: [
                        Icon(_statusIcon(s), size: 18, color: _statusColor(s)),
                        const SizedBox(width: 8),
                        Text(s.displayName),
                        if (_statusFilter == s) ...[const Spacer(), const Icon(Icons.check, size: 18, color: AppTheme.primaryColor)],
                      ],
                    ),
                  )),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'type_all', child: Text('All Types', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
              ...ProjectType.values.map((t) => PopupMenuItem(
                    value: 'type_${t.name}',
                    child: Row(
                      children: [
                        Icon(t == ProjectType.recurring ? Icons.repeat : Icons.trending_up, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(t.displayName),
                        if (_typeFilter == t) ...[const Spacer(), const Icon(Icons.check, size: 18, color: AppTheme.primaryColor)],
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: projectListAsync.when(
        data: (projects) => _buildCategoryGrid(projects),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(projectListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.projectAdd),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            )
          : null,
    );
  }

  Widget _buildCategoryGrid(List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.event_note_outlined, size: 44, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text('No event categories yet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Create your first category to get started',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(projectListProvider),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 88, left: 16, right: 16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return _CategoryFolderCard(
            project: projects[index],
            colorIndex: index,
            onTap: () => context.push('/projects/${projects[index].id}/events'),
          );
        },
      ),
    );
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return Icons.play_circle_outline;
      case ProjectStatus.completed: return Icons.check_circle_outline;
      case ProjectStatus.paused: return Icons.pause_circle_outline;
    }
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return AppTheme.successColor;
      case ProjectStatus.completed: return AppTheme.primaryColor;
      case ProjectStatus.paused: return AppTheme.warningColor;
    }
  }
}

/// Category icons mapped to common NGO activity types.
IconData _categoryIcon(String? category, bool isRecurring) {
  if (category == null) return isRecurring ? Icons.repeat : Icons.event;
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.restaurant_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'medical':
    case 'health':
      return Icons.local_hospital_outlined;
    case 'environment':
      return Icons.eco_outlined;
    case 'women empowerment':
      return Icons.female_outlined;
    case 'child welfare':
      return Icons.child_care_outlined;
    case 'community':
      return Icons.groups_outlined;
    case 'infrastructure':
      return Icons.construction_outlined;
    default:
      return isRecurring ? Icons.repeat : Icons.event;
  }
}

/// Rich color palette for category cards.
const _categoryColors = [
  Color(0xFF8B1A1A),  // Deep maroon
  Color(0xFF1565C0),  // Blue
  Color(0xFF2E7D32),  // Green
  Color(0xFFE65100),  // Deep orange
  Color(0xFF6A1B9A),  // Purple
  Color(0xFF00695C),  // Teal
  Color(0xFFC62828),  // Red
  Color(0xFF283593),  // Indigo
  Color(0xFF4E342E),  // Brown
  Color(0xFF00838F),  // Cyan
];

class _CategoryFolderCard extends StatelessWidget {
  final Project project;
  final int colorIndex;
  final VoidCallback onTap;

  const _CategoryFolderCard({
    required this.project,
    required this.colorIndex,
    required this.onTap,
  });

  Color get _cardColor => _categoryColors[colorIndex % _categoryColors.length];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cardColor,
                  _cardColor.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _cardColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background folder pattern
                Positioned(
                  right: -20,
                  bottom: -15,
                  child: Icon(
                    Icons.folder_open,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Category icon
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _categoryIcon(project.category, project.isRecurring),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (project.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    project.description!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Arrow
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bottom info row
                      Row(
                        children: [
                          // Status badge
                          _buildBadge(
                            project.status.displayName,
                            icon: _statusIcon(project.status),
                          ),
                          const SizedBox(width: 8),
                          // Type badge
                          if (project.isRecurring) ...[
                            _buildBadge(
                              project.recurrenceSummary.isNotEmpty
                                  ? project.recurrenceSummary
                                  : 'Recurring',
                              icon: Icons.repeat,
                            ),
                          ] else ...[
                            if (project.category != null)
                              _buildBadge(project.category!, icon: Icons.label_outline),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return Icons.circle;
      case ProjectStatus.completed: return Icons.check_circle;
      case ProjectStatus.paused: return Icons.pause_circle;
    }
  }
}
