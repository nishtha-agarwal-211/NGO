import 'enums.dart';

/// Member model — maps to the `members` table in Supabase.
class Member {
  final String id;
  final String name;
  final String? photoUrl;
  final String? photoStoragePath;
  final String mobile;
  final String? email;
  final String? address;
  final DateTime? dateOfBirth;
  final DateTime? weddingAnniversary;
  final MemberRole role;
  final DateTime joinDate;
  final String? notes;
  final List<String> tags;
  final bool isActive;
  final String? authUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Member({
    required this.id,
    required this.name,
    this.photoUrl,
    this.photoStoragePath,
    required this.mobile,
    this.email,
    this.address,
    this.dateOfBirth,
    this.weddingAnniversary,
    this.role = MemberRole.member,
    required this.joinDate,
    this.notes,
    this.tags = const [],
    this.isActive = true,
    this.authUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      photoStoragePath: json['photo_storage_path'] as String?,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      weddingAnniversary: json['wedding_anniversary'] != null
          ? DateTime.parse(json['wedding_anniversary'] as String)
          : null,
      role: MemberRole.fromString(json['role'] as String? ?? 'member'),
      joinDate: DateTime.parse(json['join_date'] as String),
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      authUserId: json['auth_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photo_url': photoUrl,
      'photo_storage_path': photoStoragePath,
      'mobile': mobile,
      'email': email,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'wedding_anniversary': weddingAnniversary?.toIso8601String().split('T').first,
      'role': role.name,
      'join_date': joinDate.toIso8601String().split('T').first,
      'notes': notes,
      'tags': tags,
      'is_active': isActive,
      'auth_user_id': authUserId,
    };
  }

  Member copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? photoStoragePath,
    String? mobile,
    String? email,
    String? address,
    DateTime? dateOfBirth,
    DateTime? weddingAnniversary,
    MemberRole? role,
    DateTime? joinDate,
    String? notes,
    List<String>? tags,
    bool? isActive,
    String? authUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStoragePath: photoStoragePath ?? this.photoStoragePath,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weddingAnniversary: weddingAnniversary ?? this.weddingAnniversary,
      role: role ?? this.role,
      joinDate: joinDate ?? this.joinDate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      authUserId: authUserId ?? this.authUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the member's initials for avatar display.
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Check if birthday is within the next N days.
  bool isBirthdayWithin(int days) {
    if (dateOfBirth == null) return false;
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, dateOfBirth!.month, dateOfBirth!.day);
    var nextBirthday = thisYearBirthday;
    if (thisYearBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, dateOfBirth!.month, dateOfBirth!.day);
    }
    return nextBirthday.difference(now).inDays <= days;
  }

  /// Check if anniversary is within the next N days.
  bool isAnniversaryWithin(int days) {
    if (weddingAnniversary == null) return false;
    final now = DateTime.now();
    final thisYearAnniversary = DateTime(now.year, weddingAnniversary!.month, weddingAnniversary!.day);
    var nextAnniversary = thisYearAnniversary;
    if (thisYearAnniversary.isBefore(now)) {
      nextAnniversary = DateTime(now.year + 1, weddingAnniversary!.month, weddingAnniversary!.day);
    }
    return nextAnniversary.difference(now).inDays <= days;
  }

  /// Days until next birthday (-1 if no DOB set).
  int get daysUntilBirthday {
    if (dateOfBirth == null) return -1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var nextBirthday = DateTime(now.year, dateOfBirth!.month, dateOfBirth!.day);
    if (nextBirthday.isBefore(today)) {
      nextBirthday = DateTime(now.year + 1, dateOfBirth!.month, dateOfBirth!.day);
    }
    return nextBirthday.difference(today).inDays;
  }
}
