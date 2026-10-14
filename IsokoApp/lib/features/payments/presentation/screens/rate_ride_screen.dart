import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class RateRideScreen extends StatefulWidget {
  const RateRideScreen({super.key});

  @override
  State<RateRideScreen> createState() => _RateRideScreenState();
}

class _RateRideScreenState extends State<RateRideScreen> {
  int _rating = 5;
  final Set<String> _selectedTags = {'SCOOTER CONDITION'};
  final _commentController = TextEditingController();

  final _tags = const [
    'SCOOTER CONDITION',
    'SMOOTH RIDE',
    'SAFE PARKING',
    'BATTERY LEVEL',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () => context.go('/find-scooter'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row matching rate-ride-screen.png
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate your ride',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '9.5km • 29:13 min • Kigali Center',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.asset(
                        'assets/images/bike.png',
                        width: 72,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.black,
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 22),
              Divider(color: context.dividerColor, thickness: 1),
              const SizedBox(height: 24),

              // How Was Your Journey?
              Center(
                child: Text(
                  'How Was Your Journey?',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5 Stars
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          Icons.star_rounded,
                          size: 40,
                          color: starIndex <= _rating
                              ? const Color(0xFFFFB800)
                              : (context.isDarkMode
                                  ? const Color(0xFF333E38)
                                  : const Color(0xFFD0DDD6)),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 32),

              // WHAT STOOD OUT?
              Text(
                'WHAT STOOD OUT?',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),

              // Tag Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : (context.isDarkMode
                                ? const Color(0xFF1E2622)
                                : const Color(0xFFE8F0EC)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : context.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ADD A COMMENT
              Text(
                'ADD A COMMENT',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Comment text area
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 500,
                      style:
                          TextStyle(color: context.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tell us more about your experience...',
                        hintStyle: TextStyle(
                            color: context.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        counterStyle: TextStyle(
                            color: context.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Rating button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for rating your ride!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    context.go('/find-scooter');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
