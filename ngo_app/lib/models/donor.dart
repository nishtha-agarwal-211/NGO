import 'enums.dart';

/// Donor model — maps to the `donors` table in Supabase.
class Donor {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? address;
  final DonorType donorType;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed fields (not stored in DB, populated by joins)
  final double? totalDonated;
  final int? donationCount;

  const Donor({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.donorType = DonorType.oneTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.totalDonated,
    this.donationCount,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      donorType: DonorType.fromString(json['donor_type'] as String? ?? 'one_time'),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'email': email,
      'address': address,
      'donor_type': donorType.dbValue,
      'notes': notes,
    };
  }

  Donor copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? address,
    DonorType? donorType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalDonated,
    int? donationCount,
  }) {
    return Donor(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      donorType: donorType ?? this.donorType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalDonated: totalDonated ?? this.totalDonated,
      donationCount: donationCount ?? this.donationCount,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
