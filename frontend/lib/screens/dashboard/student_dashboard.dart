// lib/screens/dashboard/student_dashboard.dart - UPDATED WITH NEW COLOR SCHEME
import 'package:flutter/material.dart';
import 'package:frontend/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/auth_provider.dart';
import '../activities/recent_activities_screen.dart';

class StudentDashboard extends StatefulWidget {
  final VoidCallback? onBrowseActivitiesTap;
  const StudentDashboard({super.key, this.onBrowseActivitiesTap});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );

      // Initialize providers if needed
      if (!activityProvider.isInitialized) {
        await activityProvider.initialize();
      }
      if (!volunteerProvider.isInitialized) {
        await volunteerProvider.initialize();
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFD), // Clean white background
      appBar: AppBar(
        // Move title to far left with proper spacing
        titleSpacing: 16,
        title: const Text(
          'Beyond Activities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20, // Balanced font size
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF3F51B5), // Primary blue
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBell(), 
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: const Color(0xFF3F51B5), // Primary blue refresh indicator
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Welcome Card
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                // Stats Cards Row
                _buildStatsRow(),
                const SizedBox(height: 32),
                // Quick Actions Section
                _buildQuickActionsSection(),
                const SizedBox(height: 32),
                // Recent Activities Section
                _buildRecentActivitiesSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.fullName ?? 'Student';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3F51B5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3F51B5).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back, $userName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Balanced font size
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover exciting extracurricular activities',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14, // Balanced font size
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.onBrowseActivitiesTap ??
                    () => Navigator.pushNamed(context, '/browse-activities'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3F51B5), // Primary blue text
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Browse Activities',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Balanced font size
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Consumer2<ActivityProvider, VolunteerProvider>(
      builder: (context, activityProvider, volunteerProvider, child) {
        final activitiesJoined = activityProvider.userEnrolledActivities.length;
        final hoursEarned = volunteerProvider.myApplications.fold<double>(
          0,
          (sum, app) => sum + (app.hoursCompleted ?? 0),
        );
        final volunteerHours = volunteerProvider.myApplications
            .where((app) => app.status.toLowerCase() == 'completed')
            .fold<double>(0, (sum, app) => sum + (app.hoursCompleted ?? 0));

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                activitiesJoined.toString(),
                'Activities\nJoined',
                Icons.calendar_today,
                const Color(0xFF3F51B5), // Primary blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                hoursEarned.toInt().toString(),
                'Hours\nEarned',
                Icons.access_time,
                const Color(0xFF10B981), // Success green
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                volunteerHours.toInt().toString(),
                'Volunteer\nHours',
                Icons.volunteer_activism,
                const Color(0xFFF59E0B), // Warning amber
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color), // Balanced icon size
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20, // Balanced font size
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Balanced font size
              color: Colors.grey[600],
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18, // Balanced font size
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              'Browse Activities',
              Icons.explore,
              const Color(0xFF3F51B5), // Primary blue
              () => Navigator.pushNamed(context, '/browse-activities'),
            ),
            _buildQuickActionCard(
              'My Activities',
              Icons.calendar_today,
              const Color(0xFF10B981), // Success green
              () => Navigator.pushNamed(context, '/my-activities'),
            ),
            _buildQuickActionCard(
              'Volunteering',
              Icons.volunteer_activism,
              const Color(0xFFF59E0B), // Warning amber
              () => Navigator.pushNamed(context, '/volunteering-dashboard'),
            ),
            _buildQuickActionCard(
              'Profile',
              Icons.person,
              const Color(0xFF8B5CF6), // Purple
              () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color), // Balanced icon size
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13, // Balanced font size
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18, // Balanced font size
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecentActivitiesScreen(),
                ),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF3F51B5), // Primary blue
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // Balanced font size
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Show actual recent activities from provider
        Consumer<ActivityProvider>(
          builder: (context, activityProvider, child) {
            // Get recent past activities (last 7 days)
            final now = DateTime.now();
            final recentActivities = activityProvider.activities
                .where((activity) {
                  final activityEndTime = activity.endTime ??
                      activity.startTime.add(const Duration(hours: 2));
                  final isPast = activityEndTime.isBefore(now);
                  final daysSince = now.difference(activityEndTime).inDays;
                  return isPast && daysSince <= 7;
                })
                .take(3)
                .toList();

            if (recentActivities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 40, // Balanced icon size
                      color: const Color(0xFF8B95CA), // Light color
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activities',
                      style: TextStyle(
                        fontSize: 15, // Balanced font size
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activities from the past week will appear here',
                      style: TextStyle(
                        fontSize: 13, // Balanced font size
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: recentActivities
                  .map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityCard(
                        activity.title,
                        _formatActivityTime(activity.startTime),
                        activity.location,
                        activity.isVolunteering,
                        activity.isEnrolled,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String title,
    String time,
    String location,
    bool isVolunteer,
    bool isEnrolled,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isVolunteer
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF3F51B5)) // Primary blue for activities
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVolunteer ? Icons.volunteer_activism : Icons.event,
              color: isVolunteer
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF3F51B5), // Primary blue for activities
              size: 20, // Balanced icon size
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15, // Balanced font size
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13, // Balanced font size
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 13, // Balanced font size
                    color: Colors.grey[600],
                  ),
                ),
                if (isEnrolled) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVolunteer ? 'Applied' : 'Enrolled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isVolunteer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'VOLUNTEER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9, // Balanced font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    if (difference == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (difference <= 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} ${_formatTime(dateTime)}';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}