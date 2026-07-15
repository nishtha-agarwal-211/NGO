/// Supabase configuration constants.
/// 
/// IMPORTANT: Replace these with your actual Supabase project credentials.
/// You can find these in your Supabase Dashboard > Settings > API.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL
  /// Example: https://xyzcompanyid.supabase.co
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';

  /// Your Supabase anonymous (public) key
  /// This is safe to use in client-side code as RLS protects your data.
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Storage bucket names
  static const String eventPhotosBucket = 'event-photos';
  static const String memberPhotosBucket = 'member-photos';
  static const String newsClippingsBucket = 'news-clippings';

  // Storage path helpers
  static String eventPhotoPath(String projectId, String eventId, String photoId) =>
      'projects/$projectId/events/$eventId/photos/$photoId.jpg';

  static String eventThumbnailPath(String projectId, String eventId, String photoId) =>
      'projects/$projectId/events/$eventId/thumbnails/$photoId.jpg';

  static String memberPhotoPath(String memberId) =>
      'members/$memberId/profile.jpg';

  static String newsClippingPath(String newsId) =>
      'news/$newsId/clipping.jpg';
}
