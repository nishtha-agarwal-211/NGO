import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/news_item.dart';
import '../../models/enums.dart';
import '../../services/news_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/scale_tap_wrapper.dart';

/// News list screen — public access (no auth required).
/// Supports search, filter by type (article/video), and pull-to-refresh.
class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen> {
  final _searchController = TextEditingController();
  NewsType? _typeFilter;
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  NewsListParams get _params => NewsListParams(
        searchQuery: _searchQuery,
        typeFilter: _typeFilter,
      );

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsListProvider(_params));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Media'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.newsAdd),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Search + Filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMD,
              AppTheme.spacingSM,
              AppTheme.spacingMD,
              AppTheme.spacingMD,
            ),
            decoration: BoxDecoration(
              color: AppTheme.dynamicCardColor(context),
              border: Border(
                bottom: BorderSide(color: AppTheme.dynamicBorder(context)),
              ),
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.dynamicTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Search news...',
                    hintStyle: TextStyle(color: AppTheme.dynamicTextHint(context)),
                    prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.dynamicTextHint(context)),
                    suffixIcon: _searchQuery != null
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 20, color: AppTheme.dynamicTextHint(context)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = null);
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value.isEmpty ? null : value;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Type filter chips
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _typeFilter == null,
                      onTap: () => setState(() => _typeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Articles',
                      icon: Icons.article_outlined,
                      isSelected: _typeFilter == NewsType.article,
                      onTap: () => setState(() => _typeFilter = NewsType.article),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Videos',
                      icon: Icons.play_circle_outline,
                      isSelected: _typeFilter == NewsType.video,
                      onTap: () => setState(() => _typeFilter = NewsType.video),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // News list
          Expanded(
            child: newsAsync.when(
              data: (newsItems) {
                if (newsItems.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(newsListProvider(_params));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingSM,
                    ),
                    itemCount: newsItems.length,
                    itemBuilder: (context, index) {
                      return ScaleTapWrapper(
                        onTap: () => context.push('/news/${newsItems[index].id}'),
                        pressedScale: 0.98,
                        child: _NewsCard(
                          newsItem: newsItems[index],
                          onTap: () => context.push('/news/${newsItems[index].id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => _buildLoadingList(),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppTheme.errorColor),
                    const SizedBox(height: 12),
                    Text('Failed to load news',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(newsListProvider(_params)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper_outlined,
              size: 64,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery != null || _typeFilter != null
                ? 'No Matching News'
                : 'No News Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery != null || _typeFilter != null
                ? 'Try adjusting your filters'
                : 'News coverage will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return const ShimmerLoadingList(itemCount: 5, itemHeight: 120);
  }
}

// ─── Filter Chip ────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : AppTheme.dynamicBorder(context).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected
                ? primary
                : AppTheme.dynamicBorder(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.dynamicTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── News Card ──────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsItem newsItem;
  final VoidCallback onTap;

  const _NewsCard({required this.newsItem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasImage = newsItem.isVideo && newsItem.youtubeThumbnailUrl != null;
    final hasClipping = newsItem.clippingImageUrl != null;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingXS,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.adaptiveCardDecoration(
          context,
          radius: AppTheme.radiusLarge,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (hasImage || hasClipping)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: SizedBox(
                  width: 90,
                  height: 70,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: hasImage
                            ? newsItem.youtubeThumbnailUrl!
                            : newsItem.clippingImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.dynamicBorder(context).withValues(alpha: 0.3),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.dynamicBorder(context).withValues(alpha: 0.3),
                          child: Icon(Icons.image, color: AppTheme.dynamicTextHint(context)),
                        ),
                      ),
                      if (newsItem.isVideo)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: 90,
                height: 70,
                decoration: BoxDecoration(
                  color: newsItem.isVideo
                      ? AppTheme.errorColor.withValues(alpha: 0.12)
                      : primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  newsItem.isVideo
                      ? Icons.play_circle_outline
                      : Icons.article_outlined,
                  size: 32,
                  color: newsItem.isVideo ? AppTheme.errorColor : primary,
                ),
              ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: newsItem.isVideo
                              ? AppTheme.errorColor.withValues(alpha: 0.12)
                              : AppTheme.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          newsItem.newsType.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: newsItem.isVideo
                                ? AppTheme.errorColor
                                : AppTheme.accentColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateFormat.format(newsItem.publishedDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    newsItem.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),

                  // Source
                  Row(
                    children: [
                      Icon(
                        Icons.source_outlined,
                        size: 14,
                        color: AppTheme.dynamicTextHint(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          newsItem.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),

                  // Linked project
                  if (newsItem.linkedProjectName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            newsItem.linkedProjectName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
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
}

