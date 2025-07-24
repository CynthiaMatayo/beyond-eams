// lib/screens/coordinator/activity_reports_screen.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/activity.dart';
import '../../services/coordinator_service.dart';

class ActivityReportsScreen extends StatefulWidget {
  const ActivityReportsScreen({super.key});

  @override
  State<ActivityReportsScreen> createState() => _ActivityReportsScreenState();
}

class _ActivityReportsScreenState extends State<ActivityReportsScreen>
    with SingleTickerProviderStateMixin {
  // Controllers and Services
  late TabController _tabController;
  final CoordinatorService _coordinatorService = CoordinatorService();

  // State Variables
  bool _isLoading = true;
  String _selectedPeriod = 'Last 30 Days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Constants
  static const List<String> _periodOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========== Data Loading Methods ==========
  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    try {
      // FIXED: Call methods properly and handle null responses
      await Future.wait([
        _coordinatorService.getActivityReports(_startDate, _endDate),
        _coordinatorService.getAttendanceReports(_startDate, _endDate),
        _coordinatorService.getEngagementReports(_startDate, _endDate),
        _coordinatorService.getPerformanceReports(_startDate, _endDate),
      ]);
    } catch (e) {
      debugPrint('Error loading reports: $e');
      _showSnackBar('Failed to load reports', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== Date Range Methods ==========
  void _updatePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      switch (period) {
        case 'Last 7 Days':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Last 30 Days':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case 'Last 3 Months':
          _startDate = now.subtract(const Duration(days: 90));
          _endDate = now;
          break;
        case 'Last 6 Months':
          _startDate = now.subtract(const Duration(days: 180));
          _endDate = now;
          break;
        case 'Custom Range':
          _selectDateRange();
          return;
      }
    });
    _loadReportsData();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom Range';
      });
      _loadReportsData();
    }
  }

  // ========== Export and Utils ==========
  Future<void> _exportReports() async {
    try {
      await _coordinatorService.exportReports(_startDate, _endDate);
      _showSnackBar('Reports exported successfully!');
    } catch (e) {
      _showSnackBar('Failed to export reports: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========== Main Build Method ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _DateRangeSelector(
            selectedPeriod: _selectedPeriod,
            periodOptions: _periodOptions,
            startDate: _startDate,
            endDate: _endDate,
            onPeriodChanged: _updatePeriod,
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(
                        coordinatorService: _coordinatorService,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                      _AttendanceTab(
                        coordinatorService: _coordinatorService,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                      _EngagementTab(
                        coordinatorService: _coordinatorService,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                      _PerformanceTab(
                        coordinatorService: _coordinatorService,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Activity Reports',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadReportsData,
          tooltip: 'Refresh Reports',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportReports,
          tooltip: 'Export Reports',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Attendance'),
          Tab(text: 'Engagement'),
          Tab(text: 'Performance'),
        ],
      ),
    );
  }
}

// ========== Date Range Selector Widget ==========
class _DateRangeSelector extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periodOptions;
  final DateTime startDate;
  final DateTime endDate;
  final Function(String) onPeriodChanged;

  const _DateRangeSelector({
    required this.selectedPeriod,
    required this.periodOptions,
    required this.startDate,
    required this.endDate,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedPeriod,
              decoration: InputDecoration(
                labelText: 'Time Period',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: periodOptions.map((period) {
                return DropdownMenuItem(value: period, child: Text(period));
              }).toList(),
              onChanged: (value) {
                if (value != null) onPeriodChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          if (selectedPeriod == 'Custom Range')
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ========== Loading Widget ==========
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: Colors.orange));
  }
}

// ========== Overview Tab ==========
class _OverviewTab extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _OverviewTab({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _OverviewStatsSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _ActivitySummarySection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _RecentActivitiesSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
        ],
      ),
    );
  }
}

// ========== Overview Stats Section ==========
class _OverviewStatsSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _OverviewStatsSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Overview Statistics',
      icon: Icons.dashboard,
      child: FutureBuilder<Map<String, dynamic>>(
        future: coordinatorService.getOverviewStats(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIXED: Proper null handling
          final stats = snapshot.data ?? {
            'totalActivities': 0,
            'totalParticipants': 0,
            'avgAttendance': 0,
            'completionRate': 0,
          };

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Activities',
                      value: '${stats['totalActivities'] ?? 0}',
                      icon: Icons.event,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Participants',
                      value: '${stats['totalParticipants'] ?? 0}',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Avg Attendance',
                      value: '${stats['avgAttendance'] ?? 0}%',
                      icon: Icons.check_circle,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Completion Rate',
                      value: '${stats['completionRate'] ?? 0}%',
                      icon: Icons.task_alt,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ========== Activity Summary Section ==========
class _ActivitySummarySection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _ActivitySummarySection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Activity Breakdown',
      icon: Icons.pie_chart,
      child: FutureBuilder<Map<String, dynamic>>(
        future: coordinatorService.getActivitySummary(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          // FIXED: Proper null handling and type casting
          final summary = snapshot.data ?? {};
          final byCategory = Map<String, dynamic>.from(summary['byCategory'] ?? {});
          final byStatus = Map<String, dynamic>.from(summary['byStatus'] ?? {});
          final byType = Map<String, dynamic>.from(summary['byType'] ?? {});

          return Column(
            children: [
              _BreakdownSection(
                title: 'By Category',
                data: byCategory,
              ),
              const SizedBox(height: 16),
              _BreakdownSection(title: 'By Status', data: byStatus),
              const SizedBox(height: 16),
              _BreakdownSection(title: 'By Type', data: byType),
            ],
          );
        },
      ),
    );
  }
}

// ========== Recent Activities Section ==========
class _RecentActivitiesSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _RecentActivitiesSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Recent Activities',
      icon: Icons.history,
      child: FutureBuilder<List<Activity>>(
        future: coordinatorService.getRecentActivities(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data ?? [];
          if (activities.isEmpty) {
            return const _EmptyState(message: 'No activities in this period');
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _ActivityListItem(activity: activities[index]);
            },
          );
        },
      ),
    );
  }
}

// ========== Attendance Tab ==========
class _AttendanceTab extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _AttendanceTab({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _AttendanceOverviewSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _AttendanceTrendsSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _AttendanceByActivitySection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
        ],
      ),
    );
  }
}

// ========== Engagement Tab ==========
class _EngagementTab extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _EngagementTab({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _EngagementMetricsSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _ParticipationTrendsSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _EngagementByCategorySection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
        ],
      ),
    );
  }
}

// ========== Performance Tab ==========
class _PerformanceTab extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _PerformanceTab({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PerformanceMetricsSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _TopPerformersSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: 16),
          _ImprovementAreasSection(
            coordinatorService: coordinatorService,
            startDate: startDate,
            endDate: endDate,
          ),
        ],
      ),
    );
  }
}

// ========== Reusable Components ==========
class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // FIXED: Use withOpacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // FIXED: Use withOpacity
        borderRadius: BorderRadius.circular(8),
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
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const _BreakdownSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('No data available', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    // FIXED: Safe type conversion
    final total = data.values.fold<double>(
      0.0,
      (sum, value) {
        if (value is int) return sum + value.toDouble();
        if (value is double) return sum + value;
        return sum;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...data.entries.map((entry) {
          final valueDouble = entry.value is int ? (entry.value as int).toDouble() : (entry.value as double? ?? 0.0);
          final percentage = total > 0 ? (valueDouble / total) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final Activity activity;

  const _ActivityListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.isVolunteering
                  ? Colors.purple.withOpacity(0.1) // FIXED: Use withOpacity
                  : Colors.orange.withOpacity(0.1), // FIXED: Use withOpacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.isVolunteering ? Icons.volunteer_activism : Icons.event,
              color: activity.isVolunteering ? Colors.purple : Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDateTime(activity.startTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${activity.enrolledCount ?? 0}', // FIXED: Add null safety
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Text(
                'participants',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

// ========== Attendance Sections (Simplified placeholders) ==========
class _AttendanceOverviewSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _AttendanceOverviewSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Attendance Overview',
      icon: Icons.people_alt,
      child: FutureBuilder<Map<String, dynamic>>(
        future: coordinatorService.getAttendanceOverview(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIXED: Proper null handling
          final overview = snapshot.data ?? {
            'totalSessions': 0,
            'averageAttendance': 0,
            'highestAttendance': 0,
            'lowestAttendance': 0,
          };

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Sessions',
                      value: '${overview['totalSessions'] ?? 0}',
                      icon: Icons.event_available,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Avg Attendance',
                      value: '${overview['averageAttendance'] ?? 0}%',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Highest Rate',
                      value: '${overview['highestAttendance'] ?? 0}%',
                      icon: Icons.star,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Lowest Rate',
                      value: '${overview['lowestAttendance'] ?? 0}%',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceTrendsSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _AttendanceTrendsSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Attendance Trends',
      icon: Icons.timeline,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: coordinatorService.getAttendanceTrends(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trends = snapshot.data ?? [];
          if (trends.isEmpty) {
            return const _EmptyState(message: 'No trend data available');
          }

          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Attendance chart would be displayed here',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
    }
}

class _AttendanceByActivitySection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _AttendanceByActivitySection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Attendance by Activity',
      icon: Icons.bar_chart,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: coordinatorService.getAttendanceByActivity(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceData = snapshot.data ?? [];
          if (attendanceData.isEmpty) {
            return const _EmptyState(message: 'No attendance data available');
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendanceData.length,
            itemBuilder: (context, index) {
              final data = attendanceData[index];
              return _AttendanceItem(
                title: data['activityTitle']?.toString() ?? 'Unknown Activity',
                rate: (data['attendanceRate'] as num?)?.toInt() ?? 0,
                total: (data['totalParticipants'] as num?)?.toInt() ?? 0,
                attended: (data['attendedCount'] as num?)?.toInt() ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}

// ========== Engagement Sections ==========
class _EngagementMetricsSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _EngagementMetricsSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Engagement Metrics',
      icon: Icons.insights,
      child: FutureBuilder<Map<String, dynamic>>(
        future: coordinatorService.getEngagementMetrics(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIXED: Proper null handling with safe type conversion
          final metrics = snapshot.data ?? {};
          final enrollmentRate =
              (metrics['enrollmentRate'] as num?)?.toInt() ?? 0;
          final retentionRate =
              (metrics['retentionRate'] as num?)?.toInt() ?? 0;
          final feedbackScore =
              (metrics['feedbackScore'] as num?)?.toDouble() ?? 0.0;
          final recommendationRate =
              (metrics['recommendationRate'] as num?)?.toInt() ?? 0;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Enrollment Rate',
                      value: '$enrollmentRate%',
                      icon: Icons.person_add,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Retention Rate',
                      value: '$retentionRate%',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Feedback Score',
                      value: '${feedbackScore.toStringAsFixed(1)}/5',
                      icon: Icons.star,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Recommendation',
                      value: '$recommendationRate%',
                      icon: Icons.thumb_up,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticipationTrendsSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _ParticipationTrendsSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Participation Trends',
      icon: Icons.trending_up,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: coordinatorService.getParticipationTrends(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trends = snapshot.data ?? [];
          if (trends.isEmpty) {
            return const _EmptyState(
              message: 'No participation data available',
            );
          }

          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Participation trend chart would be displayed here',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EngagementByCategorySection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _EngagementByCategorySection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Engagement by Category',
      icon: Icons.category,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: coordinatorService.getEngagementByCategory(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoryData = snapshot.data ?? [];
          if (categoryData.isEmpty) {
            return const _EmptyState(message: 'No category data available');
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryData.length,
            itemBuilder: (context, index) {
              final data = categoryData[index];
              return _CategoryEngagementItem(
                category: data['category']?.toString() ?? 'Unknown',
                score: (data['engagementScore'] as num?)?.toInt() ?? 0,
                activities: (data['totalActivities'] as num?)?.toInt() ?? 0,
                avgParticipants:
                    (data['averageParticipants'] as num?)?.toInt() ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}

// ========== Performance Sections ==========
class _PerformanceMetricsSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _PerformanceMetricsSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Performance Metrics',
      icon: Icons.assessment,
      child: FutureBuilder<Map<String, dynamic>>(
        future: coordinatorService.getPerformanceMetrics(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // FIXED: Proper null handling with safe type conversion
          final metrics = snapshot.data ?? {};
          final successRate = (metrics['successRate'] as num?)?.toInt() ?? 0;
          final qualityScore =
              (metrics['qualityScore'] as num?)?.toDouble() ?? 0.0;
          final efficiencyRating =
              (metrics['efficiencyRating'] as num?)?.toDouble() ?? 0.0;
          final impactScore =
              (metrics['impactScore'] as num?)?.toDouble() ?? 0.0;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Success Rate',
                      value: '$successRate%',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Quality Score',
                      value: '${qualityScore.toStringAsFixed(1)}/10',
                      icon: Icons.star_rate,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Efficiency',
                      value: '${efficiencyRating.toStringAsFixed(1)}/10',
                      icon: Icons.speed,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Impact Score',
                      value: '${impactScore.toStringAsFixed(1)}/10',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopPerformersSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _TopPerformersSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Top Performing Activities',
      icon: Icons.emoji_events,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: coordinatorService.getTopPerformingActivities(
          startDate,
          endDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final topActivities = snapshot.data ?? [];
          if (topActivities.isEmpty) {
            return const _EmptyState(message: 'No performance data available');
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topActivities.length,
            itemBuilder: (context, index) {
              final activity = topActivities[index];
              return _PerformerItem(
                rank: index + 1,
                title: activity['title']?.toString() ?? 'Unknown Activity',
                score: (activity['score'] as num?)?.toInt() ?? 0,
                participants: (activity['participants'] as num?)?.toInt() ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}

class _ImprovementAreasSection extends StatelessWidget {
  final CoordinatorService coordinatorService;
  final DateTime startDate;
  final DateTime endDate;

  const _ImprovementAreasSection({
    required this.coordinatorService,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Areas for Improvement',
      icon: Icons.trending_down,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: coordinatorService.getImprovementAreas(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final improvements = snapshot.data ?? [];
          if (improvements.isEmpty) {
            return const _EmptyState(
              message: 'No improvement suggestions available',
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: improvements.length,
            itemBuilder: (context, index) {
              final item = improvements[index];
              return _ImprovementItem(
                area: item['area']?.toString() ?? 'Unknown Area',
                suggestion:
                    item['suggestion']?.toString() ?? 'No suggestion available',
                priority: item['priority']?.toString() ?? 'Medium',
              );
            },
          );
        },
      ),
    );
  }
}

// ========== Detailed Item Widgets ==========
class _AttendanceItem extends StatelessWidget {
  final String title;
  final int rate;
  final int total;
  final int attended;

  const _AttendanceItem({
    required this.title,
    required this.rate,
    required this.total,
    required this.attended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$rate%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      rate >= 80
                          ? Colors.green
                          : rate >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              rate >= 80
                  ? Colors.green
                  : rate >= 60
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$attended of $total participants attended',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CategoryEngagementItem extends StatelessWidget {
  final String category;
  final int score;
  final int activities;
  final int avgParticipants;

  const _CategoryEngagementItem({
    required this.category,
    required this.score,
    required this.activities,
    required this.avgParticipants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(
                    score,
                  ).withOpacity(0.1), // FIXED: Use withOpacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(score),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$activities activities',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              Text(
                '$avgParticipants avg participants',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _PerformerItem extends StatelessWidget {
  final int rank;
  final String title;
  final int score;
  final int participants;

  const _PerformerItem({
    required this.rank,
    required this.title,
    required this.score,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple];
    final color = colors[(rank - 1) % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$participants participants',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // FIXED: Use withOpacity
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImprovementItem extends StatelessWidget {
  final String area;
  final String suggestion;
  final String priority;

  const _ImprovementItem({
    required this.area,
    required this.suggestion,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor =
        priority.toLowerCase() == 'high'
            ? Colors.red
            : priority.toLowerCase() == 'medium'
            ? Colors.orange
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  area,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(
                    0.1,
                  ), // FIXED: Use withOpacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
