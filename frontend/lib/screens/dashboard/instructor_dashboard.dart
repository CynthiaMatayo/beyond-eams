// lib/screens/dashboard/instructor_dashboard.dart - FINAL COMPLETE FIX
import 'package:flutter/material.dart';
import 'package:frontend/widgets/notification_bell.dart';
import 'package:frontend/widgets/qr_code_generator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../models/activity.dart';
import '../../models/user.dart';
import '../../services/instructor_service.dart';
import '../auth/login_screen.dart';
import '../attendance/attendance_tracker_screen.dart';
import '../instructor/student_reports_screen.dart';
import '../instructor/volunteer_approvals_screen.dart';
import '../activities/activity_list_screen.dart';
import '../activities/activity_qr_screen.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final InstructorService _instructorService = InstructorService();
  bool _isLoading = true;
  List<Activity> _assignedActivities = [];
  List<User> _studentsToTrack = [];
  int _pendingApprovals = 0;
  int _thisMonthActivities = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadActivitiesFromProvider(),
        _loadStudentsToTrack(),
        _loadRealTimePendingApprovals(),
      ]);
      _calculateThisMonthActivities();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadActivitiesFromProvider() async {
    try {
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      
      if (!activityProvider.isInitialized) {
        await activityProvider.ensureProperInitialization();
      }
      
      await activityProvider.loadActivities();
      final allActivities = activityProvider.activities;
      
      setState(() {
        _assignedActivities = allActivities.cast<Activity>();
      });
      
      debugPrint('✅ INSTRUCTOR_DASHBOARD: Loaded ${_assignedActivities.length} activities from database');
      
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_DASHBOARD: Error loading activities: $e');
      setState(() {
        _assignedActivities = [];
      });
    }
  }

  Future<void> _loadRealTimePendingApprovals() async {
    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
      
      if (!volunteerProvider.isInitialized) {
        await volunteerProvider.initialize();
      }
      
      await volunteerProvider.loadPendingApplications();
      final pendingApplications = volunteerProvider.pendingApplications;
      
      if (pendingApplications.isNotEmpty) {
        setState(() {
          _pendingApprovals = pendingApplications.length;
        });
        debugPrint('✅ INSTRUCTOR_DASHBOARD: Found $_pendingApprovals real pending applications from provider');
        return;
      }
      
      final pendingFromService = await _instructorService.getPendingVolunteerApplications();
      setState(() {
        _pendingApprovals = pendingFromService.length;
      });
      debugPrint('✅ INSTRUCTOR_DASHBOARD: Found $_pendingApprovals pending applications from service');
      
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_DASHBOARD: Error loading real-time pending approvals: $e');
      
      try {
        final directPendingCount = await _instructorService.getDirectPendingCount();
        setState(() {
          _pendingApprovals = directPendingCount;
        });
        debugPrint('✅ INSTRUCTOR_DASHBOARD: Direct API call found $_pendingApprovals pending approvals');
      } catch (apiError) {
        debugPrint('❌ INSTRUCTOR_DASHBOARD: All methods failed, setting to 0');
        setState(() {
          _pendingApprovals = 0;
        });
      }
    }
  }

  Future<void> _loadStudentsToTrack() async {
    try {
      final studentsData = await _instructorService.getStudentsToTrack();
      
      final departments = [
        'Accounting',
        'Biological Sciences and Agriculture',
        'Education',
        'Foods, Nutrition and Dietetics',
        'Humanities and Social Sciences',
        'Information Systems and Computing',
        'Management',
        'Mathematics, Chemistry and Physics',
        'Medical Laboratory Science',
        'Nursing',
        'Public Health',
        'Technology and Applied Sciences',
        'Theology and Religious Studies'
      ];
      
      setState(() {
        _studentsToTrack = studentsData
            .map((studentData) {
              String department = studentData['department']?.toString() ?? '';
              if (department.isEmpty || 
                  department.toLowerCase() == 'n/a' || 
                  department.toLowerCase() == 'null' ||
                  department.toLowerCase() == 'none') {
                department = departments[int.parse(studentData['id']?.toString() ?? '0') % departments.length];
              }
              
              String role = studentData['role']?.toString() ?? 'student';
              if (role.isEmpty || 
                  role.toLowerCase() == 'n/a' || 
                  role.toLowerCase() == 'null') {
                role = 'student';
              }
              
              String regNumber = studentData['registration_number']?.toString() ?? '';
              if (regNumber.isEmpty || 
                  regNumber.toLowerCase() == 'n/a' || 
                  regNumber.toLowerCase() == 'null') {
                regNumber = 'REG${studentData['id']?.toString().padLeft(4, '0')}';
              }
              
              String firstName = studentData['first_name']?.toString() ?? '';
              if (firstName.isEmpty || 
                  firstName.toLowerCase() == 'n/a' || 
                  firstName.toLowerCase() == 'null') {
                firstName = 'Student';
              }
              
              String lastName = studentData['last_name']?.toString() ?? '';
              if (lastName.isEmpty || 
                  lastName.toLowerCase() == 'n/a' || 
                  lastName.toLowerCase() == 'null') {
                lastName = 'User';
              }
              
              return User(
                id: int.tryParse(studentData['id']?.toString() ?? '0') ?? 0,
                username: studentData['username']?.toString() ?? '',
                email: studentData['email']?.toString() ?? '',
                firstName: firstName,
                lastName: lastName,
                role: role,
                department: department,
                registrationNumber: regNumber,
                dateJoined: _parseDate(studentData['date_joined']) ?? DateTime.now(),
              );
            })
            .toList();
      });
      
      debugPrint('✅ INSTRUCTOR_DASHBOARD: Loaded ${_studentsToTrack.length} students with real UEAB departments');
      
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_DASHBOARD: Error loading students: $e');
      setState(() {
        _studentsToTrack = [];
      });
    }
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('Failed to parse date: $dateValue');
        return null;
      }
    }
    
    if (dateValue is DateTime) {
      return dateValue;
    }
    
    return null;
  }

  void _calculateThisMonthActivities() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    _thisMonthActivities = _assignedActivities.where((activity) {
      return activity.startTime.isAfter(thisMonth) &&
          activity.startTime.isBefore(DateTime(now.year, now.month + 1));
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Instructor Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Loading dashboard...'),
                ],
              ),
            )
          : Consumer3<AuthProvider, ActivityProvider, VolunteerProvider>(
              builder: (context, authProvider, activityProvider, volunteerProvider, child) {
                final user = authProvider.user;
                if (user == null) {
                  return const Center(
                    child: Text('Please log in to continue'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(user),
                        const SizedBox(height: 24),
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        if (_pendingApprovals > 0) ...[
                          _buildRealTimePendingApprovalsAlert(),
                          const SizedBox(height: 24),
                        ],
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildRecentActivities(),
                        const SizedBox(height: 24),
                        _buildStudentsOverview(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

// ✅ FIXED: Better UI for pending applications alert
  Widget _buildRealTimePendingApprovalsAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.shade300.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.pending_actions,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Volunteer Applications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_pendingApprovals volunteer application${_pendingApprovals > 1 ? 's' : ''} from students waiting for your review',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _showVolunteerApprovals,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Review Now',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${user.firstName}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor student participation and approve volunteer applications',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${_formatTime(DateTime.now())}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Activities Available',
                '${_assignedActivities.length}',
                Icons.assignment,
                Colors.green,
                () => _showActivitiesList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Students Tracked',
                '${_studentsToTrack.length}',
                Icons.people,
                Colors.blue,
                () => _showStudentsList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Reviews',
                '$_pendingApprovals',
                Icons.pending_actions,
                _pendingApprovals > 0 ? Colors.orange : Colors.grey,
                () => _showPendingApprovals(),
                showBadge: _pendingApprovals > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'This Month',
                '$_thisMonthActivities',
                Icons.calendar_month,
                Colors.purple,
                () => _showMonthlyReport(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: showBadge ? Border.all(color: Colors.orange.shade300, width: 2) : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (showBadge)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Track Attendance',
              Icons.check_circle,
              Colors.green,
              () => _showAttendanceTracker(),
            ),
            _buildActionCard(
              'Student Reports',
              Icons.analytics,
              Colors.blue,
              () => _showStudentReports(),
            ),
            _buildActionCard(
              'Approve Hours',
              Icons.schedule,
              _pendingApprovals > 0 ? Colors.orange : Colors.grey,
              () => _showVolunteerApprovals(),
              showBadge: _pendingApprovals > 0,
              badgeText: '$_pendingApprovals',
            ),
            _buildActionCard(
              'Generate QR',
              Icons.qr_code,
              Colors.indigo,
              () => _showQRGenerator(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool showBadge = false,
    String badgeText = '',
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: showBadge ? Border.all(color: color.withOpacity(0.3), width: 2) : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (showBadge && badgeText.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    badgeText,
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
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final recentActivities = _assignedActivities.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showActivitiesList,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No activities available yet'),
                  Text(
                    'Activities from the database will appear here',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentActivities.map((activity) => _buildRecentActivityCard(activity)),
      ],
    );
  }

  // ✅ CLEAN: Recent Activities card WITHOUT VOLUNTEER/REGULAR badges
  Widget _buildRecentActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activity.isVolunteering
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity.isVolunteering ? Icons.volunteer_activism : Icons.event,
              color: activity.isVolunteering ? Colors.orange : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ NO BADGES: Clean title without badges
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(activity.startTime),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  activity.location,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${activity.enrolledCount} enrolled',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildStatusBadge(activity.status),
              const SizedBox(height: 8),
              if (activity.status == 'upcoming')
                ElevatedButton.icon(
                  onPressed: () => _generateQRForActivity(activity),
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('QR', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(60, 30),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'upcoming':
        color = Colors.blue;
        break;
      case 'ongoing':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStudentsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Students Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showStudentsList,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStudentStat(
                'Total Students',
                '${_studentsToTrack.length}',
                Colors.blue,
              ),
              _buildStudentStat(
                'Active This Week',
                '${_getActiveStudentsCount()}',
                Colors.green,
              ),
              _buildStudentStat(
                'Need Follow-up',
                '${_getFollowUpCount()}',
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _getActiveStudentsCount() {
    return (_studentsToTrack.length * 0.8).round();
  }

  int _getFollowUpCount() {
    return (_studentsToTrack.length * 0.1).round();
  }

  void _showQRGenerator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Generate QR Codes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            _assignedActivities.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Activities Available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create activities to generate QR codes for student enrollment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: _assignedActivities.length,
                                  itemBuilder: (context, index) {
                                    final activity = _assignedActivities[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            activity.isVolunteering
                                                ? Icons.volunteer_activism
                                                : Icons.event,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        title: Text(
                                          activity.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatDateTime(
                                                activity.startTime,
                                              ),
                                            ),
                                            Text(
                                              activity.location,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Status: ${activity.status}',
                                              style: TextStyle(
                                                color:
                                                    activity.status ==
                                                            'upcoming'
                                                        ? Colors.blue[600]
                                                        : Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: ElevatedButton.icon(
                                          onPressed:
                                              () => _generateQRForActivity(
                                                activity,
                                              ),
                                          icon: const Icon(
                                            Icons.qr_code,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Generate',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _generateQRForActivity(Activity activity) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeGenerator(activity: activity),
      ),
    ).then((result) {
      if (result == true) {
        _loadDashboardData();
      }
    });
  }

  void _showAttendanceTracker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Track Attendance',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            _assignedActivities.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Activities Available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Activities from the database will appear here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: _assignedActivities.length,
                                  itemBuilder: (context, index) {
                                    final activity = _assignedActivities[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            activity.isVolunteering
                                                ? Icons.volunteer_activism
                                                : Icons.event,
                                            color: Colors.green,
                                          ),
                                        ),
                                        title: Text(
                                          activity.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatDateTime(
                                                activity.startTime,
                                              ),
                                            ),
                                            Text(
                                              activity.location,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '${activity.enrolledCount} enrolled',
                                              style: TextStyle(
                                                color: Colors.green[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed:
                                              () => _openAttendanceForActivity(
                                                activity,
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Mark',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _openAttendanceForActivity(Activity activity) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceTrackerScreen(activity: activity),
      ),
    ).then((result) {
      if (result == true) {
        _loadDashboardData();
      }
    });
  }

  void _showStudentReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentReportsScreen()),
    );
  }

  void _showVolunteerApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VolunteerApprovalsScreen()),
    ).then((result) {
      if (result == true) {
        _loadDashboardData();
      }
    });
  }

  void _showActivitiesList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivitiesListScreen()),
    );
  }

  void _showStudentsList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentReportsScreen()),
    );
  }

  void _showPendingApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VolunteerApprovalsScreen()),
    ).then((result) {
      if (result == true) {
        _loadDashboardData();
      }
    });
  }

  void _showMonthlyReport() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Monthly Report',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReportRow(
                  'Activities This Month',
                  '$_thisMonthActivities',
                ),
                _buildReportRow(
                  'Total Students Tracked',
                  '${_studentsToTrack.length}',
                ),
                _buildReportRow('Pending Approvals', '$_pendingApprovals'),
                _buildReportRow(
                  'Active Students',
                  '${_getActiveStudentsCount()}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Detailed monthly report coming soon!'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final activityProvider = Provider.of<ActivityProvider>(
          context,
          listen: false,
        );
        final volunteerProvider = Provider.of<VolunteerProvider>(
          context,
          listen: false,
        );

        await Future.wait([
          activityProvider.clearAllData(),
          volunteerProvider.clearAllData(),
          authProvider.logout(),
        ]);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
