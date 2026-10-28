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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialStep> _steps = const [
    _TutorialStep(
      stepNumber: '01',
      title: 'Find an ISOKO E-bike',
      description:
          'Open the app map to locate nearby available electric bikes and check their battery range in real time.',
      icon: Icons.map_rounded,
      highlight: 'Check battery & inspect vehicle',
    ),
    _TutorialStep(
      stepNumber: '02',
      title: 'Scan QR to Unlock',
      description:
          'Tap "Scan Now" on the home map and aim your camera at the QR code on the handlebar, or type the 3-digit ISK code manually.',
      icon: Icons.qr_code_scanner_rounded,
      highlight: 'Instant unlock via smart lock',
    ),
    _TutorialStep(
      stepNumber: '03',
      title: 'Ride Safely & Responsibly',
      description:
          'Always wear a helmet, follow Kigali traffic rules, and use designated cycling lanes. Use smooth electric pedal assist.',
      icon: Icons.electric_bike_rounded,
      highlight: 'Safety helmet recommended',
    ),
    _TutorialStep(
      stepNumber: '04',
      title: 'Park at Designated Stations',
      description:
          'Return your E-bike to any marked green station on the map. Lock the rear ring lock and take a quick photo to end your trip.',
      icon: Icons.local_parking_rounded,
      highlight: 'Avoid penalties by parking in green zones',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () => context.go('/menu'),
        ),
        title: const IsokoLogo(height: 30),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'How to Ride',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Step ${_currentPage + 1} of ${_steps.length}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PageView Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (ctx, i) {
                    final item = _steps[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Big Step Number & Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.stepNumber,
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen.withAlpha(140),
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withAlpha(30),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryGreen.withAlpha(80),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: AppTheme.primaryGreen,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Illustration placeholder or Bike Image
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? const Color(0xFF141C18)
                                      : const Color(0xFFE8F6EE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Image.asset(
                                  'assets/images/bike.png',
                                  height: 110,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Title & Description
                            Text(
                              item.title,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Highlight Chip
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.primaryGreen, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.highlight,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (idx) {
                  final active = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primaryGreen
                          : context.textSecondary.withAlpha(60),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Action buttons (Previous / Next / Start Riding)
              Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textPrimary,
                            side: BorderSide(color: context.cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLast) {
                            context.go('/find-scooter');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isLast ? 'Start Riding Now' : 'Next Step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.highlight,
  });

  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final String highlight;
}
