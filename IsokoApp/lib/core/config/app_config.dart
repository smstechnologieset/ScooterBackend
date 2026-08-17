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
    defaultValue: '',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
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
