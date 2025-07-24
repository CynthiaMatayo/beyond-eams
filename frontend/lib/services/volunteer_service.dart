// lib/services/volunteer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/volunteer_application.dart';

class VolunteerService {
  static const String _baseUrl =
      'http://your-api-url.com/api'; // Replace with your actual API URL

  /// Submit a volunteer application
  static Future<VolunteerApplication> submitApplication(
    VolunteerApplication application,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/volunteering/applications/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
          // 'Authorization': 'Bearer ${await _getAuthToken()}',
        },
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
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/applications/my/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((app) => VolunteerApplication.fromJson(app)).toList();
      } else {
        throw Exception('Failed to fetch applications: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to fetch applications: $e');
    }
  }

  /// Get a specific volunteer application by ID
  static Future<VolunteerApplication> getApplication(
    String applicationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
        },
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
      final response = await http.get(
        Uri.parse('$_baseUrl/volunteering/opportunities/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
        },
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
      final body = {
        'status': status.toString().split('.').last,
        if (reviewerNotes != null) 'reviewer_notes': reviewerNotes,
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
        },
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
      final body = {'hours_completed': hours, 'status': 'completed'};

      final response = await http.patch(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/hours/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
        },
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
      final response = await http.delete(
        Uri.parse('$_baseUrl/volunteering/applications/$applicationId/'),
        headers: {
          'Content-Type': 'application/json',
          // Add your auth header here
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to cancel application: ${response.body}');
      }
    } catch (e) {
      throw Exception('Unable to cancel application: $e');
    }
  }
}

/// Volunteer opportunity model
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirements: json['requirements'] ?? '',
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'])
              : DateTime.now(),
      endDate:
          json['end_date'] != null
              ? DateTime.parse(json['end_date'])
              : DateTime.now(),
      location: json['location'] ?? '',
      maxParticipants: json['max_participants'] ?? 0,
      currentParticipants: json['current_participants'] ?? 0,
      coordinatorId: json['coordinator_id'] ?? '',
      coordinatorName: json['coordinator_name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt:
          json['created_at'] != null
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

/// Volunteer statistics model
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
      totalApplications: json['total_applications'] ?? 0,
      pendingApplications: json['pending_applications'] ?? 0,
      acceptedApplications: json['accepted_applications'] ?? 0,
      completedApplications: json['completed_applications'] ?? 0,
      totalHours: (json['total_hours'] ?? 0).toDouble(),
      currentMonthHours: json['current_month_hours'] ?? 0,
    );
  }
}
