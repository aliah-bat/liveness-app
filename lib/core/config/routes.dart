import 'package:flutter/material.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../utils/constants.dart';

class AppRoutes {
  static const String initial = AppConstants.signInRoute;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.signUpRoute:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      
      case AppConstants.signInRoute:
        return MaterialPageRoute(builder: (_) => const SignInScreen());

      case AppConstants.dashboardRoute:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

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