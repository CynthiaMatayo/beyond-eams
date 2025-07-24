// lib/providers/volunteer_provider.dart - COMPLETE FIXED VERSION WITH REAL DATABASE SYNC
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VolunteerApplication {
  final String id;
  final int activityId;
  final String activityTitle;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final double hoursCompleted;
  final String appliedDate;
  final String? completedDate;
  final String? description;
  final String? location;
  final String? requirements;

  VolunteerApplication({
    required this.id,
    required this.activityId,
    required this.activityTitle,
    required this.status,
    this.hoursCompleted = 0.0,
    required this.appliedDate,
    this.completedDate,
    this.description,
    this.location,
    this.requirements,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'activityTitle': activityTitle,
      'status': status,
      'hoursCompleted': hoursCompleted,
      'appliedDate': appliedDate,
      'completedDate': completedDate,
      'description': description,
      'location': location,
      'requirements': requirements,
    };
  }

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: json['id'] ?? '',
      activityId: json['activityId'] ?? 0,
      activityTitle: json['activityTitle'] ?? '',
      status: json['status'] ?? 'pending',
      hoursCompleted: (json['hoursCompleted'] ?? 0.0).toDouble(),
      appliedDate: json['appliedDate'] ?? '',
      completedDate: json['completedDate'],
      description: json['description'],
      location: json['location'],
      requirements: json['requirements'],
    );
  }

  VolunteerApplication copyWith({
    String? id,
    int? activityId,
    String? activityTitle,
    String? status,
    double? hoursCompleted,
    String? appliedDate,
    String? completedDate,
    String? description,
    String? location,
    String? requirements,
  }) {
    return VolunteerApplication(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activityTitle: activityTitle ?? this.activityTitle,
      status: status ?? this.status,
      hoursCompleted: hoursCompleted ?? this.hoursCompleted,
      appliedDate: appliedDate ?? this.appliedDate,
      completedDate: completedDate ?? this.completedDate,
      description: description ?? this.description,
      location: location ?? this.location,
      requirements: requirements ?? this.requirements,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  String get formattedDate {
    try {
      final date = DateTime.parse(appliedDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return appliedDate;
    }
  }

  get estimatedHours => null;
}

class VolunteerProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  List<VolunteerApplication> _myApplications = [];
  SharedPreferences? _prefs;

  // Constants for SharedPreferences keys
  static const String _applicationsKey = 'volunteer_applications_v2';
  static const String _lastSyncKey = 'volunteer_last_sync_v2';
  // 🔧 FIXED: Use consistent URL with ActivityService
  static const String baseUrl = 'http://localhost:8000/api';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<VolunteerApplication> get myApplications => _myApplications;

  // Filter applications by status
  List<VolunteerApplication> get pendingApplications =>
      _myApplications.where((app) => app.status == 'pending').toList();
  List<VolunteerApplication> get acceptedApplications =>
      _myApplications.where((app) => app.status == 'approved').toList();
  List<VolunteerApplication> get rejectedApplications =>
      _myApplications.where((app) => app.status == 'rejected').toList();
  List<VolunteerApplication> get completedApplications =>
      _myApplications.where((app) => app.status == 'completed').toList();

  // Calculate total hours
  double get totalVolunteerHours => _myApplications
      .where((app) => app.status == 'completed')
      .fold(0.0, (sum, app) => sum + app.hoursCompleted);

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
        debugPrint('✅ VolunteerProvider: Found user ID: $userId');
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
            debugPrint('✅ VolunteerProvider: Found user ID from user data: $userIdFromData');
            return userIdFromData;
          }
        } catch (e) {
          debugPrint('❌ VolunteerProvider: Error parsing user data: $e');
        }
      }
      
      debugPrint('⚠️ VolunteerProvider: No user ID found, using fallback ID 1');
      return 1; // Fallback
    } catch (e) {
      debugPrint('❌ VolunteerProvider: Error getting user ID: $e');
      return 1; // Fallback
    }
  }

  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ VolunteerProvider already initialized');
      return;
    }

    debugPrint('🚀 Initializing VolunteerProvider...');
    _setLoading(true);

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load from local storage first for immediate UI
      await _loadApplicationsFromStorage();
      
      // 🆕 Then load real applications from database
      await _loadRealApplicationsFromDatabase();
      
      _isInitialized = true;
      debugPrint('✅ VolunteerProvider initialized successfully');
      debugPrint('📋 Total applications: ${_myApplications.length}');
    } catch (e) {
      debugPrint('❌ VolunteerProvider initialization failed: $e');
      _setError('Failed to initialize: $e');
      _isInitialized = true; // Still mark as initialized to prevent retry
    }

    _setLoading(false);
    notifyListeners();
  }

  // 🆕 NEW: Load real volunteer applications from Django database on startup
  Future<void> _loadRealApplicationsFromDatabase() async {
    try {
      final userId = await _getCurrentUserId();
      debugPrint('🔄 Loading real volunteer applications from database for user $userId...');
      
      // Call Django endpoint to get volunteer applications
      final response = await http.get(
        Uri.parse('$baseUrl/student-volunteer-applications/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['volunteer_applications'] != null) {
          final applications = data['volunteer_applications'] as List<dynamic>;
          
          // Convert Django applications to local format
          List<VolunteerApplication> databaseApplications = [];
          for (var app in applications) {
            try {
              final localApp = VolunteerApplication(
                id: app['id'].toString(),
                activityId: app['opportunity_id'] ?? 0, // Use opportunity_id as activityId
                activityTitle: app['opportunity_title'] ?? 'Volunteer Task',
                status: app['status'] ?? 'pending',
                hoursCompleted: (app['hours_completed'] ?? 0.0).toDouble(),
                appliedDate: app['submitted_at'] ?? DateTime.now().toIso8601String(),
                description: 'Volunteer application',
                location: 'Campus',
              );
              databaseApplications.add(localApp);
            } catch (e) {
              debugPrint('❌ Error parsing application: $e');
            }
          }
          
          // Merge database applications with local ones (database takes precedence)
          final Set<String> databaseIds = databaseApplications.map((app) => app.id).toSet();
          final localApplicationsNotInDatabase = _myApplications.where(
            (app) => !databaseIds.contains(app.id)
          ).toList();
          
          _myApplications = [...databaseApplications, ...localApplicationsNotInDatabase];
          
          // Save merged applications to storage
          await _saveApplicationsToStorage();
          
          debugPrint('✅ Loaded ${databaseApplications.length} applications from database');
          debugPrint('📱 Total applications after merge: ${_myApplications.length}');
        }
      } else {
        debugPrint('⚠️ Database API call failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading applications from database: $e');
      // Don't throw error - continue with local data
    }
  }

  // REQUIRED METHOD: Load my applications (called by your screens)
  Future<void> loadMyApplications() async {
    debugPrint('🔄 Loading my applications...');
    _setLoading(true);
    _clearError();

    try {
      await _loadApplicationsFromStorage();
      // 🆕 Also load from database
      await _loadRealApplicationsFromDatabase();
      debugPrint('✅ Loaded ${_myApplications.length} applications');
    } catch (e) {
      debugPrint('❌ Error loading applications: $e');
      _setError('Failed to load applications: $e');
    }

    _setLoading(false);
    notifyListeners();
  }

  // UPDATED: Load pending applications for instructor review - with database sync
  Future<void> loadPendingApplications() async {
    debugPrint('🔄 Loading pending applications for instructor review...');
    _setLoading(true);
    _clearError();

    try {
      // Load from local storage first
      await _loadApplicationsFromStorage();
      // 🆕 Then sync with database
      await _loadRealApplicationsFromDatabase();
      
      debugPrint('✅ Loaded ${pendingApplications.length} pending applications');
    } catch (e) {
      debugPrint('❌ Error loading pending applications: $e');
      _setError('Failed to load pending applications: $e');
    }

    _setLoading(false);
    notifyListeners();
  }

  // Load applications from storage
  Future<void> _loadApplicationsFromStorage() async {
    try {
      final applicationsJson = _prefs?.getStringList(_applicationsKey) ?? [];
      _myApplications =
          applicationsJson
              .map((jsonString) {
                try {
                  final json = jsonDecode(jsonString);
                  return VolunteerApplication.fromJson(json);
                } catch (e) {
                  debugPrint('❌ Error parsing application JSON: $e');
                  return null;
                }
              })
              .where((app) => app != null)
              .cast<VolunteerApplication>()
              .toList();
      
      debugPrint(
        '📱 Loaded ${_myApplications.length} applications from storage',
      );
    } catch (e) {
      debugPrint('❌ Error loading applications from storage: $e');
      _myApplications = [];
    }
  }

  // Save applications to storage
  Future<void> _saveApplicationsToStorage() async {
    try {
      final applicationsJson =
          _myApplications.map((app) => jsonEncode(app.toJson())).toList();
      await _prefs?.setStringList(_applicationsKey, applicationsJson);
      await _prefs?.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 Saved ${_myApplications.length} applications to storage');
    } catch (e) {
      debugPrint('❌ Error saving applications to storage: $e');
    }
  }

  // 🔧 ENHANCED: Apply for volunteer position with real user ID and database sync
  Future<bool> applyForVolunteerPosition(
    int activityId, // BACK TO: activityId (what students see)
    String activityTitle, {
    String? description,
    String? location,
  }) async {
    try {
      // Check if already applied locally
      final existingApplication =
          _myApplications.any((app) => app.activityId == activityId);
      if (existingApplication) {
        debugPrint('ℹ️ Already applied for activity $activityId');
        _setError('You have already applied for this position');
        return false;
      }

      // STEP 1: Get the opportunity ID for this activity
      final opportunityResponse = await http.get(
        Uri.parse('$baseUrl/volunteering/by-activity/$activityId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (opportunityResponse.statusCode != 200) {
        debugPrint('❌ No volunteer opportunity found for activity $activityId');
        _setError(
          'This activity does not have volunteer opportunities available',
        );
        return false;
      }

      final opportunityData = jsonDecode(opportunityResponse.body);
      final opportunityId = opportunityData['opportunity_id'];
      debugPrint('✅ Found opportunity $opportunityId for activity $activityId');

      // 🔧 STEP 2: Apply using the correct opportunity ID and REAL USER ID
      final userId = await _getCurrentUserId();
      debugPrint('🔑 Applying with user ID: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/volunteering/apply/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, // 🔧 FIXED: Use real user ID instead of hardcoded 1
          'opportunity_id': opportunityId, // Use the correct opportunity ID
          'first_name': 'John',
          'last_name': 'Matayo',
          'email': 'john.matayo@ueab.ac.ke',
          'student_id': 'REG0001',
          'phone_primary': '+254700000000',
          'department': 'Computer Science',
          'academic_year': '2024',
          'interest_reason': description ?? 'I am interested in volunteering',
          'skills_experience': 'Willing to learn and contribute',
          'availability': 'Flexible schedule',
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint(
          '✅ Backend application successful: ${responseData['message']}',
        );

        // Save locally (keep using activityId for local storage consistency)
        final newApplication = VolunteerApplication(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          activityId: activityId, // Store original activity ID
          activityTitle: activityTitle,
          status: 'pending',
          appliedDate: DateTime.now().toIso8601String(),
          description: description ?? 'Volunteer position application',
          location: location ?? 'Campus',
        );

        _myApplications.add(newApplication);
        await _saveApplicationsToStorage();
        _clearError();
        notifyListeners();

        debugPrint(
          '✅ Applied for volunteer position: $activityTitle (Activity: $activityId, Opportunity: $opportunityId)',
        );
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('❌ Backend error: ${errorData['error']}');
        _setError('Failed to apply: ${errorData['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error applying for volunteer position: $e');
      _setError('Failed to apply for position: $e');
      return false;
    }
  }

  // REQUIRED METHOD: Log volunteer hours (called by your screens)
  Future<void> logVolunteerHours(String applicationId, double hours) async {
    debugPrint('🔄 Logging $hours hours for application $applicationId');
    try {
      final index = _myApplications.indexWhere(
        (app) => app.id == applicationId,
      );
      if (index == -1) {
        debugPrint('❌ Application not found: $applicationId');
        _setError('Application not found');
        return;
      }

      _myApplications[index] = _myApplications[index].copyWith(
        hoursCompleted: _myApplications[index].hoursCompleted + hours,
        status: 'completed',
        completedDate: DateTime.now().toIso8601String(),
      );

      await _saveApplicationsToStorage();
      _clearError();
      notifyListeners();

      debugPrint('✅ Logged $hours hours for application $applicationId');
    } catch (e) {
      debugPrint('❌ Error logging volunteer hours: $e');
      _setError('Failed to log hours: $e');
    }
  }

  // REQUIRED METHOD: Withdraw application (called by your screens)
  Future<void> withdrawApplication(String applicationId) async {
    debugPrint('🔄 Withdrawing application $applicationId');
    try {
      final index = _myApplications.indexWhere(
        (app) => app.id == applicationId,
      );
      if (index == -1) {
        debugPrint('❌ Application not found: $applicationId');
        _setError('Application not found');
        return;
      }

      // Only allow withdrawal of pending applications
      if (_myApplications[index].status != 'pending') {
        _setError('Can only withdraw pending applications');
        return;
      }

      _myApplications.removeAt(index);
      await _saveApplicationsToStorage();
      _clearError();
      notifyListeners();

      debugPrint('✅ Withdrew application $applicationId');
    } catch (e) {
      debugPrint('❌ Error withdrawing application: $e');
      _setError('Failed to withdraw application: $e');
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    double? hoursCompleted,
  }) async {
    try {
      final index = _myApplications.indexWhere(
        (app) => app.id == applicationId,
      );
      if (index == -1) {
        debugPrint('❌ Application not found: $applicationId');
        return;
      }

      _myApplications[index] = _myApplications[index].copyWith(
        status: status,
        hoursCompleted: hoursCompleted ?? _myApplications[index].hoursCompleted,
        completedDate:
            status == 'completed' ? DateTime.now().toIso8601String() : null,
      );

      await _saveApplicationsToStorage();
      notifyListeners();

      debugPrint('✅ Updated application $applicationId status to $status');
    } catch (e) {
      debugPrint('❌ Error updating application status: $e');
    }
  }

  // NEW METHOD: Approve volunteer application (for instructors)
  Future<bool> approveApplication(
    String applicationId, {
    double? hoursToApprove,
  }) async {
    debugPrint('🔄 Approving application $applicationId');
    try {
      final index = _myApplications.indexWhere(
        (app) => app.id == applicationId,
      );
      if (index == -1) {
        debugPrint('❌ Application not found: $applicationId');
        _setError('Application not found');
        return false;
      }

      // Update application status to approved
      _myApplications[index] = _myApplications[index].copyWith(
        status: 'approved',
        hoursCompleted: hoursToApprove ?? _myApplications[index].hoursCompleted,
      );

      await _saveApplicationsToStorage();
      notifyListeners();

      debugPrint('✅ Approved application $applicationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error approving application: $e');
      _setError('Failed to approve application: $e');
      return false;
    }
  }

  // NEW METHOD: Reject volunteer application (for instructors)
  Future<bool> rejectApplication(String applicationId, {String? reason}) async {
    debugPrint('🔄 Rejecting application $applicationId');
    try {
      final index = _myApplications.indexWhere(
        (app) => app.id == applicationId,
      );
      if (index == -1) {
        debugPrint('❌ Application not found: $applicationId');
        _setError('Application not found');
        return false;
      }

      // Update application status to rejected
      _myApplications[index] = _myApplications[index].copyWith(
        status: 'rejected',
      );

      await _saveApplicationsToStorage();
      notifyListeners();

      debugPrint('✅ Rejected application $applicationId');
      if (reason != null) {
        debugPrint('💬 Rejection reason: $reason');
      }
      return true;
    } catch (e) {
debugPrint('❌ Error rejecting application: $e');
      _setError('Failed to reject application: $e');
      return false;
    }
  }

  // Check if user has applied for activity
  bool hasAppliedForActivity(int activityId) {
    return _myApplications.any((app) => app.activityId == activityId);
  }

  // Get application for activity
  VolunteerApplication? getApplicationForActivity(int activityId) {
    try {
      return _myApplications.firstWhere((app) => app.activityId == activityId);
    } catch (e) {
      return null;
    }
  }

  // Get application by ID
  VolunteerApplication? getApplicationById(String applicationId) {
    try {
      return _myApplications.firstWhere((app) => app.id == applicationId);
    } catch (e) {
      return null;
    }
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalApplications': _myApplications.length,
      'pendingApplications': pendingApplications.length,
      'approvedApplications': acceptedApplications.length,
      'completedApplications': completedApplications.length,
      'rejectedApplications': rejectedApplications.length,
      'totalHours': totalVolunteerHours,
    };
  }

  // 🔧 ENHANCED: Refresh data with database sync
  Future<void> refresh() async {
    await loadMyApplications();
    // 🆕 Also refresh from database
    await _loadRealApplicationsFromDatabase();
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    _myApplications.clear();
    _isInitialized = false;
    _isLoading = false;
    _error = null;

    await _prefs?.remove(_applicationsKey);
    await _prefs?.remove(_lastSyncKey);

    notifyListeners();
    debugPrint('🗑️ Cleared all volunteer data');
  }

  // Helper methods for state management
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

  // Additional helper methods for compatibility
  List<VolunteerApplication> getApplicationsByStatus(String status) {
    return _myApplications.where((app) => app.status == status).toList();
  }

  int getApplicationsCountByStatus(String status) {
    return getApplicationsByStatus(status).length;
  }

  bool canApplyForMore({int maxApplications = 5}) {
    final activeApplications =
        _myApplications
            .where((app) => app.status == 'pending' || app.status == 'approved')
            .length;
    return activeApplications < maxApplications;
  }

  List<VolunteerApplication> getRecentApplications() {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    return _myApplications.where((app) {
      try {
        final appliedDate = DateTime.parse(app.appliedDate);
        return appliedDate.isAfter(thirtyDaysAgo);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  double getHoursThisMonth() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _myApplications
        .where((app) => app.status == 'completed' && app.completedDate != null)
        .where((app) {
          try {
            final completedDate = DateTime.parse(app.completedDate!);
            return completedDate.isAfter(firstDayOfMonth);
          } catch (e) {
            return false;
          }
        })
        .fold(0.0, (sum, app) => sum + app.hoursCompleted);
  }

  String getVolunteerRank() {
    final hours = totalVolunteerHours;
    if (hours >= 100) return 'Master Volunteer';
    if (hours >= 50) return 'Senior Volunteer';
    if (hours >= 20) return 'Active Volunteer';
    if (hours >= 5) return 'Volunteer';
    return 'New Volunteer';
  }

  Map<String, dynamic> getNextMilestone() {
    final hours = totalVolunteerHours;
    if (hours < 5) {
      return {'title': 'Volunteer', 'hours': 5, 'remaining': 5 - hours};
    } else if (hours < 20) {
      return {
        'title': 'Active Volunteer',
        'hours': 20,
        'remaining': 20 - hours,
      };
    } else if (hours < 50) {
      return {
        'title': 'Senior Volunteer',
        'hours': 50,
        'remaining': 50 - hours,
      };
    } else if (hours < 100) {
      return {
        'title': 'Master Volunteer',
        'hours': 100,
        'remaining': 100 - hours,
      };
    } else {
      return {'title': 'Master Volunteer', 'hours': 100, 'remaining': 0};
    }
  }

  // Debug method
  void debugProviderState() {
    debugPrint('🔍 === VOLUNTEER PROVIDER STATE DEBUG ===');
    debugPrint('🔍 Initialized: $_isInitialized');
    debugPrint('🔍 Loading: $_isLoading');
    debugPrint('🔍 Error: $_error');
    debugPrint('🔍 Applications: ${_myApplications.length}');
    debugPrint('🔍 Pending: ${pendingApplications.length}');
    debugPrint('🔍 Approved: ${acceptedApplications.length}');
    debugPrint('🔍 Completed: ${completedApplications.length}');
    debugPrint('🔍 Total Hours: $totalVolunteerHours');
    for (var app in _myApplications) {
      debugPrint(
        '🔍   - ${app.activityTitle} (Status: ${app.status}, Hours: ${app.hoursCompleted})',
      );
    }
    debugPrint('🔍 === END VOLUNTEER DEBUG ===');
  }

  // Simulate methods for testing
  Future<void> simulateAcceptApplication(
    String applicationId, {
    double hours = 5.0,
  }) async {
    await updateApplicationStatus(applicationId, 'approved');
    await Future.delayed(Duration(seconds: 1));
    await updateApplicationStatus(
      applicationId,
      'completed',
      hoursCompleted: hours,
    );
  }

  Future<void> simulateRejectApplication(String applicationId) async {
    await updateApplicationStatus(applicationId, 'rejected');
  }
}
