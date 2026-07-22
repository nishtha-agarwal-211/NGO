import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';


import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/photo.dart';
import '../../services/photo_service.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';

/// Full-screen photo/video gallery for an event.
/// Supports upload from camera/gallery for photos and videos,
/// grid/full-screen view, caption editing, featured toggle, and deletion.
class PhotoGalleryScreen extends ConsumerStatefulWidget {
  final String eventId;

  const PhotoGalleryScreen({super.key, required this.eventId});

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadStatusText;

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(eventPhotosProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Text(event?.displayTitle ?? 'Media Gallery'),
          loading: () => const Text('Media Gallery'),
          error: (_, __) => const Text('Media Gallery'),
        ),
        actions: [
          if (isAdminAsync.valueOrNull == true)
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_a_photo_outlined),
              onSelected: _handleUploadOption,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'camera',
                  child: ListTile(
                    leading: Icon(Icons.camera_alt_outlined),
                    title: Text('Take Photo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'record_video',
                  child: ListTile(
                    leading: Icon(Icons.videocam_outlined),
                    title: Text('Record Video'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'gallery',
                  child: ListTile(
                    leading: Icon(Icons.photo_library_outlined),
                    title: Text('Photo from Gallery'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'video_gallery',
                  child: ListTile(
                    leading: Icon(Icons.video_library_outlined),
                    title: Text('Video from Gallery'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'multi',
                  child: ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Multiple Photos'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Upload progress indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _uploadStatusText ?? 'Uploading...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),

          // Photo grid
          Expanded(
            child: photosAsync.when(
              data: (photos) => photos.isEmpty
                  ? _buildEmptyState()
                  : _buildPhotoGrid(photos),
              loading: () => _buildLoadingGrid(),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppTheme.errorColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('Failed to load photos',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(error.toString(),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(eventPhotosProvider(widget.eventId)),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Photos Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the camera icon above to add photos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textHint,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingSM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoGrid(List<Photo> photos) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(eventPhotosProvider(widget.eventId));
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingSM),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return _PhotoGridTile(
            photo: photo,
            onTap: () => _openPhotoViewer(photos, index),
          );
        },
      ),
    );
  }

  void _openPhotoViewer(List<Photo> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
          eventId: widget.eventId,
          onDelete: (photo) => _deletePhoto(photo),
          onToggleFeatured: (photo) => _toggleFeatured(photo),
        ),
      ),
    );
  }

  Future<void> _handleUploadOption(String option) async {
    final photoService = ref.read(photoServiceProvider);
    final event = ref.read(eventDetailProvider(widget.eventId)).valueOrNull;
    if (event == null) return;

    switch (option) {
      case 'camera':
        final xFile = await photoService.pickImage(source: ImageSource.camera);
        if (xFile != null) {
          await _uploadSinglePhoto(xFile, event.projectId);
        }
        break;
      case 'record_video':
        final xFile = await photoService.pickVideo(source: ImageSource.camera);
        if (xFile != null) {
          await _uploadVideo(xFile, event.projectId);
        }
        break;
      case 'gallery':
        final xFile = await photoService.pickImage(source: ImageSource.gallery);
        if (xFile != null) {
          await _uploadSinglePhoto(xFile, event.projectId);
        }
        break;
      case 'video_gallery':
        final xFile = await photoService.pickVideo(source: ImageSource.gallery);
        if (xFile != null) {
          await _uploadVideo(xFile, event.projectId);
        }
        break;
      case 'multi':
        final xFiles = await photoService.pickMultipleImages();
        if (xFiles.isNotEmpty) {
          await _uploadMultiplePhotos(
            xFiles,
            event.projectId,
          );
        }
        break;
    }
  }

  Future<void> _uploadVideo(XFile videoFile, String projectId) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.5;
      _uploadStatusText = 'Uploading video...';
    });

    try {
      await ref.read(photoServiceProvider).uploadVideo(
            eventId: widget.eventId,
            projectId: projectId,
            videoFile: videoFile,
          );

      ref.invalidate(eventPhotosProvider(widget.eventId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video upload failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadStatusText = null;
        });
      }
    }
  }

  Future<void> _uploadSinglePhoto(XFile file, String projectId) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatusText = 'Uploading photo...';
    });

    try {
      await ref.read(photoServiceProvider).uploadPhoto(
            eventId: widget.eventId,
            projectId: projectId,
            file: file,
          );

      ref.invalidate(eventPhotosProvider(widget.eventId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadStatusText = null;
        });
      }
    }
  }

  Future<void> _uploadMultiplePhotos(List<XFile> files, String projectId) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatusText = 'Uploading 0/${files.length}...';
    });

    final photoService = ref.read(photoServiceProvider);
    int uploaded = 0;

    for (final file in files) {
      try {
        await photoService.uploadPhoto(
          eventId: widget.eventId,
          projectId: projectId,
          file: file,
        );
        uploaded++;
        if (mounted) {
          setState(() {
            _uploadProgress = uploaded / files.length;
            _uploadStatusText = 'Uploading $uploaded/${files.length}...';
          });
        }
      } catch (e) {
        // Continue with remaining photos
      }
    }

    ref.invalidate(eventPhotosProvider(widget.eventId));

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
        _uploadStatusText = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$uploaded/${files.length} photos uploaded'),
          backgroundColor: uploaded > 0 ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deletePhoto(Photo photo) async {
    try {
      await ref.read(photoServiceProvider).deletePhoto(photo);
      ref.invalidate(eventPhotosProvider(widget.eventId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleFeatured(Photo photo) async {
    try {
      await ref.read(photoServiceProvider).toggleFeatured(photo.id, !photo.isFeatured);
      ref.invalidate(eventPhotosProvider(widget.eventId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// ─── Photo / Video Grid Tile ────────────────────────────────────────────

class _PhotoGridTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _PhotoGridTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'photo_${photo.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.thumbnailUrl != null || photo.isPhoto)
                CachedNetworkImage(
                  imageUrl: photo.displayUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: Icon(
                      photo.isVideo ? Icons.videocam : Icons.broken_image,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white70,
                      size: 40,
                    ),
                  ),
                ),

              // Video overlay & play icon
              if (photo.isVideo) ...[
                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam, size: 12, color: Colors.white),
                        if (photo.formattedDuration.isNotEmpty) ...[
                          const SizedBox(width: 3),
                          Text(
                            photo.formattedDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Featured star indicator
              if (photo.isFeatured)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Full-Screen Photo & Video Viewer ───────────────────────────────────

class _PhotoViewerScreen extends ConsumerStatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final String eventId;
  final Function(Photo) onDelete;
  final Function(Photo) onToggleFeatured;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
    required this.eventId,
    required this.onDelete,
    required this.onToggleFeatured,
  });

  @override
  ConsumerState<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Photo get _currentPhoto => widget.photos[_currentIndex];

  Future<void> _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video player')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_currentPhoto.isVideo)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              onPressed: () => _launchVideo(_currentPhoto.url),
              tooltip: 'Play in video player',
            ),
          if (isAdmin) ...[
            IconButton(
              icon: Icon(
                _currentPhoto.isFeatured ? Icons.star : Icons.star_border,
                color: _currentPhoto.isFeatured
                    ? AppTheme.secondaryColor
                    : Colors.white,
              ),
              onPressed: () {
                widget.onToggleFeatured(_currentPhoto);
                setState(() {});
              },
              tooltip: 'Toggle featured',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _confirmDelete(),
              tooltip: _currentPhoto.isVideo ? 'Delete video' : 'Delete photo',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Swipeable media items
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];

              if (photo.isVideo) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _launchVideo(photo.url),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Video Media',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _launchVideo(photo.url),
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Play Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return InteractiveViewer(
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    ),
                  ),
                ),
              );
            },
          ),

          // Caption overlay
          if (_currentPhoto.caption != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Text(
                    _currentPhoto.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('This photo will be permanently deleted. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDelete(_currentPhoto);
      Navigator.pop(context);
    }
  }
}
