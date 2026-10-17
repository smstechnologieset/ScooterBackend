enum RideStatus {
  active,
  paused,
  completed,
  cancelled,
}

class RouteBreadcrumb {
  const RouteBreadcrumb({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speedKmh = 0.0,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speedKmh;
}

class RideSession {
  const RideSession({
    required this.id,
    required this.scooterId,
    required this.scooterCode,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.distanceKm = 0.0,
    this.currentSpeedKmh = 0.0,
    this.costRwf = 0,
    this.status = RideStatus.active,
    this.breadcrumbs = const [],
  });

  final String id;
  final String scooterId;
  final String scooterCode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final double distanceKm;
  final double currentSpeedKmh;
  final int costRwf;
  final RideStatus status;
  final List<RouteBreadcrumb> breadcrumbs;

  bool get isPaused => status == RideStatus.paused;
  bool get isActive => status == RideStatus.active;
  bool get isCompleted => status == RideStatus.completed;

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  RideSession copyWith({
    DateTime? endedAt,
    int? durationSeconds,
    double? distanceKm,
    double? currentSpeedKmh,
    int? costRwf,
    RideStatus? status,
    List<RouteBreadcrumb>? breadcrumbs,
  }) {
    return RideSession(
      id: id,
      scooterId: scooterId,
      scooterCode: scooterCode,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      costRwf: costRwf ?? this.costRwf,
      status: status ?? this.status,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
    );
  }
}

