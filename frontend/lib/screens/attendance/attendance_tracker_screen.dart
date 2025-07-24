// lib/screens/attendance/attendance_tracker_screen.dart
import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../../services/instructor_service.dart';

class AttendanceTrackerScreen extends StatefulWidget {
  final Activity activity;

  const AttendanceTrackerScreen({super.key, required this.activity});

  @override
  State<AttendanceTrackerScreen> createState() =>
      _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  final InstructorService _instructorService = InstructorService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _participants = [];
  Map<int, String> _attendanceStatus = {}; // student_id -> status
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final participants = await _instructorService.getActivityParticipants(
        widget.activity.id,
      );
      setState(() {
        _participants = participants;
        // Initialize attendance status - default to 'absent'
        for (final participant in participants) {
          _attendanceStatus[participant['student_id']] =
              participant['attendance_status'] ?? 'absent';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _participants = []; // Set empty list instead of showing error
        _isLoading = false;
      });
      print('Error loading participants: $e'); // Only log to console
    }
  }

  List<Map<String, dynamic>> get _filteredParticipants {
    if (_searchQuery.isEmpty) return _participants;

    return _participants.where((participant) {
      final name =
          '${participant['first_name'] ?? ''} ${participant['last_name'] ?? ''}'
              .toLowerCase();
      final regNumber =
          (participant['registration_number'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || regNumber.contains(query);
    }).toList();
  }

  int get _presentCount {
    return _attendanceStatus.values
        .where((status) => status == 'present')
        .length;
  }

  int get _absentCount {
    return _attendanceStatus.values
        .where((status) => status == 'absent')
        .length;
  }

  int get _excusedCount {
    return _attendanceStatus.values
        .where((status) => status == 'excused')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Attendance',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              widget.activity.title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParticipants,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Activity Info and Stats
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
              children: [
                // Activity Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.activity.isVolunteering
                            ? Icons.volunteer_activism
                            : Icons.event,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDate(widget.activity.startTime)} • ${widget.activity.location}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.activity.isVolunteering)
                              const Text(
                                'Volunteer Activity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Attendance Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Present',
                        _presentCount,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('Absent', _absentCount, Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Excused',
                        _excusedCount,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or registration number...',
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
          // Participants List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                    : _filteredParticipants.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = _filteredParticipants[index];
                        return _buildParticipantCard(participant);
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _markAllPresent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Mark All Present'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('Save Attendance'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
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
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No Participants Found'
                : 'No Participants',
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
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'No students have enrolled in this activity yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    final studentId = participant['student_id'];
    final currentStatus = _attendanceStatus[studentId] ?? 'absent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(currentStatus).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Student Avatar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(currentStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
                color: _getStatusColor(currentStatus),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${participant['first_name'] ?? ''} ${participant['last_name'] ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    participant['registration_number'] ?? 'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (participant['department'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      participant['department'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            // Attendance Status Selector
            PopupMenuButton<String>(
              initialValue: currentStatus,
              onSelected: (String value) {
                setState(() {
                  _attendanceStatus[studentId] = value;
                });
              },
              itemBuilder:
                  (BuildContext context) => [
                    PopupMenuItem(
                      value: 'present',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Present'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'absent',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text('Absent'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excused',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text('Excused'),
                        ],
                      ),
                    ),
                  ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(currentStatus),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(currentStatus),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusLabel(currentStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'excused':
        return Colors.orange;
      case 'absent':
      default:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'excused':
        return Icons.info;
      case 'absent':
      default:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'excused':
        return 'Excused';
      case 'absent':
      default:
        return 'Absent';
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _markAllPresent() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.group, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Mark All Present',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to mark all ${_participants.length} participants as present?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    for (final participant in _participants) {
                      _attendanceStatus[participant['student_id']] = 'present';
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All participants marked as present'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark All'),
              ),
            ],
          ),
    );
  }

  void _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      // Prepare attendance data
      final attendanceData =
          _attendanceStatus.entries
              .map(
                (entry) => {
                  'student_id': entry.key,
                  'status': entry.value,
                  'marked_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      final success = await _instructorService.markAttendance(
        widget.activity.id,
        attendanceData,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Return true to indicate successful attendance marking
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save attendance'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
