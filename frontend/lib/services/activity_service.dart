// lib/services/activity_service.dart - COMPLETE FIXED VERSION
import 'dart:convert';
import 'package:frontend/services/export_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class ActivityService {
  // ✅ FIXED: Correct base URL - remove /activities to avoid double path
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration timeoutDuration = Duration(seconds: 15);

  // Helper method to get authentication token
  static Future<String?> _getAuthToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token =
          prefs.getString('access_token') ??
          prefs.getString('auth_token') ??
          prefs.getString('jwt_token') ??
          prefs.getString('token');
      if (token != null) {
        debugPrint('🔑 Found auth token: ${token.substring(0, 20)}...');
      } else {
        debugPrint('⚠️ No auth token found');
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null;
    }
  }

  // Helper method to get current user ID from token or storage
  static Future<int?> _getCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId =
          prefs.getInt('user_id') ??
          prefs.getInt('current_user_id') ??
          prefs.getInt('logged_in_user_id') ??
          prefs.getInt('id');
      if (userId != null) {
        debugPrint('✅ Found user ID from storage: $userId');
        return userId;
      }
      String? userDataString =
          prefs.getString('user_data') ??
          prefs.getString('current_user') ??
          prefs.getString('auth_user') ??
          prefs.getString('user');
      if (userDataString != null) {
        try {
          Map<String, dynamic> userData = json.decode(userDataString);
          int? userIdFromData =
              userData['id'] ?? userData['user_id'] ?? userData['userId'];
          if (userIdFromData != null) {
            debugPrint('✅ Found user ID from user data: $userIdFromData');
            return userIdFromData;
          }
        } catch (e) {
          debugPrint('❌ Error parsing user data: $e');
        }
      }
      debugPrint('⚠️ No user ID found, using fallback ID 1');
      return 1;
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return 1;
    }
  }

  static Future<Map<String, String>> _getHeaders({
    bool requireAuth = false,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      String? token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else if (requireAuth) {
        throw Exception('Authentication token required but not found');
      }
    }
    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('📡 Response status: ${response.statusCode}');
    debugPrint(
      '📡 Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } catch (e) {
        debugPrint('❌ JSON decode error: $e');
        return {
          'success': false,
          'error': {
            'message': 'Invalid response format from server',
            'details': response.body,
            'status_code': response.statusCode,
          },
        };
      }
    } else {
      try {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': {
            'message': _extractErrorMessage(error),
            'details': error,
            'status_code': response.statusCode,
          },
        };
      } catch (e) {
        return {
          'success': false,
          'error': {
            'message': 'Server error (${response.statusCode})',
            'details': response.body,
            'status_code': response.statusCode,
          },
        };
      }
    }
  }

  static String _extractErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Map) {
      if (error.containsKey('detail')) return error['detail'].toString();
      if (error.containsKey('message')) return error['message'].toString();
      if (error.containsKey('error')) return error['error'].toString();
      return error.toString();
    }
    return error.toString();
  }

  // ✅ FIXED: Get all activities - correct URL
  static Future<Map<String, dynamic>> getAllActivities({
    int retryCount = 0,
  }) async {
    try {
      // ✅ FIXED: Use correct endpoint - remove duplicate api/
      final url = '$baseUrl/coordinator/activities/';
      debugPrint('🔍 ACTIVITY_SERVICE getAllActivities URL: $url');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        dynamic activitiesData = result['data'];
        List activities;
        if (activitiesData is Map && activitiesData.containsKey('data')) {
          activities = activitiesData['data'] as List;
        } else if (activitiesData is List) {
          activities = activitiesData;
        } else {
          activities = [];
        }
        debugPrint('✅ Fetched ${activities.length} activities successfully');
        return {'success': true, 'data': activities};
      } else {
        debugPrint('❌ API failed: ${result['error']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error fetching activities: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to connect to server. Please try again later.',
          'type': 'connection_error',
          'details': e.toString(),
        },
      };
    }
  }

  // ✅ FIXED: Get activities with enrollment status
  static Future<Map<String, dynamic>> getActivitiesWithEnrollmentStatus({
    int? userId,
  }) async {
    try {
      userId ??= await _getCurrentUserId();

      // ✅ FIXED: Correct URL should be /api/activities/ (not double activities)
      final url = '$baseUrl/activities/?user_id=$userId';
      debugPrint('🔍 ACTIVITY_SERVICE getActivitiesWithEnrollmentStatus URL: $url');

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);

      final result = _handleResponse(response);

      if (result['success']) {
        dynamic responseData = result['data'];
        List<dynamic> activitiesJson;

        // Handle different response formats
        if (responseData is Map) {
          if (responseData.containsKey('data')) {
            activitiesJson = responseData['data'] as List;
          } else if (responseData.containsKey('activities')) {
            activitiesJson = responseData['activities'] as List;
          } else {
            activitiesJson = [responseData]; // Single activity
          }
        } else if (responseData is List) {
          activitiesJson = responseData;
        } else {
          throw Exception('Unexpected response format');
        }

        // ✅ FIXED: Convert to Activity objects with type safety
        List<Activity> activities = [];
        for (var activityJson in activitiesJson) {
          try {
            if (activityJson is Map<String, dynamic>) {
              final activity = Activity.fromJson(activityJson);
              activities.add(activity);
            }
          } catch (e) {
            debugPrint('❌ Error parsing activity: $e');
            debugPrint('❌ Problematic JSON: $activityJson');
            continue; // Skip invalid activities
          }
        }

        debugPrint(
          '✅ Successfully parsed ${activities.length} activities with enrollment status',
        );
        // Return the raw JSON data, not Activity objects, so the provider can handle parsing
        return {'success': true, 'data': activitiesJson};
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error getting activities with enrollment status: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load activities',
          'type': 'connection_error',
          'details': e.toString(),
        },
      };
    }
  }

  // ✅ FIXED: Get student enrolled activities
  static Future<Map<String, dynamic>> getStudentEnrolledActivities(
    int? userId,
  ) async {
    try {
      userId ??= await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': {
            'message': 'User ID not found. Please log in again.',
            'type': 'auth_error',
          },
        };
      }
      // ✅ FIXED: Correct endpoint pattern - remove /activities/ prefix
      final url = '$baseUrl/student-enrolled/?user_id=$userId';
      debugPrint('🔍 ENROLLED ACTIVITIES URL: $url');
      final headers = await _getHeaders(requireAuth: false);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        final data = result['data'];
        if (data is Map && data.containsKey('enrolled_activities')) {
          return {'success': true, 'data': data['enrolled_activities']};
        }
        return result;
      } else {
        debugPrint('❌ Failed to get enrolled activities: ${result['error']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error getting enrolled activities: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load enrolled activities.',
          'type': 'enrolled_activities_error',
          'details': e.toString(),
        },
      };
    }
  }

  // ✅ FIXED: Get recent activities with proper typing
  static Future<Map<String, dynamic>> getRecentActivitiesTyped({
    int? userId,
    int limit = 10,
  }) async {
    try {
      userId ??= await _getCurrentUserId();

      final url = '$baseUrl/student-recent/?user_id=$userId&limit=$limit';
      debugPrint('🔍 RECENT ACTIVITIES TYPED URL: $url');

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);

      final result = _handleResponse(response);

      if (result['success']) {
        final data = result['data'];
        List<dynamic> recentActivitiesJson;

        if (data is Map && data.containsKey('recent_activities')) {
          recentActivitiesJson = data['recent_activities'] as List;
        } else if (data is List) {
          recentActivitiesJson = data;
        } else {
          recentActivitiesJson = [];
        }

        // ✅ FIXED: Convert to Activity objects (not RecentActivity)
        List<Activity> recentActivities = [];
        for (var activityJson in recentActivitiesJson) {
          try {
            if (activityJson is Map<String, dynamic>) {
              // Add any missing required fields for Activity.fromJson
              if (!activityJson.containsKey('created_by')) {
                activityJson['created_by'] = 0;
              }
              if (!activityJson.containsKey('created_by_name')) {
                activityJson['created_by_name'] = 'Unknown';
              }
              if (!activityJson.containsKey('created_at')) {
                activityJson['created_at'] = DateTime.now().toIso8601String();
              }
              if (!activityJson.containsKey('is_volunteering')) {
                activityJson['is_volunteering'] = false;
              }

              final activity = Activity.fromJson(activityJson);
              recentActivities.add(activity);
            }
          } catch (e) {
            debugPrint('❌ Error parsing recent activity: $e');
            debugPrint('❌ Problematic JSON: $activityJson');
            continue;
          }
        }

        debugPrint(
          '✅ Successfully parsed ${recentActivities.length} recent activities',
        );
        return {'success': true, 'data': recentActivities};
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error getting recent activities: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load recent activities',
          'type': 'connection_error',
          'details': e.toString(),
        },
      };
    }
  }

  // Export activities with corrected URL
  static Future<Map<String, dynamic>> exportActivitiesFromBackend({
    int? coordinatorId,
  }) async {
    try {
      // ✅ FIXED: Build URL for backend export endpoint
      String url = '$baseUrl/coordinator/activities/';
      if (coordinatorId != null) {
        url += '?coordinator_id=$coordinatorId';
      }
      debugPrint('🔄 Exporting activities from: $url');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        // Parse activities from response
        final activities = _parseActivitiesFromResponse(result['data']);
        if (activities.isEmpty) {
          return {
            'success': false,
            'error': {
              'message': 'No activities found to export',
              'type': 'no_data',
            },
          };
        }
        debugPrint('✅ Found ${activities.length} activities to export');
        // Export using ExportService
        await ExportService.exportActivities(activities);
        return {
          'success': true,
          'message': 'Activities exported successfully',
          'count': activities.length,
        };
      } else {
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error exporting activities: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to export activities',
          'type': 'export_error',
          'details': e.toString(),
        },
      };
    }
  }

  // Helper method to safely parse activities from API responses
  static List<Activity> _parseActivitiesFromResponse(dynamic responseData) {
    List<Activity> activities = [];
    try {
      List<dynamic> activitiesJson;
      if (responseData is List) {
        activitiesJson = responseData;
      } else if (responseData is Map) {
        if (responseData.containsKey('data')) {
          activitiesJson = responseData['data'] as List;
        } else if (responseData.containsKey('activities')) {
          activitiesJson = responseData['activities'] as List;
        } else {
          activitiesJson = [responseData];
        }
      } else {
        throw Exception('Invalid response format');
      }
      for (var activityJson in activitiesJson) {
        try {
          if (activityJson is Map<String, dynamic>) {
            final activity = Activity.fromJson(activityJson);
            activities.add(activity);
          }
        } catch (e) {
          debugPrint('❌ Error parsing individual activity: $e');
          debugPrint('❌ Problematic JSON: $activityJson');
          continue; // Skip malformed activities
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _parseActivitiesFromResponse: $e');
    }
    return activities;
  }

  // ✅ FIXED: Get activities with proper type conversion
  static Future<Map<String, dynamic>> getActivitiesTyped() async {
    try {
      final result = await getAllActivities();
      if (result['success']) {
        final activities = _parseActivitiesFromResponse(result['data']);
        return {'success': true, 'data': activities};
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error in getActivitiesTyped: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load activities',
          'type': 'parsing_error',
          'details': e.toString(),
        },
      };
    }
  }

  // ✅ FIXED: Enroll in activity
  static Future<Map<String, dynamic>> enrollInActivity(
    int activityId,
    int userId,
  ) async {
    try {
      final url = '$baseUrl/activities/$activityId/enroll/';
      debugPrint('🔍 ENROLLMENT URL: $url');
      debugPrint('📡 Enrolling user $userId in activity $activityId');
      final headers = await _getHeaders(requireAuth: false);
      Map<String, dynamic> requestBody = {
        'user_id': userId,
        'activity_id': activityId,
      };
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        debugPrint('✅ Successfully enrolled in activity $activityId');
        return result;
      } else {
        debugPrint('❌ Enrollment failed: ${result['error']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error enrolling in activity: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to enroll in activity. Please try again later.',
          'type': 'enrollment_error',
          'activity_id': activityId,
          'details': e.toString(),
        },
      };
    }
  }

  // Withdraw from activity
  static Future<Map<String, dynamic>> withdrawFromActivity(
    int activityId,
    int userId,
  ) async {
    try {
      final url = '$baseUrl/activities/$activityId/enroll/';
      debugPrint('🔍 WITHDRAWAL URL: $url');
      debugPrint('📡 Withdrawing user $userId from activity $activityId');
      final headers = await _getHeaders(requireAuth: false);
      Map<String, dynamic> requestBody = {
        'user_id': userId,
        'activity_id': activityId,
      };
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        debugPrint('✅ Successfully withdrew from activity $activityId');
        return result;
      } else {
        debugPrint('❌ Withdrawal failed: ${result['error']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error withdrawing from activity: $e');
      return {
        'success': false,
        'error': {
          'message':
              'Failed to withdraw from activity. Please try again later.',
          'type': 'withdrawal_error',
          'activity_id': activityId,
          'details': e.toString(),
        },
      };
    }
  }

  // Get activity details
  static Future<Map<String, dynamic>> getActivityDetails(int id) async {
    try {
      final url = '$baseUrl/activities/$id/';
      debugPrint('🔍 ACTIVITY DETAILS URL: $url');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        try {
          final activity = Activity.fromJson(
            result['data'] as Map<String, dynamic>,
          );
          return {'success': true, 'data': activity};
        } catch (e) {
          debugPrint('❌ Error parsing activity data: $e');
          return {
            'success': false,
            'error': {
              'message': 'Invalid activity data from server',
              'type': 'parse_error',
              'details': e.toString(),
            },
          };
        }
      } else {
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error fetching activity details: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load activity details',
          'type': 'connection_error',
          'details': e.toString(),
        },
      };
    }
  }

  // QR Code check-in
  static Future<Map<String, dynamic>> checkInWithQR(
    String qrCode,
    int activityId,
  ) async {
    try {
      final url = '$baseUrl/attendance/mark/';
      debugPrint('🔍 QR CHECK-IN URL: $url');
      debugPrint('📡 Checking in with QR code: ${qrCode.substring(0, 8)}...');
      final headers = await _getHeaders(requireAuth: true);
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode({'qr_code': qrCode, 'activity_id': activityId}),
          )
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        final data = result['data'];
        debugPrint('✅ QR check-in successful');
        return {
          'success': true,
          'message': data['message'] ?? 'Check-in successful',
          'activity_title': data['activity_title'],
          'activity_id': data['activity_id'],
          'checked_in_at': data['checked_in_at'],
        };
      } else {
        final error = result['error'];
        debugPrint('❌ QR check-in failed: ${error['message']}');
        if (error['status_code'] == 401) {
          return {
            'success': false,
            'message': 'Authentication failed. Please log in again.',
          };
        } else if (error['status_code'] == 404) {
          return {
            'success': false,
            'message': 'Activity not found or QR code is invalid.',
          };
        } else if (error['status_code'] == 409) {
          return {
            'success': false,
            'message': 'You have already checked in to this activity.',
          };
        } else if (error['status_code'] == 400) {
          return {
            'success': false,
            'message': error['message'] ?? 'Invalid QR code or request.',
          };
        } else {
          return {
            'success': false,
            'message': error['message'] ?? 'Check-in failed. Please try again.',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error during QR check-in: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ✅ FIXED: Check server connectivity
  static Future<Map<String, dynamic>> checkServerConnection() async {
    try {
      final url = '$baseUrl/health/';
      debugPrint('🔍 HEALTH CHECK URL: $url');
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        debugPrint('✅ Server is reachable');
        return {
          'success': true,
          'data': {
            'status': 'connected',
            'server_time': DateTime.now().toIso8601String(),
          },
        };
      } else {
        debugPrint('⚠️ Server responded with status: ${response.statusCode}');
        return {
          'success': false,
          'error': {
            'message': 'Server not responding properly',
            'status_code': response.statusCode,
            'type': 'server_error',
          },
        };
      }
    } catch (e) {
      debugPrint('❌ Server connection failed: $e');
      return {
        'success': false,
        'error': {
          'message': 'Cannot connect to server',
          'type': 'connection_failed',
          'details': e.toString(),
        },
      };
    }
  }

  // Get student recent activities
  static Future<Map<String, dynamic>> getStudentRecentActivities(
    int? userId,
  ) async {
    try {
      userId ??= await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': {
            'message': 'User ID not found. Please log in again.',
            'type': 'auth_error',
          },
        };
      }
      final url = '$baseUrl/student-recent/?user_id=$userId';
      debugPrint('🔍 RECENT ACTIVITIES URL: $url');
      final headers = await _getHeaders(requireAuth: false);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        final data = result['data'];
        if (data is Map && data.containsKey('recent_activities')) {
          return {'success': true, 'data': data['recent_activities']};
        }
        return result;
      } else {
        debugPrint('❌ Failed to get recent activities: ${result['error']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error getting recent activities: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load recent activities.',
          'type': 'recent_activities_error',
          'details': e.toString(),
        },
      };
    }
  }

  // Get student volunteer applications
  static Future<Map<String, dynamic>> getStudentVolunteerApplications(
    int? userId,
  ) async {
    try {
      userId ??= await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': {
            'message': 'User ID not found. Please log in again.',
            'type': 'auth_error',
          },
        };
      }
      final url = '$baseUrl/student-volunteer-applications/?user_id=$userId';
      debugPrint('🔍 VOLUNTEER APPLICATIONS URL: $url');
      final headers = await _getHeaders(requireAuth: false);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        final data = result['data'];
        if (data is Map && data.containsKey('volunteer_applications')) {
          return {'success': true, 'data': data['volunteer_applications']};
        }
        return result;
      } else {
        debugPrint(
          '❌ Failed to get volunteer applications: ${result['error']}',
        );
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error getting volunteer applications: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load volunteer applications.',
          'type': 'volunteer_applications_error',
          'details': e.toString(),
        },
      };
    }
  }

  // Get student dashboard data
  static Future<Map<String, dynamic>> getStudentDashboardData(
    int? userId,
  ) async {
    try {
      userId ??= await _getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': {
            'message': 'User ID not found. Please log in again.',
            'type': 'auth_error',
          },
        };
      }
      final url = '$baseUrl/student-dashboard-data/?user_id=$userId';
      debugPrint('🔍 DASHBOARD DATA URL: $url');
      final headers = await _getHeaders(requireAuth: false);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeoutDuration);
      final result = _handleResponse(response);
      if (result['success']) {
        debugPrint('✅ Successfully loaded dashboard data');
        return result;
      } else {
        debugPrint('❌ Failed to get dashboard data: ${result['error']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error getting dashboard data: $e');
      return {
        'success': false,
        'error': {
          'message': 'Failed to load dashboard data.',
          'type': 'dashboard_data_error',
          'details': e.toString(),
        },
      };
    }
  }
}
