import 'package:flutter/material.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../widgets/scooter_marker.dart';
import '../widgets/scooter_card.dart';
import '../widgets/scan_button.dart';

/// Map screen with horizontal scrollable list of available scooters
class ScooterListScreen extends StatelessWidget {
  const ScooterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background with street lines
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
            ),
            child: CustomPaint(
              painter: MapLinesPainter(),
              size: Size.infinite,
            ),
          ),
          
          // Scooter markers on map
          const Positioned(
            top: 150,
            left: 120,
            child: ScooterMarker(),
          ),
          const Positioned(
            top: 280,
            right: 100,
            child: ScooterMarker(),
          ),
          const Positioned(
            bottom: 450,
            left: 100,
            child: ScooterMarker(),
          ),
          const Positioned(
            bottom: 400,
            right: 80,
            child: ScooterMarker(),
          ),
          
          // User location marker with route line
          Positioned(
            bottom: 480,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: Column(
              children: [
                Container(
                  width: 3,
                  height: 80,
                  color: Colors.white,
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4D3A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2DD881),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Color(0xFF2DD881),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top bar
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      IsokoLogo(height: 40),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom section with location and scooter list
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Location header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
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
                            Expanded(
                              child: Text(
                                '23rd Avenue Street',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.navigation,
                                  color: Color(0xFF2DD881),
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '3.2km',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF2DD881),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Horizontal scooter list
                      SizedBox(
                        height: 200,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            ScooterCard(
                              scooterId: 'BK2113',
                              distance: '3.2 km',
                              range: '30-35km',
                            ),
                            SizedBox(width: 12),
                            ScooterCard(
                              scooterId: 'BK3113',
                              distance: '3.2 km',
                              range: '20-25km',
                            ),
                            SizedBox(width: 12),
                            ScooterCard(
                              scooterId: 'BK2114',
                              distance: '3.2 km',
                              range: '30-35km',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Scan Now button
                      ScanButton(
                        onPressed: () {
                          // TODO: Open QR scanner
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Map painter (reused from previous screen)
class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    path.moveTo(size.width * 0.15, 0);
    path.lineTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height);
    
    path.moveTo(0, size.height * 0.25);
    path.lineTo(size.width * 0.4, size.height * 0.25);
    
    path.moveTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.4);
    
    path.moveTo(size.width * 0.2, size.height * 0.55);
    path.lineTo(size.width * 0.8, size.height * 0.55);
    
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.5);
    
    path.moveTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.6);
    
    path.moveTo(size.width * 0.8, 0);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
