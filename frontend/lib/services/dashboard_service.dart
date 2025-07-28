// lib/services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Update with your backend URL

  // Get authentication token
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Initialize service - THIS WAS MISSING
  static Future<void> initialize() async {
    try {
      print('Dashboard service initializing...');
      // You can add any initialization logic here
      // For example, checking backend health, syncing offline data, etc.
      await Future.delayed(
        Duration(milliseconds: 100),
      ); // Simulate initialization
      print('Dashboard service initialized successfully');
    } catch (e) {
      print('Dashboard service initialization failed: $e');
    }
  }

  // Get all activities - THIS WAS MISSING
  static Future<List<Map<String, dynamic>>> getAllActivities() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/activities/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('activities')) {
          return List<Map<String, dynamic>>.from(data['activities']);
        }
        return [];
      } else {
        print('Error getting activities: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network error getting activities: $e');
      return [];
    }
  }

  // Enroll in activity - THIS WAS MISSING
  static Future<bool> enrollInActivity(int userId, int activityId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${baseUrl}api/activities/$activityId/enroll/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to enroll: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Network error enrolling: $e');
      return false;
    }
  }

  // Refresh dashboard - THIS WAS MISSING
  static Future<Map<String, dynamic>> refreshDashboard(int userId) async {
    try {
      // Clear any cached data here if you implement caching later
      return await getStudentStats();
    } catch (e) {
      print('Error refreshing dashboard: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get dashboard stats - THIS WAS MISSING
  static Future<Map<String, dynamic>> getDashboardStats(int userId) async {
    try {
      return await getStudentStats();
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get student dashboard statistics
// Get student dashboard statistics
  static Future<Map<String, dynamic>> getStudentStats() async {
    try {
      final token = await _getToken();
      print('🔑 Token: ${token != null ? "exists" : "missing"}');
      print('📡 Calling: ${baseUrl}api/dashboard/student-stats/');

      final response = await http.get(
        Uri.parse(
          '${baseUrl}api/dashboard/student-stats/',
        ), // This should work based on your beyond_eams/urls.py
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        print('❌ Error getting student stats: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to load statistics'};
      }
    } catch (e) {
      print('🚨 Network error getting student stats: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get user's recent activities
  static Future<Map<String, dynamic>> getRecentActivities() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/activities/recent/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to load recent activities'};
      }
    } catch (e) {
      print('Network error getting recent activities: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get user's volunteering statistics
  static Future<Map<String, dynamic>> getVolunteeringStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/volunteering/user-stats/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to load volunteering statistics',
        };
      }
    } catch (e) {
      print('Network error getting volunteering stats: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get user's participation history
  static Future<Map<String, dynamic>> getParticipationHistory() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/participation/user-history/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to load participation history',
        };
      }
    } catch (e) {
      print('Network error getting participation history: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('${baseUrl}api/user/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to update profile'};
      }
    } catch (e) {
      print('Network error updating profile: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Join an activity
  static Future<Map<String, dynamic>> joinActivity(int activityId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${baseUrl}api/activities/$activityId/enroll/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to join activity'};
      }
    } catch (e) {
      print('Network error joining activity: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Leave an activity
  static Future<Map<String, dynamic>> leaveActivity(int activityId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${baseUrl}api/activities/$activityId/enroll/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Successfully left activity'};
      } else {
        return {'success': false, 'error': 'Failed to leave activity'};
      }
    } catch (e) {
      print('Network error leaving activity: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Apply for volunteering opportunity
  static Future<Map<String, dynamic>> applyForVolunteering(int taskId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${baseUrl}api/volunteering/$taskId/apply/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to apply for volunteering'};
      }
    } catch (e) {
      print('Network error applying for volunteering: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get volunteering opportunities
  static Future<Map<String, dynamic>> getVolunteeringOpportunities() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/volunteering/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to load volunteering opportunities',
        };
      }
    } catch (e) {
      print('Network error getting volunteering opportunities: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get user's volunteering applications
  static Future<Map<String, dynamic>> getMyVolunteeringApplications() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/volunteering/my-applications/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to load volunteering applications',
        };
      }
    } catch (e) {
      print('Network error getting volunteering applications: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get notifications
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${baseUrl}api/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to load notifications'};
      }
    } catch (e) {
      print('Network error getting notifications: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(
    int notificationId,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('${baseUrl}api/notifications/$notificationId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'read': true}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Notification marked as read'};
      } else {
        return {
          'success': false,
          'error': 'Failed to mark notification as read',
        };
      }
    } catch (e) {
      print('Network error marking notification as read: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
