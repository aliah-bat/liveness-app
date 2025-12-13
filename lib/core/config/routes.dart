import 'package:flutter/material.dart';
import '/features/auth/screens/sign_in_screen.dart';
import '/features/dashboard/screens/dashboard_screen.dart';
import '/features/bill/screens/bill_screen.dart';
import '/features/profile/screen/profile_screen.dart';

class AppRoutes {
  static const String initial = '/login';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String bills = '/bills';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => SignInScreen());
      
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