// lib/services/volunteer_service.dart - FIXED VERSION with type safety
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/volunteer_application.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class VolunteerService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  // Helper method to get authentication token (same as NotificationService)
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token') ?? 
             prefs.getString('access_token') ??
             prefs.getString('token') ??
             prefs.getString('jwt_token');
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  // Helper method to get authentication headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // FIXED: Safe parsing for integer fields from API response
  static int _parseIntField(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0; // This fixes the String->int TypeError
    }
    return 0;
  }

  // FIXED: Safe parsing for double fields
  static double _parseDoubleField(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Submit a volunteer application
  static Future<VolunteerApplication> submitApplication(
    VolunteerApplication application,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/volunteering/applications/'),
        headers: headers,
        body: json.encode(application.toJson()),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return VolunteerApplication.fromJson(data);
      } else {
        throw Exception('Failed to submit application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to submit application: $e');
    }
  }

  /// Get all volunteer applications for the current user
  static Future<List<VolunteerApplication>> getUserApplications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/applications/my/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // FIXED: Handle both direct array and nested response formats
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('applications')) {
          data = responseData['applications'] as List<dynamic>;
        } else {
          throw Exception('Unexpected response format');
        }
        
        return data.map((app) => VolunteerApplication.fromJson(app)).toList();
      } else {
        throw Exception('Failed to fetch applications: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to fetch applications: $e');
    }
  }

  /// Get volunteer statistics - FIXED for export data
  static Future<VolunteerStats> getVolunteerStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/stats/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // FIXED: Safe parsing to prevent type errors
        return VolunteerStats(
          totalApplications: _parseIntField(data['total_applications']),
          pendingApplications: _parseIntField(data['pending_applications']),
          acceptedApplications: _parseIntField(data['accepted_applications']),
          completedApplications: _parseIntField(data['completed_applications']),
          totalHours: _parseDoubleField(data['total_hours']),
          currentMonthHours: _parseIntField(data['current_month_hours']),
        );
      } else {
        throw Exception('Failed to fetch volunteer stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading volunteer stats: $e');
    }
  }

  /// Get export data for admin - FIXED version
  static Future<Map<String, dynamic>> getExportData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/export-data/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // FIXED: Safely parse all fields to prevent type errors
        return {
          'users': _parseIntField(data['users']),
          'activities': _parseIntField(data['activities']),
          'registrations': _parseIntField(data['registrations']),
          'attendance_records': _parseIntField(data['attendance_records']),
          'volunteer_applications': _parseIntField(data['volunteer_applications']), // This was causing the error
          'volunteering_hours': _parseDoubleField(data['volunteering_hours']),
          'total_notifications': _parseIntField(data['total_notifications']),
          'last_updated': data['last_updated'] ?? DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Failed to load export data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading volunteer applications: $e');
    }
  }

  /// Get a specific volunteer application by ID
  static Future<VolunteerApplication> getApplication(String applicationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VolunteerApplication.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Application not found');
      } else {
        throw Exception('Failed to fetch application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to fetch application: $e');
    }
  }

  /// Get all volunteer opportunities/tasks
  static Future<List<VolunteerOpportunity>> getOpportunities() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/opportunities/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((opportunity) => VolunteerOpportunity.fromJson(opportunity))
            .toList();
      } else {
        throw Exception('Failed to fetch opportunities: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to fetch opportunities: $e');
    }
  }

  /// Update application status (for coordinators/instructors)
  static Future<VolunteerApplication> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? reviewerNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'status': status.toString().split('.').last,
        if (reviewerNotes != null) 'reviewer_notes': reviewerNotes,
      };
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/'),
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VolunteerApplication.fromJson(data);
      } else {
        throw Exception('Failed to update application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to update application: $e');
    }
  }

  /// Log volunteer hours (for completed applications)
  static Future<VolunteerApplication> logHours(
    String applicationId,
    double hours,
  ) async {
    try {
      final headers = await _getHeaders();
      final body = {'hours_completed': hours, 'status': 'completed'};
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/hours/'),
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VolunteerApplication.fromJson(data);
      } else {
        throw Exception('Failed to log hours: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to log hours: $e');
    }
  }

  /// Cancel a pending application
  static Future<void> cancelApplication(String applicationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/'),
        headers: headers,
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to cancel application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to cancel application: $e');
    }
  }
}

// Rest of your existing classes remain the same...
class VolunteerOpportunity {
  final String id;
  final String title;
  final String description;
  final String requirements;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final int maxParticipants;
  final int currentParticipants;
  final String coordinatorId;
  final String coordinatorName;
  final bool isActive;
  final DateTime createdAt;

  const VolunteerOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.coordinatorId,
    required this.coordinatorName,
    required this.isActive,
    required this.createdAt,
  });

  factory VolunteerOpportunity.fromJson(Map<String, dynamic> json) {
    return VolunteerOpportunity(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirements: json['requirements'] ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      location: json['location'] ?? '',
      maxParticipants: VolunteerService._parseIntField(json['max_participants']),
      currentParticipants: VolunteerService._parseIntField(json['current_participants']),
      coordinatorId: json['coordinator_id']?.toString() ?? '',
      coordinatorName: json['coordinator_name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requirements': requirements,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'coordinator_id': coordinatorId,
      'coordinator_name': coordinatorName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isFull => currentParticipants >= maxParticipants;
  bool get hasSpace => currentParticipants < maxParticipants;
}

class VolunteerStats {
  final int totalApplications;
  final int pendingApplications;
  final int acceptedApplications;
  final int completedApplications;
  final double totalHours;
  final int currentMonthHours;

  const VolunteerStats({
    required this.totalApplications,
    required this.pendingApplications,
    required this.acceptedApplications,
    required this.completedApplications,
    required this.totalHours,
    required this.currentMonthHours,
  });

  factory VolunteerStats.fromJson(Map<String, dynamic> json) {
    return VolunteerStats(
      totalApplications: VolunteerService._parseIntField(json['total_applications']),
      pendingApplications: VolunteerService._parseIntField(json['pending_applications']),
      acceptedApplications: VolunteerService._parseIntField(json['accepted_applications']),
      completedApplications: VolunteerService._parseIntField(json['completed_applications']),
      totalHours: VolunteerService._parseDoubleField(json['total_hours']),
      currentMonthHours: VolunteerService._parseIntField(json['current_month_hours']),
    );
  }
}