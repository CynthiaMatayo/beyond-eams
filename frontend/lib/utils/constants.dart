// lib/utils/constants.dart
import 'package:flutter/material.dart';

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

// App Colors
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFFF9800);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
}
