import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

import '../../config/theme.dart';
import '../../models/member.dart';
import '../../models/enums.dart';
import '../../services/member_service.dart';

/// Create/edit member form with photo picker, date pickers, role selector,
/// tags input, and validation.
class MemberFormScreen extends ConsumerStatefulWidget {
  final String? memberId;

  const MemberFormScreen({super.key, this.memberId});

  bool get isEditing => memberId != null;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();

  MemberRole _role = MemberRole.member;
  DateTime _joinDate = DateTime.now();
  DateTime? _dateOfBirth;
  DateTime? _weddingAnniversary;
  List<String> _tags = [];
  bool _isActive = true;
  XFile? _selectedPhoto;
  String? _existingPhotoUrl;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _loadMember(Member member) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameController.text = member.name;
    _mobileController.text = member.mobile;
    _emailController.text = member.email ?? '';
    _addressController.text = member.address ?? '';
    _notesController.text = member.notes ?? '';
    _role = member.role;
    _joinDate = member.joinDate;
    _dateOfBirth = member.dateOfBirth;
    _weddingAnniversary = member.weddingAnniversary;
    _tags = List.from(member.tags);
    _isActive = member.isActive;
    _existingPhotoUrl = member.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    // If editing, load member data
    if (widget.isEditing) {
      final memberAsync = ref.watch(memberDetailProvider(widget.memberId!));
      return memberAsync.when(
        data: (member) {
          if (member == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Member')),
              body: const Center(child: Text('Member not found')),
            );
          }
          _loadMember(member);
          return _buildForm(context, member);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Member')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Member')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, Member? existing) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Member' : 'Add Member'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => _saveMember(existing),
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photo picker
            _buildPhotoPicker(),
            const SizedBox(height: 28),

            // Name
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outlined,
              required: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Mobile
            _buildTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              required: true,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email (optional)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Address
            _buildTextField(
              controller: _addressController,
              label: 'Address (optional)',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Role selector
            _buildSectionLabel('Role'),
            const SizedBox(height: 8),
            _buildRoleSelector(),
            const SizedBox(height: 24),

            // Joining Date Info
            _buildSectionLabel('Joining Details'),
            const SizedBox(height: 12),
            _buildMonthYearField(
              label: 'Join Month & Year',
              icon: Icons.calendar_today_outlined,
              value: _joinDate,
              onChanged: (d) => setState(() => _joinDate = d),
            ),
            const SizedBox(height: 24),

            // Tags
            _buildSectionLabel('Tags'),
            const SizedBox(height: 8),
            _buildTagsInput(),
            const SizedBox(height: 24),

            // Notes
            _buildTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              icon: Icons.notes_outlined,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Active toggle
            if (widget.isEditing) ...[
              _buildActiveToggle(),
              const SizedBox(height: 24),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveMember(existing),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(widget.isEditing ? 'Update Member' : 'Add Member'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: _selectedPhoto != null
                  ? (kIsWeb
                      ? NetworkImage(_selectedPhoto!.path)
                      : FileImage(io.File(_selectedPhoto!.path)) as ImageProvider)
                  : (_existingPhotoUrl != null
                      ? NetworkImage(_existingPhotoUrl!) as ImageProvider
                      : null),
              child: (_selectedPhoto == null && _existingPhotoUrl == null)
                  ? Icon(Icons.person, size: 44, color: AppTheme.primaryColor.withValues(alpha: 0.4))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Photo', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _selectedPhoto = pickedFile);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: MemberRole.values.map((role) {
        final isSelected = _role == role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: role != MemberRole.values.last ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => _role = role),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _roleIcon(role),
                      size: 20,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthYearField({
    required String label,
    required IconData icon,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      onTap: () => _pickMonthYear(value, onChanged),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          DateFormat('MMMM yyyy').format(value),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonthYear(DateTime initial, ValueChanged<DateTime> onChanged) async {
    int selectedYear = initial.year;
    int selectedMonth = initial.month;

    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Month & Year'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () {
                            setStateDialog(() => selectedYear--);
                          },
                        ),
                        Text(
                          '$selectedYear',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () {
                            setStateDialog(() => selectedYear++);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(12, (index) {
                        final isSelected = selectedMonth == index + 1;
                        return ChoiceChip(
                          label: SizedBox(
                            width: 60,
                            child: Center(
                              child: Text(
                                months[index].substring(0, 3),
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          onSelected: (selected) {
                            if (selected) {
                              setStateDialog(() => selectedMonth = index + 1);
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(selectedYear, selectedMonth, 1));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                )),
          ],
        ),
        if (_tags.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag (e.g., cooking, driving)',
                  prefixIcon: const Icon(Icons.label_outline),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addTag,
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isActive
            ? AppTheme.successColor.withValues(alpha: 0.05)
            : AppTheme.errorColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: _isActive
              ? AppTheme.successColor.withValues(alpha: 0.2)
              : AppTheme.errorColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: _isActive ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Status',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  _isActive ? 'Member is active' : 'Member is inactive',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Future<void> _saveMember(Member? existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(memberServiceProvider);

      // Check for duplicate mobile
      final isTaken = await service.isMobileNumberTaken(
        _mobileController.text.trim(),
        excludeMemberId: widget.memberId,
      );

      if (isTaken && mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This mobile number is already registered'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      String? photoUrl = _existingPhotoUrl;

      // Upload photo if selected
      if (_selectedPhoto != null && existing != null) {
        photoUrl = await service.uploadProfilePhoto(
          existing.id,
          _selectedPhoto!,
        );
      }

      final now = DateTime.now();
      final member = Member(
        id: existing?.id ?? '',
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        photoUrl: photoUrl,
        role: _role,
        joinDate: _joinDate,
        dateOfBirth: _dateOfBirth,
        weddingAnniversary: _weddingAnniversary,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isActive: _isActive,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        final updated = await service.updateMember(member);
        // Upload photo for updated member
        if (_selectedPhoto != null) {
          final newPhotoUrl = await service.uploadProfilePhoto(
            updated.id,
            _selectedPhoto!,
          );
          await service.updateMember(updated.copyWith(photoUrl: newPhotoUrl));
        }
      } else {
        final created = await service.createMember(member);
        // Upload photo for newly created member
        if (_selectedPhoto != null) {
          final newPhotoUrl = await service.uploadProfilePhoto(
            created.id,
            _selectedPhoto!,
          );
          await service.updateMember(created.copyWith(photoUrl: newPhotoUrl));
        }
      }

      ref.invalidate(memberListProvider);
      ref.invalidate(memberDetailProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Member updated' : 'Member added'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  IconData _roleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return Icons.admin_panel_settings;
      case MemberRole.volunteer:
        return Icons.volunteer_activism;
      case MemberRole.member:
        return Icons.person;
    }
  }
}
