import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import 'qr_code_display_screen.dart';

class ActivityAttendancesScreen extends StatefulWidget {
  final int activityId;
  final String activityTitle;

  const ActivityAttendancesScreen({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  @override
  State<ActivityAttendancesScreen> createState() =>
      _ActivityAttendancesScreenState();
}

class _ActivityAttendancesScreenState extends State<ActivityAttendancesScreen> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendances() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).getActivityAttendance(widget.activityId);
    } catch (e) {
      debugPrint('Error loading attendances: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    
    // FIXED: Convert raw data to Attendance objects if needed
    List<Attendance> attendances = [];
    
    if (attendanceProvider.attendances is List<Attendance>) {
      attendances = attendanceProvider.attendances as List<Attendance>;
    } else if (attendanceProvider.attendances is List<Map<String, dynamic>>) {
      // Convert Map objects to Attendance objects
      attendances = (attendanceProvider.attendances as List<Map<String, dynamic>>)
          .map((data) => Attendance.fromJson(data))
          .toList();
    } else if (attendanceProvider.attendances is List) {
      // Handle mixed list - convert each item
      attendances = attendanceProvider.attendances.map<Attendance>((item) {
        if (item is Attendance) return item;
        if (item is Map<String, dynamic>) return Attendance.fromJson(item);
        // Fallback - create a basic attendance object
        return Attendance(
          id: item['id'] ?? 0,
          activityId: widget.activityId,
          userId: item['user_id'] ?? item['student_id'] ?? 0,
          status: item['status'] ?? 'attended',
          markedAt: DateTime.tryParse(item['marked_at'] ?? '') ?? DateTime.now(),
          studentName: item['student_name'] ?? item['name'] ?? 'Unknown',
        );
      }).toList();
    }

    // Check if user has instructor or coordinator role
    if (user == null ||
        (user.role != 'instructor' &&
            user.role != 'coordinator' &&
            user.role != 'admin')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendances')),
        body: const Center(
          child: Text(
            'Only instructors and coordinators can view attendances.',
          ),
        ),
      );
    }

    // Filter attendances by search query
    final filteredAttendances = attendances.where((attendance) {
      final studentName = attendance.studentDisplayName;
      final nameMatch = studentName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return nameMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          // Stats card
          _buildStatsCard(attendances, filteredAttendances),
          // Attendance list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendances.isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceList(filteredAttendances),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('${widget.activityTitle} Attendances'),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code),
          tooltip: 'Show QR Code',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRCodeDisplayScreen(
                  activityId: widget.activityId,
                  activityTitle: widget.activityTitle,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _loadAttendances,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.indigo,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatsCard(
    List<Attendance> attendances,
    List<Attendance> filteredAttendances,
  ) {
    // Calculate attendance statistics
    int attendedCount = attendances.where((a) => a.isPresent).length;
    int missedCount = attendances.where((a) => a.isMissed).length;
    int excusedCount = attendances.where((a) => a.isExcused).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.people, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Records: ${attendances.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing: ${filteredAttendances.length} result${filteredAttendances.length != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (attendances.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Attended',
                    attendedCount.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Missed',
                    missedCount.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Excused',
                    excusedCount.toString(),
                    Colors.orange,
                    Icons.info,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Icon(
                Icons.people_outline,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No attendance records yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show the QR code to students or manually mark attendance to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRCodeDisplayScreen(
                          activityId: widget.activityId,
                          activityTitle: widget.activityTitle,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Show QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddAttendanceDialog(context);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Mark Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildAttendanceList(List<Attendance> attendances) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: attendances.length,
      itemBuilder: (context, index) {
        final attendance = attendances[index];

        // FIXED: Safe string handling for avatar
        String avatarText = '?';
        final studentName = attendance.studentDisplayName;
        if (studentName.isNotEmpty) {
          avatarText = studentName.substring(0, 1).toUpperCase();
        }

        // Get status color
        Color statusColor = Colors.grey;
        IconData statusIcon = Icons.help;
        
        if (attendance.isPresent) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (attendance.isMissed) {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        } else if (attendance.isExcused) {
          statusColor = Colors.orange;
          statusIcon = Icons.info;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 25,
              child: Text(
                avatarText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              attendance.studentDisplayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Marked: ${dateFormat.format(attendance.checkedInAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${attendance.studentId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      attendance.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12, 
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.info_outline, color: Colors.indigo.shade700),
                onPressed: () {
                  _showAttendanceDetails(context, attendance);
                },
                tooltip: 'View Details',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showAddAttendanceDialog(context);
      },
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add),
      label: const Text('Mark Attendance'),
    );
  }

  void _showAttendanceDetails(BuildContext context, Attendance attendance) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy h:mm a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.indigo.shade700),
            const SizedBox(width: 8),
            const Text('Attendance Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Student:',
              attendance.studentDisplayName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Student ID:', '#${attendance.studentId}'),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Status:',
              attendance.status.toUpperCase(),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Marked at:',
              dateFormat.format(attendance.checkedInAt),
            ),
            if (attendance.studentEmail != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Email:',
                attendance.studentEmail!,
              ),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  void _showAddAttendanceDialog(BuildContext context) {
    final TextEditingController studentIdController = TextEditingController();
    bool isProcessing = false;
    String? errorMessage;
    String selectedStatus = 'attended'; // Default status

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Mark Attendance Manually'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'Enter student ID number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.indigo,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.assignment_turned_in),
                ),
                items: const [
                  DropdownMenuItem(value: 'attended', child: Text('Attended')),
                  DropdownMenuItem(value: 'missed', child: Text('Missed')),
                  DropdownMenuItem(value: 'excused', child: Text('Excused')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (studentIdController.text.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Please enter a student ID';
                        });
                        return;
                      }

                      int? studentId = int.tryParse(
                        studentIdController.text,
                      );
                      if (studentId == null) {
                        setDialogState(() {
                          errorMessage = 'Invalid student ID format';
                        });
                        return;
                      }

                      setDialogState(() {
                        isProcessing = true;
                        errorMessage = null;
                      });

                      try {
                        final success = await Provider.of<AttendanceProvider>(
                          context,
                          listen: false,
                        ).markAttendanceManual(
                          widget.activityId,
                          studentId,
                          status: selectedStatus,
                        );

                        if (mounted) {
                          if (success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Attendance marked as ${selectedStatus.toUpperCase()} successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            final error = Provider.of<AttendanceProvider>(
                              context,
                              listen: false,
                            ).error;
                            setDialogState(() {
                              isProcessing = false;
                              errorMessage = error ?? 'Failed to mark attendance';
                            });
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            isProcessing = false;
                            errorMessage = 'Failed to mark attendance: $e';
                          });
                        }
                        }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isProcessing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Mark Attendance'),
                    ),
                  ],
                ),
          ),
    ).then((_) {
      studentIdController.dispose();
    });
  }
}
