import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'member_service.dart';
import 'event_service.dart';

/// Service for local notifications — birthday reminders, event reminders.
/// Uses flutter_local_notifications for scheduling.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification channel IDs
  static const String _birthdayChannelId = 'birthday_reminders';
  static const String _eventChannelId = 'event_reminders';

  /// Initialize the notification plugin.
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen
    // This can be enhanced with routing based on payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show an immediate notification.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _birthdayChannelId
          ? 'Birthday Reminders'
          : channelId == _eventChannelId
              ? 'Event Reminders'
              : 'General',
      channelDescription: 'NGO Manager notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Check for upcoming birthdays and show notifications.
  static Future<void> checkBirthdayReminders(MemberService memberService) async {
    try {
      final members = await memberService.getUpcomingBirthdays(withinDays: 1);

      for (final member in members) {
        final days = member.daysUntilBirthday;
        final title = days == 0
            ? '🎂 Happy Birthday!'
            : '🎂 Birthday Tomorrow!';
        final body = days == 0
            ? 'It\'s ${member.name}\'s birthday today!'
            : '${member.name}\'s birthday is tomorrow!';

        await showNotification(
          id: member.id.hashCode,
          title: title,
          body: body,
          channelId: _birthdayChannelId,
          payload: 'member:${member.id}',
        );
      }
    } catch (e) {
      debugPrint('Birthday notification check failed: $e');
    }
  }

  /// Check for upcoming events and show notifications.
  static Future<void> checkEventReminders(EventService eventService) async {
    try {
      final events = await eventService.getUpcomingEvents(limit: 20);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final event in events) {
        final eventDay = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
        );
        final daysUntil = eventDay.difference(today).inDays;

        // Notify for events happening today or tomorrow
        if (daysUntil <= 1) {
          final title = daysUntil == 0
              ? '📅 Event Today!'
              : '📅 Event Tomorrow';
          final body = daysUntil == 0
              ? '${event.displayTitle}${event.eventTime != null ? ' at ${event.eventTime}' : ''}'
              : '${event.displayTitle} is scheduled for tomorrow${event.eventTime != null ? ' at ${event.eventTime}' : ''}';

          await showNotification(
            id: event.id.hashCode,
            title: title,
            body: body,
            channelId: _eventChannelId,
            payload: 'event:${event.id}',
          );
        }
      }
    } catch (e) {
      debugPrint('Event notification check failed: $e');
    }
  }

  /// Cancel all notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification.
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}

// ─── Riverpod Provider ──────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Trigger a notification check (birthdays + events).
final notificationCheckProvider = FutureProvider<void>((ref) async {
  final memberService = ref.read(memberServiceProvider);
  final eventService = ref.read(eventServiceProvider);

  await NotificationService.initialize();
  await NotificationService.checkBirthdayReminders(memberService);
  await NotificationService.checkEventReminders(eventService);
});
