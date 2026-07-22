import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/news_item.dart';
import '../models/enums.dart';
import '../config/constants.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

/// Service for news/media CRUD operations via Supabase.
class NewsService {
  final SupabaseClient _client;

  NewsService(this._client);

  /// Fetch all news items, optionally filtered.
  Future<List<NewsItem>> getNewsItems({
    String? searchQuery,
    NewsType? typeFilter,
  }) async {
    var query = _client
        .from(AppConstants.newsItemsTable)
        .select('*, projects(name)');

    if (typeFilter != null) {
      query = query.eq('news_type', typeFilter.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query = query.or('title.ilike.$term,source_name.ilike.$term,summary.ilike.$term');
    }

    final response = await query.order('published_date', ascending: false);
    return (response as List).map((json) => NewsItem.fromJson(json)).toList();
  }

  /// Fetch a single news item by ID.
  Future<NewsItem?> getNewsItemById(String id) async {
    final response = await _client
        .from(AppConstants.newsItemsTable)
        .select('*, projects(name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return NewsItem.fromJson(response);
  }

  /// Create a new news item.
  Future<NewsItem> createNewsItem(NewsItem newsItem) async {
    final response = await _client
        .from(AppConstants.newsItemsTable)
        .insert(newsItem.toJson())
        .select('*, projects(name)')
        .single();

    return NewsItem.fromJson(response);
  }

  /// Update an existing news item.
  Future<NewsItem> updateNewsItem(NewsItem newsItem) async {
    final response = await _client
        .from(AppConstants.newsItemsTable)
        .update(newsItem.toJson())
        .eq('id', newsItem.id)
        .select('*, projects(name)')
        .single();

    return NewsItem.fromJson(response);
  }

  /// Delete a news item.
  Future<void> deleteNewsItem(String id) async {
    // Also try to delete any stored clipping image
    final item = await getNewsItemById(id);
    if (item?.clippingStoragePath != null) {
      try {
        await _client.storage
            .from(SupabaseConfig.newsClippingsBucket)
            .remove([item!.clippingStoragePath!]);
      } catch (_) {}
    }

    await _client.from(AppConstants.newsItemsTable).delete().eq('id', id);
  }

  /// Upload a news clipping image to Supabase Storage.
  ///
  /// Accepts an [XFile] instead of a raw file path so it works safely
  /// on both mobile and Flutter Web (no `dart:io` dependency).
  Future<String> uploadClippingImage(String newsId, XFile file) async {
    final storagePath = SupabaseConfig.newsClippingPath(newsId);
    final bytes = await file.readAsBytes();

    await _client.storage
        .from(SupabaseConfig.newsClippingsBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final url = _client.storage
        .from(SupabaseConfig.newsClippingsBucket)
        .getPublicUrl(storagePath);

    return url;
  }

  /// Get news item count.
  Future<int> getNewsCount() async {
    final response = await _client
        .from(AppConstants.newsItemsTable)
        .select('id');

    return (response as List).length;
  }

  /// Get recent news items.
  Future<List<NewsItem>> getRecentNews({int limit = 5}) async {
    final response = await _client
        .from(AppConstants.newsItemsTable)
        .select('*, projects(name)')
        .order('published_date', ascending: false)
        .limit(limit);

    return (response as List).map((json) => NewsItem.fromJson(json)).toList();
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(ref.watch(supabaseClientProvider));
});

class NewsListParams {
  final String? searchQuery;
  final NewsType? typeFilter;

  const NewsListParams({this.searchQuery, this.typeFilter});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsListParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          typeFilter == other.typeFilter;

  @override
  int get hashCode => searchQuery.hashCode ^ typeFilter.hashCode;
}

final newsListProvider =
    FutureProvider.family<List<NewsItem>, NewsListParams>((ref, params) async {
  return ref.watch(newsServiceProvider).getNewsItems(
        searchQuery: params.searchQuery,
        typeFilter: params.typeFilter,
      );
});

final newsDetailProvider =
    FutureProvider.family<NewsItem?, String>((ref, newsId) async {
  return ref.watch(newsServiceProvider).getNewsItemById(newsId);
});

final newsCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(newsServiceProvider).getNewsCount();
});

final recentNewsProvider = FutureProvider<List<NewsItem>>((ref) async {
  return ref.watch(newsServiceProvider).getRecentNews();
});
