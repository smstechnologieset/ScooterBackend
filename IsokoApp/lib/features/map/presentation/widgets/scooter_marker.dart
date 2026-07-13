import 'package:flutter/material.dart';

/// Green circular marker showing scooter location on map
class ScooterMarker extends StatelessWidget {
  const ScooterMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF2DD881),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2DD881).withAlpha(77),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.pedal_bike,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
