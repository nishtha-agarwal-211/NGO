import 'enums.dart';

/// NewsItem model — maps to the `news_items` table in Supabase.
class NewsItem {
  final String id;
  final String title;
  final String sourceName;
  final NewsType newsType;
  final String? articleUrl;
  final String? youtubeUrl;
  final String? clippingImageUrl;
  final String? clippingStoragePath;
  final String? linkedProjectId;
  final String? linkedEventId;
  final DateTime publishedDate;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? linkedProjectName;

  const NewsItem({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.newsType,
    this.articleUrl,
    this.youtubeUrl,
    this.clippingImageUrl,
    this.clippingStoragePath,
    this.linkedProjectId,
    this.linkedEventId,
    required this.publishedDate,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
    this.linkedProjectName,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      sourceName: json['source_name'] as String,
      newsType: NewsType.fromString(json['news_type'] as String? ?? 'article'),
      articleUrl: json['article_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      clippingImageUrl: json['clipping_image_url'] as String?,
      clippingStoragePath: json['clipping_storage_path'] as String?,
      linkedProjectId: json['linked_project_id'] as String?,
      linkedEventId: json['linked_event_id'] as String?,
      publishedDate: DateTime.parse(json['published_date'] as String),
      summary: json['summary'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      linkedProjectName: json['projects'] != null ? json['projects']['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source_name': sourceName,
      'news_type': newsType.name,
      'article_url': articleUrl,
      'youtube_url': youtubeUrl,
      'clipping_image_url': clippingImageUrl,
      'clipping_storage_path': clippingStoragePath,
      'linked_project_id': linkedProjectId,
      'linked_event_id': linkedEventId,
      'published_date': publishedDate.toIso8601String().split('T').first,
      'summary': summary,
    };
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? sourceName,
    NewsType? newsType,
    String? articleUrl,
    String? youtubeUrl,
    String? clippingImageUrl,
    String? clippingStoragePath,
    String? linkedProjectId,
    String? linkedEventId,
    DateTime? publishedDate,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedProjectName,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceName: sourceName ?? this.sourceName,
      newsType: newsType ?? this.newsType,
      articleUrl: articleUrl ?? this.articleUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      clippingImageUrl: clippingImageUrl ?? this.clippingImageUrl,
      clippingStoragePath: clippingStoragePath ?? this.clippingStoragePath,
      linkedProjectId: linkedProjectId ?? this.linkedProjectId,
      linkedEventId: linkedEventId ?? this.linkedEventId,
      publishedDate: publishedDate ?? this.publishedDate,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedProjectName: linkedProjectName ?? this.linkedProjectName,
    );
  }

  bool get isVideo => newsType == NewsType.video;
  bool get isArticle => newsType == NewsType.article;

  /// Extract YouTube video ID from URL for embedding.
  String? get youtubeVideoId {
    if (youtubeUrl == null) return null;
    final uri = Uri.tryParse(youtubeUrl!);
    if (uri == null) return null;

    // Handle youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    // Handle youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    return null;
  }

  /// Thumbnail URL for YouTube video.
  String? get youtubeThumbnailUrl {
    final videoId = youtubeVideoId;
    if (videoId == null) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
