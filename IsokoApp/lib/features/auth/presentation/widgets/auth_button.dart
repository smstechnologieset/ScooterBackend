import 'package:flutter/material.dart';

/// Primary authentication button widget
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
