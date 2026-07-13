class Scooter {
  const Scooter({
    required this.id,
    required this.publicCode,
    required this.online,
    this.batteryPercent,
    this.rangeKm,
    this.latitude,
    this.longitude,
    this.lockState = ScooterLockState.unknown,
  });

  final String id;
  final String publicCode;
  final bool online;
  final int? batteryPercent;
  final double? rangeKm;
  final double? latitude;
  final double? longitude;
  final ScooterLockState lockState;
}

enum ScooterLockState {
  unknown,
  locked,
  unlocked;
}
