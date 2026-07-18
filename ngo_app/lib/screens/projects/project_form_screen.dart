import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/project.dart';
import '../../models/enums.dart';
import '../../services/project_service.dart';
import '../../services/event_service.dart';

/// Create/edit project form with recurrence configuration.
class ProjectFormScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const ProjectFormScreen({super.key, this.projectId});

  bool get isEditing => projectId != null;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _goalDescriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _targetBeneficiaryController = TextEditingController();
  final _recurrenceLocationController = TextEditingController();

  ProjectType _projectType = ProjectType.ongoing;
  ProjectStatus _status = ProjectStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _recurrenceDayOfWeek;
  TimeOfDay? _recurrenceTime;

  bool _isSaving = false;
  bool _isLoaded = false;

  // Category suggestions
  static const _categories = [
    'Food',
    'Education',
    'Medical',
    'Environment',
    'Women Empowerment',
    'Child Welfare',
    'Community',
    'Infrastructure',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _goalDescriptionController.dispose();
    _targetAmountController.dispose();
    _targetBeneficiaryController.dispose();
    _recurrenceLocationController.dispose();
    super.dispose();
  }

  void _loadProject(Project project) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameController.text = project.name;
    _descriptionController.text = project.description ?? '';
    _categoryController.text = project.category ?? '';
    _goalDescriptionController.text = project.goalDescription ?? '';
    _targetAmountController.text =
        project.targetAmount != null ? project.targetAmount.toString() : '';
    _targetBeneficiaryController.text =
        project.targetBeneficiaryCount != null
            ? project.targetBeneficiaryCount.toString()
            : '';
    _recurrenceLocationController.text = project.recurrenceLocation ?? '';
    _projectType = project.projectType;
    _status = project.status;
    _startDate = project.startDate;
    _endDate = project.endDate;
    _recurrenceDayOfWeek = project.recurrenceDayOfWeek;
    if (project.recurrenceTime != null) {
      final parts = project.recurrenceTime!.split(':');
      if (parts.length >= 2) {
        _recurrenceTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final projectAsync = ref.watch(projectDetailProvider(widget.projectId!));
      return projectAsync.when(
        data: (project) {
          if (project == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Project')),
              body: const Center(child: Text('Project not found')),
            );
          }
          _loadProject(project);
          return _buildForm(context, project);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Project')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Project')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, Project? existing) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Project' : 'New Project'),
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
              onPressed: () => _saveProject(existing),
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
            // ─── Name ──────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // ─── Description ───────────────────────────────────
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // ─── Category ──────────────────────────────────────
            Autocomplete<String>(
              optionsBuilder: (value) {
                if (value.text.isEmpty) return _categories;
                return _categories.where(
                  (c) => c.toLowerCase().contains(value.text.toLowerCase()),
                );
              },
              initialValue: TextEditingValue(text: _categoryController.text),
              onSelected: (value) => _categoryController.text = value,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                // Sync with our controller
                if (controller.text.isEmpty &&
                    _categoryController.text.isNotEmpty) {
                  controller.text = _categoryController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) => _categoryController.text = v,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    prefixIcon: Icon(Icons.category_outlined),
                    hintText: 'e.g., Food, Education, Medical',
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── Project Type ──────────────────────────────────
            _buildSectionHeader('Project Type'),
            const SizedBox(height: 8),
            Row(
              children: ProjectType.values.map((type) {
                final isSelected = _projectType == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type != ProjectType.values.last ? 12 : 0,
                    ),
                    child: InkWell(
                      onTap: () => setState(() {
                        _projectType = type;
                        if (type == ProjectType.ongoing) {
                          _recurrenceDayOfWeek = null;
                          _recurrenceTime = null;
                        }
                      }),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type == ProjectType.recurring
                                  ? Icons.repeat
                                  : Icons.trending_up,
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              type.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
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

            // ─── Recurrence Config (recurring projects only) ───
            if (_projectType == ProjectType.recurring) ...[
              _buildSectionHeader('Recurrence Schedule'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day of week
                    Text(
                      'Day of Week',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.dayOfWeekNames.entries.map((e) {
                        final isSelected = _recurrenceDayOfWeek == e.key;
                        return ChoiceChip(
                          label: Text(e.value.substring(0, 3)),
                          selected: isSelected,
                          selectedColor: AppTheme.secondaryColor,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                          onSelected: (_) => setState(
                            () => _recurrenceDayOfWeek = isSelected ? null : e.key,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Time
                    InkWell(
                      onTap: _pickRecurrenceTime,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _recurrenceTime != null
                              ? _recurrenceTime!.format(context)
                              : 'Select time',
                          style: GoogleFonts.inter(
                            color: _recurrenceTime != null
                                ? AppTheme.textPrimary
                                : AppTheme.textHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _recurrenceLocationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Default Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── Status ────────────────────────────────────────
            if (widget.isEditing) ...[
              _buildSectionHeader('Status'),
              const SizedBox(height: 8),
              SegmentedButton<ProjectStatus>(
                segments: ProjectStatus.values
                    .map(
                      (s) => ButtonSegment(
                        value: s,
                        label: Text(s.displayName),
                        icon: Icon(_statusIcon(s)),
                      ),
                    )
                    .toList(),
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── Dates ─────────────────────────────────────────
            _buildSectionHeader('Dates'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: true),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_startDate),
                        style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date (optional)',
                        prefixIcon: const Icon(Icons.event),
                        suffixIcon: _endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _endDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('MMM d, yyyy').format(_endDate!)
                            : 'Open-ended',
                        style: GoogleFonts.inter(
                          color: _endDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Campaign / Goal fields ────────────────────────
            _buildSectionHeader('Goal & Targets (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _goalDescriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Goal Description',
                prefixIcon: Icon(Icons.flag_outlined),
                hintText: 'e.g., Sponsor 50 students\' school fees',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (double.tryParse(v) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _targetBeneficiaryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Beneficiaries',
                      prefixIcon: Icon(Icons.people_outlined),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (int.tryParse(v) == null) {
                          return 'Invalid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── Save Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveProject(existing),
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
                label:
                    Text(widget.isEditing ? 'Update Project' : 'Create Project'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Icons.play_circle_outline;
      case ProjectStatus.completed:
        return Icons.check_circle_outline;
      case ProjectStatus.paused:
        return Icons.pause_circle_outline;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickRecurrenceTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _recurrenceTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _recurrenceTime = picked);
    }
  }

  Future<void> _saveProject(Project? existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(projectServiceProvider);

      final timeStr = _recurrenceTime != null
          ? '${_recurrenceTime!.hour.toString().padLeft(2, '0')}:${_recurrenceTime!.minute.toString().padLeft(2, '0')}:00'
          : null;

      final now = DateTime.now();
      final project = Project(
        id: existing?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        projectType: _projectType,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        recurrenceDayOfWeek:
            _projectType == ProjectType.recurring ? _recurrenceDayOfWeek : null,
        recurrenceTime:
            _projectType == ProjectType.recurring ? timeStr : null,
        recurrenceLocation:
            _projectType == ProjectType.recurring &&
                    _recurrenceLocationController.text.trim().isNotEmpty
                ? _recurrenceLocationController.text.trim()
                : null,
        goalDescription: _goalDescriptionController.text.trim().isEmpty
            ? null
            : _goalDescriptionController.text.trim(),
        targetAmount: _targetAmountController.text.trim().isNotEmpty
            ? double.tryParse(_targetAmountController.text.trim())
            : null,
        targetBeneficiaryCount:
            _targetBeneficiaryController.text.trim().isNotEmpty
                ? int.tryParse(_targetBeneficiaryController.text.trim())
                : null,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      Project savedProject;
      if (widget.isEditing) {
        savedProject = await service.updateProject(project);
      } else {
        savedProject = await service.createProject(project);
      }

      // Auto-generate events for recurring projects
      if (_projectType == ProjectType.recurring &&
          _recurrenceDayOfWeek != null) {
        final eventService = ref.read(eventServiceProvider);
        final count = await eventService.generateRecurringEvents(savedProject.id);
        if (count > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-generated $count upcoming events'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }

      ref.invalidate(projectListProvider);
      ref.invalidate(projectDetailProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Project updated' : 'Project created'),
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
}
