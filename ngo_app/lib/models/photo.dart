/// Photo model — maps to the `photos` table in Supabase.
class Photo {
  final String id;
  final String eventId;
  final String storagePath;
  final String? thumbnailPath;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final bool isFeatured;
  final String? uploadedBy;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.eventId,
    required this.storagePath,
    this.thumbnailPath,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.isFeatured = false,
    this.uploadedBy,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'storage_path': storagePath,
      'thumbnail_path': thumbnailPath,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'is_featured': isFeatured,
      'uploaded_by': uploadedBy,
    };
  }

  Photo copyWith({
    String? id,
    String? eventId,
    String? storagePath,
    String? thumbnailPath,
    String? url,
    String? thumbnailUrl,
    String? caption,
    bool? isFeatured,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      storagePath: storagePath ?? this.storagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      isFeatured: isFeatured ?? this.isFeatured,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the best URL to display (thumbnail for lists, full for detail).
  String get displayUrl => thumbnailUrl ?? url;
}
