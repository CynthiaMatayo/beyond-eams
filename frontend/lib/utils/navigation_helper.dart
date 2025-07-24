// lib/utils/navigation_helper.dart
import 'package:flutter/material.dart';

class NavigationHelper {
  // Main navigation method that handles both named routes and direct navigation
  static Future<void> navigateTo(
    BuildContext context,
    String routeName, {
    Map<String, dynamic>? arguments,
    bool replacement = false,
    bool clearStack = false,
    Widget? fallbackWidget,
    String? fallbackMessage,
  }) async {
    try {
      if (clearStack) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else if (replacement) {
        Navigator.of(
          context,
        ).pushReplacementNamed(routeName, arguments: arguments);
      } else {
        Navigator.of(context).pushNamed(routeName, arguments: arguments);
      }
    } catch (e) {
      // If named route fails, try direct widget navigation
      if (fallbackWidget != null) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => fallbackWidget));
      } else {
        // Show fallback message
        _showNavigationError(
          context,
          fallbackMessage ?? 'Navigation not available yet',
        );
      }
    }
  }

  // Navigate with bottom navigation bar maintained
  static Future<void> navigateWithBottomNav(
    BuildContext context,
    Widget destination,
    String title,
  ) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              body: destination,
              bottomNavigationBar: _buildBottomNavigationBar(context),
            ),
      ),
    );
  }

  // Quick Actions navigation specifically
  static void handleQuickAction(BuildContext context, String actionType) {
    switch (actionType) {
      case 'browse_activities':
        navigateTo(
          context,
          '/browse-activities',
          fallbackMessage: 'Browse Activities feature coming soon!',
        );
        break;
      case 'my_activities':
        navigateTo(
          context,
          '/my-activities',
          fallbackMessage: 'My Activities feature coming soon!',
        );
        break;
      case 'volunteering':
        navigateTo(
          context,
          '/volunteering-dashboard',
          fallbackMessage: 'Volunteering dashboard temporarily unavailable',
        );
        break;
      case 'my_volunteer_applications':
        navigateTo(
          context,
          '/my-volunteer-applications',
          fallbackMessage: 'Volunteer applications feature coming soon!',
        );
        break;
      case 'profile':
        navigateTo(
          context,
          '/profile',
          fallbackMessage: 'Profile feature coming soon!',
        );
        break;
      case 'notifications':
        navigateTo(
          context,
          '/notifications',
          fallbackMessage: 'Notifications feature coming soon!',
        );
        break;
      default:
        _showNavigationError(context, 'Feature not implemented yet');
    }
  }

  // Error message display
  static void _showNavigationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Build consistent bottom navigation bar
  static Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'My Activities',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) => _handleBottomNavTap(context, index),
    );
  }

  // Handle bottom navigation taps
  static void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigateTo(context, '/dashboard', replacement: true);
        break;
      case 1:
        navigateTo(context, '/browse-activities');
        break;
      case 2:
        navigateTo(context, '/my-activities');
        break;
      case 3:
        navigateTo(context, '/profile');
        break;
    }
  }

  // Check if route exists
  static bool routeExists(BuildContext context, String routeName) {
    try {
      final route = ModalRoute.of(context);
      return route?.settings.name == routeName;
    } catch (e) {
      return false;
    }
  }
}

// Extension for easier context usage
extension NavigationExtension on BuildContext {
  void navigateTo(String routeName, {Map<String, dynamic>? arguments}) {
    NavigationHelper.navigateTo(this, routeName, arguments: arguments);
  }

  void handleQuickAction(String actionType) {
    NavigationHelper.handleQuickAction(this, actionType);
  }
}
