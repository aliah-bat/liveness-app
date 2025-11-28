import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/constants.dart';
import '../../bill/screens/bill_screen.dart';

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
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Bills',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _handleNavigation(BuildContext context, int index) {
  // Remove this line that blocks navigation
  // if (index == currentIndex) return;

  switch (index) {
    case 0:
      // Home - pop back to dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
      break;
    case 1:
      // Bills - only push if not already on bills screen
      if (currentIndex != 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BillScreen()),
        );
      }
      break;
    case 2:
      // Profile - TODO: create profile screen
      break;
  }
}
}