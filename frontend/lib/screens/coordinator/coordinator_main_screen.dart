// lib/screens/coordinator/coordinator_main_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:frontend/screens/coordinator/manage_activities_screen.dart';
import 'package:frontend/screens/dashboard/coordinator_dashboard.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coordinator_provider.dart';
import 'create_activity_screen.dart';
import 'promote_activities_screen.dart';
import 'activity_reports_screen.dart';
import '../auth/login_screen.dart';

class CoordinatorMainScreen extends StatefulWidget {
  const CoordinatorMainScreen({super.key});

  @override
  State<CoordinatorMainScreen> createState() => _CoordinatorMainScreenState();
}

class _CoordinatorMainScreenState extends State<CoordinatorMainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Navigation items configuration
  static const List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.dashboard,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      tooltip: 'Coordinator Dashboard',
    ),
    BottomNavItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: 'Create',
      tooltip: 'Create New Activity',
    ),
    BottomNavItem(
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts,
      label: 'Manage',
      tooltip: 'Manage Activities',
    ),
    BottomNavItem(
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
      label: 'Promote',
      tooltip: 'Promote Activities',
    ),
    BottomNavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Reports',
      tooltip: 'Activity Reports',
    ),
  ];

  // Screen widgets
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CoordinatorDashboard(),
      const CreateActivityScreen(),
      const ManageActivitiesScreen(),
      const PromoteActivitiesScreen(),
      const ActivityReportsScreen(),
    ];
    // Initialize coordinator data when main screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCoordinatorData();
    });
  }

  Future<void> _initializeCoordinatorData() async {
    try {
      final coordinatorProvider = Provider.of<CoordinatorProvider>(
        context,
        listen: false,
      );
      if (!coordinatorProvider.isInitialized) {
        await coordinatorProvider.initialize();
      }
    } catch (e) {
      debugPrint('Error initializing coordinator data: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Double tap on same tab - handle special actions
      _handleDoubleTap(index);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    // Animate to page with smooth transition
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleDoubleTap(int index) {
    // Handle double tap actions (scroll to top, refresh, etc.)
    switch (index) {
      case 0: // Dashboard
        // Could trigger refresh of dashboard
        break;
      case 1: // Create
        // Could clear form or show quick actions
        break;
      case 2: // Manage
        // Could refresh activities list
        break;
      case 3: // Promote
        // Could refresh promotions
        break;
      case 4: // Reports
        // Could refresh reports
        break;
    }
  }

  Future<bool> _onWillPop() async {
    // Handle back button press
    if (_currentIndex != 0) {
      // Go to dashboard if not already there
      _onTabTapped(0);
      return false;
    }
    // Show logout confirmation if on dashboard
    return await _showLogoutDialog() ?? false;
  }

  Future<bool?> _showLogoutDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.orange),
                SizedBox(width: 8),
                Text('Exit Coordinator Panel'),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit the coordinator panel?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                  // Perform logout
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Check if user is still authenticated and is a coordinator
            if (!authProvider.isAuthenticated ||
                authProvider.user?.role != 'coordinator') {
              // Redirect to login if not authenticated or not a coordinator
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              });
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }
            return PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _screens,
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<CoordinatorProvider>(
      builder: (context, coordinatorProvider, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.orange,
              unselectedItemColor: Colors.grey[600],
              selectedFontSize: 12,
              unselectedFontSize: 11,
              elevation: 0,
              items:
                  _navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == _currentIndex;

                    // Create base icon widget
                    Widget iconWidget = _AnimatedNavIcon(
                      icon: item.icon,
                      activeIcon: item.activeIcon,
                      isSelected: isSelected,
                      tooltip: item.tooltip,
                    );

                    // ✅ FIXED: Only add notification badge to Promote tab (index 3)
                    // Removed badge from Manage tab (index 2)
                    if (index == 3) {
                      // Promote tab only
                      final needsPromotion =
                          coordinatorProvider
                              .getActivitiesNeedingPromotion()
                              .length;
                      if (needsPromotion > 0) {
                        iconWidget = _NotificationBadge(
                          count: needsPromotion,
                          child: iconWidget,
                        );
                      }
                    }

                    return BottomNavigationBarItem(
                      icon: iconWidget,
                      label: item.label,
                      tooltip: item.tooltip,
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ========== Navigation Item Data Class ==========
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });
}

// ========== Animated Navigation Icon ==========
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final String tooltip;

  const _AnimatedNavIcon({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.tooltip,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  widget.isSelected
                      ? BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      )
                      : null,
              child: Icon(
                widget.isSelected ? widget.activeIcon : widget.icon,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== Badge Widget for Notifications ==========
class _NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;

  const _NotificationBadge({required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
