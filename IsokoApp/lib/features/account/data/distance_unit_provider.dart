import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DistanceUnit {
  kilometers('km', 'Kilometers'),
  miles('mi', 'Miles');

  const DistanceUnit(this.symbol, this.label);
  final String symbol;
  final String label;

  /// Converts a kilometer value to the active unit.
  double convert(double km) {
    return this == DistanceUnit.miles ? km * 0.621371 : km;
  }

  /// Formats a kilometer value into a display string with symbol (e.g. "5.2 km" or "3.2 mi").
  String format(double km, {int fractionDigits = 1}) {
    final val = convert(km);
    return '${val.toStringAsFixed(fractionDigits)}$symbol';
  }

  /// Formats with a space (e.g. "5.2 km" or "3.2 mi").
  String formatWithSpace(double km, {int fractionDigits = 1}) {
    final val = convert(km);
    return '${val.toStringAsFixed(fractionDigits)} $symbol';
  }
}

class DistanceUnitNotifier extends StateNotifier<DistanceUnit> {
  DistanceUnitNotifier() : super(DistanceUnit.kilometers);

  void setUnit(DistanceUnit unit) {
    state = unit;
  }

  void toggle() {
    state = state == DistanceUnit.kilometers
        ? DistanceUnit.miles
        : DistanceUnit.kilometers;
  }
}

final distanceUnitProvider =
    StateNotifierProvider<DistanceUnitNotifier, DistanceUnit>(
  (ref) => DistanceUnitNotifier(),
);
