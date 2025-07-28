import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Update this to match your backend URL

  // Get the authorization header with the stored token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Helper method to handle HTTP responses
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    debugPrint('🌐 HTTP ${response.statusCode}: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return {'success': true};
    } else {
      final errorBody =
          response.body.isNotEmpty ? json.decode(response.body) : {};
      
      // Enhanced error message handling
      String errorMessage = 'HTTP ${response.statusCode}';
      if (errorBody['error'] != null) {
        errorMessage = errorBody['error'];
      } else if (errorBody['message'] != null) {
        errorMessage = errorBody['message'];
      } else if (errorBody['detail'] != null) {
        errorMessage = errorBody['detail'];
      } else if (errorBody['non_field_errors'] != null) {
        errorMessage = errorBody['non_field_errors'][0];
      }
      
      debugPrint('❌ API Error: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login/'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({'username': username, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register(
    String username,
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register/'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/logout/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/profile/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Activity endpoints
  Future<List<dynamic>> getActivities({Map<String, dynamic>? filters}) async {
    String url = '$baseUrl/api/activities/';
    if (filters != null && filters.isNotEmpty) {
      final queryParams = filters.entries
          .where((entry) => entry.value != null)
          .map(
            (entry) =>
                '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
          )
          .join('&');
      if (queryParams.isNotEmpty) {
        url += '?$queryParams';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ??
        result; // Handle paginated vs non-paginated responses
  }

  Future<Map<String, dynamic>> getActivity(int activityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/activities/$activityId/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createActivity(
    Map<String, dynamic> activityData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities/'),
      headers: await _getHeaders(),
      body: json.encode(activityData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateActivity(
    int activityId,
    Map<String, dynamic> activityData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/activities/$activityId/'),
      headers: await _getHeaders(),
      body: json.encode(activityData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteActivity(int activityId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/activities/$activityId/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> enrollInActivity(int activityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities/$activityId/enroll/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getEnrolledActivities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/activities/enrolled/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  // Attendance/Participation endpoints
  Future<Map<String, dynamic>> markAttendance(
    int activityId,
    int userId,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/mark/'),
      headers: await _getHeaders(),
      body: json.encode({
        'activity_id': activityId,
        'user_id': userId,
        'status': status, // 'attended', 'missed', 'excused'
      }),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getAttendanceRecords(int activityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/attendance/$activityId/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  Future<Map<String, dynamic>> getUserParticipation(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/participation/user/$userId/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getActivityParticipants(int activityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/participation/activity/$activityId/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  // QR Code attendance methods
  Future<Map<String, dynamic>> generateAttendanceQR(int activityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/qr/generate/'),
      headers: await _getHeaders(),
      body: json.encode({'activity_id': activityId}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> scanAttendanceQR(String qrCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/qr/scan/'),
      headers: await _getHeaders(),
      body: json.encode({'qr_code': qrCode}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyAttendanceQR(
    String qrCode,
    int activityId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/attendance/qr/verify/'),
      headers: await _getHeaders(),
      body: json.encode({'qr_code': qrCode, 'activity_id': activityId}),
    );
    return _handleResponse(response);
  }

  // Volunteering endpoints
  Future<List<dynamic>> getVolunteeringTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/volunteering/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  Future<Map<String, dynamic>> createVolunteeringTask(
    Map<String, dynamic> taskData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/volunteering/'),
      headers: await _getHeaders(),
      body: json.encode(taskData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> applyForVolunteering(int taskId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/volunteering/$taskId/apply/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getMyVolunteeringTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/volunteering/my-tasks/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }
  Future<List<dynamic>> getCoordinatorActivities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/coordinator/activities/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result is List ? result : (result['results'] ?? result);
  }

  Future<Map<String, dynamic>> getUserVolunteeringRecord(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/volunteering/user/$userId/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }
Future<List<dynamic>> getRecentActivities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/activities/recent/'),
      headers: await _getHeaders(),
    );

    final result = await _handleResponse(response);

    // Since your backend returns a direct list for recent activities,
    // but _handleResponse wraps it in a map, we need to handle this
    return result['results'] ?? result as List<dynamic>;
  }

  // Notifications endpoints
  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
    int notificationId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/notifications/$notificationId/'),
      headers: await _getHeaders(),
      body: json.encode({'read': true}),
    );
    return _handleResponse(response);
  }

  // Admin endpoints
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  Future<Map<String, dynamic>> changeUserRole(
    int userId,
    String newRole,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/$userId/role/'),
      headers: await _getHeaders(),
      body: json.encode({'new_role': newRole}),
    );
    return _handleResponse(response);
  }

  // Dashboard/Reports endpoints
  Future<Map<String, dynamic>> getDashboardOverview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/overview/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getParticipationReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reports/participation/'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Utility endpoints
  Future<List<dynamic>> getDepartments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/utils/departments/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  Future<List<dynamic>> getActivityCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/utils/categories/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }

  Future<List<dynamic>> getRoles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/utils/roles/'),
      headers: await _getHeaders(),
    );
    final result = await _handleResponse(response);
    return result['results'] ?? result;
  }
}
