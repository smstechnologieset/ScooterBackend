import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../widgets/scooter_marker.dart';
import '../widgets/location_info_card.dart';

/// Main map screen showing available scooters
class ScooterMapScreen extends StatelessWidget {
  const ScooterMapScreen({super.key});

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
            bottom: 350,
            left: 100,
            child: ScooterMarker(),
          ),
          const Positioned(
            bottom: 300,
            right: 80,
            child: ScooterMarker(),
          ),
          
          // User location marker (center with route line)
          Positioned(
            bottom: 380,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: Column(
              children: [
                // Route line
                Container(
                  width: 3,
                  height: 100,
                  color: Colors.white,
                ),
                // User location circle
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
                // Top bar with menu and logo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                      ), 
                      
                      // ISOKO logo
                      const IsokoLogo(height: 40),
                      
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom location info card
                LocationInfoCard(
                  onScanPressed: () {
                    context.push('/scooter-list');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for map street lines
class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Vertical streets
    path.moveTo(size.width * 0.15, 0);
    path.lineTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height);
    
    // Horizontal streets
    path.moveTo(0, size.height * 0.25);
    path.lineTo(size.width * 0.4, size.height * 0.25);
    
    path.moveTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.4);
    
    path.moveTo(size.width * 0.2, size.height * 0.55);
    path.lineTo(size.width * 0.8, size.height * 0.55);
    
    // Diagonal streets
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.5);
    
    path.moveTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.6);
    
    path.moveTo(size.width * 0.8, 0);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    
    canvas.drawPath(path, paint);
    
    // Add street names
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    textPainter.text = const TextSpan(
      text: 'Street Name',
      style: TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.05, size.height * 0.3));
    
    canvas.save();
    canvas.translate(size.width * 0.75, size.height * 0.25);
    canvas.rotate(-1.5708);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
    
    textPainter.text = const TextSpan(
      text: 'Street Name',
      style: TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.35, size.height * 0.57));
    
    canvas.save();
    canvas.translate(size.width * 0.85, size.height * 0.5);
    canvas.rotate(-1.5708);
    textPainter.text = const TextSpan(
      text: 'Street Name',
      style: TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
