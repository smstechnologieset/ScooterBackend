import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../scooters/data/providers.dart';
import '../../../scooters/domain/scooter_code_translator.dart';

class ManualCodeScreen extends ConsumerStatefulWidget {
  const ManualCodeScreen({super.key});

  @override
  ConsumerState<ManualCodeScreen> createState() => _ManualCodeScreenState();
}

class _ManualCodeScreenState extends ConsumerState<ManualCodeScreen> {
  final _controller = TextEditingController(text: 'BK-2134');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitCode(String rawCode) async {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorMessage = 'Please enter a bike number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final friendlyCode = ScooterCodeTranslator.toFriendlyCode(trimmed);
      final scooter = await ref
          .read(scooterApiProvider)
          .getScooterByCode(friendlyCode);

      ref.read(selectedScooterProvider.notifier).state = scooter;

      if (mounted) {
        context.go('/unlocking');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'Scooter "$trimmed" not found. Try ISK-001 or BK-2134.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Center Pencil Icon matching unlocking-bike-with-number-screen.png
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1C2420)
                        : const Color(0xFFE8F6EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title matching mockup
              Center(
                child: Text(
                  'Unlock Using bike number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Label
              Text(
                'Enter bike number',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Dark/Light Text Field matching mockup
              Container(
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF222B26)
                      : const Color(0xFFEFF3F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppTheme.danger
                        : context.cardBorder,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. BK-2134 or ISK-001',
                    hintStyle: TextStyle(
                        color: context.textSecondary, fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _submitCode,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: AppTheme.danger, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              // Green Unlock Button matching mockup
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _submitCode(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Unlock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Quick select chips
              Text(
                'Or select a test bike:',
                style: TextStyle(
                    color: context.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    code: 'ISK-001 (BK2113)',
                    onTap: () {
                      _controller.text = 'ISK-001';
                      _submitCode('ISK-001');
                    },
                  ),
                  _QuickChip(
                    code: 'ISK-002 (BK3113)',
                    onTap: () {
                      _controller.text = 'ISK-002';
                      _submitCode('ISK-002');
                    },
                  ),
                  _QuickChip(
                    code: 'ISK-003 (BK2114)',
                    onTap: () {
                      _controller.text = 'ISK-003';
                      _submitCode('ISK-003');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        code,
        style: TextStyle(
            color: context.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
      backgroundColor: context.cardBg,
      side: BorderSide(color: context.cardBorder),
      onPressed: onTap,
    );
  }
}
