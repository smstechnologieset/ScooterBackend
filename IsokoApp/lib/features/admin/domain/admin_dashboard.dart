enum AdminConnectionStatus {
  online,
  offline;
}

enum AdminLockState {
  unknown,
  locked,
  unlocked;
}

enum AdminRideState {
  unknown,
  idle,
  reserved,
  inRide,
  maintenance;
}

enum AdminEventSeverity {
  info,
  warning,
  critical;
}

enum AdminScooterAction {
  lock,
  unlock;
}

class AdminDashboard {
  const AdminDashboard({
    required this.metrics,
    required this.scooters,
    required this.events,
    required this.isLive,
  });

  final AdminFleetMetrics metrics;
  final List<AdminScooter> scooters;
  final List<AdminFleetEvent> events;
  final bool isLive;

  factory AdminDashboard.fromJson(
    Map<String, Object?> json, {
    bool isLive = true,
  }) {
    final scooters = _listFromJson(json['scooters'])
        .whereType<Map<String, Object?>>()
        .map(AdminScooter.fromJson)
        .toList(growable: false);
    final metricsJson = _mapFromJson(json['metrics']);
    final events = _listFromJson(json['events'])
        .whereType<Map<String, Object?>>()
        .map(AdminFleetEvent.fromJson)
        .toList(growable: false);

    return AdminDashboard(
      metrics: metricsJson == null
          ? AdminFleetMetrics.fromScooters(scooters)
          : AdminFleetMetrics.fromJson(metricsJson, scooters),
      scooters: scooters,
      events: events.isEmpty ? AdminFleetEvent.fromScooters(scooters) : events,
      isLive: isLive,
    );
  }

  factory AdminDashboard.seed({bool isLive = false}) {
    final now = DateTime.now().toUtc();
    final scooters = [
      AdminScooter(
        id: '8f6e4e3a-2b14-4c96-a7d5-0d6e7d3f1001',
        deviceId: 'BK2113',
        publicCode: 'BK2113',
        status: AdminConnectionStatus.online,
        batteryPercent: 86,
        signalStrength: 82,
        lockState: AdminLockState.locked,
        rideState: AdminRideState.idle,
        latitude: -1.9441,
        longitude: 30.0619,
        lastHeartbeatAt: now.subtract(const Duration(minutes: 2)),
        lastGpsAt: now.subtract(const Duration(minutes: 4)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
      ),
      AdminScooter(
        id: '5c1dbb50-9d5f-4f46-89db-609caeb41002',
        deviceId: 'BK3113',
        publicCode: 'BK3113',
        status: AdminConnectionStatus.online,
        batteryPercent: 18,
        signalStrength: 64,
        lockState: AdminLockState.unlocked,
        rideState: AdminRideState.inRide,
        latitude: -1.9532,
        longitude: 30.0928,
        lastHeartbeatAt: now.subtract(const Duration(minutes: 1)),
        lastGpsAt: now.subtract(const Duration(minutes: 3)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
      ),
      AdminScooter(
        id: '7a67ad8e-063b-42f5-82e1-39a2bb0d1003',
        deviceId: 'BK2103',
        publicCode: 'BK2103',
        status: AdminConnectionStatus.offline,
        batteryPercent: 42,
        signalStrength: 0,
        lockState: AdminLockState.unknown,
        rideState: AdminRideState.maintenance,
        latitude: -1.9706,
        longitude: 30.1044,
        lastHeartbeatAt: now.subtract(const Duration(hours: 2, minutes: 20)),
        lastGpsAt: now.subtract(const Duration(hours: 2, minutes: 25)),
        updatedAt: now.subtract(const Duration(hours: 2, minutes: 20)),
      ),
      AdminScooter(
        id: '0e94c13d-7b0d-4c4b-8f9a-565a5bd51004',
        deviceId: 'BK2114',
        publicCode: 'BK2114',
        status: AdminConnectionStatus.online,
        batteryPercent: 57,
        signalStrength: 71,
        lockState: AdminLockState.locked,
        rideState: AdminRideState.reserved,
        latitude: -1.9356,
        longitude: 30.1308,
        lastHeartbeatAt: now.subtract(const Duration(minutes: 8)),
        lastGpsAt: now.subtract(const Duration(minutes: 9)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
      ),
    ];

    return AdminDashboard(
      metrics: AdminFleetMetrics.fromScooters(scooters),
      scooters: scooters,
      events: AdminFleetEvent.fromScooters(scooters),
      isLive: isLive,
    );
  }
}

class AdminFleetMetrics {
  const AdminFleetMetrics({
    required this.total,
    required this.online,
    required this.offline,
    required this.locked,
    required this.unlocked,
    required this.inRide,
    required this.lowBattery,
    required this.alerts,
  });

  final int total;
  final int online;
  final int offline;
  final int locked;
  final int unlocked;
  final int inRide;
  final int lowBattery;
  final int alerts;

  factory AdminFleetMetrics.fromJson(
    Map<String, Object?> json,
    List<AdminScooter> fallbackScooters,
  ) {
    final fallback = AdminFleetMetrics.fromScooters(fallbackScooters);
    return AdminFleetMetrics(
      total: _intFromJson(json['total']) ?? fallback.total,
      online: _intFromJson(json['online']) ?? fallback.online,
      offline: _intFromJson(json['offline']) ?? fallback.offline,
      locked: _intFromJson(json['locked']) ?? fallback.locked,
      unlocked: _intFromJson(json['unlocked']) ?? fallback.unlocked,
      inRide: _intFromJson(json['inRide']) ?? fallback.inRide,
      lowBattery: _intFromJson(json['lowBattery']) ?? fallback.lowBattery,
      alerts: _intFromJson(json['alerts']) ?? fallback.alerts,
    );
  }

  factory AdminFleetMetrics.fromScooters(List<AdminScooter> scooters) {
    final online = scooters.where((scooter) => scooter.isOnline).length;
    final unlocked = scooters
        .where((scooter) => scooter.lockState == AdminLockState.unlocked)
        .length;
    final lowBattery = scooters
        .where((scooter) =>
            scooter.batteryPercent != null && scooter.batteryPercent! <= 20)
        .length;

    return AdminFleetMetrics(
      total: scooters.length,
      online: online,
      offline: scooters.length - online,
      locked: scooters
          .where((scooter) => scooter.lockState == AdminLockState.locked)
          .length,
      unlocked: unlocked,
      inRide: scooters
          .where((scooter) => scooter.rideState == AdminRideState.inRide)
          .length,
      lowBattery: lowBattery,
      alerts: scooters.length - online + lowBattery + unlocked,
    );
  }
}

class AdminScooter {
  const AdminScooter({
    required this.id,
    required this.deviceId,
    required this.publicCode,
    required this.status,
    required this.lockState,
    required this.rideState,
    this.batteryPercent,
    this.signalStrength,
    this.latitude,
    this.longitude,
    this.lastHeartbeatAt,
    this.lastGpsAt,
    this.updatedAt,
  });

  final String id;
  final String deviceId;
  final String publicCode;
  final AdminConnectionStatus status;
  final AdminLockState lockState;
  final AdminRideState rideState;
  final int? batteryPercent;
  final int? signalStrength;
  final double? latitude;
  final double? longitude;
  final DateTime? lastHeartbeatAt;
  final DateTime? lastGpsAt;
  final DateTime? updatedAt;

  bool get isOnline => status == AdminConnectionStatus.online;
  bool get isLowBattery => batteryPercent != null && batteryPercent! <= 20;
  bool get requiresAttention =>
      !isOnline || isLowBattery || lockState == AdminLockState.unlocked;

  String get batteryLabel => batteryPercent == null ? '--' : '$batteryPercent%';
  String get signalLabel => signalStrength == null ? '--' : '$signalStrength%';

  factory AdminScooter.fromJson(Map<String, Object?> json) {
    final deviceId = _stringFromJson(json['deviceId']) ??
        _stringFromJson(json['id']) ??
        'unknown';
    final publicCode = _stringFromJson(json['publicCode']) ??
        _stringFromJson(json['code']) ??
        _stringFromJson(json['displayCode']) ??
        deviceId;

    return AdminScooter(
      id: _stringFromJson(json['id']) ?? deviceId,
      deviceId: deviceId,
      publicCode: publicCode,
      status: _connectionStatusFromJson(json['status'] ?? json['online']),
      batteryPercent: _intFromJson(json['batteryPercent']),
      signalStrength: _intFromJson(json['signalStrength']),
      lockState: _lockStateFromJson(json['lockState']),
      rideState: _rideStateFromJson(json['rideState']),
      latitude: _doubleFromJson(json['latitude']),
      longitude: _doubleFromJson(json['longitude']),
      lastHeartbeatAt: _dateFromJson(json['lastHeartbeatAt']),
      lastGpsAt: _dateFromJson(json['lastGpsAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
    );
  }
}

class AdminFleetEvent {
  const AdminFleetEvent({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String detail;
  final AdminEventSeverity severity;
  final DateTime createdAt;

  factory AdminFleetEvent.fromJson(Map<String, Object?> json) {
    return AdminFleetEvent(
      id: _stringFromJson(json['id']) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _stringFromJson(json['title']) ??
          _stringFromJson(json['type']) ??
          'Fleet event',
      detail: _stringFromJson(json['detail']) ??
          _stringFromJson(json['message']) ??
          _stringFromJson(json['status']) ??
          '',
      severity: _severityFromJson(json['severity']),
      createdAt: _dateFromJson(json['createdAt']) ?? DateTime.now().toUtc(),
    );
  }

  static List<AdminFleetEvent> fromScooters(List<AdminScooter> scooters) {
    final now = DateTime.now().toUtc();
    final events = <AdminFleetEvent>[];

    for (final scooter
        in scooters.where((scooter) => !scooter.isOnline).take(3)) {
      events.add(AdminFleetEvent(
        id: '${scooter.id}-offline',
        title: 'Connection lost',
        detail: '${scooter.publicCode} last heartbeat is stale',
        severity: AdminEventSeverity.critical,
        createdAt: scooter.lastHeartbeatAt ?? now,
      ));
    }

    for (final scooter
        in scooters.where((scooter) => scooter.isLowBattery).take(3)) {
      events.add(AdminFleetEvent(
        id: '${scooter.id}-battery',
        title: 'Low battery',
        detail: '${scooter.publicCode} is at ${scooter.batteryLabel}',
        severity: AdminEventSeverity.warning,
        createdAt: scooter.updatedAt ?? now,
      ));
    }

    for (final scooter in scooters
        .where((scooter) => scooter.rideState == AdminRideState.inRide)
        .take(3)) {
      events.add(AdminFleetEvent(
        id: '${scooter.id}-ride',
        title: 'Ride in progress',
        detail: '${scooter.publicCode} is currently rented',
        severity: AdminEventSeverity.info,
        createdAt: scooter.updatedAt ?? now,
      ));
    }

    if (events.isEmpty) {
      events.add(AdminFleetEvent(
        id: 'fleet-ready',
        title: 'Fleet ready',
        detail: 'No operational alerts in current snapshot.',
        severity: AdminEventSeverity.info,
        createdAt: now,
      ));
    }

    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events.take(6).toList(growable: false);
  }
}

List<Object?> _listFromJson(Object? value) {
  return value is List ? value : const [];
}

Map<String, Object?>? _mapFromJson(Object? value) {
  return value is Map<String, Object?> ? value : null;
}

String? _stringFromJson(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  return null;
}

int? _intFromJson(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return null;
}

double? _doubleFromJson(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return null;
}

DateTime? _dateFromJson(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }

  return null;
}

AdminConnectionStatus _connectionStatusFromJson(Object? value) {
  if (value == true || value == 'online') {
    return AdminConnectionStatus.online;
  }

  return AdminConnectionStatus.offline;
}

AdminLockState _lockStateFromJson(Object? value) {
  switch (value) {
    case 'locked':
      return AdminLockState.locked;
    case 'unlocked':
      return AdminLockState.unlocked;
    default:
      return AdminLockState.unknown;
  }
}

AdminRideState _rideStateFromJson(Object? value) {
  switch (value) {
    case 'idle':
      return AdminRideState.idle;
    case 'reserved':
      return AdminRideState.reserved;
    case 'in_ride':
      return AdminRideState.inRide;
    case 'maintenance':
      return AdminRideState.maintenance;
    default:
      return AdminRideState.unknown;
  }
}

AdminEventSeverity _severityFromJson(Object? value) {
  switch (value) {
    case 'critical':
      return AdminEventSeverity.critical;
    case 'warning':
      return AdminEventSeverity.warning;
    default:
      return AdminEventSeverity.info;
  }
}
