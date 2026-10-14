import 'dart:math';

/// Represents a designated parking station for scooter drop-off.
class ParkingStation {
  const ParkingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}

/// Manages parking station locations and proximity validation.
///
/// Uses the Haversine formula to calculate distance between the rider's
/// GPS coordinates and known station positions. A ride can only be ended
/// when the rider is within [maxDistanceMeters] of a station.
class ParkingZoneValidator {
  const ParkingZoneValidator({
    this.maxDistanceMeters = 100,
  });

  /// Maximum allowed distance (in meters) from a station for a valid park.
  final double maxDistanceMeters;

  /// Demo parking stations located around Kigali, Rwanda.
  /// These will be replaced with real station data from the backend once
  /// physical infrastructure is deployed.
  static const List<ParkingStation> stations = [
    ParkingStation(
      id: 'station-001',
      name: 'Kigali Convention Centre',
      latitude: -1.9536,
      longitude: 29.8894,
    ),
    ParkingStation(
      id: 'station-002',
      name: 'Kigali Heights',
      latitude: -1.9496,
      longitude: 29.8767,
    ),
    ParkingStation(
      id: 'station-003',
      name: 'Nyabugogo Bus Park',
      latitude: -1.9390,
      longitude: 29.8518,
    ),
    ParkingStation(
      id: 'station-004',
      name: 'Kimironko Market',
      latitude: -1.9400,
      longitude: 29.8980,
    ),
    ParkingStation(
      id: 'station-005',
      name: 'Kigali City Tower',
      latitude: -1.9437,
      longitude: 29.8759,
    ),
    ParkingStation(
      id: 'station-006',
      name: 'Remera Stadium',
      latitude: -1.9478,
      longitude: 29.8990,
    ),
    ParkingStation(
      id: 'station-007',
      name: 'University of Rwanda - Gikondo',
      latitude: -1.9652,
      longitude: 29.8730,
    ),
    ParkingStation(
      id: 'station-008',
      name: 'Kicukiro Centre',
      latitude: -1.9740,
      longitude: 29.8640,
    ),
  ];

  /// Validates whether [lat]/[lng] is within [maxDistanceMeters] of any station.
  /// Returns the nearest station if in range, or null if outside all zones.
  ParkingStation? findNearestValidStation(double lat, double lng) {
    ParkingStation? nearest;
    double shortestDistance = double.infinity;

    for (final station in stations) {
      final distance = _haversineMeters(
        lat, lng,
        station.latitude, station.longitude,
      );
      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearest = station;
      }
    }

    if (shortestDistance <= maxDistanceMeters) {
      return nearest;
    }
    return null;
  }

  /// Returns distance in meters between two GPS coordinates using Haversine.
  static double _haversineMeters(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadiusM = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusM * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);
}
