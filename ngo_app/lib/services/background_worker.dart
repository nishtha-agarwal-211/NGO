import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../config/supabase_config.dart';
import 'member_service.dart';
import 'event_service.dart';
import 'notification_service.dart';

/// Background worker configuration for WorkManager.
/// Handles periodic tasks like birthday/event notification checks.
class BackgroundWorker {
  static const String taskName = 'ngo_periodic_check';
}

/// Top-level callback function for WorkManager.
/// This runs in a separate isolate, so we need to re-initialize services.
@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('[BackgroundWorker] Executing task: $task');

      // Initialize Supabase in the background isolate
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );

      // Initialize notifications
      await NotificationService.initialize();

      final client = Supabase.instance.client;

      // Only run checks if user is authenticated
      if (client.auth.currentSession != null) {
        final memberService = MemberService(client);
        final eventService = EventService(client);

        // Check for birthday reminders
        await NotificationService.checkBirthdayReminders(memberService);

        // Check for event reminders
        await NotificationService.checkEventReminders(eventService);

        debugPrint('[BackgroundWorker] Notification checks completed');
      } else {
        debugPrint('[BackgroundWorker] Skipped — user not authenticated');
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('[BackgroundWorker] Error: $e');
      return Future.value(false);
    }
  });
}
