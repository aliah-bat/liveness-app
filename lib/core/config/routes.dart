import 'package:flutter/material.dart';
import '/features/auth/screens/sign_in_screen.dart';
import '/features/auth/screens/sign_up_screen.dart';
import '/features/auth/screens/forgot_password_screen.dart'; // <-- ADD THIS
import '/features/dashboard/screens/dashboard_screen.dart';
import '/features/bill/screens/bill_screen.dart';
import '/features/profile/screen/profile_screen.dart';

class AppRoutes {
  static const String initial = '/sign-in';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password'; // <-- ADD THIS
  static const String dashboard = '/dashboard';
  static const String bills = '/bills';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      
      case forgotPassword: // <-- ADD THIS CASE
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      case dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      
      case bills:
        return MaterialPageRoute(builder: (_) => const BillScreen());
      
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}