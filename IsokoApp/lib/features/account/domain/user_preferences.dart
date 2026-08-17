class UserPreferences {
  const UserPreferences({
    required this.userId,
    required this.languageCode,
    required this.currencyCode,
    required this.distanceUnit,
    required this.rideNotifications,
    required this.marketingNotifications,
  });

  final String userId;
  final String languageCode;
  final String currencyCode;
  final String distanceUnit;
  final bool rideNotifications;
  final bool marketingNotifications;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'] as String,
      languageCode: json['language_code'] as String,
      currencyCode: json['currency_code'] as String,
      distanceUnit: json['distance_unit'] as String,
      rideNotifications: json['ride_notifications'] as bool,
      marketingNotifications: json['marketing_notifications'] as bool,
    );
  }
}
