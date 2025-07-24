// lib/screens/activities/my_activities_screen.dart - FIXED SYNTAX
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../providers/auth_provider.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  bool _isInitialized = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized || !mounted) return;
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

      if (authProvider.user == null) return;

      if (!activityProvider.isInitialized) {
        await activityProvider.ensureProperInitialization();
      }

      if (!volunteerProvider.isInitialized) {
        await volunteerProvider.initialize();
      }

      await activityProvider.fetchUserActivities(authProvider.user!.id);
      await volunteerProvider.loadMyApplications();

      _isInitialized = true;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load activities');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Activities',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/activity_qr_screen');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', Icons.apps),
                const SizedBox(width: 8),
                _buildFilterChip('Joined', Icons.event_available),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('Volunteer', Icons.volunteer_activism),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Consumer3<ActivityProvider, VolunteerProvider, AuthProvider>(
              builder: (
                context,
                activityProvider,
                volunteerProvider,
                authProvider,
                child,
              ) {
                if (!_isInitialized ||
                    activityProvider.isLoading ||
                    volunteerProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFF3F51B5),
                  child: _buildContent(activityProvider, volunteerProvider),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context, 2),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3F51B5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ActivityProvider activityProvider,
    VolunteerProvider volunteerProvider,
  ) {
    List<Map<String, dynamic>> filteredActivities = [];

    if (_selectedFilter == 'All' || _selectedFilter == 'Joined') {
      final joinedActivities = activityProvider.getJoinedActivities(limit: 100);
      final userEnrolledActivities = activityProvider.userEnrolledActivities;

      // Add joined activities
      for (final activity in joinedActivities) {
        filteredActivities.add({
          'id': activity.id,
          'title': activity.title,
          'description': activity.description,
          'location': activity.location,
          'start_time': activity.startTime.toIso8601String(),
          'end_time': activity.endTime.toIso8601String(),
          'is_volunteering': activity.isVolunteering,
          'status': activity.status,
          'max_participants': activity.maxParticipants,
          'type': 'joined',
        });
      }

      // Add enrolled activities
      for (final enrolledActivity in userEnrolledActivities) {
        final id = enrolledActivity['id'];
        final alreadyAdded = filteredActivities.any((a) => a['id'] == id);
        if (!alreadyAdded) {
          final activityData = Map<String, dynamic>.from(enrolledActivity);
          activityData['type'] = 'joined';
          filteredActivities.add(activityData);
        }
      }
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Completed') {
      final completedActivities = activityProvider.userCompletedActivities;
      for (final activity in completedActivities) {
        final activityData = Map<String, dynamic>.from(activity);
        activityData['type'] = 'completed';
        filteredActivities.add(activityData);
      }
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Volunteer') {
      final applications = volunteerProvider.myApplications;
      for (final application in applications) {
        filteredActivities.add({
          'id': application.activityId,
          'title': application.activityTitle,
          'description': 'Volunteer application',
          'location': '',
          'start_time':
              application.appliedDate ?? DateTime.now().toIso8601String(),
          'is_volunteering': true,
          'status': application.status,
          'hours': application.estimatedHours ?? 0.0,
          'type': 'volunteer',
        });
      }
    }

    if (filteredActivities.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredActivities.length,
      itemBuilder: (context, index) {
        final activity = filteredActivities[index];
        if (activity['type'] == 'volunteer') {
          return _buildVolunteerCard(activity);
        }
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activityData) {
    final title = activityData['title'] ?? 'Unknown Activity';
    final description =
        activityData['description'] ?? 'No description available';
    final location = activityData['location'] ?? 'Unknown location';
    final isVolunteering = activityData['is_volunteering'] ?? false;
    final status = activityData['status'] ?? 'unknown';
    final type = activityData['type'] ?? 'joined';

    DateTime? startTime;
    try {
      if (activityData['start_time'] != null) {
        startTime = DateTime.parse(activityData['start_time']);
      }
    } catch (e) {
      debugPrint('Error parsing start time: $e');
    }

    final borderColor =
        isVolunteering ? Colors.orange : const Color(0xFF3F51B5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                if (type == 'joined')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'JOINED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (type == 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isVolunteering) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VOLUNTEER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Location and date
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                if (startTime != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(startTime),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showActivityDetails(activityData),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (type == 'joined' &&
                    (status == 'upcoming' || status == 'ongoing'))
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.pushNamed(
                            context,
                            '/activity_qr_screen',
                            arguments: activityData,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: borderColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'QR Scan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else if (type == 'joined')
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          status == 'completed'
                              ? null
                              : () => _handleUnenroll(activityData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            status == 'completed'
                                ? Colors.grey.shade300
                                : Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        status == 'completed' ? 'Completed' : 'Unenroll',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(Map<String, dynamic> applicationData) {
    final title = applicationData['title'] ?? 'Unknown Activity';
    final status = applicationData['status'] ?? 'pending';
    final hours = applicationData['hours'] ?? 0.0;

    DateTime? appliedDate;
    try {
      if (applicationData['start_time'] != null) {
        appliedDate = DateTime.parse(applicationData['start_time']);
      }
    } catch (e) {
      debugPrint('Error parsing applied date: $e');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getApplicationStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Applied date and hours
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  appliedDate != null
                      ? 'Applied: ${_formatDate(appliedDate)}'
                      : 'Volunteer Application',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                if (hours > 0) ...[
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${hours.toStringAsFixed(1)} hours',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Status description
            Text(
              _getApplicationStatusDescription(status),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedFilter == 'All' ? '' : _selectedFilter} Activities',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'You haven\'t joined any activities yet.'
                : 'No ${_selectedFilter.toLowerCase()} activities found.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(Map<String, dynamic> activityData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(activityData['title'] ?? 'Activity Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activityData['description'] != null) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(activityData['description']),
                  const SizedBox(height: 8),
                ],
                if (activityData['location'] != null) ...[
                  const Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(activityData['location']),
                  const SizedBox(height: 8),
                ],
                if (activityData['start_time'] != null) ...[
                  const Text(
                    'Date & Time:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(_formatDateTime(activityData['start_time'])),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleUnenroll(Map<String, dynamic> activityData) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Unenrollment'),
            content: Text(
              'Are you sure you want to unenroll from "${activityData['title']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Unenroll'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final activityProvider = Provider.of<ActivityProvider>(
          context,
          listen: false,
        );
        final success = await activityProvider.unenrollActivity(
          activityData['id'],
        );

        if (success) {
          _showSuccessSnackBar('Successfully unenrolled from activity');
          await _refreshData();
        } else {
          _showErrorSnackBar('Failed to unenroll from activity');
        }
      } catch (e) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // Helper methods
  Color _getApplicationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getApplicationStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your application is being reviewed by instructors.';
      case 'approved':
        return 'Your volunteer application has been approved.';
      case 'rejected':
        return 'Application was not approved this time.';
      default:
        return 'Application status approved.';
    }
  }

  String _formatDate(DateTime dateTime) {
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
    return '${months[dateTime.month - 1]} ${dateTime.day}/${dateTime.year}';
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
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
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} • $displayHour:$minute $ampm';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isInitialized = false);
    await _initializeData();
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3F51B5),
      unselectedItemColor: const Color(0xFF9CA3AF),
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'My Activities',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/student-dashboard',
              (route) => false,
            );
            break;
          case 1:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/browse-activities',
              (route) => false,
            );
            break;
          case 2:
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile',
              (route) => false,
            );
            break;
        }
      },
    );
  }
}
