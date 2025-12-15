import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/config/routes.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primaryColor,
      onTap: (index) => _handleNavigation(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bills'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.bills, (route) => route.settings.name == AppRoutes.dashboard);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profile, (route) => route.settings.name == AppRoutes.dashboard);
        break;
    }
  }
}