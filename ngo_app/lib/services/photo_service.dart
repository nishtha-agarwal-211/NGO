import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/photo.dart';
import '../config/constants.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

/// Service for photo upload, compression, thumbnail generation,
/// and gallery management via Supabase Storage + Database.
class PhotoService {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  PhotoService(this._client);

  // ─── Photo CRUD ─────────────────────────────────────────────

  /// Fetch all photos for an event, ordered by creation date.
  Future<List<Photo>> getEventPhotos(String eventId) async {
    final response = await _client
        .from(AppConstants.photosTable)
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Photo.fromJson(json)).toList();
  }

  /// Fetch featured photos for an event.
  Future<List<Photo>> getFeaturedPhotos(String eventId) async {
    final response = await _client
        .from(AppConstants.photosTable)
        .select()
        .eq('event_id', eventId)
        .eq('is_featured', true)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Photo.fromJson(json)).toList();
  }

  /// Get photo count for an event.
  Future<int> getEventPhotoCount(String eventId) async {
    final response = await _client
        .from(AppConstants.photosTable)
        .select('id')
        .eq('event_id', eventId);

    return (response as List).length;
  }

  /// Delete a photo (removes from storage and database).
  Future<void> deletePhoto(Photo photo) async {
    // Remove from storage
    try {
      await _client.storage
          .from(SupabaseConfig.eventPhotosBucket)
          .remove([photo.storagePath]);
      if (photo.thumbnailPath != null) {
        await _client.storage
            .from(SupabaseConfig.eventPhotosBucket)
            .remove([photo.thumbnailPath!]);
      }
    } catch (_) {
      // Storage deletion may fail if file doesn't exist — continue
    }

    // Remove from database
    await _client.from(AppConstants.photosTable).delete().eq('id', photo.id);
  }

  /// Toggle featured status of a photo.
  Future<void> toggleFeatured(String photoId, bool isFeatured) async {
    await _client
        .from(AppConstants.photosTable)
        .update({'is_featured': isFeatured})
        .eq('id', photoId);
  }

  /// Update photo caption.
  Future<void> updateCaption(String photoId, String? caption) async {
    await _client
        .from(AppConstants.photosTable)
        .update({'caption': caption})
        .eq('id', photoId);
  }

  // ─── Photo Upload ─────────────────────────────────────────────

  /// Pick an image from camera or gallery.
  Future<XFile?> pickImage({required ImageSource source}) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      maxWidth: AppConstants.fullImageMaxWidth.toDouble(),
      maxHeight: AppConstants.fullImageMaxHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );
  }

  /// Pick multiple images from gallery.
  Future<List<XFile>> pickMultipleImages() async {
    final picker = ImagePicker();
    return await picker.pickMultiImage(
      maxWidth: AppConstants.fullImageMaxWidth.toDouble(),
      maxHeight: AppConstants.fullImageMaxHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );
  }

  /// Compress image file and return compressed bytes.
  Future<Uint8List?> _compressImage(String filePath) async {
    final result = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: AppConstants.fullImageMaxWidth,
      minHeight: AppConstants.fullImageMaxHeight,
      quality: AppConstants.imageQuality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// Generate thumbnail from image file.
  Future<Uint8List?> _generateThumbnail(String filePath) async {
    final result = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: AppConstants.thumbnailWidth,
      minHeight: AppConstants.thumbnailHeight,
      quality: AppConstants.thumbnailQuality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// Upload a photo: compress, generate thumbnail, upload to storage, insert DB row.
  /// Returns the created Photo record.
  Future<Photo> uploadPhoto({
    required String eventId,
    required String projectId,
    required String filePath,
    String? caption,
  }) async {
    final photoId = _uuid.v4();
    final storagePath = SupabaseConfig.eventPhotoPath(projectId, eventId, photoId);
    final thumbnailStoragePath = SupabaseConfig.eventThumbnailPath(projectId, eventId, photoId);

    // Compress original image
    final compressedBytes = await _compressImage(filePath);
    if (compressedBytes == null) {
      throw Exception('Failed to compress image');
    }

    // Generate thumbnail
    final thumbnailBytes = await _generateThumbnail(filePath);

    // Upload original
    await _client.storage
        .from(SupabaseConfig.eventPhotosBucket)
        .uploadBinary(
          storagePath,
          compressedBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final url = _client.storage
        .from(SupabaseConfig.eventPhotosBucket)
        .getPublicUrl(storagePath);

    // Upload thumbnail
    String? thumbnailUrl;
    if (thumbnailBytes != null) {
      await _client.storage
          .from(SupabaseConfig.eventPhotosBucket)
          .uploadBinary(
            thumbnailStoragePath,
            thumbnailBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      thumbnailUrl = _client.storage
          .from(SupabaseConfig.eventPhotosBucket)
          .getPublicUrl(thumbnailStoragePath);
    }

    // Insert database record
    final userId = _client.auth.currentUser?.id;
    final response = await _client
        .from(AppConstants.photosTable)
        .insert({
          'event_id': eventId,
          'storage_path': storagePath,
          'thumbnail_path': thumbnailStoragePath,
          'url': url,
          'thumbnail_url': thumbnailUrl,
          'caption': caption,
          'is_featured': false,
          'uploaded_by': userId,
        })
        .select()
        .single();

    return Photo.fromJson(response);
  }

  /// Upload multiple photos at once.
  /// Returns a stream of progress updates.
  Stream<PhotoUploadProgress> uploadMultiplePhotos({
    required String eventId,
    required String projectId,
    required List<String> filePaths,
  }) async* {
    for (var i = 0; i < filePaths.length; i++) {
      yield PhotoUploadProgress(
        current: i,
        total: filePaths.length,
        status: UploadStatus.uploading,
      );

      try {
        await uploadPhoto(
          eventId: eventId,
          projectId: projectId,
          filePath: filePaths[i],
        );

        yield PhotoUploadProgress(
          current: i + 1,
          total: filePaths.length,
          status: UploadStatus.uploading,
        );
      } catch (e) {
        yield PhotoUploadProgress(
          current: i,
          total: filePaths.length,
          status: UploadStatus.error,
          errorMessage: 'Failed to upload photo ${i + 1}: $e',
        );
      }
    }

    yield PhotoUploadProgress(
      current: filePaths.length,
      total: filePaths.length,
      status: UploadStatus.completed,
    );
  }
}

// ─── Upload Progress Model ──────────────────────────────────────

enum UploadStatus { uploading, completed, error }

class PhotoUploadProgress {
  final int current;
  final int total;
  final UploadStatus status;
  final String? errorMessage;

  const PhotoUploadProgress({
    required this.current,
    required this.total,
    required this.status,
    this.errorMessage,
  });

  double get progress => total > 0 ? current / total : 0;
  bool get isCompleted => status == UploadStatus.completed;
  bool get hasError => status == UploadStatus.error;
}

// ─── Riverpod Providers ─────────────────────────────────────────

final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService(ref.watch(supabaseClientProvider));
});

final eventPhotosProvider =
    FutureProvider.family<List<Photo>, String>((ref, eventId) async {
  return ref.watch(photoServiceProvider).getEventPhotos(eventId);
});

final eventPhotoCountProvider =
    FutureProvider.family<int, String>((ref, eventId) async {
  return ref.watch(photoServiceProvider).getEventPhotoCount(eventId);
});
