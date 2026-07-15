import 'enums.dart';

/// Donation model — maps to the `donations` table in Supabase.
class Donation {
  final String id;
  final String donorId;
  final String? projectId;
  final String? eventId;
  final DonationType donationType;
  final double? amount;
  final String? itemDescription;
  final DateTime donationDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (populated when fetching with relations)
  final String? donorName;
  final String? projectName;
  final String? eventTitle;

  const Donation({
    required this.id,
    required this.donorId,
    this.projectId,
    this.eventId,
    this.donationType = DonationType.cash,
    this.amount,
    this.itemDescription,
    required this.donationDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.donorName,
    this.projectName,
    this.eventTitle,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      donorId: json['donor_id'] as String,
      projectId: json['project_id'] as String?,
      eventId: json['event_id'] as String?,
      donationType: DonationType.fromString(json['donation_type'] as String? ?? 'cash'),
      amount: (json['amount'] as num?)?.toDouble(),
      itemDescription: json['item_description'] as String?,
      donationDate: DateTime.parse(json['donation_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Handle joined data
      donorName: json['donors'] != null ? json['donors']['name'] as String? : null,
      projectName: json['projects'] != null ? json['projects']['name'] as String? : null,
      eventTitle: json['events'] != null ? json['events']['title'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'donor_id': donorId,
      'project_id': projectId,
      'event_id': eventId,
      'donation_type': donationType.name,
      'amount': amount,
      'item_description': itemDescription,
      'donation_date': donationDate.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  Donation copyWith({
    String? id,
    String? donorId,
    String? projectId,
    String? eventId,
    DonationType? donationType,
    double? amount,
    String? itemDescription,
    DateTime? donationDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? donorName,
    String? projectName,
    String? eventTitle,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      projectId: projectId ?? this.projectId,
      eventId: eventId ?? this.eventId,
      donationType: donationType ?? this.donationType,
      amount: amount ?? this.amount,
      itemDescription: itemDescription ?? this.itemDescription,
      donationDate: donationDate ?? this.donationDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      donorName: donorName ?? this.donorName,
      projectName: projectName ?? this.projectName,
      eventTitle: eventTitle ?? this.eventTitle,
    );
  }

  /// Display string for the donation value.
  String get displayValue {
    if (donationType == DonationType.cash && amount != null) {
      return '₹${amount!.toStringAsFixed(amount! == amount!.roundToDouble() ? 0 : 2)}';
    }
    return itemDescription ?? 'N/A';
  }
}
