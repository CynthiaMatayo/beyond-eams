// lib/models/activity.dart - FINAL FIXED VERSION
import 'package:flutter/material.dart';

class Activity {
  // Core Fields
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isVolunteering;
  final String status;
  int enrolledCount; // FIXED: Non-final for setter capability
  final bool isEnrolled;
  final String? category;
  final String? requirements;
  final int? maxParticipants;

  // Enhanced Fields
  final String? shortDescription;
  final DateTime? registrationDeadline;
  final DateTime? updatedAt;
  final bool isVirtual;
  final String? virtualLink;
  final int? categoryId;
  final String? difficulty;
  final int? minAge;
  final int? maxAge;
  final bool isFeatured;
  final bool isPublic;
  final int? attendedCount;
  final double? attendanceRate;
  final String? posterImage;
  final String? bannerImage;
  final int pointsReward;
  final bool certificateAvailable;
  final int viewCount;
  final double? feedbackScore;
  final int? ratingCount;
  final bool isPromoted;
  final int? promotionCount;
  final DateTime? lastPromoted;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.isVolunteering,
    required this.status,
    required this.enrolledCount,
    this.isEnrolled = false,
    this.category,
    this.requirements,
    this.maxParticipants,
    this.shortDescription,
    this.registrationDeadline,
    this.updatedAt,
    this.isVirtual = false,
    this.virtualLink,
    this.categoryId,
    this.difficulty,
    this.minAge,
    this.maxAge,
    this.isFeatured = false,
    this.isPublic = true,
    this.attendedCount,
    this.attendanceRate,
    this.posterImage,
    this.bannerImage,
    this.pointsReward = 10,
    this.certificateAvailable = false,
    this.viewCount = 0,
    this.feedbackScore,
    this.ratingCount,
    this.isPromoted = false,
    this.promotionCount,
    this.lastPromoted,
    this.metadata,
    this.tags,
  });

  // 🔧 FIX: Remove the conflicting getter/setter and use only the field
  // REMOVED: int get enrollmentCount => enrolledCount;
  // REMOVED: set enrollmentCount(int value) => enrolledCount = value;

  // 🔧 FIX: Add only a getter that returns the field value
  int get enrollmentCount => enrolledCount;

  // FIXED: getDynamicStatus method with debug output
  String getDynamicStatus() {
    final now = DateTime.now();
    debugPrint('🔍 getDynamicStatus for "${this.title}":');
    debugPrint('  - DB Status: "${this.status}"');
    debugPrint('  - Current Time: $now');
    debugPrint('  - Start Time: ${this.startTime}');
    debugPrint('  - End Time: ${this.endTime}');
    debugPrint('  - Now before start? ${now.isBefore(this.startTime)}');
    debugPrint('  - Now after end? ${now.isAfter(this.endTime)}');

    // If explicitly draft or cancelled, keep those
    if (status.toLowerCase() == 'draft' ||
        status.toLowerCase() == 'cancelled') {
      debugPrint('  - Result: $status (explicit)');
      return status;
    }

    // Calculate based on dates
    String result;
    if (now.isBefore(this.startTime)) {
      result = 'upcoming';
    } else if (now.isAfter(this.endTime)) {
      result = 'completed';
    } else {
      result = 'ongoing';
    }

    debugPrint('  - Result: $result (calculated)');
    return result;
  }

  // Status getters
  String get databaseStatus => status;
  String get currentStatus => getDynamicStatus();

  // Helper methods using dynamic status
  bool get isUpcoming => getDynamicStatus() == 'upcoming';
  bool get isCompleted => getDynamicStatus() == 'completed';
  bool get isOngoing => getDynamicStatus() == 'ongoing';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  // ENHANCED: fromJson with better error handling and enrollment_count support
  factory Activity.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint(
        '🔧 Parsing Activity JSON: ${json['id']} - status: "${json['status']}"',
      );
      return Activity(
        id: _parseToInt(json['id']) ?? 0,
        title: _parseToString(json['title']) ?? 'Untitled Activity',
        description: _parseToString(json['description']) ?? '',
        location: _parseToString(json['location']) ?? 'TBD',
        startTime: _parseToDateTime(json['start_time']) ?? DateTime.now(),
        endTime:
            _parseToDateTime(json['end_time']) ??
            DateTime.now().add(const Duration(hours: 2)),
        createdBy: _parseToInt(json['created_by']) ?? 0,
        createdByName: _parseToString(json['created_by_name']) ?? 'Unknown',
        createdAt: _parseToDateTime(json['created_at']) ?? DateTime.now(),
        isVolunteering: _parseToBool(json['is_volunteering']) ?? false,
        status: _parseToString(json['status']) ?? 'upcoming',
        // CRITICAL FIX: Handle ALL possible enrollment count field names
        enrolledCount:
            _parseToInt(json['enrolled_count']) ??
            _parseToInt(json['enrollment_count']) ??
            _parseToInt(json['participants_count']) ??
            _parseToInt(json['participant_count']) ??
            _parseToInt(json['enrollments']) ??
            0,
        isEnrolled: _parseToBool(json['is_enrolled']) ?? false,
        category: _parseToString(json['category']),
        requirements: _parseToString(json['requirements']),
        maxParticipants: _parseToInt(json['max_participants']),
        shortDescription: _parseToString(json['short_description']),
        registrationDeadline: _parseToDateTime(json['registration_deadline']),
        updatedAt: _parseToDateTime(json['updated_at']),
        isVirtual: _parseToBool(json['is_virtual']) ?? false,
        virtualLink: _parseToString(json['virtual_link']),
        categoryId: _parseToInt(json['category_id']),
        difficulty: _parseToString(json['difficulty']),
        minAge: _parseToInt(json['min_age']),
        maxAge: _parseToInt(json['max_age']),
        isFeatured: _parseToBool(json['is_featured']) ?? false,
        isPublic: _parseToBool(json['is_public']) ?? true,
        attendedCount: _parseToInt(json['attended_count']),
        attendanceRate: _parseToDouble(json['attendance_rate']),
        posterImage: _parseToString(json['poster_image']),
        bannerImage: _parseToString(json['banner_image']),
        pointsReward: _parseToInt(json['points_reward']) ?? 10,
        certificateAvailable:
            _parseToBool(json['certificate_available']) ?? false,
        viewCount: _parseToInt(json['view_count']) ?? 0,
        feedbackScore: _parseToDouble(json['feedback_score']),
        ratingCount: _parseToInt(json['rating_count']),
        isPromoted: _parseToBool(json['is_promoted']) ?? false,
        promotionCount: _parseToInt(json['promotion_count']),
        lastPromoted: _parseToDateTime(json['last_promoted']),
        metadata:
            json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
        tags: json['tags'] is List ? List<String>.from(json['tags']) : null,
      );
    } catch (e) {
      debugPrint('❌ ERROR parsing Activity from JSON: $e');
      debugPrint('Problematic JSON: $json');
      return Activity(
        id: 0,
        title: 'Error Loading Activity',
        description: 'There was an error loading this activity',
        location: 'Unknown',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        createdBy: 0,
        createdByName: 'System',
        createdAt: DateTime.now(),
        isVolunteering: false,
        status: 'error',
        enrolledCount: 0,
      );
    }
  }

  // Helper parsing methods
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static String? _parseToString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static bool? _parseToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Failed to parse DateTime: $value');
        return null;
      }
    }
    return null;
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
      'is_volunteering': isVolunteering,
      'status': status,
      // FIXED: Support multiple field names for compatibility
      'enrolled_count': enrolledCount,
      'enrollment_count': enrolledCount,
      'is_enrolled': isEnrolled,
      'category': category,
      'requirements': requirements,
      'max_participants': maxParticipants,
      'short_description': shortDescription,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_virtual': isVirtual,
      'virtual_link': virtualLink,
      'category_id': categoryId,
      'difficulty': difficulty,
      'min_age': minAge,
      'max_age': maxAge,
      'is_featured': isFeatured,
      'is_public': isPublic,
      'attended_count': attendedCount,
      'attendance_rate': attendanceRate,
      'poster_image': posterImage,
      'banner_image': bannerImage,
      'points_reward': pointsReward,
      'certificate_available': certificateAvailable,
      'view_count': viewCount,
      'feedback_score': feedbackScore,
      'rating_count': ratingCount,
      'is_promoted': isPromoted,
      'promotion_count': promotionCount,
      'last_promoted': lastPromoted?.toIso8601String(),
      'metadata': metadata,
      'tags': tags,
    };
  }

  // copyWith method
  Activity copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? createdBy,
    String? createdByName,
    DateTime? createdAt,
    bool? isVolunteering,
    String? status,
    int? enrolledCount,
    bool? isEnrolled,
    String? category,
    String? requirements,
    int? maxParticipants,
    String? shortDescription,
    DateTime? registrationDeadline,
    DateTime? updatedAt,
    bool? isVirtual,
    String? virtualLink,
    int? categoryId,
    String? difficulty,
    int? minAge,
    int? maxAge,
    bool? isFeatured,
    bool? isPublic,
    int? attendedCount,
    double? attendanceRate,
    String? posterImage,
    String? bannerImage,
    int? pointsReward,
    bool? certificateAvailable,
    int? viewCount,
    double? feedbackScore,
    int? ratingCount,
    bool? isPromoted,
    int? promotionCount,
    DateTime? lastPromoted,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      isVolunteering: isVolunteering ?? this.isVolunteering,
      status: status ?? this.status,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      category: category ?? this.category,
      requirements: requirements ?? this.requirements,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      shortDescription: shortDescription ?? this.shortDescription,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      updatedAt: updatedAt ?? this.updatedAt,
      isVirtual: isVirtual ?? this.isVirtual,
      virtualLink: virtualLink ?? this.virtualLink,
      categoryId: categoryId ?? this.categoryId,
      difficulty: difficulty ?? this.difficulty,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublic: isPublic ?? this.isPublic,
      attendedCount: attendedCount ?? this.attendedCount,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      posterImage: posterImage ?? this.posterImage,
      bannerImage: bannerImage ?? this.bannerImage,
      pointsReward: pointsReward ?? this.pointsReward,
      certificateAvailable: certificateAvailable ?? this.certificateAvailable,
      viewCount: viewCount ?? this.viewCount,
      feedbackScore: feedbackScore ?? this.feedbackScore,
      ratingCount: ratingCount ?? this.ratingCount,
      isPromoted: isPromoted ?? this.isPromoted,
      promotionCount: promotionCount ?? this.promotionCount,
      lastPromoted: lastPromoted ?? this.lastPromoted,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  // Helper methods
  String get dateTime =>
      startTime.toIso8601String(); // FIXED: Add missing dateTime getter

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[startTime.month - 1]} ${startTime.day}';
  }

  String get formattedTime {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  bool get canEnroll {
    if (maxParticipants != null && enrolledCount >= maxParticipants!) {
      return false;
    }
    return getDynamicStatus() == 'upcoming' && !isEnrolled;
  }

  bool get isFull {
    return maxParticipants != null && enrolledCount >= maxParticipants!;
  }

  double get enrollmentPercentage {
    if (maxParticipants == null || maxParticipants == 0) return 0.0;
    return (enrolledCount / maxParticipants!).clamp(0.0, 1.0);
  }

  bool get isRegistrationOpen {
    if (registrationDeadline != null) {
      return DateTime.now().isBefore(registrationDeadline!) &&
          getDynamicStatus() == 'upcoming';
    }
    return getDynamicStatus() == 'upcoming';
  }

  double get durationHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  @override
  String toString() {
    return 'Activity(id: $id, title: $title, status: $status, enrolledCount: $enrolledCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
