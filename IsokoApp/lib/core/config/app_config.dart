/// Runtime configuration for the ISOKO mobile app.
///
/// Values can be overridden at build/run time with --dart-define, for example:
/// flutter run --dart-define=API_BASE_URL=http://62.171.160.225:3000
class AppConfig {
  const AppConfig._();

  static const String appName = 'ISOKO Scooter';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://62.171.160.225:3000',
  );
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String countryCode = 'RW';
  static const String primaryCurrency = 'RWF';
  static const List<String> supportedCurrencies = ['RWF', 'USD'];

  static bool get hasMapboxAccessToken => mapboxAccessToken.isNotEmpty;
}
