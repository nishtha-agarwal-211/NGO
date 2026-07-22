import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/news_item.dart';
import '../../models/enums.dart';
import '../../services/news_service.dart';
import '../../services/project_service.dart';
import '../../utils/error_utils.dart';


/// News form screen — admin-only, for creating/editing news items.
/// Supports article URL, YouTube URL, clipping image upload, and project linking.
class NewsFormScreen extends ConsumerStatefulWidget {
  final String? newsId;

  const NewsFormScreen({super.key, this.newsId});

  bool get isEditing => newsId != null;

  @override
  ConsumerState<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends ConsumerState<NewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _sourceNameController = TextEditingController();
  final _articleUrlController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _summaryController = TextEditingController();

  NewsType _newsType = NewsType.article;
  DateTime _publishedDate = DateTime.now();
  String? _linkedProjectId;
  String? _clippingImageUrl;
  String? _clippingStoragePath;
  XFile? _pendingClippingFile;
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingItem();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceNameController.dispose();
    _articleUrlController.dispose();
    _youtubeUrlController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingItem() async {
    setState(() => _isLoading = true);
    try {
      final newsItem = await ref
          .read(newsServiceProvider)
          .getNewsItemById(widget.newsId!);

      if (newsItem != null && mounted) {
        setState(() {
          _titleController.text = newsItem.title;
          _sourceNameController.text = newsItem.sourceName;
          _articleUrlController.text = newsItem.articleUrl ?? '';
          _youtubeUrlController.text = newsItem.youtubeUrl ?? '';
          _summaryController.text = newsItem.summary ?? '';
          _newsType = newsItem.newsType;
          _publishedDate = newsItem.publishedDate;
          _linkedProjectId = newsItem.linkedProjectId;
          _clippingImageUrl = newsItem.clippingImageUrl;
          _clippingStoragePath = newsItem.clippingStoragePath;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(
      projectListProvider(const ProjectListParams()),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit News Item' : 'Add News Item'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                children: [
                  // News Type selector
                  Text(
                    'Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeCard(
                          label: 'Article',
                          icon: Icons.article_outlined,
                          isSelected: _newsType == NewsType.article,
                          onTap: () =>
                              setState(() => _newsType = NewsType.article),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeCard(
                          label: 'Video',
                          icon: Icons.play_circle_outline,
                          isSelected: _newsType == NewsType.video,
                          onTap: () =>
                              setState(() => _newsType = NewsType.video),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      prefixIcon: Icon(Icons.title),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Source Name
                  TextFormField(
                    controller: _sourceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Source Name *',
                      prefixIcon: Icon(Icons.source_outlined),
                      hintText: 'e.g. Times of India, YouTube',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Source name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Published Date
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Published Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          hintText: DateFormat('MMM d, yyyy').format(_publishedDate),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('MMM d, yyyy').format(_publishedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Article URL (shown for articles)
                  if (_newsType == NewsType.article) ...[
                    TextFormField(
                      controller: _articleUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Article URL',
                        prefixIcon: Icon(Icons.link),
                        hintText: 'https://...',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // YouTube URL (shown for videos)
                  if (_newsType == NewsType.video) ...[
                    TextFormField(
                      controller: _youtubeUrlController,
                      decoration: const InputDecoration(
                        labelText: 'YouTube URL',
                        prefixIcon: Icon(Icons.play_circle_outline),
                        hintText: 'https://youtube.com/watch?v=...',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Linked Project
                  projectsAsync.when(
                    data: (projects) => DropdownButtonFormField<String>(
                      value: _linkedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Linked Project (optional)',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...projects.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            )),
                      ],
                      onChanged: (value) =>
                          setState(() => _linkedProjectId = value),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 16),

                  // Summary
                  TextFormField(
                    controller: _summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Summary',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // Clipping image
                  Text(
                    'Clipping Image (optional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_clippingImageUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          child: Image.network(
                            _clippingImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            onPressed: () {
                              setState(() {
                                _clippingImageUrl = null;
                                _clippingStoragePath = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickClippingImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Upload Clipping'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNewsItem,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _publishedDate = date);
    }
  }

  Future<void> _pickClippingImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (xFile == null) return;

    // For new items, we'll upload after saving
    // For existing items, upload immediately
    if (widget.isEditing) {
      try {
        final url = await ref
            .read(newsServiceProvider)
            .uploadClippingImage(widget.newsId!, xFile);
        setState(() {
          _clippingImageUrl = url;
        });
      } catch (e) {
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, e);
        }
      }
    } else {
      // Store XFile temporarily — will upload after news item is created
      setState(() {
        _pendingClippingFile = xFile;
        _clippingImageUrl = xFile.path; // temp local path for preview
        _clippingStoragePath = 'pending_upload';
      });
    }
  }

  Future<void> _saveNewsItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newsService = ref.read(newsServiceProvider);
      final now = DateTime.now();

      if (widget.isEditing) {
        // Update existing
        final updated = NewsItem(
          id: widget.newsId!,
          title: _titleController.text.trim(),
          sourceName: _sourceNameController.text.trim(),
          newsType: _newsType,
          articleUrl: _articleUrlController.text.trim().isEmpty
              ? null
              : _articleUrlController.text.trim(),
          youtubeUrl: _youtubeUrlController.text.trim().isEmpty
              ? null
              : _youtubeUrlController.text.trim(),
          clippingImageUrl: _clippingStoragePath == 'pending_upload'
              ? null
              : _clippingImageUrl,
          clippingStoragePath: _clippingStoragePath == 'pending_upload'
              ? null
              : _clippingStoragePath,
          linkedProjectId: _linkedProjectId,
          publishedDate: _publishedDate,
          summary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );

        await newsService.updateNewsItem(updated);
      } else {
        // Create new
        final newsItem = NewsItem(
          id: '', // will be auto-generated
          title: _titleController.text.trim(),
          sourceName: _sourceNameController.text.trim(),
          newsType: _newsType,
          articleUrl: _articleUrlController.text.trim().isEmpty
              ? null
              : _articleUrlController.text.trim(),
          youtubeUrl: _youtubeUrlController.text.trim().isEmpty
              ? null
              : _youtubeUrlController.text.trim(),
          linkedProjectId: _linkedProjectId,
          publishedDate: _publishedDate,
          summary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );

        final created = await newsService.createNewsItem(newsItem);

        // Upload clipping if pending
        if (_clippingStoragePath == 'pending_upload' &&
            _pendingClippingFile != null) {
          try {
            final url = await newsService.uploadClippingImage(
                created.id, _pendingClippingFile!);
            await newsService.updateNewsItem(created.copyWith(
              clippingImageUrl: url,
            ));
          } catch (_) {
            // Non-critical — news item was still created
          }
        }
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'News item updated'
                : 'News item created'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── Type Card Widget ───────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textHint,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
