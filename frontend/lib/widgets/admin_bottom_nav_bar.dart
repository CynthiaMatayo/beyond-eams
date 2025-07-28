// lib/widgets/admin_bottom_nav_bar.dart
import 'package:flutter/material.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Roles'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    print('🔥 ADMIN NAV: Tab $index tapped (current: $currentIndex)');
    // Don't navigate if already on the selected tab
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        print('🔥 ADMIN NAV: Navigating to dashboard');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin-dashboard',
          (route) => false,
        );
        break;
      case 1:
        print('🔥 ADMIN NAV: Navigating to user management');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/user-management',
          (route) => false,
        );
        break;
      case 2:
        print('🔥 ADMIN NAV: Navigating to system reports');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/system-reports',
          (route) => false,
        );
        break;
      case 3:
        print('🔥 ADMIN NAV: Navigating to role management');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/role-management',
          (route) => false,
        );
        break;
      case 4:
        print('🔥 ADMIN NAV: Navigating to system settings');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/system-settings',
          (route) => false,
        );
        break;
    }
  }
}
