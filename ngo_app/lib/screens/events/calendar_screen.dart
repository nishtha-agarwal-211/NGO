import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/theme.dart';
import '../../models/event.dart';
import '../../models/enums.dart';
import '../../services/event_service.dart';
import '../../widgets/scale_tap_wrapper.dart';

/// Calendar screen showing all events across projects.
/// Uses table_calendar for the calendar widget with event dots,
/// and shows a list of events for the selected day below.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Event>> _eventMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final service = ref.read(eventServiceProvider);
      final map = await service.getEventsForCalendar(firstDay, lastDay);

      if (mounted) {
        setState(() {
          _eventMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadEvents();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Event',
            onPressed: () => context.push('/events/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Calendar Widget ────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: AppTheme.adaptiveCardDecoration(
              context,
              radius: AppTheme.radiusLarge,
            ),
            child: TableCalendar<Event>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadEvents();
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondaryDark,
                ),
                selectedDecoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                defaultTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.dynamicTextPrimary(context),
                ),
                weekendTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorColor,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 6,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: primary),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                formatButtonTextStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.dynamicTextPrimary(context),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dynamicTextSecondary(context),
                ),
                weekendStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),

          // ─── Selected Day Info ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selectedEvents.isEmpty
                        ? AppTheme.dynamicTextHint(context).withValues(alpha: 0.15)
                        : AppTheme.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selectedEvents.isEmpty
                          ? AppTheme.dynamicTextHint(context)
                          : AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Events List ───────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedEvents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) =>
                            _buildEventCard(selectedEvents[index]),
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
          Icon(
            Icons.event_available,
            size: 56,
            color: AppTheme.dynamicTextHint(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No events on this day',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/events/add'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Event'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final effectiveStatus = event.effectiveStatus;
    final statusColor = _getStatusColor(effectiveStatus);
    final timeDisplay = event.formattedTimeRange.isNotEmpty
        ? event.formattedTimeRange
        : (event.eventTime != null ? _formatTime(event.eventTime!) : '');

    return ScaleTapWrapper(
      onTap: () => context.push('/events/${event.id}'),
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.adaptiveCardDecoration(
          context,
          radius: AppTheme.radiusMedium,
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.displayTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (event.projectName != null) ...[
                        Icon(
                          Icons.folder_outlined,
                          size: 14,
                          color: AppTheme.dynamicTextHint(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.projectName!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (timeDisplay.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.dynamicTextHint(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeDisplay,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (event.location != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.dynamicTextHint(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.location!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                effectiveStatus.displayName,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.dynamicTextHint(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return Theme.of(context).colorScheme.primary;
      case EventStatus.completed:
        return AppTheme.successColor;
      case EventStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final tod = TimeOfDay(hour: hour, minute: minute);
        final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
        final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
        return '$h:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return timeStr;
  }
}

