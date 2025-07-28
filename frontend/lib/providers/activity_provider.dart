// lib/providers/activity_provider.dart - UPDATED WITH VOLUNTEERING DEBUG

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity.dart';
import '../services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  List<Activity> _activities = [];
  final List<Activity> _myActivities = [];
  final List<dynamic> _userEnrolledActivities = [];
  final List<dynamic> _userCompletedActivities = [];
  final List<dynamic> _userMissedActivities = [];
  Set<int> _enrolledActivityIds = {}; // Track enrolled activity IDs
  Activity? _currentActivity;
  bool _isLoading = false;
  bool _isInitialized = false; // Track initialization state
  String? _error;

  // Getters
  List<Activity> get activities => _activities;
  List<Activity> get myActivities => _myActivities;
  List<dynamic> get userEnrolledActivities => _userEnrolledActivities;
  List<dynamic> get userCompletedActivities => _userCompletedActivities;
  List<dynamic> get userMissedActivities => _userMissedActivities;
  Set<int> get enrolledActivityIds => _enrolledActivityIds;
  Activity? get currentActivity => _currentActivity;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Constants for SharedPreferences keys
  static const String _enrolledActivitiesKey = 'enrolled_activities_v3';
  static const String _userActivitiesKey = 'user_activities_cache_v3';
  static const String _lastSyncKey = 'last_sync_timestamp_v3';
  static const String _activitiesDataKey = 'activities_data_v3';

  // 🔧 NEW: Get current user ID from stored authentication data
  Future<int> _getCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // First, try direct user ID storage
      int? userId = prefs.getInt('user_id') ?? 
                    prefs.getInt('current_user_id') ?? 
                    prefs.getInt('logged_in_user_id') ??
                    prefs.getInt('id');
      
      if (userId != null) {
        debugPrint('✅ Found user ID: $userId');
        return userId;
      }
      
      // Try to get from user data JSON
      String? userDataString = prefs.getString('user_data') ?? 
                               prefs.getString('current_user') ??
                               prefs.getString('auth_user') ??
                               prefs.getString('user');
      
      if (userDataString != null) {
        try {
          Map<String, dynamic> userData = json.decode(userDataString);
          int? userIdFromData = userData['id'] ?? 
                                userData['user_id'] ?? 
                                userData['userId'];
          if (userIdFromData != null) {
            debugPrint('✅ Found user ID from user data: $userIdFromData');
            return userIdFromData;
          }
        } catch (e) {
          debugPrint('❌ Error parsing user data: $e');
        }
      }
      
      // Try to get from token payload (if JWT)
      String? token = prefs.getString('access_token') ?? 
                      prefs.getString('auth_token') ?? 
                      prefs.getString('jwt_token') ?? 
                      prefs.getString('token');
      
      if (token != null) {
        try {
          // Basic JWT payload extraction (without verification)
          List<String> parts = token.split('.');
          if (parts.length == 3) {
            String payload = parts[1];
            // Add padding if needed
            while (payload.length % 4 != 0) {
              payload += '=';
            }
            String decoded = utf8.decode(base64Decode(payload));
            Map<String, dynamic> tokenData = json.decode(decoded);
            int? userIdFromToken = tokenData['user_id'] ?? 
                                   tokenData['id'] ?? 
                                   tokenData['sub'];
            if (userIdFromToken != null) {
              debugPrint('✅ Found user ID from token: $userIdFromToken');
              return userIdFromToken;
            }
          }
        } catch (e) {
          debugPrint('❌ Error parsing token: $e');
        }
      }
      
      debugPrint('⚠️ No user ID found, using fallback ID 1');
      return 1; // Fallback
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return 1; // Fallback
    }
  }

  // MAIN INITIALIZATION METHOD
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ ActivityProvider already initialized');
      return;
    }
    debugPrint('🚀 ActivityProvider: Starting initialization...');
    _setLoading(true);
    try {
      // Step 1: Load enrolled IDs from storage
      await _loadEnrolledActivitiesFromStorage();
      debugPrint(
        '📱 Loaded ${_enrolledActivityIds.length} enrolled IDs: $_enrolledActivityIds',
      );
      // Step 2: Create immediate UI data from enrolled IDs
      if (_enrolledActivityIds.isNotEmpty) {
        _createUserActivitiesFromEnrolledIds();
      }
      // Step 3: Try to load activities from server
      try {
        await loadActivities();
        debugPrint('📡 Loaded activities from server');
      } catch (e) {
        debugPrint('⚠️ Server unavailable, using cached data: $e');
        await _loadCachedActivitiesData();
      }
      // 🆕 Step 4: Load REAL enrolled activities from Django backend
      await _loadRealEnrolledActivitiesFromDatabase();
      // Step 5: Update user activities with server data
      await _updateUserEnrolledActivities();
      _isInitialized = true;
      debugPrint('✅ ActivityProvider: Initialization complete');
    } catch (e) {
      debugPrint('❌ ActivityProvider: Initialization failed: $e');
      _isInitialized = true; // Still mark as initialized to prevent infinite retry
    }
    _setLoading(false);
    notifyListeners();
  }

  // 🆕 NEW: Load real enrolled activities from Django database on startup
  Future<void> _loadRealEnrolledActivitiesFromDatabase() async {
    try {
      final userId = await _getCurrentUserId();
      debugPrint('🔄 Loading real enrolled activities from database for user $userId...');
      
      // Call Django endpoint to get enrolled activities
      final response = await ActivityService.getStudentEnrolledActivities(userId);
      
      if (response['success'] && response['data'] != null) {
        final enrolledActivities = response['data'] as List<dynamic>;
        
        // Update local enrolled IDs with database data
        Set<int> databaseEnrolledIds = {};
        for (var activity in enrolledActivities) {
          final activityId = activity['id'];
          if (activityId != null) {
            databaseEnrolledIds.add(int.parse(activityId.toString()));
          }
        }
        
        // Merge with local enrolled IDs
        _enrolledActivityIds.addAll(databaseEnrolledIds);
        
        // Save updated IDs to local storage
        await _saveEnrolledActivitiesToStorage();
        
        debugPrint('✅ Loaded ${databaseEnrolledIds.length} enrolled activities from database');
        debugPrint('📱 Total enrolled activities: ${_enrolledActivityIds.length}');
        
        // Update user enrolled activities list
        _userEnrolledActivities.clear();
        _userEnrolledActivities.addAll(enrolledActivities);
        
      } else {
        debugPrint('⚠️ No enrolled activities found in database or API call failed');
      }
    } catch (e) {
      debugPrint('❌ Error loading enrolled activities from database: $e');
      // Don't throw error - continue with local data
    }
  }

  // NEW: Ensure proper initialization method
  Future<void> ensureProperInitialization() async {
    if (!_isInitialized) {
      debugPrint('🚀 Provider not initialized, initializing now...');
      await initialize();
    } else {
      debugPrint('✅ Provider already initialized');
      // Ensure state consistency even if already initialized
      _ensureEnrollmentStateSync();
      notifyListeners();
    }
  }

  // NEW: Enhanced state synchronization
  void _ensureEnrollmentStateSync() {
    debugPrint('🔄 SYNC: Ensuring enrollment state synchronization...');
    bool hasChanges = false;
    for (int i = 0; i < _activities.length; i++) {
      final activity = _activities[i];
      final shouldBeEnrolled = _enrolledActivityIds.contains(activity.id);
      final currentlyMarkedEnrolled = activity.isEnrolled;
      if (shouldBeEnrolled != currentlyMarkedEnrolled) {
        debugPrint(
          '🔧 SYNC: Fixing activity ${activity.id}: stored=$shouldBeEnrolled, marked=$currentlyMarkedEnrolled',
        );
        _activities[i] = activity.copyWith(isEnrolled: shouldBeEnrolled);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      debugPrint(
        '✅ SYNC: Enrollment state synchronized - triggering UI update',
      );
      notifyListeners();
    }
    debugPrint('✅ SYNC: Enrollment state synchronization complete');
  }

  // Load enrolled activity IDs from SharedPreferences
  Future<void> _loadEnrolledActivitiesFromStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> enrolledIds = prefs.getStringList(_enrolledActivitiesKey) ?? [];
      if (enrolledIds.isNotEmpty) {
        _enrolledActivityIds = enrolledIds.map((id) => int.parse(id)).toSet();
        debugPrint(
          '📱 RESTORED ${_enrolledActivityIds.length} enrolled activities from storage: $_enrolledActivityIds',
        );
      } else {
        _enrolledActivityIds = {};
        debugPrint('📱 NO enrolled activities found in storage');
      }
    } catch (e) {
      debugPrint('❌ Error loading enrolled activities from storage: $e');
      _enrolledActivityIds = {};
    }
  }

  // Save enrolled activity IDs to SharedPreferences
  Future<void> _saveEnrolledActivitiesToStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> enrolledIds = _enrolledActivityIds.map((id) => id.toString()).toList();
      
      debugPrint('💾 SAVING enrolled IDs to storage: $enrolledIds');
      bool success = await prefs.setStringList(_enrolledActivitiesKey, enrolledIds);
      debugPrint('💾 Save success: $success');
      
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      // VERIFY the save worked
      List<String>? savedIds = prefs.getStringList(_enrolledActivitiesKey);
      debugPrint('✅ VERIFIED saved IDs: $savedIds');
    } catch (e) {
      debugPrint('❌ Error saving enrolled activities to storage: $e');
    }
  }

  // Create immediate user activities from enrolled IDs (for instant UI display)
  void _createUserActivitiesFromEnrolledIds() {
    _userEnrolledActivities.clear();
    for (int activityId in _enrolledActivityIds) {
      _userEnrolledActivities.add({
        'id': activityId,
        'title': 'Activity #$activityId',
        'description': 'You are enrolled in this activity. Details will load when connected to server.',
        'location': 'Campus',
        'start_time': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'is_volunteering': false,
        'status': 'enrolled',
        'enrollment_status': 'enrolled',
        'isLocalData': true,
      });
    }
    debugPrint(
      '📱 Created ${_userEnrolledActivities.length} user activities from enrolled IDs',
    );
    notifyListeners(); // Immediately notify UI
  }

  // Load cached activities data
  Future<void> _loadCachedActivitiesData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_activitiesDataKey);
      if (cachedData != null) {
        List<dynamic> activitiesJson = json.decode(cachedData);
        _activities = activitiesJson.map((json) => Activity.fromJson(json)).toList();
        
        // Update enrollment status based on stored IDs
        _updateActivitiesWithLocalEnrollmentData();
        
        debugPrint('💾 Loaded ${_activities.length} activities from cache');
      }
    } catch (e) {
      debugPrint('❌ Error loading activities from cache: $e');
    }
  }

  // Save activities data to cache
  Future<void> _saveActivitiesDataToCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> activitiesJson = _activities.map((activity) => activity.toJson()).toList();
      await prefs.setString(_activitiesDataKey, json.encode(activitiesJson));
      debugPrint('💾 Saved ${_activities.length} activities to cache');
    } catch (e) {
      debugPrint('❌ Error saving activities to cache: $e');
    }
  }

  // FIXED: Update activities with local enrollment data
  void _updateActivitiesWithLocalEnrollmentData() {
    debugPrint('🔧 Updating activities with local enrollment data...');
    debugPrint('🔧 Enrolled IDs: $_enrolledActivityIds');
    
    bool hasChanges = false;
    for (int i = 0; i < _activities.length; i++) {
      final activity = _activities[i];
      final shouldBeEnrolled = _enrolledActivityIds.contains(activity.id);
      
      if (activity.isEnrolled != shouldBeEnrolled) {
        _activities[i] = activity.copyWith(isEnrolled: shouldBeEnrolled);
        hasChanges = true;
        debugPrint(
          '🔄 Activity ${activity.id}: updated isEnrolled to $shouldBeEnrolled',
        );
      }
    }
    if (hasChanges) {
      debugPrint(
        '✅ Updated activities with local enrollment data - triggering UI update',
      );
      notifyListeners(); // Ensure UI updates
    }
    debugPrint(
      '🔄 Updated ${_activities.length} activities with local enrollment status',
    );
  }

Future<void> loadActivities() async {
    debugPrint('📡 Loading activities...');
    _setLoading(true);
    _clearError();

    try {
      // FIXED: Call getActivitiesWithEnrollmentStatus for student browse activities
      final response = await ActivityService.getActivitiesWithEnrollmentStatus();

      if (response['success']) {
        final List<dynamic> activitiesData = response['data'] as List<dynamic>;

        // ADD VOLUNTEERING DEBUG CODE HERE
        if (activitiesData.isNotEmpty) {
          debugPrint('🔍 === ACTIVITY DEBUG - RAW API DATA ===');
          for (
            int i = 0;
            i < (activitiesData.length > 3 ? 3 : activitiesData.length);
            i++
          ) {
            final rawActivity = activitiesData[i];
            debugPrint('Activity $i: ${rawActivity['title']}');
            debugPrint(
              '  - Raw is_volunteering: ${rawActivity['is_volunteering']}',
            );
            debugPrint(
              '  - Raw is_volunteering type: ${rawActivity['is_volunteering'].runtimeType}',
            );

            final parsedActivity = Activity.fromJson(
              rawActivity as Map<String, dynamic>,
            );
            debugPrint(
              '  - Parsed isVolunteering: ${parsedActivity.isVolunteering}',
            );
            debugPrint(
              '  - Should show: ${parsedActivity.isVolunteering ? "VOLUNTEER" : "REGULAR"}',
            );
            debugPrint('---');
          }
          debugPrint('🔍 === END ACTIVITY DEBUG ===');
        }

        List<Activity> newActivities =
            activitiesData
                .map((json) => Activity.fromJson(json as Map<String, dynamic>))
                .toList();
        debugPrint(
          '📡 Received ${newActivities.length} activities from server',
        );

        // Get current user ID for enrollment checking
        final userId = await _getCurrentUserId();

        // CRITICAL: Apply local enrollment state IMMEDIATELY
        for (int i = 0; i < newActivities.length; i++) {
          final activity = newActivities[i];
          final isLocallyEnrolled = _enrolledActivityIds.contains(activity.id);

          // Override server enrollment state with local state
          newActivities[i] = activity.copyWith(isEnrolled: isLocallyEnrolled);

          debugPrint(
            '📊 Activity ${activity.id}: server_enrolled=${activity.isEnrolled}, local_enrolled=$isLocallyEnrolled, final=${newActivities[i].isEnrolled}',
          );
        }

        _activities = newActivities;
        await _saveActivitiesDataToCache();
        await _updateUserEnrolledActivities();

        // Ensure state is properly synchronized
        _ensureEnrollmentStateSync();

        debugPrint('✅ Activities loaded and synced successfully');
      } else {
        _setError(_extractErrorMessage(response['error']));
      }
    } catch (e) {
      debugPrint('❌ Load activities error: $e');
      _setError('Failed to load activities: $e');

      // Try to load from cache on error
      await _loadCachedActivitiesData();
      _ensureEnrollmentStateSync();
    }

    _setLoading(false);
    notifyListeners();
  }

  // Update user enrolled activities with real activity data
  Future<void> _updateUserEnrolledActivities() async {
    _userEnrolledActivities.clear();
    
    debugPrint('🔄 UPDATING USER ENROLLED ACTIVITIES');
    debugPrint('🔄 Enrolled activity IDs: $_enrolledActivityIds');
    for (int activityId in _enrolledActivityIds) {
      Activity? activity;
      try {
        activity = _activities.firstWhere((a) => a.id == activityId);
        debugPrint('✅ Found activity $activityId: ${activity.title}');
      } catch (e) {
        activity = null;
        debugPrint('❌ Activity $activityId not found in loaded activities');
      }
      if (activity != null) {
        final activityMap = {
          'id': activity.id,
          'title': activity.title,
          'description': activity.description,
          'location': activity.location,
          'start_time': activity.startTime.toIso8601String(),
          'is_volunteering': activity.isVolunteering,
          'status': 'enrolled',
          'enrollment_status': 'enrolled',
        };
        _userEnrolledActivities.add(activityMap);
        debugPrint('✅ Added enrolled activity: ${activity.title}');
      } else {
        // Keep fallback data if activity not found on server
        final fallbackMap = {
          'id': activityId,
          'title': 'Activity #$activityId',
          'description': 'You are enrolled in this activity. Details will load when connected to server.',
          'location': 'Campus',
          'start_time': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'is_volunteering': false,
          'status': 'enrolled',
          'enrollment_status': 'enrolled',
          'isLocalData': true,
        };
        _userEnrolledActivities.add(fallbackMap);
        debugPrint('📱 Created fallback for activity $activityId');
      }
    }
    debugPrint(
      '📋 FINAL: Updated ${_userEnrolledActivities.length} enrolled activities',
    );
  }

  // 🔧 ENHANCED: Enroll in activity with real user ID and immediate UI feedback
  Future<bool> enrollActivity(int activityId) async {
    debugPrint('🔄 ENROLL: Starting enrollment for activity $activityId');
    _clearError();
    if (_enrolledActivityIds.contains(activityId)) {
      debugPrint('ℹ️ Already enrolled in activity $activityId');
      return true;
    }
    try {
      // IMMEDIATE: Update local state first for instant UI feedback
      _enrolledActivityIds.add(activityId);
      _updateActivityEnrollmentStatus(activityId, isEnrolled: true);
      await _saveEnrolledActivitiesToStorage();
      await _updateUserEnrolledActivities();
      // Trigger immediate UI update
      notifyListeners();
      debugPrint('✅ ENROLL: Local enrollment updated immediately');
      // 🔧 Then sync with server using REAL USER ID
      final int userId = await _getCurrentUserId();
      debugPrint('🔑 Using user ID: $userId for enrollment');
      
      final serverResponse = await ActivityService.enrollInActivity(
        activityId,
        userId,
      );
      if (serverResponse['success']) {
        debugPrint('✅ ENROLL: Server enrollment successful');
        
        // Update enrollment count if provided by server
        if (serverResponse['data'] is Map) {
          final data = serverResponse['data'] as Map<String, dynamic>;
          if (data['enrollment_count'] != null) {
            _updateActivityEnrollmentCount(
              activityId,
              data['enrollment_count'],
            );
          }
        }
        
        _clearError();
        notifyListeners();
        return true;
      } else {
        // Server failed - keep local state but show warning
        final errorMessage = _extractErrorMessage(serverResponse['error']);
        debugPrint(
          '⚠️ ENROLL: Server failed but local state preserved: $errorMessage',
        );
        _setError('Enrolled locally. Server sync failed: $errorMessage');
        notifyListeners();
        return true; // Return true since local enrollment succeeded
      }
    } catch (e) {
      // Revert local changes if everything fails
      _enrolledActivityIds.remove(activityId);
      _updateActivityEnrollmentStatus(activityId, isEnrolled: false);
      await _saveEnrolledActivitiesToStorage();
      await _updateUserEnrolledActivities();
      
      debugPrint('❌ ENROLL: Total enrollment failure: $e');
      _setError('Failed to enroll in activity: $e');
      notifyListeners();
      return false;
    }
  }

  // NEW: Update activity enrollment count
  void _updateActivityEnrollmentCount(int activityId, int newCount) {
    final activityIndex = _activities.indexWhere((a) => a.id == activityId);
    if (activityIndex != -1) {
      final activity = _activities[activityIndex];
      _activities[activityIndex] = activity.copyWith(enrolledCount: newCount);
      debugPrint(
        '📊 Updated activity $activityId enrollment count to $newCount',
      );
    }
    if (_currentActivity?.id == activityId) {
      _currentActivity = _currentActivity!.copyWith(enrolledCount: newCount);
    }
  }

  // 🔧 UNENROLL FROM ACTIVITY with real user ID
  Future<bool> unenrollActivity(int activityId) async {
    debugPrint('🔄 UNENROLL: Starting unenrollment for activity $activityId');
    _clearError();
    if (!_enrolledActivityIds.contains(activityId)) {
      debugPrint('ℹ️ Not enrolled in activity $activityId');
      return true;
    }
    try {
      // Remove from local storage immediately (optimistic update)
      _enrolledActivityIds.remove(activityId);
      await _saveEnrolledActivitiesToStorage();
      // Update activity enrollment status
      _updateActivityEnrollmentStatus(activityId, isEnrolled: false);
      // Update user enrolled activities
      await _updateUserEnrolledActivities();
      // Notify listeners for immediate UI update
      notifyListeners();
      debugPrint('✅ UNENROLL: Local unenrollment completed');
      // 🔧 Sync with server using REAL USER ID
      final int userId = await _getCurrentUserId();
      debugPrint('🔑 Using user ID: $userId for unenrollment');
      
      final serverResponse = await ActivityService.withdrawFromActivity(
        activityId,
        userId,
      );
      if (serverResponse['success']) {
        debugPrint('✅ UNENROLL: Server unenrollment successful');
        _clearError();
        return true;
      } else {
        debugPrint('⚠️ UNENROLL: Server failed: ${serverResponse['error']}');
        _setError(
          'Unenrolled locally. Server sync failed: ${serverResponse['error']}',
        );
        return true; // Still return true since local unenrollment succeeded
      }
    } catch (e) {
      // If anything fails, revert the local change
      _enrolledActivityIds.add(activityId);
      _updateActivityEnrollmentStatus(activityId, isEnrolled: true);
      await _saveEnrolledActivitiesToStorage();
      await _updateUserEnrolledActivities();
      
      debugPrint('❌ UNENROLL: Unenrollment failed: $e');
      _setError('Failed to unenroll from activity: $e');
      notifyListeners();
      return false;
    }
  }

  // Update enrollment status for a specific activity
  void _updateActivityEnrollmentStatus(
    int activityId, {
    required bool isEnrolled,
  }) {
    final activityIndex = _activities.indexWhere((a) => a.id == activityId);
    if (activityIndex != -1) {
      final activity = _activities[activityIndex];
      _activities[activityIndex] = activity.copyWith(isEnrolled: isEnrolled);
      debugPrint('✅ Updated activity $activityId: isEnrolled=$isEnrolled');
    }
    // Update current activity if it matches
    if (_currentActivity?.id == activityId) {
      _currentActivity = _currentActivity!.copyWith(isEnrolled: isEnrolled);
    }
  }

  // ENHANCED: Check if user is enrolled in an activity with consistency check
  bool isEnrolledInActivity(int activityId) {
    final isEnrolledInSet = _enrolledActivityIds.contains(activityId);
    
    // Also check the activity object for consistency
    final activity = _activities.where((a) => a.id == activityId).firstOrNull;
    final isEnrolledInActivity = activity?.isEnrolled ?? false;
    if (isEnrolledInSet != isEnrolledInActivity) {
      debugPrint(
        '⚠️ INCONSISTENCY: Activity $activityId - Set: $isEnrolledInSet, Object: $isEnrolledInActivity',
      );
      // Trust the Set as the source of truth
      if (activity != null) {
        final index = _activities.indexWhere((a) => a.id == activityId);
        if (index != -1) {
          _activities[index] = activity.copyWith(isEnrolled: isEnrolledInSet);
          debugPrint('🔧 Fixed inconsistency for activity $activityId');
        }
      }
    }
    debugPrint('🔍 isEnrolledInActivity($activityId): $isEnrolledInSet');
    return isEnrolledInSet;
  }

  // QR CODE CHECK-IN METHOD
  Future<Map<String, dynamic>> checkInWithQR(String qrCode, int activityId) async {
    try {
      // Use your existing ActivityService pattern
      final response = await ActivityService.checkInWithQR(qrCode, activityId);
      
      if (response['success']) {
        // Success - user checked in
        return {
          'success': true,
          'message': response['message'] ?? 'Check-in successful',
          'activity_title': response['activity_title'],
          'activity_id': response['activity_id'],
          'checked_in_at': response['checked_in_at'],
        };
      } else {
        // Failed - return error message
        return {
          'success': false,
          'message': response['message'] ?? 'Check-in failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper methods
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

  String _extractErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Map) {
      if (error.containsKey('detail')) return error['detail'].toString();
      if (error.containsKey('message')) return error['message'].toString();
      if (error.containsKey('error')) return error['error'].toString();
      return error.toString();
    }
    return error.toString();
  }

  // Additional utility methods
  List<Activity> getJoinedActivities({int limit = 3}) {
    return _activities
        .where((activity) => _enrolledActivityIds.contains(activity.id))
        .take(limit)
        .toList();
  }

  List<Activity> getRecentActivities({int limit = 5}) {
    return _activities
        .where((activity) => activity.status == 'upcoming')
        .take(limit)
        .toList();
  }

  bool get hasEnrolledActivities => _enrolledActivityIds.isNotEmpty;

  int get enrolledActivitiesCount => _enrolledActivityIds.length;

  Future<void> clearAllData() async {
    _activities.clear();
    _myActivities.clear();
    _userEnrolledActivities.clear();
    _userCompletedActivities.clear();
    _userMissedActivities.clear();
    _enrolledActivityIds.clear();
    _currentActivity = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enrolledActivitiesKey);
    await prefs.remove(_userActivitiesKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_activitiesDataKey);
    notifyListeners();
  }

  // Debug method
  void debugProviderState() {
    debugPrint('🔍 === PROVIDER STATE DEBUG ===');
    debugPrint('🔍 Initialized: $_isInitialized');
    debugPrint('🔍 Loading: $_isLoading');
    debugPrint('🔍 Error: $_error');
    debugPrint('🔍 Enrolled IDs: $_enrolledActivityIds');
    debugPrint(
      '🔍 User enrolled activities: ${_userEnrolledActivities.length}',
    );
    for (var activity in _userEnrolledActivities) {
      debugPrint('🔍   - ${activity['title']} (ID: ${activity['id']})');
    }
    debugPrint('🔍 === END PROVIDER DEBUG ===');
  }

  // Additional utility methods
  List<Activity> searchActivities(String query) {
    return _activities
        .where(
          (activity) =>
              activity.title.toLowerCase().contains(query.toLowerCase()) ||
              activity.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  int getCurrentEnrollmentCount(int activityId) {
    try {
      final activity = _activities.firstWhere((a) => a.id == activityId);
      return activity.enrolledCount;
    } catch (e) {
      return 0;
    }
  }

  bool isUserEnrolled(Activity activity, int userId) {
    return _enrolledActivityIds.contains(activity.id);
  }

  int getEnrollmentCount(Activity activity) {
    return activity.enrolledCount;
  }

  bool get hasActivities => _activities.isNotEmpty;

  // Load activity details
  Future<void> loadActivityDetail(int id) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await ActivityService.getActivityDetails(id);
      if (response['success']) {
        _currentActivity = response['data'] as Activity;
        final isEnrolled = _enrolledActivityIds.contains(id);
        _currentActivity = _currentActivity!.copyWith(isEnrolled: isEnrolled);
        _updateActivityInList(_currentActivity!);
      } else {
        _setError(_extractErrorMessage(response['error']));
      }
    } catch (e) {
      _setError('Failed to load activity details: $e');
    }
    _setLoading(false);
  }

  // Update activity in lists
  void _updateActivityInList(Activity updatedActivity) {
    final index = _activities.indexWhere((a) => a.id == updatedActivity.id);
    if (index != -1) {
      _activities[index] = updatedActivity;
    }
    final myIndex = _myActivities.indexWhere((a) => a.id == updatedActivity.id);
    if (myIndex != -1) {
      _myActivities[myIndex] = updatedActivity;
    }
  }

  // 🔧 ENHANCED: Fetch user activities by category with database sync
  Future<void> fetchUserActivities(dynamic userId) async {
    debugPrint('🔄 FETCH USER ACTIVITIES: Starting...');
    if (!_isInitialized) {
      debugPrint(
        '🔄 FETCH USER ACTIVITIES: Provider not initialized, initializing...',
      );
      await initialize();
      return;
    }
    debugPrint('🔄 FETCH USER ACTIVITIES: Enrolled IDs: $_enrolledActivityIds');
    debugPrint(
      '🔄 FETCH USER ACTIVITIES: Current enrolled activities: ${_userEnrolledActivities.length}',
    );
    // 🆕 Load fresh data from database
    await _loadRealEnrolledActivitiesFromDatabase();
    await _updateUserEnrolledActivities();
    _userCompletedActivities.clear();
    _userMissedActivities.clear();
    debugPrint('📋 FETCH USER ACTIVITIES: Final state:');
    debugPrint('  - Enrolled: ${_userEnrolledActivities.length}');
    debugPrint('  - Completed: ${_userCompletedActivities.length}');
    debugPrint('  - Missed: ${_userMissedActivities.length}');
    notifyListeners();
  }

  // Force refresh - clears cache and reloads everything
  Future<void> refresh() async {
    _clearError();
    await loadActivities();
    // 🆕 Also refresh enrolled activities from database
    await _loadRealEnrolledActivitiesFromDatabase();
  }

  // Sync with server
  Future<void> syncWithServer() async {
    debugPrint('🔄 Syncing with server...');
    await loadActivities();
    await _loadRealEnrolledActivitiesFromDatabase();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Create/Update activity methods (for coordinators)
  Future<bool> createActivity(dynamic activityRequest) async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: Implement actual activity creation with ActivityService
      // final response = await ActivityService.createActivity(activityRequest);
      // For now, simulate the creation
      await Future.delayed(Duration(seconds: 1));
      // Show that it's not yet implemented
      _setError('Create activity feature is being implemented');
      // Refresh activities list to show any changes
      await loadActivities();
      return false; // Return false until actual implementation
    } catch (e) {
      _setError('Failed to create activity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateActivity(int id, dynamic activityRequest) async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: Implement actual activity update with ActivityService
      // final response = await ActivityService.updateActivity(id, activityRequest);
      // For now, simulate the update
      await Future.delayed(Duration(seconds: 1));
      // Show that it's not yet implemented
      _setError('Update activity feature is being implemented');
      // Refresh activities list and current activity
      await loadActivities();
      if (_currentActivity?.id == id) {
        await loadActivityDetail(id);
      }
      return false; // Return false until actual implementation
    } catch (e) {
      _setError('Failed to update activity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Legacy compatibility methods
  Future<void> fetchActivities() async => await loadActivities();
  Future<bool> enrollInActivity(int activityId) async =>
      await enrollActivity(activityId);
  Future<bool> withdrawFromActivity(int activityId) async =>
      await unenrollActivity(activityId);
}
