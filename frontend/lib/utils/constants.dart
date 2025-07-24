// lib/utils/constants.dart
class AppConstants {
  static const String baseUrl = 'http://127.0.0.1:8000/';

  // User roles
  static const String roleStudent = 'student';
  static const String roleInstructor = 'instructor';
  static const String roleCoordinator = 'coordinator';
  static const String roleAdmin = 'admin';

  static const List<String> allRoles = [
    roleStudent,
    roleInstructor,
    roleCoordinator,
    roleAdmin,
  ];

  // Activity statuses
  static const String statusUpcoming = 'upcoming';
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Issue severities
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';
}
