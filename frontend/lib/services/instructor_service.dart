// lib/services/instructor_service.dart - CORRECTED TO MATCH YOUR EXISTING BACKEND URLS
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class InstructorService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Helper method to get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // FIXED: Use your existing backend URL - /api/instructor/pending-applications/
  Future<List<Map<String, dynamic>>> getPendingVolunteerApplications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/pending-applications/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint(
          '✅ INSTRUCTOR_SERVICE: Loaded ${data.length} pending applications from database',
        );
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        debugPrint(
          'ℹ️ INSTRUCTOR_SERVICE: No pending applications found in database',
        );
        return [];
      } else {
        debugPrint(
          '❌ INSTRUCTOR_SERVICE: Database error ${response.statusCode}: ${response.body}',
        );
        throw Exception('Database error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_SERVICE: Failed to connect to database: $e');
      throw Exception('Database connection failed: $e');
    }
  }

  // FIXED: Use your existing backend URL - /api/instructor/pending-count/
  Future<int> getDirectPendingCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/pending-count/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        debugPrint(
          '✅ INSTRUCTOR_SERVICE: Loaded pending count from database: $count',
        );
        return count;
      } else if (response.statusCode == 404) {
        debugPrint(
          'ℹ️ INSTRUCTOR_SERVICE: No pending applications in database',
        );
        return 0;
      } else {
        debugPrint(
          '❌ INSTRUCTOR_SERVICE: Database error ${response.statusCode}: ${response.body}',
        );
        throw Exception('Database error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_SERVICE: Failed to connect to database: $e');
      throw Exception('Database connection failed: $e');
    }
  }

  // FIXED: Use your existing backend URL - /api/instructor/all-applications/
  Future<List<Map<String, dynamic>>> getAllVolunteerApplications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/all-applications/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint(
          '✅ INSTRUCTOR_SERVICE: Loaded ${data.length} total applications from database',
        );
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint(
          '❌ INSTRUCTOR_SERVICE: Failed to load all applications: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_SERVICE: Error loading all applications: $e');
      return [];
    }
  }

  // FIXED: Use your existing backend URL - /api/instructor/approve-application/
  Future<bool> approveVolunteerApplication(
    String applicationId, {
    double? approvedHours,
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/instructor/approve-application/$applicationId/',
        ),
        headers: await _getHeaders(),
        body: json.encode({
          'status': 'approved',
          'approved_hours': approvedHours ?? 5.0,
          'comments': comments ?? 'Approved by instructor',
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint(
          '✅ INSTRUCTOR_SERVICE: Approved application $applicationId in database',
        );
        return result['success'] == true;
      } else {
        debugPrint(
          '❌ INSTRUCTOR_SERVICE: Failed to approve application: ${response.statusCode}',
        );
        throw Exception(
          'Failed to approve application: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_SERVICE: Error approving application: $e');
      throw Exception('Database error: $e');
    }
  }

  // FIXED: Use your existing backend URL - /api/instructor/reject-application/
  Future<bool> rejectVolunteerApplication(
    String applicationId, {
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/instructor/reject-application/$applicationId/'),
        headers: await _getHeaders(),
        body: json.encode({
          'status': 'rejected',
          'rejection_reason': reason ?? 'Rejected by instructor',
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint(
          '✅ INSTRUCTOR_SERVICE: Rejected application $applicationId in database',
        );
        return result['success'] == true;
      } else {
        debugPrint(
          '❌ INSTRUCTOR_SERVICE: Failed to reject application: ${response.statusCode}',
        );
        throw Exception('Failed to reject application: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ INSTRUCTOR_SERVICE: Error rejecting application: $e');
      throw Exception('Database error: $e');
    }
  }

  // FIXED: Use your existing backend URL - /api/instructor/approve-hours/
  Future<bool> approveVolunteerHours(
    dynamic verificationId,
    dynamic hours,
    String comments,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/instructor/approve-hours/$verificationId/'),
        headers: await _getHeaders(),
        body: json.encode({
          'approved': true,
          'hours': hours,
          'comments': comments,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        throw Exception(
          'Failed to approve volunteer hours: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error approving volunteer hours: $e');
    }
  }

  // FIXED: Use your existing backend URL - /api/instructor/reject-hours/
  Future<bool> rejectVolunteerHours(
    dynamic verificationId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/instructor/reject-hours/$verificationId/'),
        headers: await _getHeaders(),
        body: json.encode({'approved': false, 'reason': reason}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        throw Exception(
          'Failed to reject volunteer hours: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error rejecting volunteer hours: $e');
    }
  }

  // === EXISTING METHODS (keeping all your original methods unchanged) ===

  Future<Map<String, dynamic>> getInstructorStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/stats/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load instructor stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading instructor stats: $e');
    }
  }

  Future<List<Activity>> getAssignedActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/activities/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load assigned activities: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading assigned activities: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsToTrack() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/students/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading students: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/pending-verifications/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          'Failed to load pending verifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading pending verifications: $e');
    }
  }

  Future<Map<String, dynamic>> getStudentParticipation(
    dynamic studentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/student/$studentId/participation/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load student participation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading student participation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActivityParticipants(
    dynamic activityId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/activity-participants/$activityId/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['participants']);
      } else {
        throw Exception(
          'Failed to load activity participants: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading activity participants: $e');
    }
  }

  Future<bool> markAttendance(
    dynamic activityId,
    List<Map<String, dynamic>> attendanceData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/instructor/mark-attendance/$activityId/'),
        headers: await _getHeaders(),
        body: json.encode({'attendance': attendanceData}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking attendance: $e');
    }
  }

  Future<Map<String, dynamic>> getStudentReport(dynamic studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/instructor/student-report/$studentId/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load student report: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading student report: $e');
    }
  }

  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/instructor/monthly-report/?month=$month&year=$year',
        ),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load monthly report: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading monthly report: $e');
    }
  }
}
