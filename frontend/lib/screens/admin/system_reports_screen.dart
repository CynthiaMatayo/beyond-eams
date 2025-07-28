// lib/screens/admin/system_reports_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';
import '../../utils/constants.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _systemStats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _loadSystemReports();
  }

  Future<void> _loadSystemReports() async {
    setState(() => _isLoading = true);
    try {
      print('📊 SYSTEM REPORTS: Starting to load data...');
      final stats = await _adminService.getSystemStats();
      print('📊 SYSTEM REPORTS: Got stats: $stats');
      final activities = await _adminService.getRecentActivities(limit: 10);
      print('📊 SYSTEM REPORTS: Got activities: $activities');
      
      setState(() {
        _systemStats = stats;
        _recentActivities = activities;
        _isLoading = false;
      });
      print('📊 SYSTEM REPORTS: Data loaded successfully');
    } catch (e) {
      print('📊 SYSTEM REPORTS: Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 20),
                  _buildSystemOverview(),
                  const SizedBox(height: 20),
                  _buildUserStatistics(),
                  const SizedBox(height: 20),
                  _buildActivityStatistics(),
                  const SizedBox(height: 20),
                  _buildRecentActivities(),
                  const SizedBox(height: 20),
                  _buildSystemHealth(),
                ],
              ),
            ),
      bottomNavigationBar: const AdminBottomNavBar(
        currentIndex: 2, // Reports tab
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildTimeRangeChip('7d', '7 Days'),
                _buildTimeRangeChip('30d', '30 Days'),
                _buildTimeRangeChip('90d', '90 Days'),
                _buildTimeRangeChip('1y', '1 Year'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label) {
    final isSelected = _selectedTimeRange == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTimeRange = value);
        _loadSystemReports();
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildSystemOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    _systemStats['total_users']?.toString() ?? '0',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Users',
                    _systemStats['active_users']?.toString() ?? '0',
                    Icons.person_outline,
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
                    'Total Activities',
                    _systemStats['total_activities']?.toString() ?? '0',
                    Icons.event,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Activities',
                    _systemStats['active_activities']?.toString() ?? '0',
                    Icons.event_available,
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

  Widget _buildUserStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Students', _systemStats['student_count']?.toString() ?? '0'),
            _buildStatRow('Coordinators', _systemStats['coordinator_count']?.toString() ?? '0'),
            _buildStatRow('Instructors', _systemStats['instructor_count']?.toString() ?? '0'),
            _buildStatRow('Admins', _systemStats['admin_count']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Registrations', _systemStats['total_registrations']?.toString() ?? '0'),
            _buildStatRow('This Month', _systemStats['monthly_registrations']?.toString() ?? '0'),
            _buildStatRow('Completion Rate', '${_systemStats['completion_rate']?.toString() ?? '0'}%'),
            _buildStatRow('Average Rating', '${_systemStats['average_rating']?.toString() ?? '0'}/5'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              const Center(
                child: Text('No recent activities'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (activity['title']?.toString().isNotEmpty == true) 
                            ? activity['title'].toString().substring(0, 1).toUpperCase() 
                            : 'A',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(activity['title']?.toString() ?? 'Unknown Activity'),
                    subtitle: Text(activity['description']?.toString() ?? ''),
                    trailing: Text(
                      activity['created_at']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHealthIndicator('Database', true),
            _buildHealthIndicator('API Services', true),
            _buildHealthIndicator('Email Service', _systemStats['email_service_status'] == 'healthy'),
            _buildHealthIndicator('Storage', true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String service, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: isHealthy ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isHealthy ? 'Healthy' : 'Error',
                style: TextStyle(
                  color: isHealthy ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
