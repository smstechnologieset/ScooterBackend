/// Runtime configuration for the ISOKO mobile app.
///
/// Values can be overridden at build/run time with --dart-define, for example:
/// flutter run --dart-define-from-file=env.local.json
class AppConfig {
  const AppConfig._();

  static const String appName = 'ISOKO Scooter';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.smstechnologieset.com',
  );
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jvshfztgfgzlvgznajge.supabase.co',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2c2hmenRnZmd6bHZnem5hamdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MjM1OTcsImV4cCI6MjEwMDE5OTU5N30.SN3X8Cf8dJ5_OC7HaWjus4WPuaWRm9fQYVAkrPAr5GU',
  );
  static const String authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'com.smstechnologieset.isoko://auth/callback',
  );
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String countryCode = 'RW';
  static const String primaryCurrency = 'RWF';
  static const List<String> supportedCurrencies = ['RWF', 'USD'];

  static bool get hasMapboxAccessToken => mapboxAccessToken.isNotEmpty;
  static String get supabaseClientKey => supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseClientKey.isNotEmpty;
}
