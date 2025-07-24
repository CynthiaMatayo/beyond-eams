// lib/screens/admin/system_reports_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final data = await _adminService.getSystemAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData(String dataType) async {
    try {
      final downloadUrl = await _adminService.exportData(
        dataType: dataType,
        startDate: _startDate,
        endDate: _endDate,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export ready: $downloadUrl')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString()}')));
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAnalytics,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Filter
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _startDate != null && _endDate != null
                                    ? 'From ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}'
                                    : 'All Time Data',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _selectDateRange,
                              child: const Text('Change Range'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Overview Stats
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOverviewSection(),

                    const SizedBox(height: 24),

                    // User Analytics
                    const Text(
                      'User Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildUserAnalyticsSection(),

                    const SizedBox(height: 24),

                    // Activity Analytics
                    const Text(
                      'Activity Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildActivityAnalyticsSection(),

                    const SizedBox(height: 24),

                    // Export Section
                    const Text(
                      'Data Export',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildExportSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildOverviewSection() {
    final data = _analyticsData?['overview'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    '${data['total_users'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Activities',
                    '${data['total_activities'] ?? 0}',
                    Icons.event,
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
                    'Active Sessions',
                    '${data['active_sessions'] ?? 0}',
                    Icons.wifi,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'System Uptime',
                    '${data['uptime'] ?? "99.9%"}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnalyticsSection() {
    final data = _analyticsData?['users'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Distribution by Role',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...['student', 'instructor', 'coordinator', 'admin'].map((role) {
              final count = data['by_role']?[role] ?? 0;
              final percentage =
                  data['total_users'] != null && data['total_users'] > 0
                      ? (count / data['total_users'] * 100).toStringAsFixed(1)
                      : '0.0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getRoleColor(role),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(role.toUpperCase())),
                    Text('$count ($percentage%)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityAnalyticsSection() {
    final data = _analyticsData?['activities'] ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Statistics',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildDataRow('Upcoming Activities', '${data['upcoming'] ?? 0}'),
            _buildDataRow('Ongoing Activities', '${data['ongoing'] ?? 0}'),
            _buildDataRow('Completed Activities', '${data['completed'] ?? 0}'),
            _buildDataRow(
              'Total Enrollments',
              '${data['total_enrollments'] ?? 0}',
            ),
            _buildDataRow(
              'Average Enrollment Rate',
              '${data['avg_enrollment_rate'] ?? 0}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildExportButton('Users', 'users', Icons.people),
                _buildExportButton('Activities', 'activities', Icons.event),
                _buildExportButton(
                  'Enrollments',
                  'enrollments',
                  Icons.assignment,
                ),
                _buildExportButton('Analytics', 'analytics', Icons.analytics),
              ],
            ),
          ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, String dataType, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _exportData(dataType),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'coordinator':
        return Colors.purple;
      case 'instructor':
        return Colors.green;
      case 'student':
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
