import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../models/enums.dart';
import '../models/event_volunteer.dart';
import '../models/donation.dart';
import '../config/constants.dart';
import 'auth_service.dart';

/// Service for event CRUD, volunteer management, donation logging,
/// expense tracking, and weekly event auto-generation.
class EventService {
  final SupabaseClient _client;

  EventService(this._client);

  /// Sync event statuses in DB — mark any events whose end time/date has passed as 'completed'.
  Future<void> _syncPastEventStatuses() async {
    try {
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T').first;

      // 1. Mark events on past dates as completed
      await _client
          .from(AppConstants.eventsTable)
          .update({'status': 'completed'})
          .eq('status', 'upcoming')
          .lt('event_date', todayStr);

      // 2. Check today's upcoming events if their end time has passed
      final todayEventsResponse = await _client
          .from(AppConstants.eventsTable)
          .select('id, event_date, event_time, event_end_time')
          .eq('status', 'upcoming')
          .eq('event_date', todayStr);

      final todayEvents = todayEventsResponse as List;
      final idsToComplete = <String>[];

      for (final e in todayEvents) {
        final timeToParse = (e['event_end_time'] ?? e['event_time']) as String?;
        if (timeToParse != null && timeToParse.isNotEmpty) {
          try {
            final parts = timeToParse.split(':');
            if (parts.length >= 2) {
              final h = int.parse(parts[0]);
              final m = int.parse(parts[1]);
              final endDateTime = DateTime(now.year, now.month, now.day, h, m);
              if (endDateTime.isBefore(now)) {
                idsToComplete.add(e['id'] as String);
              }
            }
          } catch (_) {}
        }
      }

      if (idsToComplete.isNotEmpty) {
        await _client
            .from(AppConstants.eventsTable)
            .update({'status': 'completed'})
            .inFilter('id', idsToComplete);
      }
    } catch (_) {
      // Gracefully ignore sync errors
    }
  }

  // ─── Events CRUD ──────────────────────────────────────────────

  /// Fetch all events, optionally filtered.
  Future<List<Event>> getEvents({
    String? projectId,
    EventStatus? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await _syncPastEventStatuses();

    var query = _client
        .from(AppConstants.eventsTable)
        .select('*, projects(name)');

    if (projectId != null) {
      query = query.eq('project_id', projectId);
    }
    if (statusFilter != null) {
      query = query.eq('status', statusFilter.name);
    }
    if (fromDate != null) {
      query = query.gte('event_date', fromDate.toIso8601String().split('T').first);
    }
    if (toDate != null) {
      query = query.lte('event_date', toDate.toIso8601String().split('T').first);
    }

    final response = await query.order('event_date', ascending: false);
    return (response as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Fetch a single event by ID with project name.
  Future<Event?> getEventById(String id) async {
    final response = await _client
        .from(AppConstants.eventsTable)
        .select('*, projects(name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Event.fromJson(response);
  }

  /// Create a new event.
  Future<Event> createEvent(Event event) async {
    final response = await _client
        .from(AppConstants.eventsTable)
        .insert(event.toJson())
        .select('*, projects(name)')
        .single();

    return Event.fromJson(response);
  }

  /// Update an existing event.
  Future<Event> updateEvent(Event event) async {
    final response = await _client
        .from(AppConstants.eventsTable)
        .update(event.toJson())
        .eq('id', event.id)
        .select('*, projects(name)')
        .single();

    return Event.fromJson(response);
  }

  /// Delete an event.
  Future<void> deleteEvent(String id) async {
    await _client.from(AppConstants.eventsTable).delete().eq('id', id);
  }

  /// Mark an event as completed.
  Future<void> completeEvent(String id) async {
    await _client
        .from(AppConstants.eventsTable)
        .update({'status': 'completed'})
        .eq('id', id);
  }

  /// Get upcoming events (today and future).
  Future<List<Event>> getUpcomingEvents({int limit = 10}) async {
    await _syncPastEventStatuses();

    final today = DateTime.now().toIso8601String().split('T').first;
    final response = await _client
        .from(AppConstants.eventsTable)
        .select('*, projects(name)')
        .gte('event_date', today)
        .eq('status', 'upcoming')
        .order('event_date', ascending: true)
        .limit(limit);

    final events = (response as List).map((json) => Event.fromJson(json)).toList();
    return events.where((e) => e.isUpcoming).toList();
  }

  /// Get events for a date range (calendar view).
  Future<Map<DateTime, List<Event>>> getEventsForCalendar(
      DateTime firstDay, DateTime lastDay) async {
    await _syncPastEventStatuses();

    final response = await _client
        .from(AppConstants.eventsTable)
        .select('*, projects(name)')
        .gte('event_date', firstDay.toIso8601String().split('T').first)
        .lte('event_date', lastDay.toIso8601String().split('T').first)
        .order('event_date', ascending: true);

    final events =
        (response as List).map((json) => Event.fromJson(json)).toList();

    final map = <DateTime, List<Event>>{};
    for (final event in events) {
      final dateKey = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);
      map.putIfAbsent(dateKey, () => []).add(event);
    }
    return map;
  }

  /// Get event count.
  Future<int> getEventCount() async {
    final response =
        await _client.from(AppConstants.eventsTable).select('id');
    return (response as List).length;
  }

  /// Get this month's event count.
  Future<int> getThisMonthEventCount() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final response = await _client
        .from(AppConstants.eventsTable)
        .select('id')
        .gte('event_date', firstDay.toIso8601String().split('T').first)
        .lte('event_date', lastDay.toIso8601String().split('T').first);

    return (response as List).length;
  }

  // ─── Volunteers ───────────────────────────────────────────────

  /// Get volunteers for an event.
  Future<List<EventVolunteer>> getEventVolunteers(String eventId) async {
    final response = await _client
        .from(AppConstants.eventVolunteersTable)
        .select('*, members(name)')
        .eq('event_id', eventId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => EventVolunteer.fromJson(json))
        .toList();
  }

  /// Add a volunteer to an event (by member ID).
  Future<void> addMemberVolunteer(String eventId, String memberId) async {
    await _client.from(AppConstants.eventVolunteersTable).insert({
      'event_id': eventId,
      'member_id': memberId,
    });
  }

  /// Add an ad-hoc volunteer to an event (by name).
  Future<void> addAdHocVolunteer(String eventId, String name) async {
    await _client.from(AppConstants.eventVolunteersTable).insert({
      'event_id': eventId,
      'volunteer_name': name,
    });
  }

  /// Remove a volunteer from an event.
  Future<void> removeVolunteer(String volunteerId) async {
    await _client
        .from(AppConstants.eventVolunteersTable)
        .delete()
        .eq('id', volunteerId);
  }

  // ─── Donations (event-scoped) ─────────────────────────────────

  /// Get donations for an event.
  Future<List<Donation>> getEventDonations(String eventId) async {
    final response = await _client
        .from(AppConstants.donationsTable)
        .select('*, donors(name)')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Donation.fromJson(json))
        .toList();
  }

  /// Log a donation for an event.
  Future<Donation> logEventDonation(Donation donation) async {
    final response = await _client
        .from(AppConstants.donationsTable)
        .insert(donation.toJson())
        .select('*, donors(name)')
        .single();

    return Donation.fromJson(response);
  }

  /// Delete a donation.
  Future<void> deleteDonation(String id) async {
    await _client.from(AppConstants.donationsTable).delete().eq('id', id);
  }

  // ─── Expenses ─────────────────────────────────────────────────

  /// Get expenses for an event.
  Future<List<EventExpense>> getEventExpenses(String eventId) async {
    final response = await _client
        .from(AppConstants.eventExpensesTable)
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => EventExpense.fromJson(json))
        .toList();
  }

  /// Add an expense to an event.
  Future<EventExpense> addExpense(EventExpense expense) async {
    final response = await _client
        .from(AppConstants.eventExpensesTable)
        .insert(expense.toJson())
        .select()
        .single();

    return EventExpense.fromJson(response);
  }

  /// Delete an expense.
  Future<void> deleteExpense(String id) async {
    await _client.from(AppConstants.eventExpensesTable).delete().eq('id', id);
  }

  // ─── Weekly Event Auto-generation ─────────────────────────────

  /// Generate upcoming weekly events for a recurring project.
  /// Creates event instances for the next [weeksAhead] weeks
  /// if they don't already exist.
  Future<int> generateRecurringEvents(
    String projectId, {
    int weeksAhead = 4,
  }) async {
    // Get the project to know recurrence config
    final projectResponse = await _client
        .from(AppConstants.projectsTable)
        .select()
        .eq('id', projectId)
        .single();

    final dayOfWeek = projectResponse['recurrence_day_of_week'] as int?;
    final time = projectResponse['recurrence_time'] as String?;
    final endTime = projectResponse['recurrence_end_time'] as String?;
    final location = projectResponse['recurrence_location'] as String?;
    final projectName = projectResponse['name'] as String;

    if (dayOfWeek == null) return 0;

    // Find existing event dates to avoid duplicates
    final now = DateTime.now();
    final endDate = now.add(Duration(days: weeksAhead * 7));

    final existingResponse = await _client
        .from(AppConstants.eventsTable)
        .select('event_date')
        .eq('project_id', projectId)
        .gte('event_date', now.toIso8601String().split('T').first)
        .lte('event_date', endDate.toIso8601String().split('T').first);

    final existingDates = (existingResponse as List)
        .map((e) => e['event_date'] as String)
        .toSet();

    // Calculate the next N target dates
    final targetDates = <DateTime>[];
    var cursor = now;
    while (cursor.weekday % 7 != dayOfWeek) {
      cursor = cursor.add(const Duration(days: 1));
    }
    // If the cursor date is today and it's already past, start from next week
    if (cursor.isAtSameMomentAs(DateTime(now.year, now.month, now.day)) ||
        cursor.isBefore(DateTime(now.year, now.month, now.day))) {
      if (cursor.isBefore(DateTime(now.year, now.month, now.day))) {
        cursor = cursor.add(const Duration(days: 7));
      }
    }

    for (var i = 0; i < weeksAhead; i++) {
      targetDates.add(cursor);
      cursor = cursor.add(const Duration(days: 7));
    }

    // Filter out dates that already have events
    final datesToCreate = targetDates.where((d) {
      final dateStr = d.toIso8601String().split('T').first;
      return !existingDates.contains(dateStr);
    }).toList();

    if (datesToCreate.isEmpty) return 0;

    // Batch insert
    final dayNames = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];

    final inserts = datesToCreate.map((date) {
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final title =
          '$projectName — ${dayNames[dayOfWeek]}, ${monthNames[date.month - 1]} ${date.day}';

      // Check if end time / time on this date is in the past
      final timeToParse = endTime ?? time;
      bool isPast = false;
      if (timeToParse != null && timeToParse.isNotEmpty) {
        try {
          final parts = timeToParse.split(':');
          if (parts.length >= 2) {
            final h = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final endDt = DateTime(date.year, date.month, date.day, h, m);
            if (endDt.isBefore(now)) isPast = true;
          }
        } catch (_) {}
      } else {
        final endDt = DateTime(date.year, date.month, date.day, 23, 59, 59);
        if (endDt.isBefore(now)) isPast = true;
      }

      return {
        'project_id': projectId,
        'title': title,
        'event_date': date.toIso8601String().split('T').first,
        'event_time': time,
        'event_end_time': endTime,
        'location': location,
        'status': isPast ? 'completed' : 'upcoming',
      };
    }).toList();

    await _client.from(AppConstants.eventsTable).insert(inserts);
    return datesToCreate.length;
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref.watch(supabaseClientProvider));
});

final eventDetailProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  return ref.watch(eventServiceProvider).getEventById(eventId);
});

final upcomingEventsProvider =
    FutureProvider<List<Event>>((ref) async {
  return ref.watch(eventServiceProvider).getUpcomingEvents();
});

final eventVolunteersProvider =
    FutureProvider.family<List<EventVolunteer>, String>((ref, eventId) async {
  return ref.watch(eventServiceProvider).getEventVolunteers(eventId);
});

final eventDonationsProvider =
    FutureProvider.family<List<Donation>, String>((ref, eventId) async {
  return ref.watch(eventServiceProvider).getEventDonations(eventId);
});

final eventExpensesProvider =
    FutureProvider.family<List<EventExpense>, String>((ref, eventId) async {
  return ref.watch(eventServiceProvider).getEventExpenses(eventId);
});

final eventCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(eventServiceProvider).getEventCount();
});

final thisMonthEventCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(eventServiceProvider).getThisMonthEventCount();
});

class EventListParams {
  final String? projectId;
  final EventStatus? statusFilter;
  final DateTime? fromDate;
  final DateTime? toDate;

  const EventListParams({
    this.projectId,
    this.statusFilter,
    this.fromDate,
    this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventListParams &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          statusFilter == other.statusFilter &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode =>
      projectId.hashCode ^
      statusFilter.hashCode ^
      fromDate.hashCode ^
      toDate.hashCode;
}

final eventListProvider =
    FutureProvider.family<List<Event>, EventListParams>((ref, params) async {
  return ref.watch(eventServiceProvider).getEvents(
        projectId: params.projectId,
        statusFilter: params.statusFilter,
        fromDate: params.fromDate,
        toDate: params.toDate,
      );
});
