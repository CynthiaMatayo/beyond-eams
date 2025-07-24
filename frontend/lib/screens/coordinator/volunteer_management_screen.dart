// lib/screens/coordinator/volunteer_management_screen.dart
// FIXED: Coordinator-only version showing statistics and analytics
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/coordinator_provider.dart';
import '../../models/activity.dart';

class VolunteerManagementScreen extends StatefulWidget {
  const VolunteerManagementScreen({super.key});

  @override
  State<VolunteerManagementScreen> createState() => _VolunteerManagementScreenState();
}

class _VolunteerManagementScreenState extends State<VolunteerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Volunteer Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Volunteer Activities'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildVolunteerActivitiesTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/coordinator/create-activity'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.volunteer_activism),
        label: const Text('New Volunteer Activity'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<CoordinatorProvider>(
      builder: (context, provider, child) {
        final volunteerActivities = provider.myActivities
            .where((activity) => activity.isVolunteering)
            .toList();
        
        final totalVolunteers = volunteerActivities.fold(0, (sum, activity) => sum + activity.enrolledCount);
        final activeVolunteerActivities = volunteerActivities.where((activity) => 
            provider.getActivityDynamicStatus(activity) == 'upcoming' || 
            provider.getActivityDynamicStatus(activity) == 'ongoing').length;
        final completedVolunteerActivities = volunteerActivities.where((activity) => 
            provider.getActivityDynamicStatus(activity) == 'completed').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Volunteer Activities',
                      volunteerActivities.length.toString(),
                      Icons.volunteer_activism,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Volunteers',
                      totalVolunteers.toString(),
                      Icons.people,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Active Activities',
                      activeVolunteerActivities.toString(),
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Completed Activities',
                      completedVolunteerActivities.toString(),
                      Icons.check_circle,
                      Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Volunteer Application Management',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'As a coordinator, you create and manage volunteer activities. Instructors handle volunteer application approvals and rejections.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showInstructorContactInfo(),
                      icon: const Icon(Icons.contact_support, size: 16),
                      label: const Text('Contact Instructors'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVolunteerActivitiesTab() {
    return Consumer<CoordinatorProvider>(
      builder: (context, provider, child) {
        final allVolunteerActivities = provider.myActivities
            .where((activity) => activity.isVolunteering)
            .toList();

        if (allVolunteerActivities.isEmpty) {
          return _buildEmptyState(
            'No Volunteer Activities',
            'Create your first volunteering activity',
            Icons.add_circle_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allVolunteerActivities.length,
          itemBuilder: (context, index) {
            return _buildVolunteerActivityCard(allVolunteerActivities[index], provider);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<CoordinatorProvider>(
      builder: (context, provider, child) {
        final volunteerActivities = provider.myActivities
            .where((activity) => activity.isVolunteering)
            .toList();

        if (volunteerActivities.isEmpty) {
          return _buildEmptyState(
            'No Analytics Available',
            'Create volunteer activities to see analytics',
            Icons.analytics,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Volunteer Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Engagement Metrics
              _buildAnalyticsCard(
                'Engagement Metrics',
                [
                  _buildAnalyticsRow('Average Volunteers per Activity', 
                      volunteerActivities.isEmpty ? '0' : 
                      (volunteerActivities.fold(0, (sum, activity) => sum + activity.enrolledCount) / volunteerActivities.length).toStringAsFixed(1)),
                  _buildAnalyticsRow('Most Popular Activity', 
                      volunteerActivities.isEmpty ? 'None' :
                      volunteerActivities.reduce((a, b) => a.enrolledCount > b.enrolledCount ? a : b).title),
                  _buildAnalyticsRow('Total Volunteer Hours Offered', 
                      (volunteerActivities.fold(0.0, (sum, activity) => sum + activity.durationHours)).toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 16),

// Activity Status Distribution
              _buildAnalyticsCard('Activity Status Distribution', [
                _buildAnalyticsRow(
                  'Upcoming',
                  volunteerActivities
                      .where(
                        (a) =>
                            provider.getActivityDynamicStatus(a) == 'upcoming',
                      )
                      .length
                      .toString(),
                ),
                _buildAnalyticsRow(
                  'Ongoing',
                  volunteerActivities
                      .where(
                        (a) =>
                            provider.getActivityDynamicStatus(a) == 'ongoing',
                      )
                      .length
                      .toString(),
                ),
                _buildAnalyticsRow(
                  'Completed',
                  volunteerActivities
                      .where(
                        (a) =>
                            provider.getActivityDynamicStatus(a) == 'completed',
                      )
                      .length
                      .toString(),
                ),
                _buildAnalyticsRow(
                  'Draft',
                  volunteerActivities
                      .where((a) => a.status.toLowerCase() == 'draft')
                      .length
                      .toString(),
                ),
              ]),
              const SizedBox(height: 16),

              // Performance Metrics
              _buildAnalyticsCard('Performance Metrics', [
                _buildAnalyticsRow(
                  'Activities This Month',
                  provider.thisMonthActivitiesCount.toString(),
                ),
                _buildAnalyticsRow(
                  'Average Activity Duration',
                  volunteerActivities.isEmpty
                      ? '0 hours'
                      : '${(volunteerActivities.fold(0.0, (sum, activity) => sum + activity.durationHours) / volunteerActivities.length).toStringAsFixed(1)} hours',
                ),
                _buildAnalyticsRow(
                  'Featured Activities',
                  volunteerActivities
                      .where((a) => a.isFeatured)
                      .length
                      .toString(),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildVolunteerActivityCard(
    Activity activity,
    CoordinatorProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.purple,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      activity.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(provider.getActivityDynamicStatus(activity)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                '${activity.enrolledCount} Volunteers',
                Icons.people,
                Colors.purple,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                activity.formattedDate,
                Icons.calendar_today,
                Colors.blue,
              ),
            ],
          ),
          if (activity.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              activity.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewVolunteerStatistics(activity),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('View Statistics'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _manageActivity(activity),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Manage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
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

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  '/coordinator/create-activity',
                ),
            icon: const Icon(Icons.add),
            label: const Text('Create Volunteer Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _viewVolunteerStatistics(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Statistics - ${activity.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticRow(
                  'Enrolled Volunteers',
                  '${activity.enrolledCount}',
                ),
                _buildStatisticRow(
                  'Max Participants',
                  '${activity.maxParticipants ?? 'Unlimited'}',
                ),
                _buildStatisticRow(
                  'Enrollment Rate',
                  '${(activity.enrollmentPercentage * 100).toStringAsFixed(1)}%',
                ),
                _buildStatisticRow(
                  'Duration',
                  '${activity.durationHours.toStringAsFixed(1)} hours',
                ),
                _buildStatisticRow('Points Reward', '${activity.pointsReward}'),
                _buildStatisticRow(
                  'Registration Status',
                  activity.isRegistrationOpen ? 'Open' : 'Closed',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatisticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _manageActivity(Activity activity) {
    Navigator.pushNamed(context, '/coordinator/edit-activity/${activity.id}');
  }

  void _showInstructorContactInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Instructor Contact Information'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('For volunteer application management, please contact:'),
                SizedBox(height: 16),
                Text('📧 Email: instructors@university.edu'),
                Text('📞 Phone: +1 (555) 123-4567'),
                Text('🏢 Office: Faculty Building, Room 201'),
                SizedBox(height: 16),
                Text(
                  'Instructors handle all volunteer application approvals and rejections for your activities.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
