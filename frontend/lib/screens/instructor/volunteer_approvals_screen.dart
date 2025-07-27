// lib/screens/instructor/volunteer_approvals_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/volunteer_provider.dart';

class VolunteerApprovalsScreen extends StatefulWidget {
  const VolunteerApprovalsScreen({super.key});

  @override
  State<VolunteerApprovalsScreen> createState() =>
      _VolunteerApprovalsScreenState();
}

class _VolunteerApprovalsScreenState extends State<VolunteerApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );
    if (!volunteerProvider.isInitialized) {
      await volunteerProvider.initialize();
    }
    await volunteerProvider.loadPendingApplications();
  }

@override
  Widget build(BuildContext context) {
    return Consumer<VolunteerProvider>(
      builder: (context, volunteerProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Volunteer Applications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadApplications,
                tooltip: 'Refresh Applications',
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _showPreviousActivities,
                tooltip: 'Previous Activities',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: _buildTabWithCount(
                    'All',
                    volunteerProvider.myApplications.length,
                  ),
                ),
                Tab(
                  child: _buildTabWithCount(
                    'Pending',
                    volunteerProvider.pendingApplications.length,
                  ),
                ),
                Tab(
                  child: _buildTabWithCount(
                    'Approved',
                    volunteerProvider.acceptedApplications.length,
                  ),
                ),
                Tab(
                  child: _buildTabWithCount(
                    'Rejected',
                    volunteerProvider.rejectedApplications.length,
                  ),
                ),
              ],
            ),
          ),
          body:
              volunteerProvider.isLoading
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text('Loading applications...'),
                      ],
                    ),
                  )
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApplicationsList(
                        volunteerProvider.myApplications,
                        'all',
                      ),
                      _buildApplicationsList(
                        volunteerProvider.pendingApplications,
                        'pending',
                      ),
                      _buildApplicationsList(
                        volunteerProvider.acceptedApplications,
                        'approved',
                      ),
                      _buildApplicationsList(
                        volunteerProvider.rejectedApplications,
                        'rejected',
                      ),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildTabWithCount(String title, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsList(
    List<VolunteerApplication> applications,
    String filter,
  ) {
    if (applications.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;

      switch (filter) {
        case 'pending':
          emptyMessage = 'No pending applications';
          emptyIcon = Icons.pending_actions;
          break;
        case 'approved':
          emptyMessage = 'No approved applications';
          emptyIcon = Icons.check_circle_outline;
          break;
        case 'rejected':
          emptyMessage = 'No rejected applications';
          emptyIcon = Icons.cancel_outlined;
          break;
        default:
          emptyMessage = 'No applications found';
          emptyIcon = Icons.assignment_turned_in;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'pending'
                  ? 'All volunteer applications have been reviewed'
                  : 'Applications will appear here when available',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
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
              border: Border.all(
                color: _getStatusColor(application.status).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: _buildApplicationCard(application),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildApplicationCard(VolunteerApplication application) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getStatusColor(application.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.volunteer_activism,
          color: _getStatusColor(application.status),
          size: 24,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            application.studentName.isNotEmpty
                ? application.studentName
                : 'Student Application',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            application.activityTitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              'Applied: ${application.formattedDate}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(application.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                application.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(application.status),
                ),
              ),
            ),
          ],
        ),
      ),
      children: [_buildApplicationDetails(application)],
    );
  }

  Widget _buildApplicationDetails(VolunteerApplication application) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity Information Section
        _buildSectionHeader('Activity Information'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                Icons.event,
                'Activity',
                application.activityTitle,
                Colors.blue.shade700,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.access_time,
                'Date & Time',
                application.formattedActivityDateTime,
                Colors.blue.shade700,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.location_on,
                'Location',
                application.activityLocation.isNotEmpty
                    ? application.activityLocation
                    : 'Campus',
                Colors.blue.shade700,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Student Information Section
        _buildSectionHeader('Student Information'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                Icons.person,
                'Name',
                application.studentName.isNotEmpty
                    ? application.studentName
                    : 'Student Name',
                Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.email,
                'Email',
                application.studentEmail.isNotEmpty
                    ? application.studentEmail
                    : 'student@ueab.ac.ke',
                Colors.green.shade700,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Application Details Section
        _buildSectionHeader('Application Details'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.work_outline,
                'Preferred Role',
                application.specificRole.isNotEmpty
                    ? application.specificRole
                    : 'General volunteer',
                Colors.purple.shade700,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.schedule,
                'Availability',
                application.availability.isNotEmpty
                    ? application.availability
                    : 'Not specified',
                Colors.purple.shade700,
              ),
              const SizedBox(height: 16),

              // Motivation Section
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Motivation:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  application.motivation.isNotEmpty
                      ? application.motivation
                      : 'I am interested in volunteering for this activity.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Hours completed (if applicable)
              if (application.hoursCompleted > 0) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.timer,
                  'Hours Completed',
                  '${application.hoursCompleted} hours',
                  Colors.purple.shade700,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons (only for pending applications)
        if (application.status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(application),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveApplication(application),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Status information for non-pending applications
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(application.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getStatusColor(application.status).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(application.status),
                  color: _getStatusColor(application.status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusMessage(application.status),
                    style: TextStyle(
                      color: _getStatusColor(application.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'This application has been approved';
      case 'rejected':
        return 'This application has been rejected';
      case 'completed':
        return 'This volunteer work has been completed';
      default:
        return 'Application status: $status';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: color, fontSize: 14)),
        ),
      ],
    );
  }

  Future<void> _approveApplication(VolunteerApplication application) async {
    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      final success = await volunteerProvider.approveApplication(
        application.id,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Approved ${application.studentName}\'s application for ${application.activityTitle}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showRejectDialog(VolunteerApplication application) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Reject Application'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject ${application.studentName}\'s application for ${application.activityTitle}?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason (Optional):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Provide a reason for rejection...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(), // FIXED: Added close button
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(
                    context,
                  ).pop(); // FIXED: Close dialog before proceeding
                  await _rejectApplication(
                    application,
                    reasonController.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _rejectApplication(
    VolunteerApplication application,
    String reason,
  ) async {
    try {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      final success = await volunteerProvider.rejectApplication(
        application.id,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rejected ${application.studentName}\'s application',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPreviousActivities() {
    final volunteerProvider = Provider.of<VolunteerProvider>(
      context,
      listen: false,
    );

    final completedApplications = volunteerProvider.completedApplications;
    final approvedApplications = volunteerProvider.acceptedApplications;
    final rejectedApplications = volunteerProvider.rejectedApplications;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text('Previous Activities'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (completedApplications.isNotEmpty) ...[
                      _buildPreviousSection(
                        'Completed Activities',
                        completedApplications,
                        Colors.green,
                        Icons.check_circle,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (approvedApplications.isNotEmpty) ...[
                      _buildPreviousSection(
                        'Approved Activities',
                        approvedApplications,
                        Colors.blue,
                        Icons.thumb_up,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (rejectedApplications.isNotEmpty) ...[
                      _buildPreviousSection(
                        'Rejected Applications',
                        rejectedApplications,
                        Colors.red,
                        Icons.cancel,
                      ),
                    ],
                    if (completedApplications.isEmpty &&
                        approvedApplications.isEmpty &&
                        rejectedApplications.isEmpty) ...[
                      const Center(
                        child: Text(
                          'No previous activities found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(), // FIXED: Added close button
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildPreviousSection(
    String title,
    List<VolunteerApplication> applications,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...applications.map(
          (app) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.activityTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applied: ${app.formattedDate}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (app.hoursCompleted > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hours: ${app.hoursCompleted}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
