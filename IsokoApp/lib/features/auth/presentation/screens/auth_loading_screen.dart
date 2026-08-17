import 'package:flutter/material.dart';

import '../widgets/isoko_logo.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IsokoLogo(height: 54),
              SizedBox(height: 28),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
