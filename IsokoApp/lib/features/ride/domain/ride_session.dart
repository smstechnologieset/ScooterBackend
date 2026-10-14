enum RideStatus {
  active,
  paused,
  completed,
  cancelled,
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
    this.costRwf = 0,
    this.status = RideStatus.active,
  });

  final String id;
  final String scooterId;
  final String scooterCode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final double distanceKm;
  final int costRwf;
  final RideStatus status;

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
    int? costRwf,
    RideStatus? status,
  }) {
    return RideSession(
      id: id,
      scooterId: scooterId,
      scooterCode: scooterCode,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      costRwf: costRwf ?? this.costRwf,
      status: status ?? this.status,
    );
  }
}
