class AuthInputValidators {
  AuthInputValidators._();

  static final RegExp _simpleEmailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  static String? validateEmail(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!_simpleEmailPattern.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validateSignInPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? validateSignUpPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
