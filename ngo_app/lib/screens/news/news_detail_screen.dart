import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';
import '../../models/news_item.dart';
import '../../services/news_service.dart';
import '../../services/auth_service.dart';

/// News detail screen — shows full news item with YouTube embed,
/// clipping image, article link, and sharing functionality.
class NewsDetailScreen extends ConsumerWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsDetailProvider(newsId));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return newsAsync.when(
      data: (newsItem) {
        if (newsItem == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('News item not found')),
          );
        }
        return _NewsDetailContent(
          newsItem: newsItem,
          isAdmin: isAdmin,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(newsDetailProvider(newsId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsDetailContent extends ConsumerWidget {
  final NewsItem newsItem;
  final bool isAdmin;

  const _NewsDetailContent({
    required this.newsItem,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detail'),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareNews(context),
            tooltip: 'Share',
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YouTube video thumbnail / Clipping image
            if (newsItem.isVideo && newsItem.youtubeThumbnailUrl != null)
              _buildVideoThumbnail(context)
            else if (newsItem.clippingImageUrl != null)
              _buildClippingImage(context),

            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + source
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: newsItem.isVideo
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppTheme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              newsItem.isVideo
                                  ? Icons.play_circle_outline
                                  : Icons.article_outlined,
                              size: 16,
                              color: newsItem.isVideo
                                  ? Colors.red
                                  : AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              newsItem.newsType.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: newsItem.isVideo
                                    ? Colors.red
                                    : AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateFormat.format(newsItem.publishedDate),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    newsItem.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Source row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.source_outlined,
                            size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            newsItem.sourceName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Linked project
                  if (newsItem.linkedProjectName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.05),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined,
                              size: 18, color: AppTheme.accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Project: ${newsItem.linkedProjectName}',
                            style: const TextStyle(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Summary
                  if (newsItem.summary != null) ...[
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsItem.summary!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  if (newsItem.articleUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(newsItem.articleUrl!),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Read Full Article'),
                      ),
                    ),

                  if (newsItem.youtubeUrl != null) ...[
                    if (newsItem.articleUrl != null)
                      const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(newsItem.youtubeUrl!),
                        icon: const Icon(Icons.play_circle_filled, size: 18),
                        label: const Text('Watch Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (newsItem.youtubeUrl != null) _openUrl(newsItem.youtubeUrl!);
      },
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 220,
            child: CachedNetworkImage(
              imageUrl: newsItem.youtubeThumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClippingImage(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: newsItem.clippingImageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(height: 200, color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Future<void> _shareNews(BuildContext context) async {
    final text = StringBuffer('${newsItem.title}\n');
    text.write('Source: ${newsItem.sourceName}\n');
    if (newsItem.articleUrl != null) text.write('\n${newsItem.articleUrl}');
    if (newsItem.youtubeUrl != null) text.write('\n${newsItem.youtubeUrl}');

    await Share.share(text.toString());
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleMenuAction(
      BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        context.push('/news/${newsItem.id}/edit');
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete News Item'),
            content: const Text(
                'This will permanently delete this news item. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            await ref.read(newsServiceProvider).deleteNewsItem(newsItem.id);
            if (context.mounted) {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('News item deleted'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        }
        break;
    }
  }
}
