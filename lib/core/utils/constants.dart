class AppConstants {
  // Route Names (Auth only)
  static const String signUpRoute = '/sign-up';
  static const String signInRoute = '/sign-in';
  static const String otpRoute = '/otp';
  static const String dashboardRoute = '/dashboard';
  static const String forgotPasswordRoute = '/forgot-password';

  // Validation
  static const int minPasswordLength = 8;
  static const int otpLength = 6;
  static const int otpResendTimeout = 60; // seconds

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String invalidCredentials = 'Invalid email or password.';

  // Success Messages
  static const String signUpSuccess = 'Account created successfully!';
  static const String signInSuccess = 'Welcome back!';
  static const String otpVerified = 'OTP verified successfully!';

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(
    r'^\+?[0-9]{10,15}$',
  );
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$',
  );

  // Supabase Table Names
  static const String usersTable = 'users';

  // Snackbar Duration
  static const Duration snackBarDuration = Duration(seconds: 3);
}