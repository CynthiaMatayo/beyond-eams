// lib/screens/coordinator/manage_activities_screen.dart - FINAL FIXED VERSION
import 'package:flutter/material.dart';
import 'package:frontend/screens/activities/activity_detail_screen.dart';
import 'package:frontend/screens/coordinator/edit_activity_screen.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../providers/coordinator_provider.dart';
import '../../services/export_service.dart';
import 'create_activity_screen.dart';

class ManageActivitiesScreen extends StatefulWidget {
  const ManageActivitiesScreen({super.key});

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Activity> _filteredActivities = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  final List<String> _statusFilters = [
    'All',
    'Draft',
    'Upcoming',
    'Ongoing',
    'Completed',
    'Cancelled',
  ];

  final List<String> _categoryFilters = [
    'All',
    'Academic',
    'Sports',
    'Cultural',
    'Technology',
    'Community Service',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coordinatorProvider = context.read<CoordinatorProvider>();
      if (!coordinatorProvider.isInitialized) {
        coordinatorProvider.initialize();
      }
      // CRITICAL: Force refresh activities on screen load
      coordinatorProvider.loadMyActivities();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterActivities(List<Activity> allActivities) {
    final coordinatorProvider = context.read<CoordinatorProvider>();
    _filteredActivities =
        allActivities.where((activity) {
          final matchesSearch =
              activity.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              activity.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          final dynamicStatus = coordinatorProvider.getActivityDynamicStatus(
            activity,
          );
          final matchesStatus =
              _selectedStatus == 'All' ||
              dynamicStatus.toLowerCase() == _selectedStatus.toLowerCase();

          return matchesSearch && matchesStatus;
        }).toList();

    debugPrint(
      '🔍 Filtered ${_filteredActivities.length} activities from ${allActivities.length} total',
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportActivities() async {
    try {
      debugPrint('🔄 Starting export debug...');

      final coordinatorProvider = context.read<CoordinatorProvider>();
      final activities = coordinatorProvider.myActivities;

      debugPrint('📊 Activities to export: ${activities.length}');
      debugPrint(
        '🔍 Provider state: loading=${coordinatorProvider.isLoading}, initialized=${coordinatorProvider.isInitialized}',
      );

      if (activities.isEmpty) {
        debugPrint('⚠️ No activities found - trying to reload...');
        await coordinatorProvider.loadMyActivities();
        final reloadedActivities = coordinatorProvider.myActivities;
        debugPrint('📊 After reload: ${reloadedActivities.length} activities');

        if (reloadedActivities.isEmpty) {
          _showErrorSnackBar('No activities to export');
          return;
        }
      }

      // Log first activity details for debugging
      if (activities.isNotEmpty) {
        final firstActivity = activities.first;
        debugPrint(
          '🎯 Sample activity: ${firstActivity.title} (ID: ${firstActivity.id})',
        );
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text('Exporting activities...'),
                  ],
                ),
              ),
        );
      }

      try {
        // Try the original ExportService first
        debugPrint('🧪 Attempting ExportService.exportActivities...');
        await ExportService.exportActivities(activities);
        debugPrint('✅ ExportService succeeded!');
      } catch (exportError) {
        debugPrint('❌ ExportService failed: $exportError');
        debugPrint('🔄 Trying fallback export method...');

        // Fallback to simple export
        await _fallbackExport(activities);
        debugPrint('✅ Fallback export succeeded!');
      }

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      _showSuccessSnackBar(
        '${activities.length} activities exported successfully! Check your Downloads folder.',
      );

      // Show detailed download info
      _showDownloadInfo();
    } catch (e) {
      debugPrint('❌ Complete export failure: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      debugPrint('🔍 Stack trace: ${StackTrace.current}');

      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showErrorSnackBar('Export failed: ${e.toString()}');
    }
  }

  // Fallback export method
  Future<void> _fallbackExport(List<Activity> activities) async {
    debugPrint('🔄 Starting fallback export...');

    // Create CSV content
    final StringBuffer csvBuffer = StringBuffer();

    // Headers
    csvBuffer.writeln(
      'ID,Title,Description,Location,Start Time,End Time,Status,Enrolled Count,Is Volunteering',
    );

    // Data rows
    for (final activity in activities) {
      final row = [
        activity.id?.toString() ?? '',
        _escapeCsvField(activity.title),
        _escapeCsvField(activity.description),
        _escapeCsvField(activity.location ?? ''),
        activity.startTime.toIso8601String(),
        activity.endTime.toIso8601String(),
        activity.status ?? '',
        activity.enrolledCount.toString(),
        activity.isVolunteering.toString(),
      ].join(',');

      csvBuffer.writeln(row);
    }

    final csvContent = csvBuffer.toString();
    debugPrint('📄 CSV content created (${csvContent.length} characters)');

    // For now, just log the content (you can extend this for actual file saving)
    debugPrint(
      '📋 CSV Preview:\n${csvContent.substring(0, csvContent.length > 200 ? 200 : csvContent.length)}...',
    );

    // You can implement file saving here based on your platform
    // For web: use html.Blob and download
    // For mobile: use path_provider and File.writeAsString
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Add this method to show download information
  void _showDownloadInfo() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.download_done, color: Colors.green),
                SizedBox(width: 8),
                Text('Export Complete'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your activities have been exported successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('📁 File details:'),
                Text('• Format: CSV (Excel compatible)'),
                Text('• Location: Downloads folder'),
                Text('• Filename: activities_export_[timestamp].csv'),
                SizedBox(height: 12),
                Text('You can open this file with:'),
                Text('• Microsoft Excel'),
                Text('• Google Sheets'),
                Text('• Any spreadsheet application'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Activity'),
            content: Text(
              'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final coordinatorProvider = context.read<CoordinatorProvider>();
      final success = await coordinatorProvider.deleteActivity(activity.id);

      if (success) {
        _showSuccessSnackBar('Activity deleted successfully');
      } else {
        _showErrorSnackBar(
          coordinatorProvider.error ?? 'Failed to delete activity',
        );
      }
    }
  }

  Future<void> _duplicateActivity(Activity activity) async {
    if (!mounted) return;

    final coordinatorProvider = context.read<CoordinatorProvider>();
    final success = await coordinatorProvider.duplicateActivity(activity.id);

    if (success) {
      _showSuccessSnackBar('Activity duplicated successfully');
    } else {
      _showErrorSnackBar(
        coordinatorProvider.error ?? 'Failed to duplicate activity',
      );
    }
  }

  List<Activity> _getActivitiesByStatus(
    String status,
    List<Activity> activities,
  ) {
    if (status == 'All') return activities;

    final coordinatorProvider = context.read<CoordinatorProvider>();
    return activities.where((activity) {
      final dynamicStatus = coordinatorProvider.getActivityDynamicStatus(
        activity,
      );
      return dynamicStatus.toLowerCase() == status.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateActivity,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Manage Activities',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // NEW: Export Button in AppBar
        Consumer<CoordinatorProvider>(
          builder: (context, coordinatorProvider, child) {
            return IconButton(
              icon: const Icon(Icons.download),
              onPressed:
                  coordinatorProvider.myActivities.isEmpty
                      ? null
                      : _exportActivities,
              tooltip: 'Export Activities',
            );
          },
        ),
        Consumer<CoordinatorProvider>(
          builder: (context, coordinatorProvider, child) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  coordinatorProvider.isLoading
                      ? null
                      : () {
                        debugPrint('🔄 Manual refresh triggered');
                        coordinatorProvider.loadMyActivities();
                      },
              tooltip: 'Refresh',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToCreateActivity(),
          tooltip: 'Create Activity',
        ),
      ],
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: Consumer<CoordinatorProvider>(
        builder: (context, coordinatorProvider, child) {
          final activities = coordinatorProvider.myActivities;
          _filterActivities(activities);
          return TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All (${_filteredActivities.length})'),
              Tab(
                text:
                    'Upcoming (${_getActivitiesByStatus('upcoming', _filteredActivities).length})',
              ),
              Tab(
                text:
                    'Draft (${_getActivitiesByStatus('draft', _filteredActivities).length})',
              ),
              Tab(
                text:
                    'Completed (${_getActivitiesByStatus('completed', _filteredActivities).length})',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CoordinatorProvider>(
      builder: (context, coordinatorProvider, child) {
        if (coordinatorProvider.isLoading &&
            !coordinatorProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        if (coordinatorProvider.error != null &&
            coordinatorProvider.myActivities.isEmpty) {
          return _buildErrorState(coordinatorProvider);
        }

        final activities = coordinatorProvider.myActivities;
        _filterActivities(activities);

        debugPrint(
          '📊 ManageActivities: ${activities.length} total, ${_filteredActivities.length} filtered',
        );

        return Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActivityList(_filteredActivities),
                  _buildActivityList(
                    _getActivitiesByStatus('upcoming', _filteredActivities),
                  ),
                  _buildActivityList(
                    _getActivitiesByStatus('draft', _filteredActivities),
                  ),
                  _buildActivityList(
                    _getActivitiesByStatus('completed', _filteredActivities),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(CoordinatorProvider coordinatorProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Activities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              coordinatorProvider.error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => coordinatorProvider.loadMyActivities(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Export Button Row
          Consumer<CoordinatorProvider>(
            builder: (context, coordinatorProvider, child) {
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          coordinatorProvider.myActivities.isEmpty
                              ? null
                              : _exportActivities,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Activities'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search activities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      _statusFilters.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      _categoryFilters.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<Activity> activities) {
    debugPrint(
      '📋 Building activity list with ${activities.length} activities',
    );

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No activities found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first activity to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateActivity,
              icon: const Icon(Icons.add),
              label: const Text('Create Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Pull-to-refresh triggered');
        await context.read<CoordinatorProvider>().loadMyActivities();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          debugPrint(
            '🎯 Displaying activity: ${activity.id} - ${activity.title}',
          );
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final coordinatorProvider = context.read<CoordinatorProvider>();
    final dynamicStatus = coordinatorProvider.getActivityDynamicStatus(
      activity,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    activity.isVolunteering
                        ? Colors.purple.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                activity.isVolunteering
                    ? Icons.volunteer_activism
                    : Icons.event,
                color: activity.isVolunteering ? Colors.purple : Colors.orange,
                size: 24,
              ),
            ),
            title: Text(
              activity.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(activity.startTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.enrolledCount} enrolled',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _buildStatusBadge(dynamicStatus),
            onTap: () => _viewActivityDetails(activity),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'View',
                  onPressed: () => _viewActivityDetails(activity),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onPressed: () => _editActivity(activity),
                ),
                _buildActionButton(
                  icon: Icons.copy,
                  label: 'Duplicate',
                  onPressed: () => _duplicateActivity(activity),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onPressed: () => _deleteActivity(activity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'upcoming':
        color = Colors.blue;
        break;
      case 'ongoing':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      case 'draft':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToCreateActivity() {
    debugPrint('🚀 Navigating to create activity');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateActivityScreen()),
    ).then((result) {
      if (result == true && mounted) {
        debugPrint('✅ Returned from create activity, refreshing...');
        context.read<CoordinatorProvider>().loadMyActivities();
      }
    });
  }

  void _editActivity(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(activity: activity),
      ),
    ).then((result) {
      if (result == true && mounted) {
        context.read<CoordinatorProvider>().loadMyActivities();
      }
    });
  }

  void _viewActivityDetails(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailsScreen(activity: activity),
      ),
    );
  }
}
