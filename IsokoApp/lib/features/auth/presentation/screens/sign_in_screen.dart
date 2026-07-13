import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_auth_button.dart';
import '../widgets/isoko_logo.dart';

/// Sign In screen matching Figma design
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bike image positioned at top right
          Positioned(
            top: 40,
            right: -30,
            child: Image.asset(
              'assets/images/bike.png',
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    
                    // ISOKO Logo
                    const IsokoLogo(height: 60),
                
                const SizedBox(height: 80),
                
                // Hello text
                Text(
                  'Hello,',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 8),
                
                // Sign in Now text
                Text(
                  'Sign in Now',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                
                const SizedBox(height: 60),
                
                // Enter Phone Number label
                Text(
                  'Enter Phone Number',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 12),
                
                // Phone Number input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Continue button
                AuthButton(
                  text: 'Continue',
                  onPressed: () {
                    // TODO: Implement phone authentication
                    context.push('/enable-location');
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Or Continue with text
                Center(
                  child: Text(
                    'Or Continue with',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Google sign in button
                SocialAuthButton(
                  icon: Icons.g_mobiledata,
                  text: 'Continue with Google',
                  onPressed: () {
                    // TODO: Implement Google sign in
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Apple sign in button
                SocialAuthButton(
                  icon: Icons.apple,
                  text: 'Continue with Apple',
                  onPressed: () {
                    // TODO: Implement Apple sign in
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Don't have an account text
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/sign-up'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Dont have an account?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
