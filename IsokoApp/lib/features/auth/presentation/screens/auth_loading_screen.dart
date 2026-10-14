import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/isoko_logo.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: const SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IsokoLogo(height: 64),
                SizedBox(height: 36),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
