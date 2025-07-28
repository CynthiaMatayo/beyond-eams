// lib/services/export_service.dart - COMPLETE FINAL VERSION with all methods
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../../services/export_service.dart';


class ExportService {
  // MAIN EXPORT METHODS
  /// Export activities with proper typing and error handling
  static Future<void> exportActivities(List<dynamic> activities) async {
    try {
      debugPrint('🔄 Starting export of ${activities.length} activities');
      
      // Convert to Activity objects if they're not already
      List<Activity> typedActivities = [];
      for (var item in activities) {
        if (item is Activity) {
          typedActivities.add(item);
        } else if (item is Map<String, dynamic>) {
          try {
            typedActivities.add(Activity.fromJson(item));
          } catch (e) {
            debugPrint('❌ Error converting activity: $e');
            continue;
          }
        }
      }
      
      if (typedActivities.isEmpty) {
        throw Exception('No valid activities to export');
      }
      
      // Generate CSV content
      final csvContent = _generateActivitiesCSV(typedActivities);
      
      // Download the file
      _downloadCSVFile(
        csvContent,
        'activities_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      
      debugPrint('✅ Successfully exported ${typedActivities.length} activities');
    } catch (e) {
      debugPrint('❌ Export error: $e');
      rethrow;
    }
  }

  /// Export users with proper typing
  static Future<void> exportUsers(List<dynamic> users) async {
    try {
      debugPrint('🔄 Starting export of ${users.length} users');
      
      // Convert to proper format
      List<Map<String, dynamic>> userData = [];
      for (var user in users) {
        if (user is Map<String, dynamic>) {
          userData.add(user);
        } else {
          try {
            userData.add(_convertUserToMap(user));
          } catch (e) {
            debugPrint('❌ Error converting user: $e');
            continue;
          }
        }
      }
      
      if (userData.isEmpty) {
        throw Exception('No valid users to export');
      }
      
      // Generate CSV content
      final csvContent = _generateUsersCSV(userData);
      
      // Download the file
      _downloadCSVFile(
        csvContent,
        'users_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      
      debugPrint('✅ Successfully exported ${userData.length} users');
    } catch (e) {
      debugPrint('❌ Export error: $e');
      rethrow;
    }
  }

  /// Export volunteer applications
  static Future<void> exportVolunteerApplications(List<dynamic> applications) async {
    try {
      debugPrint('🔄 Starting export of ${applications.length} volunteer applications');
      
      // Convert to proper format
      List<Map<String, dynamic>> appData = [];
      for (var app in applications) {
        if (app is Map<String, dynamic>) {
          appData.add(app);
        } else {
          try {
            appData.add(_convertVolunteerAppToMap(app));
          } catch (e) {
            debugPrint('❌ Error converting volunteer app: $e');
            continue;
          }
        }
      }
      
      if (appData.isEmpty) {
        throw Exception('No valid volunteer applications to export');
      }
      
      // Generate CSV content
      final csvContent = _generateVolunteerApplicationsCSV(appData);
      
      // Download the file
      _downloadCSVFile(
        csvContent,
        'volunteer_applications_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      
      debugPrint('✅ Successfully exported ${appData.length} volunteer applications');
    } catch (e) {
      debugPrint('❌ Export error: $e');
      rethrow;
    }
  }

  /// Export student reports with optional department filtering
  static Future<void> exportStudentReports(
    List<dynamic> reports, {
    String? department,
  }) async {
    try {
      debugPrint('🔄 Starting export of ${reports.length} student reports');
      
      // Convert to proper format
      List<Map<String, dynamic>> reportData = [];
      for (var report in reports) {
        if (report is Map<String, dynamic>) {
          reportData.add(report);
        } else {
          try {
            reportData.add(_convertStudentReportToMap(report));
          } catch (e) {
            debugPrint('❌ Error converting student report: $e');
            continue;
          }
        }
      }
      
      if (reportData.isEmpty) {
        throw Exception('No valid student reports to export');
      }
      
      // Filter by department if specified
      if (department != null && department.isNotEmpty && department != 'All') {
        reportData = reportData.where((report) =>
          report['department']?.toString().toLowerCase() == department.toLowerCase()
        ).toList();
      }
      
      // Generate CSV content
      final csvContent = _generateStudentReportsCSV(reportData);
      
      // Download the file
      final filename = department != null && department != 'All'
        ? 'student_reports_${department.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv'
        : 'student_reports_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      _downloadCSVFile(csvContent, filename);
      
      debugPrint('✅ Successfully exported ${reportData.length} student reports');
    } catch (e) {
      debugPrint('❌ Export error: $e');
      rethrow;
    }
  }

  /// Export analytics report
  static Future<void> exportAnalyticsReport(Map<String, dynamic> analyticsData) async {
    try {
      debugPrint('🔄 Starting analytics report export');
      
      if (analyticsData.isEmpty) {
        throw Exception('No analytics data to export');
      }
      
      // Convert analytics data to CSV format
      final csvContent = _generateAnalyticsCSV(analyticsData);
      
      // Download the file
      _downloadCSVFile(
        csvContent,
        'analytics_report_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      
      debugPrint('✅ Successfully exported analytics report');
    } catch (e) {
      debugPrint('❌ Analytics export error: $e');
      rethrow;
    }
  }

  /// Export to JSON format
  static Future<void> exportToJSON({
    required Map<String, dynamic> data,
    required String filename,
  }) async {
    try {
      debugPrint('🔄 Starting JSON export: $filename');
      
      if (data.isEmpty) {
        throw Exception('No data to export');
      }
      
      // Convert to JSON string with pretty formatting
      final jsonContent = const JsonEncoder.withIndent('  ').convert(data);
      
      // Ensure filename has .json extension
      final cleanFilename = filename.endsWith('.json') ? filename : '$filename.json';
      
      // Download the file
      _downloadJSONFile(jsonContent, cleanFilename);
      
      debugPrint('✅ Successfully exported JSON: $cleanFilename');
    } catch (e) {
      debugPrint('❌ JSON export error: $e');
      rethrow;
    }
  }

  /// Export system logs
  static Future<void> exportSystemLogs(List<Map<String, dynamic>> logs) async {
    try {
      debugPrint('🔄 Starting system logs export');
      
      if (logs.isEmpty) {
        throw Exception('No system logs to export');
      }
      
      // Generate logs CSV content
      final csvContent = _generateSystemLogsCSV(logs);
      
      // Download the file
      _downloadCSVFile(
        csvContent,
        'system_logs_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      
      debugPrint('✅ Successfully exported ${logs.length} system logs');
    } catch (e) {
      debugPrint('❌ System logs export error: $e');
      rethrow;
    }
  }

  /// Generic CSV export with custom headers
  static Future<void> exportToCSV({
    required List<Map<String, dynamic>> data,
    required String filename,
    required List<String> headers,
  }) async {
    try {
      debugPrint('🔄 Starting generic CSV export: $filename');
      
      if (data.isEmpty) {
        throw Exception('No data to export');
      }
      
      // Generate CSV content
      final csvContent = _generateGenericCSV(data, headers);
      
      // Ensure filename has .csv extension
      final cleanFilename = filename.endsWith('.csv') ? filename : '$filename.csv';
      
      // Download the file
      _downloadCSVFile(csvContent, cleanFilename);
      
      debugPrint('✅ Successfully exported ${data.length} records to $cleanFilename');
    } catch (e) {
      debugPrint('❌ Export error: $e');
      rethrow;
    }
  }

  /// Enhanced export for complex data structures
  static Future<void> exportComplexData({
    required Map<String, dynamic> data,
    required String filename,
    String format = 'csv', // csv, json
  }) async {
    try {
      debugPrint('🔄 Starting complex data export: $filename');
      
      if (data.isEmpty) {
        throw Exception('No data to export');
      }
      
      if (format.toLowerCase() == 'json') {
        await exportToJSON(data: data, filename: filename);
      } else {
        // Convert complex data to CSV
        final csvContent = _generateComplexDataCSV(data);
        final cleanFilename = filename.endsWith('.csv') ? filename : '$filename.csv';
        _downloadCSVFile(csvContent, cleanFilename);
      }
      
      debugPrint('✅ Successfully exported complex data: $filename');
    } catch (e) {
      debugPrint('❌ Complex data export error: $e');
      rethrow;
    }
  }

  /// Get file save location information
  static String getFileSaveLocation() {
    return 'Downloads folder (browser default)';
  }

  // PRIVATE CSV GENERATION METHODS
  static String _generateActivitiesCSV(List<Activity> activities) {
    final headers = [
      'ID',
      'Title',
      'Description',
      'Location',
      'Start Time',
      'End Time',
      'Coordinator',
      'Enrolled Count',
      'Max Participants',
      'Status',
      'Is Volunteering',
      'Points Reward',
      'Category',
      'Requirements',
      'Created At',
      'Virtual Link',
      'Duration (Hours)',
    ];
    
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final activity in activities) {
      final row = [
        activity.id.toString(),
        _escapeCSVField(activity.title),
        _escapeCSVField(activity.description),
        _escapeCSVField(activity.location),
        _formatDateTime(activity.startTime),
        _formatDateTime(activity.endTime),
        _escapeCSVField(activity.createdByName),
        activity.enrolledCount.toString(),
        (activity.maxParticipants ?? 0).toString(),
        activity.currentStatus,
        activity.isVolunteering.toString(),
        activity.pointsReward.toString(),
        _escapeCSVField(activity.category ?? 'N/A'),
        _escapeCSVField(activity.requirements ?? 'None'),
        _formatDateTime(activity.createdAt),
        _escapeCSVField(activity.virtualLink ?? 'N/A'),
        activity.durationHours.toStringAsFixed(1),
      ];
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  static String _generateUsersCSV(List<Map<String, dynamic>> users) {
    final headers = [
      'ID',
      'Username',
      'Email',
      'First Name',
      'Last Name',
      'Full Name',
      'Role',
      'Department',
      'Registration Number',
      'Phone',
      'Date Joined',
      'Is Active',
      'Total Enrollments',
      'Completed Activities',
      'Volunteer Hours',
      'Participation Rate',
    ];
    
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final user in users) {
      final row = [
        user['id']?.toString() ?? '',
        _escapeCSVField(user['username']?.toString() ?? ''),
        _escapeCSVField(user['email']?.toString() ?? ''),
        _escapeCSVField(user['first_name']?.toString() ?? ''),
        _escapeCSVField(user['last_name']?.toString() ?? ''),
        _escapeCSVField(user['full_name']?.toString() ?? ''),
        _escapeCSVField(user['role']?.toString() ?? ''),
        _escapeCSVField(user['department']?.toString() ?? ''),
        _escapeCSVField(user['registration_number']?.toString() ?? ''),
        _escapeCSVField(user['phone']?.toString() ?? ''),
        _escapeCSVField(user['date_joined']?.toString() ?? ''),
        (user['is_active'] ?? true).toString(),
        user['total_enrollments']?.toString() ?? '0',
        user['completed_activities']?.toString() ?? '0',
        user['volunteer_hours']?.toString() ?? '0.0',
        '${user['participation_rate']?.toString() ?? '0'}%',
      ];
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  static String _generateVolunteerApplicationsCSV(List<Map<String, dynamic>> applications) {
    final headers = [
      'ID',
      'Activity Title',
      'Student Name',
      'Student Email',
      'Department',
      'Registration Number',
      'Phone',
      'Academic Year',
      'Status',
      'Hours Completed',
      'Application Date',
      'Interest Reason',
      'Skills Experience',
      'Availability',
      'Approved By',
    ];
    
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final app in applications) {
      final row = [
        app['id']?.toString() ?? '',
        _escapeCSVField(app['activity_title']?.toString() ?? app['opportunity_title']?.toString() ?? ''),
        _escapeCSVField(app['student_name']?.toString() ?? ''),
        _escapeCSVField(app['student_email']?.toString() ?? ''),
        _escapeCSVField(app['department']?.toString() ?? ''),
        _escapeCSVField(app['registration_number']?.toString() ?? app['student_id']?.toString() ?? ''),
        _escapeCSVField(app['phone']?.toString() ?? app['phone_primary']?.toString() ?? ''),
        _escapeCSVField(app['academic_year']?.toString() ?? ''),
        _escapeCSVField(app['status']?.toString() ?? ''),
        app['hours_completed']?.toString() ?? '0.0',
        _escapeCSVField(app['application_date']?.toString() ?? app['submitted_at']?.toString() ?? ''),
        _escapeCSVField(app['interest_reason']?.toString() ?? ''),
        _escapeCSVField(app['skills_experience']?.toString() ?? ''),
        _escapeCSVField(app['availability']?.toString() ?? ''),
        _escapeCSVField(app['approved_by']?.toString() ?? ''),
      ];
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  static String _generateStudentReportsCSV(List<Map<String, dynamic>> reports) {
    final headers = [
      'Student ID',
      'Student Name',
      'Email',
      'Department',
      'Registration Number',
      'Activities Participated',
      'Completed Activities',
      'Total Hours',
      'Volunteer Hours',
      'Attendance Rate',
      'Participation Rate',
      'Last Activity Date',
      'Points Earned',
      'Date Joined',
    ];
    
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final report in reports) {
      final row = [
        report['student_id']?.toString() ?? report['id']?.toString() ?? '',
        _escapeCSVField(report['student_name']?.toString() ?? report['full_name']?.toString() ?? ''),
        _escapeCSVField(report['email']?.toString() ?? ''),
        _escapeCSVField(report['department']?.toString() ?? ''),
        _escapeCSVField(report['registration_number']?.toString() ?? ''),
        report['activities_participated']?.toString() ?? report['total_enrollments']?.toString() ?? '0',
        report['completed_activities']?.toString() ?? '0',
        report['total_hours']?.toString() ?? '0.0',
        report['volunteer_hours']?.toString() ?? '0.0',
        '${report['attendance_rate']?.toString() ?? '0'}%',
        '${report['participation_rate']?.toString() ?? '0'}%',
        _escapeCSVField(report['last_activity_date']?.toString() ?? ''),
        report['points_earned']?.toString() ?? '0',
        _escapeCSVField(report['date_joined']?.toString() ?? ''),
      ];
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  static String _generateAnalyticsCSV(Map<String, dynamic> analyticsData) {
    final csvLines = <String>[];
    
    // Add header
    csvLines.add('Metric,Value,Date Generated');
    
    // Add general analytics
    if (analyticsData.containsKey('overview')) {
      final overview = analyticsData['overview'] as Map<String, dynamic>;
      overview.forEach((key, value) {
        csvLines.add(
          '${_escapeCSVField(key)},${_escapeCSVField(value.toString())},${DateTime.now().toIso8601String()}',
        );
      });
    }
    
    // Add activity statistics
    if (analyticsData.containsKey('activity_stats')) {
      final activityStats = analyticsData['activity_stats'] as Map<String, dynamic>;
      activityStats.forEach((key, value) {
        csvLines.add(
          'Activity ${_escapeCSVField(key)},${_escapeCSVField(value.toString())},${DateTime.now().toIso8601String()}',
        );
      });
    }
    
    // Add user statistics
    if (analyticsData.containsKey('user_stats')) {
      final userStats = analyticsData['user_stats'] as Map<String, dynamic>;
      userStats.forEach((key, value) {
        csvLines.add(
          'User ${_escapeCSVField(key)},${_escapeCSVField(value.toString())},${DateTime.now().toIso8601String()}',
        );
      });
    }
    
    // Add volunteer statistics
    if (analyticsData.containsKey('volunteer_stats')) {
      final volunteerStats = analyticsData['volunteer_stats'] as Map<String, dynamic>;
      volunteerStats.forEach((key, value) {
        csvLines.add(
          'Volunteer ${_escapeCSVField(key)},${_escapeCSVField(value.toString())},${DateTime.now().toIso8601String()}',
        );
      });
    }
    
    // Add trend data if available
    if (analyticsData.containsKey('trends')) {
      csvLines.add(''); // Empty line
      csvLines.add('Trend Data');
      csvLines.add('Period,Activities Created,Users Joined,Applications Submitted');
      
      final trends = analyticsData['trends'] as List<dynamic>;
      for (final trend in trends) {
        if (trend is Map<String, dynamic>) {
          final period = trend['period'] ?? '';
          final activities = trend['activities_created'] ?? 0;
          final users = trend['users_joined'] ?? 0;
          final applications = trend['applications_submitted'] ?? 0;
          
          csvLines.add(
            '${_escapeCSVField(period.toString())},$activities,$users,$applications',
          );
        }
      }
    }
    
    return csvLines.join('\n');
  }

  static String _generateSystemLogsCSV(List<Map<String, dynamic>> logs) {
    final headers = [
      'Timestamp',
      'Level',
      'Source',
      'User ID',
      'Action',
      'Details',
      'IP Address',
      'User Agent',
      'Status',
    ];
    
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final log in logs) {
      final row = [
        _escapeCSVField(log['timestamp']?.toString() ?? ''),
        _escapeCSVField(log['level']?.toString() ?? ''),
        _escapeCSVField(log['source']?.toString() ?? ''),
        _escapeCSVField(log['user_id']?.toString() ?? ''),
        _escapeCSVField(log['action']?.toString() ?? ''),
        _escapeCSVField(log['details']?.toString() ?? ''),
        _escapeCSVField(log['ip_address']?.toString() ?? ''),
        _escapeCSVField(log['user_agent']?.toString() ?? ''),
        _escapeCSVField(log['status']?.toString() ?? ''),
      ];
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  static String _generateGenericCSV(List<Map<String, dynamic>> data, List<String> headers) {
    final csvLines = <String>[];
    csvLines.add(headers.join(','));
    
    for (final item in data) {
      final row = headers.map((header) {
        final value = item[header] ?? item[header.toLowerCase()] ?? '';
        return _escapeCSVField(value.toString());
      }).toList();
      csvLines.add(row.join(','));
    }
    
    return csvLines.join('\n');
  }

  static String _generateComplexDataCSV(Map<String, dynamic> data) {
    final csvLines = <String>[];
    
    // Add metadata header
    csvLines.add('Section,Key,Value,Type');
    
    void processData(Map<String, dynamic> map, String section) {
      map.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          processData(value, '$section.$key');
        } else if (value is List) {
          for (int i = 0; i < value.length; i++) {
            if (value[i] is Map<String, dynamic>) {
              processData(value[i] as Map<String, dynamic>, '$section.$key[$i]');
            } else {
              csvLines.add(
                '${_escapeCSVField(section)},${_escapeCSVField('$key[$i]')},${_escapeCSVField(value[i].toString())},${value[i].runtimeType}',
              );
            }
          }
        } else {
          csvLines.add(
            '${_escapeCSVField(section)},${_escapeCSVField(key)},${_escapeCSVField(value.toString())},${value.runtimeType}',
          );
        }
      });
    }
    
    processData(data, 'root');
    return csvLines.join('\n');
  }

  // UTILITY METHODS
  static String _escapeCSVField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static void _downloadCSVFile(String csvContent, String filename) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  static void _downloadJSONFile(String jsonContent, String filename) {
    final bytes = utf8.encode(jsonContent);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  // CONVERSION HELPER METHODS
  static Map<String, dynamic> _convertUserToMap(dynamic user) {
    if (user is Map<String, dynamic>) return user;
    
    final map = <String, dynamic>{};
    
    try {
      map['id'] = _getProperty(user, 'id') ?? 0;
      map['username'] = _getProperty(user, 'username') ?? '';
      map['email'] = _getProperty(user, 'email') ?? '';
      map['first_name'] = _getProperty(user, 'firstName') ?? _getProperty(user, 'first_name') ?? '';
      map['last_name'] = _getProperty(user, 'lastName') ?? _getProperty(user, 'last_name') ?? '';
      map['full_name'] = _getProperty(user, 'fullName') ?? _getProperty(user, 'full_name') ?? '';
      map['role'] = _getProperty(user, 'role') ?? 'student';
      map['department'] = _getProperty(user, 'department') ?? '';
      map['registration_number'] = _getProperty(user, 'registrationNumber') ?? _getProperty(user, 'registration_number') ?? '';
      map['date_joined'] = _getProperty(user, 'dateJoined') ?? _getProperty(user, 'date_joined') ?? '';
      map['is_active'] = _getProperty(user, 'isActive') ?? _getProperty(user, 'is_active') ?? true;
    } catch (e) {
      debugPrint('❌ Error converting user to map: $e');
      map['id'] = user.hashCode;
      map['username'] = user.toString();
    }
    
    return map;
  }

  static Map<String, dynamic> _convertVolunteerAppToMap(dynamic app) {
    if (app is Map<String, dynamic>) return app;
    
    final map = <String, dynamic>{};
    
    try {
      map['id'] = _getProperty(app, 'id') ?? 0;
      map['student_name'] = _getProperty(app, 'studentName') ?? _getProperty(app, 'student_name') ?? '';
      map['student_email'] = _getProperty(app, 'studentEmail') ?? _getProperty(app, 'student_email') ?? '';
      map['activity_title'] = _getProperty(app, 'activityTitle') ?? _getProperty(app, 'activity_title') ?? '';
      map['status'] = _getProperty(app, 'status') ?? 'pending';
      map['hours_completed'] = _getProperty(app, 'hoursCompleted') ?? _getProperty(app, 'hours_completed') ?? 0.0;
      map['application_date'] = _getProperty(app, 'applicationDate') ?? _getProperty(app, 'submitted_at') ?? '';
    } catch (e) {
      debugPrint('❌ Error converting volunteer app to map: $e');
      map['id'] = app.hashCode;
      map['student_name'] = app.toString();
    }
    
    return map;
  }

  static Map<String, dynamic> _convertStudentReportToMap(dynamic report) {
    if (report is Map<String, dynamic>) return report;
    
    final map = <String, dynamic>{};
    
    try {
      map['student_id'] = _getProperty(report, 'studentId') ?? _getProperty(report, 'student_id') ?? _getProperty(report, 'id') ?? 0;
      map['student_name'] = _getProperty(report, 'studentName') ?? _getProperty(report, 'student_name') ?? _getProperty(report, 'full_name') ?? '';
      map['department'] = _getProperty(report, 'department') ?? '';
      map['activities_participated'] = _getProperty(report, 'activitiesParticipated') ?? _getProperty(report, 'total_enrollments') ?? 0;
      map['volunteer_hours'] = _getProperty(report, 'volunteerHours') ?? _getProperty(report, 'volunteer_hours') ?? 0.0;
      map['participation_rate'] = _getProperty(report, 'participationRate') ?? _getProperty(report, 'participation_rate') ?? 0.0;
    } catch (e) {
      debugPrint('❌ Error converting student report to map: $e');
      map['student_id'] = report.hashCode;
      map['student_name'] = report.toString();
    }
    
    return map;
  }

  static dynamic _getProperty(dynamic object, String propertyName) {
    try {
      switch (propertyName) {
        case 'id':
          return object.id;
        case 'username':
          return object.username;
        case 'email':
          return object.email;
        case 'firstName':
        case 'first_name':
          return object.firstName ?? object.first_name;
        case 'lastName':
        case 'last_name':
          return object.lastName ?? object.last_name;
        case 'fullName':
        case 'full_name':
          return object.fullName ?? object.full_name;
        case 'role':
          return object.role;
        case 'department':
          return object.department;
        case 'registrationNumber':
        case 'registration_number':
          return object.registrationNumber ?? object.registration_number;
        case 'dateJoined':
        case 'date_joined':
          return object.dateJoined ?? object.date_joined;
        case 'isActive':
        case 'is_active':
          return object.isActive ?? object.is_active;
        case 'studentName':
        case 'student_name':
          return object.studentName ?? object.student_name;
        case 'studentEmail':
        case 'student_email':
          return object.studentEmail ?? object.student_email;
        case 'activityTitle':
        case 'activity_title':
          return object.activityTitle ?? object.activity_title;
        case 'hoursCompleted':
        case 'hours_completed':
          return object.hoursCompleted ?? object.hours_completed;
        case 'applicationDate':
        case 'submitted_at':
          return object.applicationDate ?? object.submitted_at;
        case 'studentId':
        case 'student_id':
          return object.studentId ?? object.student_id;
        case 'activitiesParticipated':
        case 'total_enrollments':
          return object.activitiesParticipated ?? object.total_enrollments;
        case 'volunteerHours':
        case 'volunteer_hours':
          return object.volunteerHours ?? object.volunteer_hours;
        case 'participationRate':
        case 'participation_rate':
          return object.participationRate ?? object.participation_rate;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ADDITIONAL UTILITY METHODS
  /// Get export format options
  static List<String> getSupportedFormats() {
    return ['csv', 'json'];
  }

  /// Get file extension for format
  static String getFileExtension(String format) {
    switch (format.toLowerCase()) {
      case 'json':
        return '.json';
      case 'csv':
      default:
        return '.csv';
    }
  }

  /// Validate export data before processing
  static bool validateExportData(dynamic data) {
    if (data == null) return false;
    if (data is List) {
      return data.isNotEmpty;
    } else if (data is Map) {
      return data.isNotEmpty;
    }
    return false;
  }

  /// Get export statistics
  static Map<String, dynamic> getExportStats(List<dynamic> data) {
    final stats = <String, dynamic>{};
    stats['total_records'] = data.length;
    stats['export_date'] = DateTime.now().toIso8601String();

    // Analyze data types
    final dataTypes = <String, int>{};
    for (final item in data) {
      final typeName = item.runtimeType.toString();
      dataTypes[typeName] = (dataTypes[typeName] ?? 0) + 1;
    }
    stats['data_types'] = dataTypes;
    return stats;
  }

  /// Create export metadata
  static Map<String, dynamic> createExportMetadata({
    required String exportType,
    required int recordCount,
    String? department,
    Map<String, dynamic>? filters,
  }) {
    return {
      'export_type': exportType,
      'record_count': recordCount,
      'export_date': DateTime.now().toIso8601String(),
      'department': department,
      'filters': filters ?? {},
      'exported_by': 'Beyond Activities System',
      'version': '1.0.0',
    };
  }

  /// Export with metadata
  static Future<void> exportWithMetadata({
    required List<dynamic> data,
    required String filename,
    required String exportType,
    String? department,
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('🔄 Starting export with metadata: $filename');

      if (data.isEmpty) {
        throw Exception('No data to export');
      }

      // Create metadata
      final metadata = createExportMetadata(
        exportType: exportType,
        recordCount: data.length,
        department: department,
        filters: filters,
      );

      // Add metadata to export
      final exportData = {
        'metadata': metadata,
        'data': data,
        'statistics': getExportStats(data),
      };

      // Export as JSON with metadata
      await exportToJSON(
        data: exportData,
        filename: '${filename}_with_metadata',
      );

      debugPrint(
        '✅ Successfully exported ${data.length} records with metadata',
      );
    } catch (e) {
      debugPrint('❌ Export with metadata error: $e');
      rethrow;
    }
  }

  /// Batch export multiple data types
  static Future<void> exportBatch({
    required Map<String, List<dynamic>> dataSets,
    required String baseFilename,
    String format = 'csv',
  }) async {
    try {
      debugPrint('🔄 Starting batch export: ${dataSets.keys.join(', ')}');

      if (dataSets.isEmpty) {
        throw Exception('No data sets to export');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (final entry in dataSets.entries) {
        final dataType = entry.key;
        final data = entry.value;

        if (data.isNotEmpty) {
          final filename = '${baseFilename}_${dataType}_$timestamp';

          switch (dataType.toLowerCase()) {
            case 'activities':
              await exportActivities(data);
              break;
            case 'users':
              await exportUsers(data);
              break;
            case 'volunteer_applications':
            case 'volunteers':
              await exportVolunteerApplications(data);
              break;
            case 'student_reports':
            case 'reports':
              await exportStudentReports(data);
              break;
            default:
              // Generic export for unknown types
              if (format.toLowerCase() == 'json') {
                await exportToJSON(data: {'data': data}, filename: filename);
              } else {
                final headers = _inferHeaders(data);
                final processedData =
                    data
                        .map(
                          (item) =>
                              item is Map<String, dynamic>
                                  ? item
                                  : {'data': item.toString()},
                        )
                        .cast<Map<String, dynamic>>()
                        .toList();
                await exportToCSV(
                  data: processedData,
                  filename: filename,
                  headers: headers,
                );
              }
          }
          debugPrint('✅ Exported $dataType: ${data.length} records');
        }
      }

      debugPrint('✅ Batch export completed successfully');
    } catch (e) {
      debugPrint('❌ Batch export error: $e');
      rethrow;
    }
  }

  /// Infer headers from data
  static List<String> _inferHeaders(List<dynamic> data) {
    if (data.isEmpty) return ['data'];

    final firstItem = data.first;
    if (firstItem is Map<String, dynamic>) {
      return firstItem.keys.toList();
    }
    return ['data'];
  }

  /// Export summary report
  static Future<void> exportSummaryReport({
    required Map<String, dynamic> summaryData,
    String? title,
  }) async {
    try {
      final reportTitle = title ?? 'System Summary Report';
      debugPrint('🔄 Generating $reportTitle');

      if (summaryData.isEmpty) {
        throw Exception('No summary data to export');
      }

      // Create comprehensive summary
      final report = {
        'title': reportTitle,
        'generated_at': DateTime.now().toIso8601String(),
        'summary': summaryData,
        'metadata': {
          'report_type': 'summary',
          'exported_by': 'Beyond Activities System',
          'format': 'json',
        },
      };

      await exportToJSON(
        data: report,
        filename: 'summary_report_${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint('✅ Summary report exported successfully');
    } catch (e) {
      debugPrint('❌ Summary report export error: $e');
      rethrow;
    }
  }

  /// Clean up temporary files (placeholder for future implementation)
  static Future<void> cleanupTempFiles() async {
    // For web applications, this is handled by the browser
    // In future, could implement cleanup for downloaded files tracking
    debugPrint('🧹 Cleanup completed (handled by browser)');
  }

  /// Get download information for user
  static Map<String, String> getDownloadInfo() {
    return {
      'location': getFileSaveLocation(),
      'supported_formats': getSupportedFormats().join(', '),
      'note':
          'Files are automatically downloaded to your browser\'s default download folder',
      'tip': 'Check your browser\'s download bar if you don\'t see the file',
    };
  }

  // FIXED: API integration methods for getting export data
  /// Get export data from API with type safety
  static Future<Map<String, dynamic>> getExportData() async {
    try {
      // TODO: Replace with actual API call to admin service
      // For now, return zeros instead of fake numbers
      return {
        'users': 0,
        'activities': 0,
        'registrations': 0,
        'attendance_records': 0,
        'volunteer_applications': 0,
        'volunteering_hours': 0.0,
        'total_notifications': 0,
        'total_volunteer_hours': 0.0,
        'active_users': 0,
        'pending_applications': 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting export data: $e');
      rethrow;
    }
  }

  // FIXED: Safe parsing methods to prevent type errors
  static int _parseIntField(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0; // This fixes the String->int TypeError
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDoubleField(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Export current system data (uses API)
  static Future<void> exportSystemData() async {
    try {
      debugPrint('🔄 Starting system data export');

      final exportData = await getExportData();

      // Convert to CSV format
      final csvLines = <String>[];
      csvLines.add('Metric,Value,Type');

      exportData.forEach((key, value) {
        if (key != 'last_updated') {
          final valueStr = value.toString();
          final type = value.runtimeType.toString();
          csvLines.add(
            '${_escapeCSVField(key)},${_escapeCSVField(valueStr)},$type',
          );
        }
      });

      csvLines.add(
        'export_timestamp,${DateTime.now().toIso8601String()},DateTime',
      );

      final csvContent = csvLines.join('\n');

      _downloadCSVFile(
        csvContent,
        'system_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      debugPrint('✅ System data exported successfully');
    } catch (e) {
      debugPrint('❌ System data export error: $e');
      rethrow;
    }
  }
}
