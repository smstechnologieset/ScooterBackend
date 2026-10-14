import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../scooters/domain/scooter_code_translator.dart';
import '../../data/ride_controller.dart';
import '../../domain/ride_session.dart';

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(rideHistoryNotifierProvider);

    final displayRides = history.isNotEmpty
        ? history
        : [
            RideSession(
              id: 'demo-1',
              scooterId: '7000000000001',
              scooterCode: 'ISK-001',
              startedAt: DateTime.now().subtract(const Duration(days: 1)),
              endedAt: DateTime.now()
                  .subtract(const Duration(days: 1, minutes: -15)),
              durationSeconds: 135,
              distanceKm: 6.1,
              costRwf: 3100,
            ),
            RideSession(
              id: 'demo-2',
              scooterId: '7000000000002',
              scooterCode: 'ISK-002',
              startedAt: DateTime.now().subtract(const Duration(days: 3)),
              endedAt: DateTime.now()
                  .subtract(const Duration(days: 3, minutes: -20)),
              durationSeconds: 75,
              distanceKm: 3.1,
              costRwf: 8100,
            ),
            RideSession(
              id: 'demo-3',
              scooterId: '7000000000003',
              scooterCode: 'ISK-003',
              startedAt: DateTime.now().subtract(const Duration(days: 7)),
              endedAt: DateTime.now()
                  .subtract(const Duration(days: 7, minutes: -35)),
              durationSeconds: 255,
              distanceKm: 5.1,
              costRwf: 4100,
            ),
            RideSession(
              id: 'demo-4',
              scooterId: '7000000000004',
              scooterCode: 'ISK-004',
              startedAt: DateTime.now().subtract(const Duration(days: 14)),
              endedAt: DateTime.now()
                  .subtract(const Duration(days: 14, minutes: -40)),
              durationSeconds: 1935,
              distanceKm: 15.1,
              costRwf: 20100,
            ),
          ];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () => context.go('/menu'),
        ),
        title: Text(
          'Ride History',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: displayRides.length,
          itemBuilder: (ctx, i) {
            final ride = displayRides[i];
            final displayCode =
                ScooterCodeTranslator.formatDisplay(ride.scooterCode);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Isoko ride $displayCode',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ride.durationSeconds ~/ 60}m · ${ride.distanceKm.toStringAsFixed(1)}km',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${ride.costRwf.toInt()} RWF',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
