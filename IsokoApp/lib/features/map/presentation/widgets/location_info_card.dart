import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'scan_button.dart';

/// Bottom card showing location info and scooter availability
class LocationInfoCard extends StatelessWidget {
  final VoidCallback onScanPressed;
  
  const LocationInfoCard({
    super.key,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Scooter icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pedal_bike,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Location info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '23rd Avenue Street',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '3 Scooters available',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.pedal_bike,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Distance indicator
              Column(
                children: [
                  const Icon(
                    Icons.navigation,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3.2km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Scan Now button
          ScanButton(onPressed: onScanPressed),
        ],
      ),
    );
  }
}
