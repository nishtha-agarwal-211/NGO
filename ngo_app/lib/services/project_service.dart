import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../config/constants.dart';
import 'auth_service.dart';

/// Service for project CRUD operations via Supabase.
class ProjectService {
  final SupabaseClient _client;

  ProjectService(this._client);

  /// Fetch all projects, ordered by name.
  Future<List<Project>> getProjects({
    String? searchQuery,
    ProjectStatus? statusFilter,
    ProjectType? typeFilter,
  }) async {
    var query = _client.from(AppConstants.projectsTable).select();

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.name);
    }

    if (typeFilter != null) {
      query = query.eq('project_type', typeFilter.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query = query.or('name.ilike.$term,description.ilike.$term,category.ilike.$term');
    }

    final response = await query.order('name', ascending: true);
    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  /// Fetch a single project by ID.
  Future<Project?> getProjectById(String id) async {
    final response = await _client
        .from(AppConstants.projectsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Project.fromJson(response);
  }

  /// Create a new project.
  Future<Project> createProject(Project project) async {
    final response = await _client
        .from(AppConstants.projectsTable)
        .insert(project.toJson())
        .select()
        .single();

    return Project.fromJson(response);
  }

  /// Update an existing project.
  Future<Project> updateProject(Project project) async {
    final response = await _client
        .from(AppConstants.projectsTable)
        .update(project.toJson())
        .eq('id', project.id)
        .select()
        .single();

    return Project.fromJson(response);
  }

  /// Delete a project.
  Future<void> deleteProject(String id) async {
    await _client.from(AppConstants.projectsTable).delete().eq('id', id);
  }

  /// Get events for a project, ordered by date descending.
  Future<List<Event>> getProjectEvents(String projectId) async {
    final response = await _client
        .from(AppConstants.eventsTable)
        .select('*, projects(name)')
        .eq('project_id', projectId)
        .order('event_date', ascending: false);

    return (response as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Get event count for a project.
  Future<int> getProjectEventCount(String projectId) async {
    final response = await _client
        .from(AppConstants.eventsTable)
        .select('id')
        .eq('project_id', projectId);

    return (response as List).length;
  }

  /// Get total project count.
  Future<int> getProjectCount() async {
    final response = await _client
        .from(AppConstants.projectsTable)
        .select('id');

    return (response as List).length;
  }

  /// Get active project count.
  Future<int> getActiveProjectCount() async {
    final response = await _client
        .from(AppConstants.projectsTable)
        .select('id')
        .eq('status', 'active');

    return (response as List).length;
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(ref.watch(supabaseClientProvider));
});

class ProjectListParams {
  final String? searchQuery;
  final ProjectStatus? statusFilter;
  final ProjectType? typeFilter;

  const ProjectListParams({this.searchQuery, this.statusFilter, this.typeFilter});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectListParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          statusFilter == other.statusFilter &&
          typeFilter == other.typeFilter;

  @override
  int get hashCode => searchQuery.hashCode ^ statusFilter.hashCode ^ typeFilter.hashCode;
}

final projectListProvider = FutureProvider.family<List<Project>, ProjectListParams>((ref, params) async {
  return ref.watch(projectServiceProvider).getProjects(
    searchQuery: params.searchQuery,
    statusFilter: params.statusFilter,
    typeFilter: params.typeFilter,
  );
});

final projectDetailProvider = FutureProvider.family<Project?, String>((ref, projectId) async {
  return ref.watch(projectServiceProvider).getProjectById(projectId);
});

final projectEventsProvider = FutureProvider.family<List<Event>, String>((ref, projectId) async {
  return ref.watch(projectServiceProvider).getProjectEvents(projectId);
});

final projectCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(projectServiceProvider).getProjectCount();
});

final activeProjectCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(projectServiceProvider).getActiveProjectCount();
});
