/// Supabase configuration constants.
///
/// Credentials are read from `--dart-define` at build time so you can
/// swap dev / staging / prod without editing source code:
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=https://… --dart-define=SUPABASE_ANON_KEY=…
/// ```
///
/// The current values serve as **fallback defaults** for local development.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL (overridable via `--dart-define=SUPABASE_URL=…`)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mwzxaiqcgujcgvbslypq.supabase.co',
  );

  /// Your Supabase anonymous (public) key
  /// (overridable via `--dart-define=SUPABASE_ANON_KEY=…`)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_efra7-8leY8sgMVNwXNG_Q_1zXh5sz-',
  );

  // Storage bucket names
  static const String eventPhotosBucket = 'event-photos';
  static const String eventVideosBucket = 'event-videos';
  static const String memberPhotosBucket = 'member-photos';
  static const String newsClippingsBucket = 'news-clippings';

  // Storage path helpers
  static String eventPhotoPath(String projectId, String eventId, String photoId) =>
      'projects/$projectId/events/$eventId/photos/$photoId.jpg';

  static String eventThumbnailPath(String projectId, String eventId, String photoId) =>
      'projects/$projectId/events/$eventId/thumbnails/$photoId.jpg';

  static String eventVideoPath(String projectId, String eventId, String videoId) =>
      'projects/$projectId/events/$eventId/videos/$videoId.mp4';

  static String eventVideoThumbnailPath(String projectId, String eventId, String videoId) =>
      'projects/$projectId/events/$eventId/video-thumbnails/$videoId.jpg';

  static String memberPhotoPath(String memberId) =>
      'members/$memberId/profile.jpg';

  static String newsClippingPath(String newsId) =>
      'news/$newsId/clipping.jpg';
}
