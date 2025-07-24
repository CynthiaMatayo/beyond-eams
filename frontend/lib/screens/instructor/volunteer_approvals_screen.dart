// lib/screens/instructor/volunteer_approvals_screen.dart - UPDATED WITH STUDENT NAME FIX
import 'package:flutter/material.dart';
import '../../services/instructor_service.dart';

class VolunteerApprovalsScreen extends StatefulWidget {
  const VolunteerApprovalsScreen({super.key});

  @override
  State<VolunteerApprovalsScreen> createState() =>
      _VolunteerApprovalsScreenState();
}

class _VolunteerApprovalsScreenState extends State<VolunteerApprovalsScreen> {
  final InstructorService _instructorService = InstructorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allApprovals = [];
  String _selectedStatus = 'pending';
  final List<String> _statusOptions = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() => _isLoading = true);
    try {
      final approvals = await _instructorService.getAllVolunteerApplications();

      if (mounted) {
        setState(() {
          _allApprovals = approvals;
          _isLoading = false;
        });

        // Debug: Print student names to verify fix
        if (approvals.isNotEmpty) {
          print('✅ LOADED ${approvals.length} applications');
          for (
            var i = 0;
            i < (approvals.length > 3 ? 3 : approvals.length);
            i++
          ) {
            final app = approvals[i];
            print(
              'Sample $i: ${app['student_name']} (${app['status']}) - ${app['activity_title']}',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allApprovals = [];
          _isLoading = false;
        });
        print('❌ Error loading approvals: $e');

        // Show error with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load applications: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _loadApprovals,
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApprovals {
    return _allApprovals.where((approval) {
      return approval['status'] == _selectedStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Volunteer Hour Approvals',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApprovals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusOptions.length,
                    itemBuilder: (context, index) {
                      final status = _statusOptions[index];
                      final isSelected = _selectedStatus == status;
                      final statusCount =
                          _allApprovals
                              .where((app) => app['status'] == status)
                              .length;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            '${status.toUpperCase()} ($statusCount)',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedStatus = status);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color:
                                isSelected ? Colors.orange : Colors.grey[300]!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Approvals List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                    : _filteredApprovals.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadApprovals,
                      color: Colors.orange,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredApprovals.length,
                        itemBuilder: (context, index) {
                          final approval = _filteredApprovals[index];
                          return _buildApprovalCard(approval);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions,
              size: 64,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${_selectedStatus.toUpperCase()} Approvals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _selectedStatus == 'pending'
                  ? 'No volunteer hours awaiting approval'
                  : 'No ${_selectedStatus} volunteer hour submissions',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadApprovals,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> approval) {
    final status = approval['status'] ?? 'pending';
    final hours = approval['volunteer_hours'] ?? 0;
    final submissionDate = approval['submission_date'];

    // FIXED: Better student name handling with fallbacks
    String studentName = approval['student_name'] ?? 'Unknown Student';
    if (studentName.trim().isEmpty || studentName == 'Student User') {
      // Try alternative fields if student_name is empty or generic
      studentName =
          approval['student_email']?.split('@')[0] ??
          'Student ${approval['student_id'] ?? 'Unknown'}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        approval['activity_title'] ?? 'Unknown Activity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Details
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.schedule, '$hours hours', Colors.blue),
                _buildInfoChip(
                  Icons.calendar_today,
                  _formatSubmissionDate(submissionDate),
                  Colors.green,
                ),
                _buildInfoChip(
                  Icons.person,
                  'ID: ${approval['student_id'] ?? 'N/A'}',
                  Colors.purple,
                ),
                if (approval['student_email'] != null)
                  _buildInfoChip(
                    Icons.email,
                    approval['student_email'],
                    Colors.indigo,
                  ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              // Action Buttons for pending approvals
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectApproval(approval, studentName),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveHours(approval, studentName),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (approval['comments'] != null ||
                approval['reason'] != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'approved' ? 'Comments:' : 'Rejection Reason:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approval['comments'] ??
                          approval['reason'] ??
                          'No comments provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _formatSubmissionDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _approveHours(Map<String, dynamic> approval, String studentName) {
    final TextEditingController commentsController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Approve Volunteer Hours',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approve ${approval['volunteer_hours']} volunteer hours for $studentName?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(
                    labelText: 'Comments (Optional)',
                    hintText: 'Add any comments about the approval...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processApproval(
                    approval,
                    commentsController.text,
                    studentName,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
  }

  void _rejectApproval(Map<String, dynamic> approval, String studentName) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Reject Volunteer Hours',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reject ${approval['volunteer_hours']} volunteer hours for $studentName?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason (Required)',
                    hintText: 'Please provide a reason for rejection...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a rejection reason'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _processRejection(
                    approval,
                    reasonController.text,
                    studentName,
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

  void _processApproval(
    Map<String, dynamic> approval,
    String comments,
    String studentName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Colors.green),
          ),
    );

    try {
      final success = await _instructorService.approveVolunteerHours(
        approval['id'],
        approval['volunteer_hours'],
        comments,
      );

      if (mounted) {
        Navigator.pop(context); // Remove loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully approved ${approval['volunteer_hours']} hours for $studentName',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          await _loadApprovals(); // Refresh the list
        } else {
          throw Exception('Approval was not successful');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving hours: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _processRejection(
    Map<String, dynamic> approval,
    String reason,
    String studentName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      final success = await _instructorService.rejectVolunteerHours(
        approval['id'],
        reason,
      );

      if (mounted) {
        Navigator.pop(context); // Remove loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rejected volunteer hours for $studentName'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          await _loadApprovals(); // Refresh the list
        } else {
          throw Exception('Rejection was not successful');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting hours: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
