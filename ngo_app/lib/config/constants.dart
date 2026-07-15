/// App-wide constants.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'NGO Manager';
  static const String appVersion = '1.0.0';

  // Reminder Settings
  static const int birthdayReminderDays = 7;
  static const int eventReminderHours = 24;

  // Pagination
  static const int defaultPageSize = 20;

  // Image Settings
  static const int thumbnailWidth = 300;
  static const int thumbnailHeight = 300;
  static const int fullImageMaxWidth = 1920;
  static const int fullImageMaxHeight = 1920;
  static const int imageQuality = 85;
  static const int thumbnailQuality = 70;

  // Offline Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;

  // Supabase Table Names
  static const String profilesTable = 'profiles';
  static const String membersTable = 'members';
  static const String donorsTable = 'donors';
  static const String donationsTable = 'donations';
  static const String projectsTable = 'projects';
  static const String eventsTable = 'events';
  static const String eventVolunteersTable = 'event_volunteers';
  static const String eventExpensesTable = 'event_expenses';
  static const String photosTable = 'photos';
  static const String newsItemsTable = 'news_items';

  // Day of Week (matching PostgreSQL convention used in schema)
  static const Map<int, String> dayOfWeekNames = {
    0: 'Sunday',
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
  };
}
