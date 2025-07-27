// lib/screens/admin/admin_activities_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:frontend/models/activity.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/widgets/admin_bottom_nav_bar.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<Activity> _allActivities = [];
  List<Activity> _activeActivities = [];
  List<Activity> _upcomingActivities = [];
  List<Activity> _completedActivities = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final activities = await _adminService.getAllActivities(pageSize: 100);
      final now = DateTime.now();

      setState(() {
        _allActivities = activities;
        _activeActivities =
            activities
                .where(
                  (a) => a.startDate.isBefore(now) && a.endDate.isAfter(now),
                )
                .toList();
        _upcomingActivities =
            activities.where((a) => a.startDate.isAfter(now)).toList();
        _completedActivities =
            activities.where((a) => a.endDate.isBefore(now)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load activities: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateActivityDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${_allActivities.length})'),
            Tab(text: 'Active (${_activeActivities.length})'),
            Tab(text: 'Upcoming (${_upcomingActivities.length})'),
            Tab(text: 'Completed (${_completedActivities.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Activities',
                    _allActivities.length.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Active Now',
                    _activeActivities.length.toString(),
                    Icons.play_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'This Month',
                    _getThisMonthCount().toString(),
                    Icons.calendar_month,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ],
              ),
            ),

          // Tab Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActivitiesList(_allActivities),
                        _buildActivitiesList(_activeActivities),
                        _buildActivitiesList(_upcomingActivities),
                        _buildActivitiesList(_completedActivities),
                      ],
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(
        currentIndex: 1,
      ), // Activities tab
    );
  }

  Widget _buildSummaryCard(
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(List<Activity> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No activities found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final now = DateTime.now();
    final isActive =
        activity.startDate.isBefore(now) && activity.endDate.isAfter(now);
    final isUpcoming = activity.startDate.isAfter(now);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = Colors.green;
      statusText = 'ACTIVE';
      statusIcon = Icons.play_circle;
    } else if (isUpcoming) {
      statusColor = Colors.blue;
      statusText = 'UPCOMING';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.grey;
      statusText = 'COMPLETED';
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateRange(activity.startDate, activity.endDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  activity.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activity.category != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.category!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${activity.participantCount} participants',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (activity.maxParticipants != null) ...[
                  Text(
                    ' / ${activity.maxParticipants}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'by ${activity.coordinatorName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected:
                      (action) => _handleActivityAction(action, activity),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'participants',
                          child: Row(
                            children: [
                              Icon(Icons.people),
                              SizedBox(width: 8),
                              Text('View Participants'),
                            ],
                          ),
                        ),
                        if (isActive || isUpcoming)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit Activity'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    return _allActivities
        .where(
          (activity) =>
              activity.startDate.month == now.month &&
              activity.startDate.year == now.year,
        )
        .length;
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.day == end.day &&
        start.month == end.month &&
        start.year == end.year) {
      return '${start.day}/${start.month}/${start.year}';
    }
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }

  void _handleActivityAction(String action, Activity activity) {
    switch (action) {
      case 'view':
        _showActivityDetails(activity);
        break;
      case 'participants':
        _showParticipants(activity);
        break;
      case 'edit':
        _showEditActivityDialog(activity);
        break;
      case 'delete':
        _confirmDeleteActivity(activity);
        break;
    }
  }

  void _showActivityDetails(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(activity.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Description', activity.description),
                  _buildDetailRow('Location', activity.location),
                  _buildDetailRow(
                    'Date Range',
                    _formatDateRange(activity.startDate, activity.endDate),
                  ),
                  _buildDetailRow('Coordinator', activity.coordinatorName),
                  _buildDetailRow(
                    'Participants',
                    '${activity.participantCount} registered',
                  ),
                  if (activity.maxParticipants != null)
                    _buildDetailRow(
                      'Max Participants',
                      activity.maxParticipants.toString(),
                    ),
                  if (activity.category != null)
                    _buildDetailRow('Category', activity.category!),
                  _buildDetailRow('Status', activity.status.toUpperCase()),
                  _buildDetailRow('Created', _formatDate(activity.createdAt)),
                ],
              ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showParticipants(Activity activity) async {
    try {
      final participants = await _adminService.getActivityParticipants(
        activity.id.toString(),
      );
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('${activity.title} - Participants'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child:
                      participants.isEmpty
                          ? const Center(child: Text('No participants yet'))
                          : ListView.builder(
                            itemCount: participants.length,
                            itemBuilder: (context, index) {
                              final participant = participants[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      participant.hasAttended
                                          ? Colors.green
                                          : Colors.grey,
                                  child: Text(
                                    participant.userName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(participant.userName),
                                subtitle: Text(participant.userEmail),
                                trailing:
                                    participant.hasAttended
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                        : const Icon(
                                          Icons.pending,
                                          color: Colors.orange,
                                        ),
                              );
                            },
                          ),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading participants: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditActivityDialog(Activity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality would open a detailed form'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCreateActivityDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create activity form would open here'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDeleteActivity(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Activity'),
            content: Text(
              'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteActivity(activity);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteActivity(Activity activity) async {
    try {
      final success = await _adminService.deleteActivity(
        activity.id.toString(),
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadActivities(); // Refresh the list
      } else {
        throw Exception('Failed to delete activity');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete activity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
