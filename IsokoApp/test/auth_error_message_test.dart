import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/auth/data/auth_repository.dart';

void main() {
  test('sign-in password errors use neutral credential wording', () {
    expect(
      friendlySignInErrorMessage('Password should be at least 6 characters'),
      'The email or password is incorrect.',
    );
    expect(
      friendlySignInErrorMessage('Invalid login credentials'),
      'The email or password is incorrect.',
    );
  });

  test('sign-in preserves actionable email and rate-limit messages', () {
    expect(
      friendlySignInErrorMessage('Email not confirmed'),
      'Please confirm your email before signing in.',
    );
    expect(
      friendlySignInErrorMessage('Too many requests'),
      'Please wait a moment before trying again.',
    );
  });
}
