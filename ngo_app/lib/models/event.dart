import 'enums.dart';

/// Event model — maps to the `events` table in Supabase.
class Event {
  final String id;
  final String projectId;
  final String? title;
  final DateTime eventDate;
  final String? eventTime;
  final String? eventEndTime;
  final String? location;
  final int beneficiaryCount;
  final String? beneficiaryDetails;
  final String? notes;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? projectName;
  final int? photoCount;
  final int? volunteerCount;
  final int? donationCount;

  const Event({
    required this.id,
    required this.projectId,
    this.title,
    required this.eventDate,
    this.eventTime,
    this.eventEndTime,
    this.location,
    this.beneficiaryCount = 0,
    this.beneficiaryDetails,
    this.notes,
    this.status = EventStatus.upcoming,
    required this.createdAt,
    required this.updatedAt,
    this.projectName,
    this.photoCount,
    this.volunteerCount,
    this.donationCount,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      eventTime: json['event_time'] as String?,
      eventEndTime: json['event_end_time'] as String? ?? json['end_time'] as String?,
      location: json['location'] as String?,
      beneficiaryCount: json['beneficiary_count'] as int? ?? 0,
      beneficiaryDetails: json['beneficiary_details'] as String?,
      notes: json['notes'] as String?,
      status: EventStatus.fromString(json['status'] as String? ?? 'upcoming'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      projectName: json['projects'] != null ? json['projects']['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'event_date': eventDate.toIso8601String().split('T').first,
      'event_time': eventTime,
      'event_end_time': eventEndTime,
      'location': location,
      'beneficiary_count': beneficiaryCount,
      'beneficiary_details': beneficiaryDetails,
      'notes': notes,
      'status': status.name,
    };
  }

  Event copyWith({
    String? id,
    String? projectId,
    String? title,
    DateTime? eventDate,
    String? eventTime,
    String? eventEndTime,
    String? location,
    int? beneficiaryCount,
    String? beneficiaryDetails,
    String? notes,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? projectName,
    int? photoCount,
    int? volunteerCount,
    int? donationCount,
  }) {
    return Event(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      location: location ?? this.location,
      beneficiaryCount: beneficiaryCount ?? this.beneficiaryCount,
      beneficiaryDetails: beneficiaryDetails ?? this.beneficiaryDetails,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projectName: projectName ?? this.projectName,
      photoCount: photoCount ?? this.photoCount,
      volunteerCount: volunteerCount ?? this.volunteerCount,
      donationCount: donationCount ?? this.donationCount,
    );
  }

  /// Display title — uses custom title if set, otherwise generates one.
  String get displayTitle => title ?? 'Event on ${_formatDate(eventDate)}';

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Calculated exact end DateTime for status checks.
  DateTime get endDateTime {
    final timeToParse = eventEndTime ?? eventTime;
    if (timeToParse != null && timeToParse.isNotEmpty) {
      try {
        final parts = timeToParse.split(':');
        if (parts.length >= 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          return DateTime(eventDate.year, eventDate.month, eventDate.day, h, m);
        }
      } catch (_) {}
    }
    // Default to end of event date if no valid time
    return DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59, 59);
  }

  /// True if the event end time or date has passed.
  bool get hasEnded => endDateTime.isBefore(DateTime.now());

  /// Effective status — if explicitly marked upcoming but end time has passed, treat as completed.
  EventStatus get effectiveStatus {
    if (status == EventStatus.upcoming && hasEnded) {
      return EventStatus.completed;
    }
    return status;
  }

  bool get isUpcoming => effectiveStatus == EventStatus.upcoming;
  bool get isCompleted => effectiveStatus == EventStatus.completed;
  bool get isPast => hasEnded;

  /// Formatted time string range (e.g. "11:45 AM - 1:45 PM" or "11:45 AM").
  String get formattedTimeRange {
    final startStr = _formatSingleTime(eventTime);
    final endStr = _formatSingleTime(eventEndTime);
    if (startStr.isNotEmpty && endStr.isNotEmpty) {
      return '$startStr – $endStr';
    } else if (startStr.isNotEmpty) {
      return startStr;
    } else if (endStr.isNotEmpty) {
      return 'Until $endStr';
    }
    return '';
  }

  String _formatSingleTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final h = hour % 12 == 0 ? 12 : hour % 12;
        return '$h:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return timeStr;
  }
}
