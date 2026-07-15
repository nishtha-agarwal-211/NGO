/// Enum types matching the Supabase database enums.

enum MemberRole {
  admin,
  volunteer,
  member;

  String get displayName {
    switch (this) {
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.volunteer:
        return 'Volunteer';
      case MemberRole.member:
        return 'Member';
    }
  }

  static MemberRole fromString(String value) {
    return MemberRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MemberRole.member,
    );
  }
}

enum DonorType {
  oneTime('one_time'),
  recurring('recurring');

  final String dbValue;
  const DonorType(this.dbValue);

  String get displayName {
    switch (this) {
      case DonorType.oneTime:
        return 'One-time';
      case DonorType.recurring:
        return 'Recurring';
    }
  }

  static DonorType fromString(String value) {
    return DonorType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => DonorType.oneTime,
    );
  }
}

enum DonationType {
  cash,
  kind,
  service;

  String get displayName {
    switch (this) {
      case DonationType.cash:
        return 'Cash';
      case DonationType.kind:
        return 'In-Kind';
      case DonationType.service:
        return 'Service';
    }
  }

  static DonationType fromString(String value) {
    return DonationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DonationType.cash,
    );
  }
}

enum ProjectType {
  recurring,
  ongoing;

  String get displayName {
    switch (this) {
      case ProjectType.recurring:
        return 'Recurring';
      case ProjectType.ongoing:
        return 'Ongoing';
    }
  }

  static ProjectType fromString(String value) {
    return ProjectType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectType.ongoing,
    );
  }
}

enum ProjectStatus {
  active,
  completed,
  paused;

  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.paused:
        return 'Paused';
    }
  }

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectStatus.active,
    );
  }
}

enum NewsType {
  article,
  video;

  String get displayName {
    switch (this) {
      case NewsType.article:
        return 'Article';
      case NewsType.video:
        return 'Video';
    }
  }

  static NewsType fromString(String value) {
    return NewsType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NewsType.article,
    );
  }
}

enum EventStatus {
  upcoming,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case EventStatus.upcoming:
        return 'Upcoming';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventStatus.upcoming,
    );
  }
}
