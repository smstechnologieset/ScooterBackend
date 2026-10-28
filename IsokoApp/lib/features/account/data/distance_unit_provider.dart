import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DistanceUnit {
  kilometers('km', 'Kilometers'),
  miles('mi', 'Miles');

  const DistanceUnit(this.symbol, this.label);
  final String symbol;
  final String label;
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
