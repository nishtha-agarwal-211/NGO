import 'enums.dart';

/// Project model — maps to the `projects` table in Supabase.
class Project {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final ProjectType projectType;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  // Recurrence fields
  final int? recurrenceDayOfWeek;
  final String? recurrenceTime;
  final String? recurrenceLocation;
  // Campaign fields
  final String? goalDescription;
  final double? targetAmount;
  final int? targetBeneficiaryCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed fields
  final int? eventCount;
  final double? totalDonations;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.projectType = ProjectType.ongoing,
    this.status = ProjectStatus.active,
    required this.startDate,
    this.endDate,
    this.recurrenceDayOfWeek,
    this.recurrenceTime,
    this.recurrenceLocation,
    this.goalDescription,
    this.targetAmount,
    this.targetBeneficiaryCount,
    required this.createdAt,
    required this.updatedAt,
    this.eventCount,
    this.totalDonations,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      projectType: ProjectType.fromString(json['project_type'] as String? ?? 'ongoing'),
      status: ProjectStatus.fromString(json['status'] as String? ?? 'active'),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      recurrenceDayOfWeek: json['recurrence_day_of_week'] as int?,
      recurrenceTime: json['recurrence_time'] as String?,
      recurrenceLocation: json['recurrence_location'] as String?,
      goalDescription: json['goal_description'] as String?,
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
      targetBeneficiaryCount: json['target_beneficiary_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'project_type': projectType.name,
      'status': status.name,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'recurrence_day_of_week': recurrenceDayOfWeek,
      'recurrence_time': recurrenceTime,
      'recurrence_location': recurrenceLocation,
      'goal_description': goalDescription,
      'target_amount': targetAmount,
      'target_beneficiary_count': targetBeneficiaryCount,
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    ProjectType? projectType,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? recurrenceDayOfWeek,
    String? recurrenceTime,
    String? recurrenceLocation,
    String? goalDescription,
    double? targetAmount,
    int? targetBeneficiaryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? eventCount,
    double? totalDonations,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      projectType: projectType ?? this.projectType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurrenceDayOfWeek: recurrenceDayOfWeek ?? this.recurrenceDayOfWeek,
      recurrenceTime: recurrenceTime ?? this.recurrenceTime,
      recurrenceLocation: recurrenceLocation ?? this.recurrenceLocation,
      goalDescription: goalDescription ?? this.goalDescription,
      targetAmount: targetAmount ?? this.targetAmount,
      targetBeneficiaryCount: targetBeneficiaryCount ?? this.targetBeneficiaryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      eventCount: eventCount ?? this.eventCount,
      totalDonations: totalDonations ?? this.totalDonations,
    );
  }

  bool get isRecurring => projectType == ProjectType.recurring;

  String get recurrenceSummary {
    if (!isRecurring || recurrenceDayOfWeek == null) return '';
    final dayName = _dayName(recurrenceDayOfWeek!);
    final time = recurrenceTime ?? '';
    final location = recurrenceLocation ?? '';
    return 'Every $dayName${time.isNotEmpty ? ' at $time' : ''}${location.isNotEmpty ? ' · $location' : ''}';
  }

  String _dayName(int day) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[day % 7];
  }
}
