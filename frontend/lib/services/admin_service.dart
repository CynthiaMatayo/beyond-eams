// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String _baseUrl = 'http://localhost:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    // Get token from SharedPreferences (same as AuthProvider)
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

  // Dashboard Statistics
  Future<AdminStats> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/admin/dashboard/stats/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AdminStats.fromJson(data);
      } else {
        throw Exception(
          'Failed to load dashboard stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading dashboard stats: $e');
    }
  }

  // User Management
  Future<List<User>> getUsers({
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
        '$_baseUrl/auth/admin/users/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['users'] as List)
            .map((user) => User.fromJson(user))
            .toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/auth/admin/users/$userId/role/'),
        headers: await _getHeaders(),
        body: json.encode({'role': newRole}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/auth/admin/users/$userId/status/'),
        headers: await _getHeaders(),
        body: json.encode({'is_active': isActive}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  // System Analytics
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
        '$_baseUrl/auth/admin/analytics/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading analytics: $e');
    }
  }

  // Data Export
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
        '$_baseUrl/auth/admin/export/$dataType/',
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

  // System Settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/admin/settings/'),
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

  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/admin/settings/'),
        headers: await _getHeaders(),
        body: json.encode(settings),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating system settings: $e');
    }
  }

  // Notifications
  Future<bool> sendSystemNotification({
    required String title,
    required String message,
    List<String>? userIds,
    List<String>? roles,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/admin/notifications/'),
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

  // System Backup
  Future<String> backupSystemData() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/admin/backup/'),
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
}

// Models needed by the service
class AdminStats {
  final int totalUsers;
  final int newUsersThisMonth;
  final int activeActivities;
  final int upcomingActivities;
  final int systemHealth;
  final int pendingIssues;
  final List<RecentActivity> recentActivities;

  AdminStats({
    required this.totalUsers,
    required this.newUsersThisMonth,
    required this.activeActivities,
    required this.upcomingActivities,
    required this.systemHealth,
    required this.pendingIssues,
    required this.recentActivities,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      newUsersThisMonth: json['new_users_this_month'] ?? 0,
      activeActivities: json['active_activities'] ?? 0,
      upcomingActivities: json['upcoming_activities'] ?? 0,
      systemHealth: json['system_health'] ?? 100,
      pendingIssues: json['pending_issues'] ?? 0,
      recentActivities:
          (json['recent_activities'] as List<dynamic>?)
              ?.map((e) => RecentActivity.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecentActivity {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final String? userId;
  final String? userName;

  RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.userId,
    this.userName,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['user_id'],
      userName: json['user_name'],
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime dateJoined;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.dateJoined,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      isActive: json['is_active'] ?? true,
      dateJoined: DateTime.parse(json['date_joined']),
    );
  }
}
