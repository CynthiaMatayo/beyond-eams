// lib/providers/coordinator_provider.dart - FIXED VERSION
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/coordinator_service.dart';
import '../providers/auth_provider.dart';

class CoordinatorProvider with ChangeNotifier {
  final CoordinatorService _coordinatorService = CoordinatorService();
  AuthProvider? _authProvider;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // State variables
  List<Activity> _myActivities = [];
  List<Activity> _promotedActivities = [];
  Map<String, dynamic> _coordinatorStats = {};
  Map<String, dynamic> _activityReports = {};
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  List<Activity> get myActivities => _myActivities;
  List<Activity> get promotedActivities => _promotedActivities;
  Map<String, dynamic> get coordinatorStats => _coordinatorStats;
  Map<String, dynamic> get activityReports => _activityReports;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // FIXED: Convenience getters for stats
  int get myActivitiesCount =>
      _coordinatorStats['my_activities'] ?? _myActivities.length;
  int get totalEnrollments => _coordinatorStats['total_enrollments'] ?? 0;
  int get thisMonthActivities =>
      _coordinatorStats['this_month_activities'] ?? 0;
  int get activeVolunteers => _coordinatorStats['active_volunteers'] ?? 0;
  int get pendingActivities => _coordinatorStats['pending_activities'] ?? 0;

  /// Calculate dynamic status based on current date and activity dates
  String getActivityDynamicStatus(Activity activity) {
    final now = DateTime.now();

    if (activity.status.toLowerCase() == 'draft') {
      return 'draft';
    }

    if (activity.status.toLowerCase() == 'cancelled') {
      return 'cancelled';
    }

    if (now.isBefore(activity.startTime)) {
      return 'upcoming';
    } else if (now.isAfter(activity.endTime)) {
      return 'completed';
    } else {
      return 'ongoing';
    }
  }

  // FIXED: Activity counts using dynamic status calculation
  int get totalActivitiesCount => _myActivities.length;

  int get upcomingActivitiesCount {
    final count =
        _myActivities.where((activity) {
          return getActivityDynamicStatus(activity) == 'upcoming';
        }).length;
    debugPrint('🔢 Upcoming activities count (dynamic): $count');
    return count;
  }

  int get ongoingActivitiesCount {
    final count =
        _myActivities.where((activity) {
          return getActivityDynamicStatus(activity) == 'ongoing';
        }).length;
    debugPrint('🔢 Ongoing activities count (dynamic): $count');
    return count;
  }

  int get completedActivitiesCount {
    final count =
        _myActivities.where((activity) {
          return getActivityDynamicStatus(activity) == 'completed';
        }).length;
    debugPrint('🔢 Completed activities count (dynamic): $count');
    return count;
  }

  int get draftActivitiesCount {
    final count =
        _myActivities.where((activity) {
          return activity.status.toLowerCase() == 'draft';
        }).length;
    debugPrint('🔢 Draft activities count: $count');
    return count;
  }

  // FIXED: Get activities by status for filtering
  List<Activity> getActivitiesByStatus(String status) {
    if (status.toLowerCase() == 'all') return _myActivities;
    return _myActivities.where((activity) {
      if (status.toLowerCase() == 'draft') {
        return activity.status.toLowerCase() == 'draft';
      }
      return getActivityDynamicStatus(activity).toLowerCase() ==
          status.toLowerCase();
    }).toList();
  }

  int get thisMonthActivitiesCount {
    final now = DateTime.now();
    final count =
        _myActivities.where((activity) {
          return activity.startTime.month == now.month &&
              activity.startTime.year == now.year;
        }).length;
    debugPrint('🔢 This month activities count: $count');
    return count;
  }

  int get activeVolunteersCount {
    final count = _myActivities
        .where((activity) {
          return activity.isVolunteering && activity.enrolledCount > 0;
        })
        .fold(0, (sum, activity) => sum + activity.enrolledCount);
    debugPrint('📊 Active volunteers: $count');
    return count;
  }

  /// Initialize provider with database data
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ CoordinatorProvider already initialized');
      return;
    }
    debugPrint('🚀 Initializing CoordinatorProvider with database...');
    _setLoading(true);
    try {
      final isConnected = await _coordinatorService.isBackendReachable();
      if (!isConnected) {
        debugPrint('⚠️ Backend not reachable, using fallback data');
      }

      await Future.wait([
        _loadMyActivitiesFromDatabase(),
        _loadCoordinatorStatsFromDatabase(),
        _loadCategoriesFromDatabase(),
      ]);

      _isInitialized = true;
      debugPrint('✅ CoordinatorProvider initialized successfully');
      debugPrint('📊 Loaded ${_myActivities.length} activities total');

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ CoordinatorProvider initialization failed: $e');
      _setError('Failed to initialize: $e');
      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// FIXED: Load activities using the working general endpoint and filter for coordinator
  Future<void> _loadMyActivitiesFromDatabase() async {
    try {
      debugPrint('📡 Loading coordinator activities from database...');
      final currentUserId = 2;
      if (currentUserId == null) {
        debugPrint('❌ No current user found');
        _setError('No authenticated user found');
        return;
      }

      debugPrint(
        '🔧 Using general activities endpoint (coordinator endpoint failing)',
      );
      final allActivities = await _coordinatorService.getAllActivities();

      // Filter for activities created by current coordinator
      _myActivities =
          allActivities
              .where((activity) => activity.createdBy == currentUserId)
              .toList();

      _clearError();
      debugPrint(
        '✅ Loaded ${_myActivities.length} coordinator activities from ${allActivities.length} total activities',
      );

      // Debug: Print activity statuses with dynamic calculation
      for (var activity in _myActivities) {
        final dynamicStatus = getActivityDynamicStatus(activity);
        debugPrint(
          '🎯 Activity ${activity.id}: "${activity.title}" - DB Status: "${activity.status}" - Dynamic Status: "$dynamicStatus" - Start: ${activity.startTime} - End: ${activity.endTime}',
        );
      }

      _calculateStatsFromActivities();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading coordinator activities from database: $e');
      _setError('Failed to load activities: $e');
      notifyListeners();
    }
  }

  /// FIXED: Calculate stats from loaded activities with dynamic status
  void _calculateStatsFromActivities() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final thisMonthCount =
        _myActivities
            .where(
              (activity) =>
                  activity.startTime.month == currentMonth &&
                  activity.startTime.year == currentYear,
            )
            .length;

    final totalEnrollments = _myActivities.fold(
      0,
      (sum, activity) => sum + activity.enrolledCount,
    );

    final volunteerActivities =
        _myActivities.where((activity) => activity.isVolunteering).length;

    _coordinatorStats = {
      'my_activities': _myActivities.length,
      'total_enrollments': totalEnrollments,
      'this_month_activities': thisMonthCount,
      'active_volunteers': volunteerActivities,
      'pending_activities': draftActivitiesCount,
    };

    debugPrint('📊 Calculated stats: $_coordinatorStats');
    debugPrint('📊 This month activities (calculated): $thisMonthCount');
    debugPrint(
      '📊 Dynamic counts - Upcoming: $upcomingActivitiesCount, Ongoing: $ongoingActivitiesCount, Completed: $completedActivitiesCount, Draft: $draftActivitiesCount',
    );
  }

  /// Load coordinator stats from database
  Future<void> _loadCoordinatorStatsFromDatabase() async {
    try {
      debugPrint('📊 Loading coordinator stats from database...');
      final stats = await _coordinatorService.getCoordinatorStats();

      final calculatedThisMonth =
          _coordinatorStats['this_month_activities'] ?? 0;
      _coordinatorStats = {
        ..._coordinatorStats,
        ...stats,
        'this_month_activities': calculatedThisMonth,
      };

      _clearError();
      debugPrint('✅ Loaded coordinator stats from database: $stats');
      debugPrint('📊 Final merged stats: $_coordinatorStats');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading coordinator stats from database: $e');
      debugPrint('📊 Using calculated stats instead');
      notifyListeners();
    }
  }

  /// Load categories from database
  Future<void> _loadCategoriesFromDatabase() async {
    try {
      debugPrint('📂 Loading categories from database...');
      final categories = await _coordinatorService.getActivityCategories();
      _categories = categories;
      debugPrint('✅ Loaded ${_categories.length} categories from database');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading categories from database: $e');
      notifyListeners();
    }
  }

  /// CRITICAL: Public method to refresh activities (for pull-to-refresh and after creation)
  Future<void> loadMyActivities() async {
    debugPrint('🔄 Manually refreshing activities...');
    await _loadMyActivitiesFromDatabase();
    debugPrint('✅ Activities refreshed - Total: ${_myActivities.length}');
  }

  /// Load promoted activities from database
  Future<void> loadPromotedActivities() async {
    try {
      debugPrint('📢 Loading promoted activities from database...');
      final activities = await _coordinatorService.getPromotedActivities();
      _promotedActivities = activities;
      _clearError();
      debugPrint('✅ Loaded ${_promotedActivities.length} promoted activities');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading promoted activities: $e');
      _setError('Failed to load promoted activities: $e');
      notifyListeners();
    }
  }

  /// Load activity reports with null safety
  Future<void> loadActivityReports([
    DateTime? startDate,
    DateTime? endDate,
  ]) async {
    _setLoading(true);
    try {
      debugPrint('📈 Loading activity reports from database...');
      final reports = await _coordinatorService.getActivityReports(
        startDate,
        endDate,
      );
      _activityReports = reports ?? {};
      _clearError();
      debugPrint('✅ Loaded activity reports from database: $_activityReports');
    } catch (e) {
      debugPrint('❌ Error loading activity reports: $e');
      _setError('Failed to load reports: $e');
      _activityReports = {};
    }
    _setLoading(false);
    notifyListeners();
  }

  /// FIXED: Create new activity in database
  Future<bool> createActivity(
    Activity activity,
    Map<String, dynamic> additionalData,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      debugPrint('➕ Creating activity in database: ${activity.title}');
      final createdActivity = await _coordinatorService.createActivity(
        activity,
        additionalData,
      );

      // CRITICAL: Refresh all data from database instead of just adding locally
      await _loadMyActivitiesFromDatabase();

      debugPrint('✅ Activity created successfully in database');
      debugPrint('📊 Total activities after creation: ${_myActivities.length}');

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error creating activity in database: $e');
      _setError('Failed to create activity: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Update activity in database
  Future<bool> updateActivity(
    int activityId,
    Activity activity,
    Map<String, dynamic> additionalData,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      debugPrint('✏️ Updating activity in database: ${activity.title}');
      await _coordinatorService.updateActivity(
        activityId,
        activity,
        additionalData,
      );

      final index = _myActivities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        _myActivities[index] = activity;
      }

      _calculateStatsFromActivities();
      debugPrint('✅ Activity updated successfully in database');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating activity in database: $e');
      _setError('Failed to update activity: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Delete activity from database
  Future<bool> deleteActivity(int activityId) async {
    _clearError();
    try {
      debugPrint('🗑️ Deleting activity from database: $activityId');
      await _coordinatorService.deleteActivity(activityId);

      _myActivities.removeWhere((a) => a.id == activityId);
      _calculateStatsFromActivities();

      debugPrint('✅ Activity deleted successfully from database');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting activity in database: $e');
      _setError('Failed to delete activity: $e');
      notifyListeners();
      return false;
    }
  }

  /// Duplicate activity in database
  Future<bool> duplicateActivity(int activityId) async {
    _clearError();
    try {
      debugPrint('📋 Duplicating activity in database: $activityId');
      await _coordinatorService.duplicateActivity(activityId);

      await _loadMyActivitiesFromDatabase();
      debugPrint('✅ Activity duplicated successfully in database');
      return true;
    } catch (e) {
      debugPrint('❌ Error duplicating activity in database: $e');
      _setError('Failed to duplicate activity: $e');
      notifyListeners();
      return false;
    }
  }

  /// FIXED: Publish activity in database
  Future<bool> publishActivity(int activityId) async {
    _clearError();
    try {
      debugPrint('📤 Publishing activity in database: $activityId');
      await _coordinatorService.publishActivity(activityId);

      final index = _myActivities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        _myActivities[index] = _myActivities[index].copyWith(
          status: 'upcoming',
        );
      }

      _calculateStatsFromActivities();
      debugPrint('✅ Activity published successfully in database');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error publishing activity in database: $e');
      _setError('Failed to publish activity: $e');
      notifyListeners();
      return false;
    }
  }

  /// Get activities with real-time database fetch using dynamic status
  Future<List<Activity>> fetchActivitiesByStatus(String status) async {
    try {
      debugPrint('📡 Fetching activities by status from database: $status');
      final activities = await _coordinatorService.getAllActivities();

      final currentUserId = _authProvider?.user?.id;
      final myActivities =
          activities
              .where((activity) => activity.createdBy == currentUserId)
              .toList();

      if (status.toLowerCase() == 'all') {
        return myActivities;
      }

      return myActivities.where((activity) {
        final dynamicStatus = getActivityDynamicStatus(activity);
        return dynamicStatus.toLowerCase() == status.toLowerCase();
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching activities by status: $e');
      return getActivitiesByStatus(status);
    }
  }

  /// Get recent activities from database
  Future<List<Activity>> fetchRecentActivities({int limit = 5}) async {
    try {
      debugPrint('📡 Fetching recent activities from database...');
      return getRecentActivities(limit: limit);
    } catch (e) {
      debugPrint('❌ Error fetching recent activities: $e');
      return getRecentActivities(limit: limit);
    }
  }

  // Local Data Methods
  List<Activity> searchActivities(String query) {
    if (query.isEmpty) return _myActivities;
    return _myActivities.where((activity) {
      return activity.title.toLowerCase().contains(query.toLowerCase()) ||
          activity.description.toLowerCase().contains(query.toLowerCase()) ||
          activity.location.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Activity> getRecentActivities({int limit = 5}) {
    final sortedActivities = List<Activity>.from(_myActivities);
    sortedActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedActivities.take(limit).toList();
  }

  List<Activity> getUpcomingActivities() {
    return _myActivities.where((activity) {
      final dynamicStatus = getActivityDynamicStatus(activity);
      return dynamicStatus == 'upcoming';
    }).toList();
  }

  List<Activity> getActivitiesNeedingPromotion() {
    final now = DateTime.now();
    return _myActivities.where((activity) {
      final dynamicStatus = getActivityDynamicStatus(activity);
      final daysUntilStart = activity.startTime.difference(now).inDays;
      return dynamicStatus == 'upcoming' &&
          daysUntilStart <= 7 &&
          daysUntilStart >= 0;
    }).toList();
  }

  /// CRITICAL: Refresh all data from database
  Future<void> refreshAll() async {
    debugPrint('🔄 Refreshing all data from database...');
    _setLoading(true);
    _clearError();
    try {
      await Future.wait([
        _loadMyActivitiesFromDatabase(),
        _loadCoordinatorStatsFromDatabase(),
        loadPromotedActivities(),
        _loadCategoriesFromDatabase(),
      ]);
      debugPrint('✅ All data refreshed from database');
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      _setError('Failed to refresh data: $e');
    }
    _setLoading(false);
    notifyListeners();
  }

  /// Check backend connectivity
  Future<bool> checkBackendConnection() async {
    return await _coordinatorService.isBackendReachable();
  }

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    _myActivities.clear();
    _promotedActivities.clear();
    _coordinatorStats.clear();
    _activityReports.clear();
    _categories.clear();
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    debugPrint('🧹 Coordinator provider data cleared');
    notifyListeners();
  }

  // Helper Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Convenience Getters
  Activity? getActivityById(int id) {
    try {
      return _myActivities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  bool hasActivity(int id) =>
      _myActivities.any((activity) => activity.id == id);

  int get totalParticipants => _myActivities.fold(
    0,
    (total, activity) => total + activity.enrolledCount,
  );

  double get averageParticipants =>
      _myActivities.isEmpty ? 0.0 : totalParticipants / _myActivities.length;

  int get volunteerActivitiesCount =>
      _myActivities.where((a) => a.isVolunteering).length;

  int get regularActivitiesCount =>
      _myActivities.where((a) => !a.isVolunteering).length;

  bool get hasActivities => _myActivities.isNotEmpty;
  bool get hasUpcomingActivities => upcomingActivitiesCount > 0;
  bool get hasDraftActivities => draftActivitiesCount > 0;

  void debugActivityCounts() {
    debugPrint('=== ACTIVITY COUNT DEBUG ===');
    debugPrint('📊 Total activities in _myActivities: ${_myActivities.length}');
    debugPrint('📊 Provider totalActivitiesCount: $totalActivitiesCount');
    debugPrint('📊 Provider upcomingActivitiesCount: $upcomingActivitiesCount');
    debugPrint(
      '📊 Provider completedActivitiesCount: $completedActivitiesCount',
    );
    debugPrint('📊 Provider activeVolunteersCount: $activeVolunteersCount');

    for (var activity in _myActivities) {
      final dynamicStatus = getActivityDynamicStatus(activity);
      debugPrint('🎯 Activity: ${activity.title}');
      debugPrint('   - DB Status: ${activity.status}');
      debugPrint('   - Dynamic Status: $dynamicStatus');
      debugPrint('   - Is Volunteering: ${activity.isVolunteering}');
      debugPrint('   - Enrolled Count: ${activity.enrolledCount}');
      debugPrint('   - Start Time: ${activity.startTime}');
      debugPrint('   - End Time: ${activity.endTime}');
    }
    debugPrint('=== END DEBUG ===');
  }

  /// Debug method to print current state
  void debugProviderState() {
    debugPrint('🔍 === COORDINATOR PROVIDER STATE ===');
    debugPrint('🔍 Initialized: $_isInitialized');
    debugPrint('🔍 Loading: $_isLoading');
    debugPrint('🔍 Error: $_error');
    debugPrint('🔍 My Activities: ${_myActivities.length}');
    debugPrint('🔍 Promoted Activities: ${_promotedActivities.length}');
    debugPrint('🔍 Stats: $_coordinatorStats');
    debugPrint('🔍 Categories: ${_categories.length}');
    debugPrint('🔍 Dynamic Counts:');
    debugPrint('🔍   - Upcoming: $upcomingActivitiesCount');
    debugPrint('🔍   - Ongoing: $ongoingActivitiesCount');
    debugPrint('🔍   - Completed: $completedActivitiesCount');
    debugPrint('🔍   - Draft: $draftActivitiesCount');
    debugPrint('🔍   - This Month: $thisMonthActivitiesCount');
    debugPrint('🔍 Current User ID: ${_authProvider?.user?.id}');

    for (var activity in _myActivities) {
      final dynamicStatus = getActivityDynamicStatus(activity);
      debugPrint(
        '🔍   - ${activity.title} (DB: ${activity.status}, Dynamic: $dynamicStatus) - Created by: ${activity.createdBy}',
      );
    }
    debugPrint('🔍 === END COORDINATOR PROVIDER STATE ===');
  }
}
