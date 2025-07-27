// lib/screens/dashboard/coordinator_dashboard.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:frontend/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import '../../providers/coordinator_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/activity.dart';
import '../../models/user.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});
  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  bool _isLoading = true;
  List<Activity> _myActivities = [];
  int _activitiesNeedingPromotion = 0;
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
        _loadActivitiesNeedingPromotion(),
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
      final coordinatorProvider = Provider.of<CoordinatorProvider>(
        context,
        listen: false,
      );
      if (!coordinatorProvider.isInitialized) {
        await coordinatorProvider.initialize();
      }
      // CRITICAL: Force refresh data from database
      await coordinatorProvider.loadMyActivities();
      final activities = coordinatorProvider.myActivities;
      setState(() {
        _myActivities = activities;
      });
      debugPrint('📊 Dashboard loaded ${activities.length} activities');
    } catch (e) {
      debugPrint('Error loading activities: $e');
      setState(() {
        _myActivities = [];
      });
    }
  }

  Future<void> _loadActivitiesNeedingPromotion() async {
    try {
      final coordinatorProvider = Provider.of<CoordinatorProvider>(
        context,
        listen: false,
      );
      final activitiesNeedingPromotion =
          coordinatorProvider.getActivitiesNeedingPromotion();
      setState(() {
        _activitiesNeedingPromotion = activitiesNeedingPromotion.length;
      });
    } catch (e) {
      debugPrint('Error loading activities needing promotion: $e');
      setState(() {
        _activitiesNeedingPromotion = 0;
      });
    }
  }

  void _calculateThisMonthActivities() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    _thisMonthActivities =
        _myActivities.where((activity) {
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
          'Coordinator Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange,
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
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text('Loading dashboard...'),
                  ],
                ),
              )
              : Consumer2<AuthProvider, CoordinatorProvider>(
                builder: (context, authProvider, coordinatorProvider, child) {
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
                          _buildQuickStats(coordinatorProvider),
                          const SizedBox(height: 24),
                          // Activities needing promotion alert
                          if (_activitiesNeedingPromotion > 0) ...[
                            _buildPromotionAlert(),
                            const SizedBox(height: 24),
                          ],
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildRecentActivities(),
                          const SizedBox(height: 24),
                          _buildActivityStatusOverview(coordinatorProvider),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildPromotionAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activities Need Promotion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_activitiesNeedingPromotion activit${_activitiesNeedingPromotion > 1 ? 'ies' : 'y'} starting soon need${_activitiesNeedingPromotion > 1 ? '' : 's'} promotion',
                  style: TextStyle(color: Colors.orange.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showPromoteActivities,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Promote Now', style: TextStyle(fontSize: 12)),
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
          colors: [Colors.orange.shade400, Colors.orange.shade600],
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
            'Create and manage activities for student engagement',
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

  Widget _buildQuickStats(CoordinatorProvider provider) {
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
                'Total Activities',
                '${provider.totalActivitiesCount}',
                Icons.event,
                Colors.blue,
                () => _showManageActivities(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Enrollments',
                '${provider.totalEnrollments}',
                Icons.people,
                Colors.green,
                () => _showActivityReports(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month',
                '${provider.thisMonthActivitiesCount}',
                Icons.calendar_month,
                Colors.purple,
                () => _showMonthlyReport(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Volunteers',
                '${provider.activeVolunteersCount}',
                Icons.volunteer_activism,
                Colors.orange,
                () => _showVolunteerManagement(),
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
          border:
              showBadge
                  ? Border.all(color: Colors.orange.shade300, width: 2)
                  : null,
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
    return Consumer<CoordinatorProvider>(
      builder: (context, provider, child) {
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
                  'Create Activity',
                  Icons.add_circle,
                  Colors.orange,
                  () => _showCreateActivity(),
                ),
                _buildActionCard(
                  'Manage Activities',
                  Icons.list_alt,
                  Colors.blue,
                  () => _showManageActivities(),
                ),
                _buildActionCard(
                  'Promote Activities',
                  Icons.campaign,
                  Colors.purple,
                  () => _showPromoteActivities(),
                  showBadge: _activitiesNeedingPromotion > 0,
                  badgeText: '$_activitiesNeedingPromotion',
                ),
                _buildActionCard(
                  'View Reports',
                  Icons.analytics,
                  Colors.green,
                  () => _showActivityReports(),
                ),
              ],
            ),
          ],
        );
      },
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
          border:
              showBadge
                  ? Border.all(color: color.withOpacity(0.3), width: 2)
                  : null,
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
    final recentActivities = _myActivities.take(3).toList();
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
              onPressed: _showManageActivities,
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
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No activities created yet'),
                  const Text(
                    'Create your first activity to get started',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateActivity,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentActivities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final coordinatorProvider = Provider.of<CoordinatorProvider>(
      context,
      listen: false,
    );
    final dynamicStatus = coordinatorProvider.getActivityDynamicStatus(
      activity,
    );

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
              color:
                  activity.isVolunteering
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
              _buildStatusBadge(dynamicStatus),
              const SizedBox(height: 8),
              if (dynamicStatus == 'upcoming' || dynamicStatus == 'draft')
                ElevatedButton.icon(
                  onPressed: () => _editActivity(activity),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
      case 'draft':
        color = Colors.orange;
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

  Widget _buildActivityStatusOverview(CoordinatorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity Status Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              _buildStatusStat(
                'Upcoming',
                '${provider.upcomingActivitiesCount}',
                Colors.blue,
              ),
              _buildStatusStat(
                'Ongoing',
                '${provider.ongoingActivitiesCount}',
                Colors.green,
              ),
              _buildStatusStat(
                'Completed',
                '${provider.completedActivitiesCount}',
                Colors.grey,
              ),
              _buildStatusStat(
                'Drafts',
                '${provider.draftActivitiesCount}',
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStat(String label, String value, Color color) {
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

  int _getTotalEnrollments() {
    return _myActivities.fold(
      0,
      (total, activity) => total + activity.enrolledCount,
    );
  }

  // FIXED: Navigation methods now refresh dashboard after returning
  void _showCreateActivity() {
    Navigator.pushNamed(context, '/coordinator/create-activity').then((_) {
      // Refresh dashboard after returning from create activity
      _loadDashboardData();
    });
  }

  void _showManageActivities() {
    Navigator.pushNamed(context, '/coordinator/manage-activities').then((_) {
      // Refresh dashboard after returning from manage activities
      _loadDashboardData();
    });
  }

  void _showPromoteActivities() {
    Navigator.pushNamed(context, '/coordinator/promote-activities');
  }

  void _showActivityReports() {
    Navigator.pushNamed(context, '/coordinator/activity-reports');
  }

  void _showVolunteerManagement() {
    Navigator.pushNamed(context, '/coordinator/volunteer-management');
  }

  void _editActivity(Activity activity) {
    Navigator.pushNamed(
      context,
      '/coordinator/edit-activity/${activity.id}',
    ).then((_) {
      // Refresh dashboard after editing
      _loadDashboardData();
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
                _buildReportRow('Total Activities', '${_myActivities.length}'),
                _buildReportRow(
                  'Total Enrollments',
                  '${_getTotalEnrollments()}',
                ),
                _buildReportRow(
                  'Need Promotion',
                  '$_activitiesNeedingPromotion',
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
                  _showActivityReports();
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
        final coordinatorProvider = Provider.of<CoordinatorProvider>(
          context,
          listen: false,
        );
        await Future.wait([
          coordinatorProvider.clearAllData(),
          authProvider.logout(),
        ]);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
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
