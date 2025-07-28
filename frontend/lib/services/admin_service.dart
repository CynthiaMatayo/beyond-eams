// lib/services/admin_service.dart - FINAL POLISHED VERSION
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/activity.dart';

class AdminService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      return {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting headers: $e');
      return {'Content-Type': 'application/json'};
    }
  }

  // FIXED: Dashboard Statistics with fallback
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔧 ADMIN SERVICE: Getting dashboard stats...');
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard/stats/'),
        headers: await _getHeaders(),
      );
      
      print('🔧 ADMIN SERVICE: Dashboard stats response status: ${response.statusCode}');
      print('🔧 ADMIN SERVICE: Dashboard stats response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('🔧 ADMIN SERVICE: Dashboard stats parsed successfully');
          return jsonData;
        } catch (e) {
          print('🔧 ADMIN SERVICE: JSON parse error for dashboard stats: $e');
          print('🔧 ADMIN SERVICE: Raw response: ${response.body}');
          return _getFallbackStats();
        }
      } else {
        print('🔧 ADMIN SERVICE: Dashboard stats API failed: ${response.statusCode}');
        print('🔧 ADMIN SERVICE: Error response body: ${response.body}');
        return _getFallbackStats();
      }
    } catch (e) {
      print('🔧 ADMIN SERVICE: Error loading dashboard stats: $e');
      return _getFallbackStats();
    }
  }

  Map<String, dynamic> _getFallbackStats() {
    return {
      'total_users': 0,
      'new_users_this_month': 0,
      'active_activities': 0,
      'upcoming_activities': 0,
      'system_health': 0,
      'pending_issues': 1,
      'recent_activities': [],
    };
  }

  // FIXED: User Management with correct endpoint
  Future<List<Map<String, dynamic>>> getUsers({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    String? roleFilter,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
        if (roleFilter != null && roleFilter.isNotEmpty) 'role': roleFilter,
      };
      final uri = Uri.parse(
        '$_baseUrl/admin/users/',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final usersList = data['users'] ?? data['results'] ?? [];
        return List<Map<String, dynamic>>.from(usersList);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  // FIXED: Get all users for export
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users/all/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final usersList = data['users'] ?? data['results'] ?? [];
        return List<Map<String, dynamic>>.from(usersList);
      } else {
        throw Exception('Failed to load all users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading all users: $e');
    }
  }

  // FIXED: Get all volunteer applications
  Future<List<VolunteerApplication>> getAllVolunteerApplications() async {
    try {
      final response = await http.get(
    Uri.parse('$_baseUrl/instructor/all-applications/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final applicationsList = data['applications'] ?? data['results'] ?? [];
        return (applicationsList as List)
            .map((app) => VolunteerApplication.fromJson(app))
            .toList();
      } else {
        throw Exception(
          'Failed to load volunteer applications: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading volunteer applications: $e');
    }
  }

  // FIXED: Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/users/$userId/role/'),
        headers: await _getHeaders(),
        body: json.encode({'role': newRole}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  // FIXED: Toggle user status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/users/$userId/status/'),
        headers: await _getHeaders(),
        body: json.encode({'is_active': isActive}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  // FIXED: Get all activities using existing Activity model
// FIXED: getAllActivities method for AdminService
  Future<List<Activity>> getAllActivities({
    int page = 1,
    int pageSize = 50,
    String? searchQuery,
    String? statusFilter,
  }) async {
    try {
      print('🔧 ADMIN SERVICE: Getting activities with pageSize: $pageSize');
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
        if (statusFilter != null && statusFilter.isNotEmpty)
          'status': statusFilter,
      };
      final uri = Uri.parse(
        '$_baseUrl/activities/',
      ).replace(queryParameters: queryParams);
      
      print('🔧 ADMIN SERVICE: Activities URL: $uri');
      final response = await http.get(uri, headers: await _getHeaders());
      
      print('🔧 ADMIN SERVICE: Activities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // FIXED: Handle different response formats
        dynamic activitiesList;
        if (data is List) {
          // Direct list response
          activitiesList = data;
        } else if (data is Map) {
          // Wrapped response - try different keys
          activitiesList =
              data['activities'] ?? data['results'] ?? data['data'] ?? [];
        } else {
          activitiesList = [];
        }

        print('🔧 ADMIN SERVICE: Found ${activitiesList.length} activities');

        // FIXED: Safely convert to Activity objects
        if (activitiesList is List) {
          return activitiesList
              .map((activity) {
                try {
                  if (activity is Map<String, dynamic>) {
                    return Activity.fromJson(activity);
                  } else {
                    // Handle case where activity is already an Activity object
                    return activity as Activity;
                  }
                } catch (e) {
                  print('Error parsing activity: $e');
                  // Return a default activity or skip this one
                  return null;
                }
              })
              .where((activity) => activity != null)
              .cast<Activity>()
              .toList();
        } else {
          return [];
        }
      } else {
        print('🔧 ADMIN SERVICE: Activities API failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      print('🔧 ADMIN SERVICE: Error in getAllActivities: $e');
      throw Exception('Error loading activities: $e');
    }
  }

  // FIXED: System Analytics with fallback
  Future<Map<String, dynamic>> getSystemAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      final uri = Uri.parse(
        '$_baseUrl/admin/analytics/',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return _getFallbackAnalytics();
      }
    } catch (e) {
      print('Error loading analytics: $e');
      return _getFallbackAnalytics();
    }
  }

  Map<String, dynamic> _getFallbackAnalytics() {
    return {
      'total_users': 0,
      'avg_participation_rate': 0,
      'active_sessions': 0,
      'total_activities': 0,
      'total_volunteer_hours': 0,
      'avg_response_time': 0,
    };
  }

  // FIXED: Data Export
  Future<String> exportData({
    required String dataType,
    String? format = 'csv',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        'format': format,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };
      final uri = Uri.parse(
        '$_baseUrl/admin/export/$dataType/',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['download_url'] ?? '';
      } else {
        throw Exception('Failed to export data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting data: $e');
    }
  }

  // FIXED: System Settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/settings/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load system settings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading system settings: $e');
    }
  }

  // FIXED: Send System Notification
  Future<bool> sendSystemNotification({
    required String title,
    required String message,
    List<String>? userIds,
    List<String>? roles,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/admin/send/'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'message': message,
          if (userIds != null) 'user_ids': userIds,
          if (roles != null) 'roles': roles,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  // ADDED: Missing methods that admin screens expect
  Future<List<ActivityParticipant>> getActivityParticipants(
    String activityId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/activities/$activityId/participants/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final participantsList = data['participants'] ?? data['results'] ?? [];
        return (participantsList as List)
            .map((participant) => ActivityParticipant.fromJson(participant))
            .toList();
      } else {
        throw Exception('Failed to load participants: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading participants: $e');
    }
  }

  Future<bool> deleteActivity(String activityId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/activities/$activityId/'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }

  Future<List<SystemLog>> getSystemLogs({
    DateTime? startDate,
    DateTime? endDate,
    int? limit = 1000,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      final uri = Uri.parse(
        '$_baseUrl/admin/logs/',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logsList = data['logs'] ?? data['results'] ?? [];
        return (logsList as List)
            .map((log) => SystemLog.fromJson(log))
            .toList();
      } else {
        throw Exception('Failed to load system logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading system logs: $e');
    }
  }

  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/settings/'),
        headers: await _getHeaders(),
        body: json.encode(settings),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating system settings: $e');
    }
  }

  Future<String> backupSystemData() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/backup/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['backup_url'] ?? '';
      } else {
        throw Exception('Failed to create backup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating backup: $e');
    }
  }

  // System Health Check
  Future<bool> checkSystemHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/health/'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get system statistics for reports
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/system-stats/'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Return default stats if API call fails
        return {
          'total_users': 0,
          'active_users': 0,
          'total_activities': 0,
          'active_activities': 0,
          'student_count': 0,
          'coordinator_count': 0,
          'instructor_count': 0,
          'admin_count': 0,
          'total_registrations': 0,
          'monthly_registrations': 0,
          'completion_rate': 0,
          'average_rating': 0,
          'email_service_status': 'healthy',
        };
      }
    } catch (e) {
      print('Error getting system stats: $e');
      return {
        'total_users': 0,
        'active_users': 0,
        'total_activities': 0,
        'active_activities': 0,
        'student_count': 0,
        'coordinator_count': 0,
        'instructor_count': 0,
        'admin_count': 0,
        'total_registrations': 0,
        'monthly_registrations': 0,
        'completion_rate': 0,
        'average_rating': 0,
        'email_service_status': 'error',
      };
    }
  }

  // Get recent activities for reports
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/recent-activities/?limit=$limit'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both direct array response and nested object response
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          final activities = data['activities'] ?? data['results'] ?? data;
          return List<Map<String, dynamic>>.from(activities);
        }
        return [];
      } else {
        print('Recent activities API failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }
}

// ADDED: Missing model classes
class ActivityParticipant {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime joinedAt;
  final bool hasAttended;

  ActivityParticipant({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.joinedAt,
    required this.hasAttended,
  });

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) {
    return ActivityParticipant(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? json['name'] ?? '',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      joinedAt: DateTime.parse(json['joined_at'] ?? json['created_at']),
      hasAttended: json['has_attended'] ?? false,
    );
  }
}

class VolunteerApplication {
  final String id;
  final String activityTitle;
  final String studentName;
  final String studentEmail;
  final String specificRole;
  final String availability;
  final String motivation;
  final String status;
  final double hoursCompleted;
  final String appliedDate;
  final String? completedDate;

  VolunteerApplication({
    required this.id,
    required this.activityTitle,
    required this.studentName,
    required this.studentEmail,
    required this.specificRole,
    required this.availability,
    required this.motivation,
    required this.status,
    required this.hoursCompleted,
    required this.appliedDate,
    this.completedDate,
  });

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: json['id'].toString(),
      activityTitle: json['activity_title'] ?? json['title'] ?? '',
      studentName: json['student_name'] ?? json['user_name'] ?? '',
      studentEmail: json['student_email'] ?? json['user_email'] ?? '',
      specificRole: json['specific_role'] ?? json['role'] ?? '',
      availability: json['availability'] ?? '',
      motivation: json['motivation'] ?? json['message'] ?? '',
      status: json['status'] ?? 'pending',
      hoursCompleted: (json['hours_completed'] ?? 0.0).toDouble(),
      appliedDate: json['applied_date'] ?? json['created_at'] ?? '',
      completedDate: json['completed_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_title': activityTitle,
      'student_name': studentName,
      'student_email': studentEmail,
      'specific_role': specificRole,
      'availability': availability,
      'motivation': motivation,
      'status': status,
      'hours_completed': hoursCompleted,
      'applied_date': appliedDate,
      'completed_date': completedDate,
    };
  }
}

class SystemLog {
  final String id;
  final String? userId;
  final String action;
  final String description;
  final String ipAddress;
  final String userAgent;
  final DateTime timestamp;
  final String status;

  SystemLog({
    required this.id,
    this.userId,
    required this.action,
    required this.description,
    required this.ipAddress,
    required this.userAgent,
    required this.timestamp,
    required this.status,
  });

  factory SystemLog.fromJson(Map<String, dynamic> json) {
    return SystemLog(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      userAgent: json['user_agent'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? 'success',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}
