import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_button.dart';

/// Sign Up screen matching Figma design
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Back button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up Now text
                Text(
                  'Sign Up Now',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle text
                Text(
                  'Looks like you\'re not registered yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 40),
                
                // Phone Number label
                Text(
                  'Phone Number',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 12),
                
                // Phone Number input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '912345678',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Full name label
                Text(
                  'Full name',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 12),
                
                // Full name input
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'John Doe',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Email label
                Text(
                  'Email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 12),
                
                // Email input
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Example@gmail.com',
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Continue button
                AuthButton(
                  text: 'Continue',
                  onPressed: () {
                    // TODO: Implement sign up
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Terms and conditions text
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By continuing you agree to our\n',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
