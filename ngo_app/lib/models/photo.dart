/// Media type enum for distinguishing photos and videos.
enum MediaType {
  photo,
  video;

  String get displayName {
    switch (this) {
      case MediaType.photo:
        return 'Photo';
      case MediaType.video:
        return 'Video';
    }
  }

  static MediaType fromString(String? value) {
    if (value == 'video') return MediaType.video;
    return MediaType.photo;
  }
}

/// Photo/Video model — maps to the `photos` table in Supabase.
/// Supports both image and video media.
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
  final MediaType mediaType;
  final int? videoDurationSeconds;
  final String? contentType;

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
    this.mediaType = MediaType.photo,
    this.videoDurationSeconds,
    this.contentType,
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
      mediaType: MediaType.fromString(json['media_type'] as String?),
      videoDurationSeconds: json['video_duration_seconds'] as int?,
      contentType: json['content_type'] as String?,
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
      'media_type': mediaType.name,
      'video_duration_seconds': videoDurationSeconds,
      'content_type': contentType,
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
    MediaType? mediaType,
    int? videoDurationSeconds,
    String? contentType,
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
      mediaType: mediaType ?? this.mediaType,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      contentType: contentType ?? this.contentType,
    );
  }

  /// Whether this media item is a video.
  bool get isVideo => mediaType == MediaType.video;

  /// Whether this media item is a photo.
  bool get isPhoto => mediaType == MediaType.photo;

  /// Returns the best URL to display (thumbnail for lists, full for detail).
  String get displayUrl => thumbnailUrl ?? url;

  /// Formatted video duration string (e.g. "1:23" or "0:15").
  String get formattedDuration {
    if (videoDurationSeconds == null) return '';
    final minutes = videoDurationSeconds! ~/ 60;
    final seconds = videoDurationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
