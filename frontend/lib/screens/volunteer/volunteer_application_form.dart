// lib/screens/volunteer/my_volunteer_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';

class MyVolunteerApplicationsScreen extends StatefulWidget {
  const MyVolunteerApplicationsScreen({super.key});

  @override
  State<MyVolunteerApplicationsScreen> createState() =>
      _MyVolunteerApplicationsScreenState();
}

class _MyVolunteerApplicationsScreenState
    extends State<MyVolunteerApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVolunteerApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeVolunteerApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      if (!volunteerProvider.isInitialized) {
        await volunteerProvider.initialize();
      }
      await volunteerProvider.loadMyApplications();
    } catch (e) {
      debugPrint('❌ Error loading volunteer applications: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshApplications() async {
    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );
    await volunteerProvider.refresh();
  }

  Future<void> _logHours(VolunteerApplication application) async {
    final hoursController = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange),
                SizedBox(width: 8),
                Text('Log Volunteer Hours'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Activity: ${application.activityTitle}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress: ${application.hoursCompleted} hours completed',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Hours completed',
                    hintText: '2.5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final hours = double.tryParse(hoursController.text) ?? 0.0;
                  if (hours > 0) {
                    Navigator.of(context).pop(hours);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  'Log Hours',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (result != null && result > 0) {
      try {
        // Fixed: No return value expected from logVolunteerHours
        await Provider.of<VolunteerProvider>(
          context,
          listen: false,
        ).logVolunteerHours(application.id, result);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Hours logged successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging hours: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _withdrawApplication(VolunteerApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Withdraw Application'),
            content: Text(
              'Are you sure you want to withdraw your application for "${application.activityTitle}"?\n\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Withdraw'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Fixed: No return value expected from withdrawApplication
      await Provider.of<VolunteerProvider>(
        context,
        listen: false,
      ).withdrawApplication(application.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Application withdrawn successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error withdrawing application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Volunteer Applications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshApplications,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Consumer<VolunteerProvider>(
        builder: (context, volunteerProvider, child) {
          if (_isLoading || volunteerProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Loading your volunteer applications...'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshApplications,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsTab(
                  volunteerProvider.pendingApplications,
                  'pending',
                ),
                _buildApplicationsTab(
                  volunteerProvider.acceptedApplications,
                  'approved',
                ),
                _buildApplicationsTab(
                  volunteerProvider.completedApplications,
                  'completed',
                ),
                _buildApplicationsTab(
                  volunteerProvider.rejectedApplications,
                  'rejected',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationsTab(
    List<VolunteerApplication> applications,
    String type,
  ) {
    if (applications.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return _buildApplicationCard(application, type);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String title, message;
    IconData icon;

    switch (type) {
      case 'pending':
        title = 'No Pending Applications';
        message =
            'You don\'t have any pending volunteer applications.\nBrowse activities to find volunteer opportunities!';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        title = 'No Active Volunteering';
        message =
            'You don\'t have any active volunteer positions.\nApply for volunteer opportunities to get started!';
        icon = Icons.volunteer_activism;
        break;
      case 'completed':
        title = 'No Completed Volunteering';
        message =
            'You haven\'t completed any volunteer work yet.\nKeep up the great work on your active positions!';
        icon = Icons.emoji_events;
        break;
      case 'rejected':
        title = 'No Rejected Applications';
        message = 'Great! None of your applications have been rejected.';
        icon = Icons.sentiment_satisfied;
        break;
      default:
        title = 'No Applications';
        message = 'No volunteer applications found.';
        icon = Icons.volunteer_activism;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (type == 'pending' || type == 'approved') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  try {
                    Navigator.pushNamed(context, '/browse-activities');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Browse Activities coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.explore),
                label: const Text('Browse Activities'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(VolunteerApplication application, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: _getStatusColor(application.status),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      application.activityTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      application.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Application details
              if (application.description != null) ...[
                Text(
                  application.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Hours progress (for approved/completed applications)
              if (application.isAccepted || application.isCompleted) ...[
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Hours: ${application.hoursCompleted}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Status description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    application.status,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(application.status),
                      size: 16,
                      color: _getStatusColor(application.status),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Applied on ${application.formattedDate}',
                        style: TextStyle(
                          color: _getStatusColor(application.status),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showApplicationDetails(application),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Dynamic action button based on status
                  if (application.isPending) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _withdrawApplication(application),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Withdraw',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ] else if (application.isAccepted) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _logHours(application),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Log Hours',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ] else if (application.isCompleted) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'completed':
        return Icons.emoji_events;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  void _showApplicationDetails(VolunteerApplication application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        application.activityTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(application.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        application.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Application details
                if (application.description != null) ...[
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      application.description!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Application info
                const Text(
                  'Application Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _buildDetailRow(Icons.schedule, 'Status', application.status),
                _buildDetailRow(
                  Icons.access_time,
                  'Hours Completed',
                  '${application.hoursCompleted}',
                ),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Applied',
                  application.formattedDate,
                ),
                if (application.location != null)
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    application.location!,
                  ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
