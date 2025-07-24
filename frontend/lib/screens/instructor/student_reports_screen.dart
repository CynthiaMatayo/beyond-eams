// lib/screens/instructor/student_reports_screen.dart - FINAL FIX
import 'package:flutter/material.dart';
import '../../services/instructor_service.dart';

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> {
  final InstructorService _instructorService = InstructorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _departments = [
    'All',
    'Computer Science',
    'Information Technology',
    'Business Administration',
    'Engineering',
    'Education',
    'Mathematics',
    'Physics',
    'Chemistry',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _instructorService.getStudentsToTrack();

      // Debug: Print the actual field names returned by backend
      if (students.isNotEmpty) {
        print('✅ Sample student data fields: ${students.first.keys.toList()}');
        print('✅ Sample student: ${students.first}');
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _students = [];
        _isLoading = false;
      });
      print('❌ Error loading students: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load students: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _loadStudents,
          ),
        ),
      );
    }
  }

  // FIXED: Helper functions with better fallbacks
  String _getStudentName(Map<String, dynamic> student) {
    // Try full_name first (computed by backend)
    if (student['full_name'] != null &&
        student['full_name'].toString().trim().isNotEmpty) {
      return student['full_name'].toString().trim();
    }

    // Build from first_name + last_name
    final firstName = student['first_name']?.toString() ?? '';
    final lastName = student['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty && fullName != ' ') {
      return fullName;
    }

    // Fallback to username or email
    return student['username']?.toString() ??
        student['email']?.toString()?.split('@')[0] ??
        'Student ${student['id'] ?? 'Unknown'}';
  }

  String _getRegistrationNumber(Map<String, dynamic> student) {
    // Backend should now provide this
    if (student['registration_number'] != null) {
      return student['registration_number'].toString();
    }

    // Generate if missing
    final id = student['id'];
    if (id != null) {
      return 'REG${id.toString().padLeft(4, '0')}';
    }

    return 'N/A';
  }

  String _getDepartment(Map<String, dynamic> student) {
    // Backend should now provide this
    return student['department']?.toString() ??
        'Computer Science'; // Default department
  }

  String _getJoinDate(Map<String, dynamic> student) {
    // Try different date fields
    final dateField = student['date_joined'] ?? student['created_at'];

    if (dateField != null) {
      try {
        final date = DateTime.parse(dateField);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        // If parsing fails, return as is
        return dateField.toString().split('T')[0]; // Remove time part
      }
    }

    // Generate a reasonable default date
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((student) {
      final studentName = _getStudentName(student).toLowerCase();
      final regNumber = _getRegistrationNumber(student).toLowerCase();
      final department = _getDepartment(student);

      final matchesSearch =
          _searchQuery.isEmpty ||
          studentName.contains(_searchQuery.toLowerCase()) ||
          regNumber.contains(_searchQuery.toLowerCase());

      final matchesDepartment =
          _selectedDepartment == 'All' || department == _selectedDepartment;

      return matchesSearch && matchesDepartment;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Student Reports',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
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
                const SizedBox(height: 16),
                // Department Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _departments.length,
                    itemBuilder: (context, index) {
                      final department = _departments[index];
                      final isSelected = _selectedDepartment == department;

                      // Count students in this department
                      final departmentCount =
                          department == 'All'
                              ? _students.length
                              : _students
                                  .where((s) => _getDepartment(s) == department)
                                  .length;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            department == 'All'
                                ? 'All ($departmentCount)'
                                : department,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedDepartment = department);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.green,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color:
                                isSelected ? Colors.green : Colors.grey[300]!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Students List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                    : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadStudents,
                      color: Colors.green,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return _buildStudentCard(student);
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
            _searchQuery.isNotEmpty || _selectedDepartment != 'All'
                ? 'No Students Found'
                : 'No Students Available',
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
              _searchQuery.isNotEmpty || _selectedDepartment != 'All'
                  ? 'Try adjusting your search or filter criteria'
                  : 'No students are assigned to you yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStudentName(student),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRegistrationNumber(student),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _viewStudentDetails(student),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Student Info
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.email,
                  student['email']?.toString() ?? 'No email',
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.school,
                  _getDepartment(student),
                  Colors.purple,
                ),
                _buildInfoChip(
                  Icons.calendar_today,
                  _getJoinDate(student),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Activities',
                    '${student['total_enrollments'] ?? 0}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'Completed',
                    '${student['completed_activities'] ?? 0}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'Vol. Hours',
                    '${(student['volunteer_hours'] ?? 0).toInt()}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewStudentDetails(student),
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text('View Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactStudent(student),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Contact'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  void _viewStudentDetails(Map<String, dynamic> student) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Colors.green),
          ),
    );

    try {
      final participationData = await _instructorService
          .getStudentParticipation(student['id']);
      if (mounted) {
        Navigator.pop(context);
        _showStudentDetailsModal(student, participationData);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showStudentDetailsModal(student, {
          'total_activities': student['total_enrollments'] ?? 0,
          'completed_activities': student['completed_activities'] ?? 0,
          'volunteer_hours': student['volunteer_hours'] ?? 0.0,
          'participation_rate': student['participation_rate'] ?? 0.0,
          'recent_activities': [],
        });
      }
    }
  }

  void _showStudentDetailsModal(
    Map<String, dynamic> student,
    Map<String, dynamic> participation,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getStudentName(student),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              _getRegistrationNumber(student),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getDepartment(student),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Participation Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Activities',
                                      '${participation['total_activities'] ?? 0}',
                                      Icons.event,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Completed',
                                      '${participation['completed_activities'] ?? 0}',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Volunteer Hours',
                                      '${participation['volunteer_hours'] ?? 0}',
                                      Icons.volunteer_activism,
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Participation Rate',
                                      '${(participation['participation_rate'] ?? 0.0).toStringAsFixed(1)}%',
                                      Icons.trending_up,
                                      Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _contactStudent(Map<String, dynamic> student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Contact feature for ${_getStudentName(student)} coming soon!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
