enum AuthMethod {
  phoneOtp,
  emailPassword,
  google,
  apple;

  String get label {
    switch (this) {
      case AuthMethod.phoneOtp:
        return 'Phone OTP';
      case AuthMethod.emailPassword:
        return 'Email and password';
      case AuthMethod.google:
        return 'Google';
      case AuthMethod.apple:
        return 'Apple';
    }
  }
}

const supportedAuthMethods = [
  AuthMethod.phoneOtp,
  AuthMethod.emailPassword,
  AuthMethod.google,
  AuthMethod.apple,
];
