// lib/screens/activities/browse_activities_screen.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/volunteer_application_dialog.dart';
import '../../providers/activity_provider.dart';
import '../../providers/volunteer_provider.dart';
import '../../models/activity.dart';

class BrowseActivitiesScreen extends StatefulWidget {
  const BrowseActivitiesScreen({super.key});

  @override
  State<BrowseActivitiesScreen> createState() => _BrowseActivitiesScreenState();
}

class _BrowseActivitiesScreenState extends State<BrowseActivitiesScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  // FIXED: Enhanced provider initialization
  Future<void> _initializeProvider() async {
    if (!mounted) return;

    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );

      debugPrint('🚀 BrowseScreen: Ensuring provider initialization...');

      // CRITICAL: Always ensure proper initialization
      await activityProvider.ensureProperInitialization();

      // Force state synchronization
      debugPrint(
        '🔄 BrowseScreen: Provider initialized, enrolled count: ${activityProvider.enrolledActivitiesCount}',
      );
    } catch (e) {
      debugPrint('❌ Error initializing provider: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load activities: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeProvider,
            ),
          ),
        );
      }
    }
  }

  List<Activity> get _filteredActivities {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final activities = activityProvider.activities;

    return activities.where((activity) {
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Volunteering' && activity.isVolunteering) ||
          (_selectedFilter == 'Regular' && !activity.isVolunteering);

      final matchesSearch =
          _searchQuery.isEmpty ||
          activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          activity.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return matchesFilter && matchesSearch;
    }).toList();
  }

  // FIXED: Helper method to check if user has applied for volunteer activity
  bool _hasAppliedForVolunteerActivity(
    VolunteerProvider volunteerProvider,
    Activity activity,
  ) {
    try {
      return volunteerProvider.myApplications.any(
        (application) => application.activityId == activity.id,
      );
    } catch (e) {
      debugPrint('❌ Error checking volunteer application status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Browse Activities',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
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
                  Text('Loading activities...'),
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
                      _initializeProvider();
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

          final filteredActivities = _filteredActivities;

          return RefreshIndicator(
            onRefresh: () async {
              await activityProvider.refresh();
            },
            color: const Color(0xFF5A67D8),
            child: Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search activities...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Filter Chips
                      Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Volunteering'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Regular'),
                          const Spacer(),
                          Text(
                            '${filteredActivities.length} activities',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
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
                      filteredActivities.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredActivities.length,
                            itemBuilder: (context, index) {
                              final activity = filteredActivities[index];
                              return _buildActivityCard(
                                activity,
                                activityProvider,
                              );
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No activities found'
                : 'No activities available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filter criteria'
                : 'Check back later for new activities',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // FIXED: Enhanced activity card with proper state management
  Widget _buildActivityCard(
    Activity activity,
    ActivityProvider activityProvider,
  ) {
    // CRITICAL: Always get the current state from the provider
    final currentActivity =
        activityProvider.activities
            .where((a) => a.id == activity.id)
            .firstOrNull ??
        activity;

    final isVolunteering = currentActivity.isVolunteering;
    final enrollmentCount = currentActivity.enrolledCount;

    // CRITICAL: Use provider method to check enrollment status
    final isJoined = activityProvider.isEnrolledInActivity(currentActivity.id);

    debugPrint(
      '🔍 Building card for activity ${currentActivity.id}: isJoined=$isJoined',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showActivityDetails(currentActivity),
        child: Row(
          children: [
            // Colored left strip - changes color based on status
            Container(
              width: 4,
              height: 140,
              decoration: BoxDecoration(
                color:
                    isVolunteering
                        ? Colors.orange
                        : (isJoined ? Colors.green : Colors.indigo),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and badges row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentActivity.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (isVolunteering)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'VOLUNTEER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isJoined && !isVolunteering) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'JOINED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location and Date Row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentActivity.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(currentActivity.startTime),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Status row (enrollment count or volunteer status)
                    if (!isVolunteering)
                      Row(
                        children: [
                          Icon(Icons.group, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '$enrollmentCount enrolled',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      Consumer<VolunteerProvider>(
                        builder: (context, volunteerProvider, child) {
                          bool hasApplied = _hasAppliedForVolunteerActivity(
                            volunteerProvider,
                            currentActivity,
                          );
                          return Row(
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasApplied
                                    ? 'Application submitted'
                                    : 'Volunteer opportunity',
                                style: TextStyle(
                                  color:
                                      hasApplied
                                          ? Colors.green[600]
                                          : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight:
                                      hasApplied
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      currentActivity.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                () => _showActivityDetails(currentActivity),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            currentActivity,
                            activityProvider,
                            isJoined,
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
    );
  }

  // NEW: Separate action button builder for cleaner code and better state management
  Widget _buildActionButton(
    Activity activity,
    ActivityProvider activityProvider,
    bool isJoined,
  ) {
    if (!activity.isVolunteering) {
      // Regular activity button
      return isJoined
          ? Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Joined',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          : ElevatedButton(
            onPressed:
                activityProvider.isLoading
                    ? null
                    : () => _handleJoinActivity(activity, activityProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
            ),
            child:
                activityProvider.isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Join',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          );
    } else {
      // Volunteer activity button
      return Consumer<VolunteerProvider>(
        builder: (context, volunteerProvider, child) {
          bool hasApplied = _hasAppliedForVolunteerActivity(
            volunteerProvider,
            activity,
          );
          return hasApplied
              ? Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Applied',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : ElevatedButton(
                onPressed:
                    volunteerProvider.isLoading
                        ? null
                        : () => _handleJoinActivity(activity, activityProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                ),
                child:
                    volunteerProvider.isLoading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              );
        },
      );
    }
  }

  // FIXED: Handle volunteer activities with proper state tracking
  Future<void> _handleJoinActivity(
    Activity activity,
    ActivityProvider activityProvider,
  ) async {
    if (activity.isVolunteering) {
      // For volunteer activities, track application state
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );

      // Check if already applied
      bool alreadyApplied = _hasAppliedForVolunteerActivity(
        volunteerProvider,
        activity,
      );
      if (alreadyApplied) {
        _showSnackBar(
          'You have already applied for this volunteer opportunity',
          isSuccess: false,
        );
        return;
      }

      // Show the volunteer application dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
builder:
            (context) => VolunteerApplicationDialog(
              activityTitle: activity.title,
              activityDescription: activity.description,
              activityDateTime: activity.startTime,
              activityLocation: activity.location, 
              activityDurationHours:
                  2, 
              onSubmit: () async {
                try {
                  bool success = await volunteerProvider
                      .applyForVolunteerPosition(activity.id, activity.title);
                  if (success) {
                    _showSnackBar(
                      'Volunteer application submitted successfully!',
                      isSuccess: true,
                    );
                    // Force UI rebuild to show updated button state
                    setState(() {});
                  } else {
                    _showSnackBar(
                      'Failed to submit application: ${volunteerProvider.error ?? "Unknown error"}',
                      isSuccess: false,
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Error applying for volunteer position: $e');
                  _showSnackBar(
                    'Failed to submit volunteer application',
                    isSuccess: false,
                  );
                }
              },
            ),
      );
    } else {
      // Direct enrollment for regular activities
      await _joinActivity(activity, activityProvider);
    }
  }

  // FIXED: Join regular activities with better feedback
  Future<void> _joinActivity(
    Activity activity,
    ActivityProvider activityProvider,
  ) async {
    try {
      debugPrint('🔄 Starting enrollment for activity: ${activity.title}');
      bool success = await activityProvider.enrollInActivity(activity.id);

      if (mounted) {
        if (success) {
          _showSnackBar(
            'Successfully joined ${activity.title}!',
            isSuccess: true,
          );
          debugPrint('✅ Successfully enrolled in activity: ${activity.title}');
        } else {
          // Show the actual error from the provider
          String errorMessage = activityProvider.error ?? "Unknown error";
          // Clean up the error message for better user experience
          if (errorMessage.contains('Already enrolled')) {
            errorMessage = 'You are already enrolled in this activity';
          } else if (errorMessage.contains('Cannot enroll in past activity')) {
            errorMessage = 'This activity has already taken place';
          } else if (errorMessage.contains('Server sync failed')) {
            errorMessage =
                'Joined successfully! Will sync when server is available.';
          }
          _showSnackBar(errorMessage, isSuccess: false);
          debugPrint('❌ Failed to enroll in activity: ${activity.title}');
        }
      }
    } catch (e) {
      debugPrint('❌ Exception during enrollment: $e');
      if (mounted) {
        _showSnackBar(
          'Failed to join ${activity.title}. Please try again.',
          isSuccess: false,
        );
      }
    }
  }

  // Enhanced snackbar helper
  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    bool isLoading = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ] else ...[
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
            ],
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isLoading
                ? Colors.blue
                : isSuccess
                ? Colors.green
                : Colors.red,
        duration: Duration(seconds: isLoading ? 1 : 4),
      ),
    );
  }

  // Show activity details dialog
  void _showActivityDetails(Activity activity) {
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
                  Text('Location: ${activity.location}'),
                  const SizedBox(height: 8),
                  Text('Date: ${_formatDate(activity.startTime)}'),
                  const SizedBox(height: 8),
                  Text('Description: ${activity.description}'),
                  const SizedBox(height: 8),
                  Consumer<ActivityProvider>(
                    builder: (context, provider, child) {
                      final currentActivity =
                          provider.activities
                              .where((a) => a.id == activity.id)
                              .firstOrNull;
                      final currentCount =
                          currentActivity?.enrolledCount ??
                          activity.enrolledCount;
                      return Text('Enrolled: $currentCount');
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${activity.status}'),
                  if (activity.isVolunteering) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
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
                      ),
                    ),
                  ],
                  if (activity.isEnrolled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'YOU ARE ENROLLED',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
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

  // Format date for display
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference <= 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
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
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
