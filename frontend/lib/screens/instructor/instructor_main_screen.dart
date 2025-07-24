// lib/screens/instructor/instructor_main_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/screens/activities/activity_list_screen.dart';
import '../dashboard/instructor_dashboard.dart';
import 'student_reports_screen.dart';
import 'volunteer_approvals_screen.dart';
import '../profile/my_profile_screen.dart';


class InstructorMainScreen extends StatefulWidget {
  const InstructorMainScreen({super.key});

  @override
  State<InstructorMainScreen> createState() => _InstructorMainScreenState();
}

class _InstructorMainScreenState extends State<InstructorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InstructorDashboard(),
    const ActivitiesListScreen(),
    const StudentReportsScreen(),
    const VolunteerApprovalsScreen(),
    const MyProfileScreen(), // You'll need to create this or use existing profile
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Activities'),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Reports',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.approval),
      label: 'Approvals',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: _navItems,
        ),
      ),
    );
  }
}
