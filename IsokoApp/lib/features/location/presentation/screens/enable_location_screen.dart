import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';

/// Enable location permission screen
class EnableLocationScreen extends StatelessWidget {
  const EnableLocationScreen({super.key});

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
          
          // Bike image at bottom right
          Positioned(
            bottom: 200,
            right: -30,
            child: Transform.rotate(
              angle: 0.1,
              child: Image.asset(
                'assets/images/bike.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
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
                
                // Bottom content
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Get Isoko\nAnywhere....',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 32,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      Text(
                        'Please allow us to use your location to\nshow nearby scooters available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Enable Location button
                      AuthButton(
                        text: 'Enable Location',
                        onPressed: () {
                          // TODO: Request location permission
                          context.push('/scooter-locating');
                        },
                      ),
                      
                      const SizedBox(height: 40),
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

/// Custom painter for map street lines
class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw random street-like lines
    final path = Path();
    
    // Vertical street
    path.moveTo(size.width * 0.15, 0);
    path.lineTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height);
    
    // Horizontal street 1
    path.moveTo(0, size.height * 0.25);
    path.lineTo(size.width * 0.4, size.height * 0.25);
    
    // Horizontal street 2
    path.moveTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.4);
    
    // Diagonal street
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.5);
    
    // More streets
    path.moveTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.6);
    
    path.moveTo(size.width * 0.8, 0);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    
    canvas.drawPath(path, paint);
    
    // Add street names
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Street Name 1
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
    
    // Street Name 2
    textPainter.text = const TextSpan(
      text: 'Street Name',
      style: TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(size.width * 0.75, size.height * 0.25);
    canvas.rotate(-1.5708); // -90 degrees
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
