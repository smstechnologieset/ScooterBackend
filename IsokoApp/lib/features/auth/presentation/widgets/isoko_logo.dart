import 'package:flutter/material.dart';

/// ISOKO logo widget using the actual logo image
class IsokoLogo extends StatelessWidget {
  final double height;
  
  const IsokoLogo({
    super.key,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
