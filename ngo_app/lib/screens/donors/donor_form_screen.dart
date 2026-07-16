import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../models/donor.dart';
import '../../models/enums.dart';
import '../../services/donor_service.dart';

/// Create/edit donor form with duplicate detection by mobile number.
class DonorFormScreen extends ConsumerStatefulWidget {
  final String? donorId;

  const DonorFormScreen({super.key, this.donorId});

  bool get isEditing => donorId != null;

  @override
  ConsumerState<DonorFormScreen> createState() => _DonorFormScreenState();
}

class _DonorFormScreenState extends ConsumerState<DonorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DonorType _donorType = DonorType.oneTime;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadDonor(Donor donor) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameController.text = donor.name;
    _mobileController.text = donor.mobile;
    _emailController.text = donor.email ?? '';
    _addressController.text = donor.address ?? '';
    _notesController.text = donor.notes ?? '';
    _donorType = donor.donorType;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final donorAsync = ref.watch(donorDetailProvider(widget.donorId!));
      return donorAsync.when(
        data: (donor) {
          if (donor == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Donor')),
              body: const Center(child: Text('Donor not found')),
            );
          }
          _loadDonor(donor);
          return _buildForm(context, donor);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Donor')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Donor')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, Donor? existing) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Donor' : 'Add Donor'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: () => _saveDonor(existing),
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
            // Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Mobile
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Mobile is required' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Donor type selector
            Text(
              'Donor Type',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: DonorType.values.map((type) {
                final isSelected = _donorType == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: type != DonorType.values.last ? 12 : 0),
                    child: InkWell(
                      onTap: () => setState(() => _donorType = type),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentColor
                              : AppTheme.accentColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentColor : AppTheme.dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type == DonorType.recurring ? Icons.repeat : Icons.looks_one_outlined,
                              size: 24,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveDonor(existing),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(widget.isEditing ? 'Update Donor' : 'Add Donor'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDonor(Donor? existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(donorServiceProvider);

      // Duplicate check
      final isTaken = await service.isMobileNumberTaken(
        _mobileController.text.trim(),
        excludeDonorId: widget.donorId,
      );

      if (isTaken && mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A donor with this mobile number already exists'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final donor = Donor(
        id: existing?.id ?? '',
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        donorType: _donorType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await service.updateDonor(donor);
      } else {
        await service.createDonor(donor);
      }

      ref.invalidate(donorListProvider);
      ref.invalidate(donorDetailProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Donor updated' : 'Donor added')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}
