import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Card showing individual scooter details in horizontal list
class ScooterCard extends StatelessWidget {
  final String scooterId;
  final String distance;
  final String range;
  
  const ScooterCard({
    super.key,
    required this.scooterId,
    required this.distance,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Scooter ID and bike image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: ID and distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scooter ID
                    Text(
                      scooterId,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Distance
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.textSecondary,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right side: Bike image
              Image.asset(
                'assets/images/bike.png',
                height: 60,
                width: 60,
                fit: BoxFit.contain,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Range info
          Text(
            'Range',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Range value with battery icon
          Row(
            children: [
              const Icon(
                Icons.bolt,
                color: AppTheme.primaryGreen,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                range,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.pedal_bike,
                color: AppTheme.primaryGreen,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
