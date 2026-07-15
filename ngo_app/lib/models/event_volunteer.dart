/// EventVolunteer model — maps to the `event_volunteers` table.
class EventVolunteer {
  final String id;
  final String eventId;
  final String? memberId;
  final String? volunteerName;
  final DateTime createdAt;

  // Joined field
  final String? memberName;

  const EventVolunteer({
    required this.id,
    required this.eventId,
    this.memberId,
    this.volunteerName,
    required this.createdAt,
    this.memberName,
  });

  factory EventVolunteer.fromJson(Map<String, dynamic> json) {
    return EventVolunteer(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      memberId: json['member_id'] as String?,
      volunteerName: json['volunteer_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberName: json['members'] != null ? json['members']['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'member_id': memberId,
      'volunteer_name': volunteerName,
    };
  }

  /// Display name — uses member name if linked, otherwise ad-hoc name.
  String get displayName => memberName ?? volunteerName ?? 'Unknown';

  bool get isAdHoc => memberId == null;
}

/// EventExpense model — maps to the `event_expenses` table.
class EventExpense {
  final String id;
  final String eventId;
  final String description;
  final double amount;
  final DateTime createdAt;

  const EventExpense({
    required this.id,
    required this.eventId,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory EventExpense.fromJson(Map<String, dynamic> json) {
    return EventExpense(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'description': description,
      'amount': amount,
    };
  }

  String get displayAmount => '₹${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}';
}
