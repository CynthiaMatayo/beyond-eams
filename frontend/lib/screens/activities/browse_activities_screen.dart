// lib/screens/activities/browse_activities_screen.dart - FIXED VERSION
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
  bool _showPastActivities = false; // 🔧 NEW: Toggle for past activities
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    if (!mounted) return;
    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      debugPrint('🚀 BrowseScreen: Ensuring provider initialization...');
      await activityProvider.ensureProperInitialization();
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

  // 🔧 FIXED: Filter includes past activity logic
  List<Activity> get _filteredActivities {
    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    final activities = activityProvider.activities;
    final now = DateTime.now();
    
    return activities.where((activity) {
      // 🔧 NEW: Past activity filtering
      final isPast = activity.endTime.isBefore(now);
      if (!_showPastActivities && isPast) {
        return false; // Hide past activities by default
      }
      
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

  // 🔧 FIXED: Better volunteer application status checking
  bool _hasAppliedForVolunteerActivity(
    VolunteerProvider volunteerProvider,
    Activity activity,
  ) {
    try {
      // Check both by activity ID and activity title for better persistence
      return volunteerProvider.myApplications.any(
        (application) => 
          application.activityId == activity.id ||
          application.activityTitle.toLowerCase() == activity.title.toLowerCase(),
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
                      // Filter Chips and Past Activities Toggle
                      Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Volunteering'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Regular'),
                          const Spacer(),
                          // 🔧 NEW: Past activities toggle
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showPastActivities = !_showPastActivities;
                              });
                            },
                            icon: Icon(
                              _showPastActivities ? Icons.visibility_off : Icons.visibility,
                              size: 16,
                            ),
                            label: Text(
                              _showPastActivities ? 'Hide Past' : 'Show Past',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      // Activity count
                      Row(
                        children: [
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
                  child: filteredActivities.isEmpty
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
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.event_busy, // 🔧 FIXED: syntax error
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

  // 🔧 FIXED: Activity card with past activity handling and better left strip
  Widget _buildActivityCard(
    Activity activity,
    ActivityProvider activityProvider,
  ) {
    final currentActivity = activityProvider.activities
            .where((a) => a.id == activity.id)
            .firstOrNull ??
        activity;
    final isVolunteering = currentActivity.isVolunteering;
    final enrollmentCount = currentActivity.enrolledCount;
    final isJoined = activityProvider.isEnrolledInActivity(currentActivity.id);

    // 🔧 NEW: Check if activity is past
    final now = DateTime.now();
    final isPast = currentActivity.endTime.isBefore(now);
    final isOngoing = currentActivity.startTime.isBefore(now) && currentActivity.endTime.isAfter(now);

    debugPrint(
      '🔍 BROWSE: Building card for activity ${currentActivity.id} "${currentActivity.title}": isJoined=$isJoined, isVolunteering=$isVolunteering, isPast=$isPast',
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
        // 🔧 NEW: Grey border for past activities
        border: Border.all(
          color: isPast ? Colors.grey.shade300 : Colors.grey.shade200,
          width: isPast ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPast ? null : () => _showActivityDetails(currentActivity), // 🔧 Disable tap for past
        child: Row(
          children: [
            // 🔧 IMPROVED: Better left strip with gradient for non-past activities
            Container(
              width: 6,
              height: 140,
              decoration: BoxDecoration(
                gradient: isPast 
                    ? null 
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isVolunteering
                            ? [Colors.orange.shade400, Colors.orange.shade600]
                            : (isJoined 
                                ? [Colors.green.shade400, Colors.green.shade600] 
                                : [Colors.indigo.shade400, Colors.indigo.shade600]),
                      ),
                color: isPast ? Colors.grey.shade400 : null, // Solid grey for past
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Opacity(
                opacity: isPast ? 0.6 : 1.0, // 🔧 NEW: Fade past activities
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and badges row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentActivity.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isPast ? Colors.grey.shade600 : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          // 🔧 IMPROVED: Status badges with past indicator
                          Row(
                            children: [
                              // Past indicator
                              if (isPast) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'PAST',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              // Activity type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPast 
                                      ? Colors.grey.shade300
                                      : (isVolunteering ? Colors.orange : Colors.indigo),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isVolunteering ? 'VOLUNTEER' : 'REGULAR',
                                  style: TextStyle(
                                    color: isPast ? Colors.grey.shade600 : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Location and Date Row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: isPast ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              currentActivity.location,
                              style: TextStyle(
                                color: isPast ? Colors.grey[500] : Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isPast ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(currentActivity.startTime),
                            style: TextStyle(
                              color: isPast ? Colors.grey[500] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Status row with enrollment count or volunteer status
                      Row(
                        children: [
                          if (!isVolunteering) ...[
                            Icon(Icons.group, size: 14, color: isPast ? Colors.grey[400] : Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '$enrollmentCount enrolled',
                              style: TextStyle(
                                color: isPast ? Colors.grey[500] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
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
                                      color: isPast ? Colors.grey[400] : Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasApplied
                                          ? 'Application submitted'
                                          : 'Volunteer opportunity',
                                      style: TextStyle(
                                        color: isPast 
                                            ? Colors.grey[500]
                                            : (hasApplied
                                                ? Colors.green[600]
                                                : Colors.grey[600]),
                                        fontSize: 12,
                                        fontWeight: hasApplied && !isPast
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                          const Spacer(),
                          // JOINED status indicator
                          if (isJoined && !isVolunteering)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPast 
                                    ? Colors.grey.shade200
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'JOINED',
                                style: TextStyle(
                                  color: isPast ? Colors.grey.shade600 : Colors.green[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Description
                      Text(
                        currentActivity.description,
                        style: TextStyle(
                          color: isPast ? Colors.grey[500] : Colors.grey[700],
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Action buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isPast ? null : () => _showActivityDetails(currentActivity),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isPast ? Colors.grey[300]! : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: Text(
                                'View Details',
                                style: TextStyle(
                                  color: isPast ? Colors.grey[400] : Colors.grey[700],
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
                              isPast, // 🔧 NEW: Pass isPast parameter
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 UPDATED: Action button with past activity handling
  Widget _buildActionButton(
    Activity activity,
    ActivityProvider activityProvider,
    bool isJoined,
    bool isPast, // 🔧 NEW: isPast parameter
  ) {
    // 🔧 NEW: Handle past activities
    if (isPast) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          activity.isVolunteering ? 'Past' : 'Past',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

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
              onPressed: activityProvider.isLoading
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
              child: activityProvider.isLoading
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
                  onPressed: volunteerProvider.isLoading
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
                  child: volunteerProvider.isLoading
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

  // 🔧 ENHANCED: Better volunteer application handling with persistence
  Future<void> _handleJoinActivity(
    Activity activity,
    ActivityProvider activityProvider,
  ) async {
    if (activity.isVolunteering) {
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      
      // 🔧 IMPROVED: Better application status checking
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

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => VolunteerApplicationDialog(
          title: activity.title,
          description: activity.description,
          dateTime: activity.startTime,
          location: activity.location,
          durationHours: 2,
          activityId: activity.id,
          onSubmit: () async {
            try {
              bool success = await volunteerProvider
                  .applyForVolunteerPosition(activity.id, activity.title);
              if (success) {
                _showSnackBar(
                  'Volunteer application submitted successfully!',
                  isSuccess: true,
                );
                // 🔧 IMPROVED: Force provider refresh to ensure persistence
                await volunteerProvider.refresh();
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
      await _joinActivity(activity, activityProvider);
    }
  }

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
          String errorMessage = activityProvider.error ?? "Unknown error";
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
        // CONTINUATION OF browse_activities_screen.dart - Part 2

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

  // 🔧 ENHANCED: Activity details dialog with past activity status
  void _showActivityDetails(Activity activity) {
    final now = DateTime.now();
    final isPast = activity.endTime.isBefore(now);
    final isOngoing =
        activity.startTime.isBefore(now) && activity.endTime.isAfter(now);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text(activity.title)),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PAST',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Location', activity.location),
                  _buildDetailRow(
                    'Date',
                    _formatDetailDate(activity.startTime),
                  ),
                  _buildDetailRow(
                    'Time',
                    _formatDetailTime(activity.startTime, activity.endTime),
                  ),
                  _buildDetailRow('Description', activity.description),

                  // 🔧 NEW: Activity status
                  _buildDetailRow(
                    'Status',
                    isPast
                        ? 'Completed'
                        : isOngoing
                        ? 'Ongoing'
                        : 'Upcoming',
                  ),

                  Consumer<ActivityProvider>(
                    builder: (context, provider, child) {
                      final currentActivity =
                          provider.activities
                              .where((a) => a.id == activity.id)
                              .firstOrNull;
                      final currentCount =
                          currentActivity?.enrolledCount ??
                          activity.enrolledCount;
                      return _buildDetailRow(
                        'Enrolled',
                        '$currentCount students',
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Activity type badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          activity.isVolunteering
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            activity.isVolunteering
                                ? Colors.orange.shade200
                                : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activity.isVolunteering
                              ? Icons.volunteer_activism
                              : Icons.event,
                          color:
                              activity.isVolunteering
                                  ? Colors.orange.shade600
                                  : Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.isVolunteering
                              ? 'VOLUNTEER OPPORTUNITY'
                              : 'REGULAR ACTIVITY',
                          style: TextStyle(
                            color:
                                activity.isVolunteering
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enrollment status
                  if (activity.isEnrolled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'YOU ARE ENROLLED',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 🔧 NEW: Volunteer application status
                  if (activity.isVolunteering) ...[
                    const SizedBox(height: 12),
                    Consumer<VolunteerProvider>(
                      builder: (context, volunteerProvider, child) {
                        bool hasApplied = _hasAppliedForVolunteerActivity(
                          volunteerProvider,
                          activity,
                        );

                        if (hasApplied) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pending,
                                  color: Colors.orange.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'APPLICATION SUBMITTED',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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

  // Helper method for detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // 🔧 IMPROVED: Date formatting methods
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else if (difference < -1 && difference >= -7) {
      return '${difference.abs()} days ago';
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

  String _formatDetailDate(DateTime dateTime) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatDetailTime(DateTime startTime, DateTime endTime) {
    String formatTime(DateTime time) {
      final hour =
          time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
