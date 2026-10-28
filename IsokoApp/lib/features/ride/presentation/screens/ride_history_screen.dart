import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../account/data/distance_unit_provider.dart';
import '../../../scooters/domain/scooter_code_translator.dart';
import '../../data/ride_controller.dart';
import '../../domain/ride_session.dart';

class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  void _showRideDetailsModal(
    BuildContext context,
    RideSession ride,
    String displayCode,
    DistanceUnit unit,
  ) {
    final durationMin = ride.durationSeconds ~/ 60;
    final avgSpeed = ride.durationSeconds > 0
        ? (ride.distanceKm / (ride.durationSeconds / 3600)).clamp(0.0, 45.0)
        : 0.0;
    final displaySpeed = unit == DistanceUnit.miles
        ? '${(avgSpeed * 0.621371).toStringAsFixed(1)} mph'
        : '${avgSpeed.toStringAsFixed(1)} km/h';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withAlpha(70),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/bike.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Isoko Ride $displayCode',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Trip completed · Verified Parking',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: AppTheme.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'PARKED',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Metrics 3-box Grid
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: '${durationMin}m',
                      ),
                    ),
                    Container(width: 1, height: 32, color: context.dividerColor),
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.straighten_rounded,
                        label: 'Distance',
                        value: unit.formatWithSpace(ride.distanceKm),
                      ),
                    ),
                    Container(width: 1, height: 32, color: context.dividerColor),
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.speed_rounded,
                        label: 'Avg Speed',
                        value: displaySpeed,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Fare Breakdown
              Text(
                'Receipt Breakdown',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Column(
                  children: [
                    const _ReceiptRow(
                      label: 'Base Unlock Fee',
                      value: '500 RWF',
                    ),
                    const SizedBox(height: 8),
                    _ReceiptRow(
                      label: 'Distance Rate (${ride.distanceKm.toStringAsFixed(1)} km)',
                      value: '${(ride.distanceKm * 50).toInt()} RWF',
                    ),
                    const SizedBox(height: 8),
                    _ReceiptRow(
                      label: 'Ride Time ($durationMin min)',
                      value:
                          '${(ride.costRwf - 500 - (ride.distanceKm * 50)).clamp(0, 50000).toInt()} RWF',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${ride.costRwf.toInt()} RWF',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

    final unit = ref.watch(distanceUnitProvider);

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

                return InkWell(
                  onTap: () =>
                      _showRideDetailsModal(context, ride, displayCode, unit),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Row(
                      children: [
                        // E-bike Image badge
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Image.asset(
                            'assets/images/bike.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                '${ride.durationSeconds ~/ 60}m · ${unit.formatWithSpace(ride.distanceKm)}',
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
