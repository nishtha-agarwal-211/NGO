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

/// Project list screen with status badges, category chips, and filters.
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
                  hintText: 'Search projects...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
              )
            : const Text('Projects'),
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
        data: (projects) => _buildProjectList(projects),
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
              label: const Text('Add Project'),
            )
          : null,
    );
  }

  Widget _buildProjectList(List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.folder_outlined, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text('No projects yet', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Create your first project to get started',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(projectListProvider),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: projects.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${projects.length} project${projects.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                    ),
                  ),
                  if (_statusFilter != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_statusFilter!.displayName),
                      onDeleted: () { setState(() => _statusFilter = null); ref.invalidate(projectListProvider); },
                      deleteIcon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            );
          }
          return _ProjectCard(
            project: projects[index - 1],
            onTap: () => context.push('/projects/${projects[index - 1].id}'),
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

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        project.isRecurring ? Icons.repeat : Icons.trending_up,
                        color: _statusColor, size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (project.description != null)
                            Text(
                              project.description!,
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom row: category, type, recurrence
                Row(
                  children: [
                    if (project.category != null) ...[
                      _buildChip(project.category!, AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                    ],
                    _buildChip(project.projectType.displayName, AppTheme.primaryColor),
                    if (project.isRecurring && project.recurrenceSummary.isNotEmpty) ...[
                      const Spacer(),
                      Icon(Icons.schedule, size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          project.recurrenceSummary,
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        project.status.displayName,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
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
