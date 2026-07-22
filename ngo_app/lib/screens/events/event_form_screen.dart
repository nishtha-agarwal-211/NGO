import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/event.dart';
import '../../models/project.dart';
import '../../models/enums.dart';
import '../../services/event_service.dart';
import '../../services/project_service.dart';

/// Create/edit event form with project selection, date, time, location,
/// beneficiary details, and notes.
class EventFormScreen extends ConsumerStatefulWidget {
  final String? eventId;
  final String? projectId;

  const EventFormScreen({super.key, this.eventId, this.projectId});

  bool get isEditing => eventId != null;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _beneficiaryCountController = TextEditingController();
  final _beneficiaryDetailsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProjectId;
  DateTime _eventDate = DateTime.now();
  TimeOfDay? _eventTime;
  TimeOfDay? _eventEndTime;
  EventStatus _status = EventStatus.upcoming;

  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _beneficiaryCountController.dispose();
    _beneficiaryDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadEvent(Event event) {
    if (_isLoaded) return;
    _isLoaded = true;
    _titleController.text = event.title ?? '';
    _locationController.text = event.location ?? '';
    _beneficiaryCountController.text =
        event.beneficiaryCount > 0 ? event.beneficiaryCount.toString() : '';
    _beneficiaryDetailsController.text = event.beneficiaryDetails ?? '';
    _notesController.text = event.notes ?? '';
    _selectedProjectId = event.projectId;
    _eventDate = event.eventDate;
    _status = event.status;
    if (event.eventTime != null) {
      final parts = event.eventTime!.split(':');
      if (parts.length >= 2) {
        _eventTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    if (event.eventEndTime != null) {
      final parts = event.eventEndTime!.split(':');
      if (parts.length >= 2) {
        _eventEndTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final eventAsync = ref.watch(eventDetailProvider(widget.eventId!));
      return eventAsync.when(
        data: (event) {
          if (event == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Event')),
              body: const Center(child: Text('Event not found')),
            );
          }
          _loadEvent(event);
          return _buildForm(context, event);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Event')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Event')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, Event? existing) {
    // Fetch projects for dropdown
    final projectsAsync = ref.watch(
      projectListProvider(
        const ProjectListParams(statusFilter: ProjectStatus.active),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Event' : 'New Event'),
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
              onPressed: () => _saveEvent(existing),
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
            // ─── Project selector ──────────────────────────────
            _buildSectionHeader('Project'),
            const SizedBox(height: 8),
            projectsAsync.when(
              data: (projects) => _buildProjectDropdown(projects),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading projects: $e'),
            ),
            const SizedBox(height: 20),

            // ─── Title ─────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Event Title (optional)',
                prefixIcon: Icon(Icons.title),
                hintText: 'Auto-generated if empty',
              ),
            ),
            const SizedBox(height: 16),

            // ─── Date and Time ─────────────────────────────────
            InkWell(
              onTap: _pickEventDate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Event Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('EEE, MMM d, yyyy').format(_eventDate),
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickEventTime(isStart: true),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        prefixIcon: const Icon(Icons.access_time),
                        suffixIcon: _eventTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _eventTime = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _eventTime != null
                            ? _eventTime!.format(context)
                            : 'N/A',
                        style: GoogleFonts.inter(
                          color: _eventTime != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickEventTime(isStart: false),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        prefixIcon: const Icon(Icons.access_time_filled),
                        suffixIcon: _eventEndTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _eventEndTime = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _eventEndTime != null
                            ? _eventEndTime!.format(context)
                            : 'N/A',
                        style: GoogleFonts.inter(
                          color: _eventEndTime != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Location ──────────────────────────────────────
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Status (edit mode only) ───────────────────────
            if (widget.isEditing) ...[
              _buildSectionHeader('Status'),
              const SizedBox(height: 8),
              SegmentedButton<EventStatus>(
                segments: EventStatus.values
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
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ─── Beneficiaries ─────────────────────────────────
            _buildSectionHeader('Beneficiaries'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _beneficiaryCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Count',
                      prefixIcon: Icon(Icons.people_outlined),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (int.tryParse(v) == null) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beneficiaryDetailsController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Beneficiary Details (optional)',
                prefixIcon: Icon(Icons.info_outline),
                hintText: 'e.g., School name, ward number',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Notes ─────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Event Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                hintText: 'Summary of the day, observations...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ─── Save Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveEvent(existing),
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
                    Text(widget.isEditing ? 'Update Event' : 'Create Event'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDropdown(List<Project> projects) {
    return DropdownButtonFormField<String>(
      value: _selectedProjectId,
      decoration: const InputDecoration(
        labelText: 'Select Project',
        prefixIcon: Icon(Icons.folder_outlined),
      ),
      isExpanded: true,
      items: projects.map((p) {
        return DropdownMenuItem(
          value: p.id,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: p.isRecurring
                      ? AppTheme.secondaryColor
                      : AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  p.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              if (p.isRecurring)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.repeat,
                    size: 16,
                    color: AppTheme.textHint,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      validator: (v) => v == null ? 'Please select a project' : null,
      onChanged: (v) {
        setState(() => _selectedProjectId = v);
        // If user selects a project, auto-fill location and recurrence times
        if (v != null) {
          final project = projects.firstWhere((p) => p.id == v);
          if (project.recurrenceLocation != null &&
              _locationController.text.isEmpty) {
            _locationController.text = project.recurrenceLocation!;
          }
          if (project.recurrenceTime != null && _eventTime == null) {
            final parts = project.recurrenceTime!.split(':');
            if (parts.length >= 2) {
              setState(() {
                _eventTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              });
            }
          }
          if (project.recurrenceEndTime != null && _eventEndTime == null) {
            final parts = project.recurrenceEndTime!.split(':');
            if (parts.length >= 2) {
              setState(() {
                _eventEndTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              });
            }
          }
        }
      },
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

  IconData _statusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return Icons.schedule;
      case EventStatus.completed:
        return Icons.check_circle_outline;
      case EventStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _pickEventTime({required bool isStart}) async {
    final initial = isStart
        ? (_eventTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_eventEndTime ?? _eventTime ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _eventTime = picked;
        } else {
          _eventEndTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent(Event? existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(eventServiceProvider);

      final timeStr = _eventTime != null
          ? '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}:00'
          : null;
      final endTimeStr = _eventEndTime != null
          ? '${_eventEndTime!.hour.toString().padLeft(2, '0')}:${_eventEndTime!.minute.toString().padLeft(2, '0')}:00'
          : null;

      final now = DateTime.now();
      final event = Event(
        id: existing?.id ?? '',
        projectId: _selectedProjectId!,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        eventDate: _eventDate,
        eventTime: timeStr,
        eventEndTime: endTimeStr,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        beneficiaryCount: _beneficiaryCountController.text.trim().isNotEmpty
            ? int.tryParse(_beneficiaryCountController.text.trim()) ?? 0
            : 0,
        beneficiaryDetails:
            _beneficiaryDetailsController.text.trim().isEmpty
                ? null
                : _beneficiaryDetailsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: _status,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await service.updateEvent(event);
      } else {
        await service.createEvent(event);
      }

      ref.invalidate(eventListProvider);
      ref.invalidate(eventDetailProvider);
      ref.invalidate(upcomingEventsProvider);
      ref.invalidate(projectEventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.isEditing ? 'Event updated' : 'Event created'),
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
