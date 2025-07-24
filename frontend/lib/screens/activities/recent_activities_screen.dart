// lib/screens/activities/recent_activities_screen.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../models/activity.dart';

class RecentActivitiesScreen extends StatefulWidget {
  const RecentActivitiesScreen({super.key});

  @override
  State<RecentActivitiesScreen> createState() => _RecentActivitiesScreenState();
}

class _RecentActivitiesScreenState extends State<RecentActivitiesScreen> {
  String _selectedFilter = 'All';
  String _selectedTimeRange = '30 days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentActivities();
    });
  }

  Future<void> _loadRecentActivities() async {
    if (!mounted) return;

    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      if (!activityProvider.isInitialized) {
        await activityProvider.ensureProperInitialization();
      } else {
        await activityProvider.loadActivities();
      }
    } catch (e) {
      debugPrint('❌ Error loading recent activities: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load recent activities: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadRecentActivities,
            ),
          ),
        );
      }
    }
  }

  // FIXED: Enhanced recent activities filtering logic
  List<Activity> get _recentActivities {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final activities = activityProvider.activities;
    final now = DateTime.now();

    // Get time range in days
    int daysBack;
    switch (_selectedTimeRange) {
      case '7 days':
        daysBack = 7;
        break;
      case '30 days':
        daysBack = 30;
        break;
      case '90 days':
        daysBack = 90;
        break;
      default:
        daysBack = 30;
    }

    // CRITICAL FIX: Filter activities that have passed their due date/end time
    final recentActivities =
        activities.where((activity) {
          // Determine the actual end time of the activity
          final activityEndTime =
              activity.endTime ??
              activity.startTime.add(const Duration(hours: 2));

          // Check if activity has ended (past due date)
          final hasEnded = activityEndTime.isBefore(now);
          if (!hasEnded) {
            debugPrint(
              '🔍 Activity "${activity.title}" has not ended yet. End time: $activityEndTime, Now: $now',
            );
            return false; // Only show activities that have already ended
          }

          // Check if activity is within the selected time range
          final daysSinceEnd = now.difference(activityEndTime).inDays;
          final isWithinRange = daysSinceEnd >= 0 && daysSinceEnd <= daysBack;

          if (isWithinRange) {
            debugPrint(
              '✅ Including recent activity: "${activity.title}" (ended ${daysSinceEnd} days ago)',
            );
          }

          return isWithinRange;
        }).toList();

    debugPrint(
      '📊 Found ${recentActivities.length} activities that have ended in the last $daysBack days',
    );

    // Apply type filter
    final filteredActivities =
        recentActivities.where((activity) {
          switch (_selectedFilter) {
            case 'Volunteering':
              return activity.isVolunteering;
            case 'Regular':
              return !activity.isVolunteering;
            case 'Enrolled':
              return activity.isEnrolled;
            case 'All':
            default:
              return true;
          }
        }).toList();

    // Sort by end date (most recently ended first)
    filteredActivities.sort((a, b) {
      final aEndTime = a.endTime ?? a.startTime.add(const Duration(hours: 2));
      final bEndTime = b.endTime ?? b.startTime.add(const Duration(hours: 2));
      return bEndTime.compareTo(aEndTime); // Most recently ended first
    });

    debugPrint(
      '📋 Final filtered activities count: ${filteredActivities.length}',
    );
    return filteredActivities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Recent Activities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF5A67D8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () async {
              final activityProvider = Provider.of<ActivityProvider>(
                context,
                listen: false,
              );
              await activityProvider.refresh();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          if (activityProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5A67D8)),
                  SizedBox(height: 16),
                  Text('Loading recent activities...'),
                ],
              ),
            );
          }

          if (activityProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load activities',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      activityProvider.error!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      activityProvider.clearError();
                      _loadRecentActivities();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A67D8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final recentActivities = _recentActivities;

          return RefreshIndicator(
            onRefresh: () async {
              await activityProvider.refresh();
            },
            color: const Color(0xFF5A67D8),
            child: Column(
              children: [
                // ENHANCED: Filter Section with time range
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Activity type filters
                      Text(
                        'Activity Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('All'),
                          _buildFilterChip('Enrolled'),
                          _buildFilterChip('Volunteering'),
                          _buildFilterChip('Regular'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Time range filters
                      Text(
                        'Time Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTimeRangeChip('7 days'),
                          _buildTimeRangeChip('30 days'),
                          _buildTimeRangeChip('90 days'),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${recentActivities.length} activities that ended in the last $_selectedTimeRange',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Activities List
                Expanded(
                  child:
                      recentActivities.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: recentActivities.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final activity = recentActivities[index];
                              return _buildRecentActivityCard(activity);
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: const Color(0xFF5A67D8).withOpacity(0.2),
      checkmarkColor: const Color(0xFF5A67D8),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5A67D8) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  // NEW: Time range filter chips
  Widget _buildTimeRangeChip(String label) {
    final isSelected = _selectedTimeRange == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTimeRange = label;
        });
      },
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  // ENHANCED: Empty state with better messaging
  Widget _buildEmptyState() {
    String message;
    String description;
    IconData icon;

    switch (_selectedFilter) {
      case 'Volunteering':
        icon = Icons.volunteer_activism;
        message = 'No recent volunteer activities';
        description =
            'No volunteer activities have ended in the last $_selectedTimeRange';
        break;
      case 'Regular':
        icon = Icons.event;
        message = 'No recent regular activities';
        description =
            'No regular activities have ended in the last $_selectedTimeRange';
        break;
      case 'Enrolled':
        icon = Icons.event_available;
        message = 'No activities you joined recently';
        description =
            'No activities you were enrolled in have ended in the last $_selectedTimeRange';
        break;
      default:
        icon = Icons.history;
        message = 'No recent activities';
        description =
            'No activities have ended in the last $_selectedTimeRange.\n\nActivities appear here after they finish.';
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
              message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'All';
                      _selectedTimeRange = '90 days';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A67D8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Show All (90 days)'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed:
                      () => Navigator.pushNamed(context, '/browse-activities'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5A67D8)),
                  ),
                  child: const Text(
                    'Browse Activities',
                    style: TextStyle(color: Color(0xFF5A67D8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ENHANCED: Activity card with better status indicators
  Widget _buildRecentActivityCard(Activity activity) {
    final isVolunteering = activity.isVolunteering;
    final isJoined = activity.isEnrolled;
    final activityEndTime =
        activity.endTime ?? activity.startTime.add(const Duration(hours: 2));
    final daysSinceEnd = DateTime.now().difference(activityEndTime).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showActivityDetails(activity),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and badges row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isVolunteering)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'VOLUNTEER',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Time since ended indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTimeSinceEndText(daysSinceEnd),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Location and date row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.location,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.purple[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(activity.startTime),
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status row
              Row(
                children: [
                  if (isJoined) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVolunteering ? 'You Applied' : 'You Participated',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVolunteering
                                ? Icons.volunteer_activism
                                : Icons.group,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVolunteering
                                ? 'Did not apply'
                                : '${activity.enrolledCount} participated',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                activity.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Helper method for time since ended text
  String _getTimeSinceEndText(int daysSinceEnd) {
    if (daysSinceEnd == 0) {
      return 'Ended today';
    } else if (daysSinceEnd == 1) {
      return 'Ended yesterday';
    } else if (daysSinceEnd <= 7) {
      return 'Ended $daysSinceEnd days ago';
    } else if (daysSinceEnd <= 30) {
      final weeks = (daysSinceEnd / 7).floor();
      return 'Ended ${weeks == 1 ? '1 week' : '$weeks weeks'} ago';
    } else {
      final months = (daysSinceEnd / 30).floor();
      return 'Ended ${months == 1 ? '1 month' : '$months months'} ago';
    }
  }

  // ENHANCED: Activity details dialog
  void _showActivityDetails(Activity activity) {
    final activityEndTime =
        activity.endTime ?? activity.startTime.add(const Duration(hours: 2));
    final daysSinceEnd = DateTime.now().difference(activityEndTime).inDays;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(activity.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Location', activity.location),
                  _buildDetailRow(
                    'Started',
                    _formatDateTime(activity.startTime),
                  ),
                  _buildDetailRow('Ended', _formatDateTime(activityEndTime)),
                  _buildDetailRow(
                    'Duration',
                    _formatDuration(activity.startTime, activityEndTime),
                  ),
                  _buildDetailRow('Status', 'Completed'),
                  _buildDetailRow(
                    'Time Since End',
                    _getTimeSinceEndText(daysSinceEnd),
                  ),
                  if (!activity.isVolunteering)
                    _buildDetailRow(
                      'Total Participants',
                      '${activity.enrolledCount}',
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(activity.description),
                  const SizedBox(height: 12),

                  // Status badges
                  if (activity.isVolunteering) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VOLUNTEER OPPORTUNITY',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (activity.isEnrolled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.isVolunteering
                            ? 'YOU APPLIED FOR THIS'
                            : 'YOU PARTICIPATED IN THIS',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    if (difference == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (difference <= 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} ${_formatTime(dateTime)}';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
