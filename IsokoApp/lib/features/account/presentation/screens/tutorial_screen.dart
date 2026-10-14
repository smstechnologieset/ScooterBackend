import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () => context.go('/menu'),
        ),
        title: const IsokoLogo(height: 32),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tutorials',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Video Tutorial Card matching tutorial-screen.png
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Stack(
                    children: [
                      // Video Background Texture / Placeholder
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            color: context.isDarkMode
                                ? const Color(0xFF101713)
                                : const Color(0xFFF0F4F2),
                            child: Center(
                              child: Image.asset(
                                'assets/images/bike.png',
                                width: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Gradient Overlay for readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                context.isDarkMode
                                    ? Colors.black.withAlpha(220)
                                    : Colors.white.withAlpha(220),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Center Play / Pause button
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isPlaying = !_isPlaying);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isPlaying
                                    ? 'Playing video tutorial...'
                                    : 'Paused tutorial.'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primaryGreen.withAlpha(120),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Content over video
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'How to ride ISOKO Electra',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Learn the safety basics: kicking off, accelerating smoothly, using dual brakes, and parking responsibly at designated stations.',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined,
                                    color: AppTheme.primaryGreen, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '2 min watch',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Safety Tip Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF141C18)
                      : const Color(0xFFE8F6EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppTheme.primaryGreen, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Always wear a helmet and obey local Kigali bike lane regulations.',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
