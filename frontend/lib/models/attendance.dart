class Attendance {
  final int id;
  final int activityId;
  final int userId;
  final String status; // 'attended', 'missed', 'excused'
  final DateTime markedAt;
  final int? markedBy;
  final String? studentName;
  final String? studentEmail;
  final String? markedByName;

  Attendance({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    required this.markedAt,
    this.markedBy,
    this.studentName,
    this.studentEmail,
    this.markedByName,
  });

  // Create from JSON response
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      activityId: json['activity_id'] ?? json['activity'] ?? 0,
      userId: json['user_id'] ?? json['student_id'] ?? json['user'] ?? 0,
      status: json['status'] ?? 'attended',
      markedAt:
          json['marked_at'] != null
              ? DateTime.parse(json['marked_at'])
              : json['participation_time'] != null
              ? DateTime.parse(json['participation_time'])
              : DateTime.now(),
      markedBy: json['marked_by'],
      studentName:
          json['student_name'] ??
          json['user_name'] ??
          json['name'] ??
          (json['user'] != null && json['user'] is Map
              ? json['user']['name'] ?? json['user']['first_name']
              : null),
      studentEmail:
          json['student_email'] ??
          json['email'] ??
          (json['user'] != null && json['user'] is Map
              ? json['user']['email']
              : null),
      markedByName:
          json['marked_by_name'] ??
          (json['marked_by_user'] != null && json['marked_by_user'] is Map
              ? json['marked_by_user']['name']
              : null),
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'status': status,
      'marked_at': markedAt.toIso8601String(),
      if (markedBy != null) 'marked_by': markedBy,
      if (studentName != null) 'student_name': studentName,
      if (studentEmail != null) 'student_email': studentEmail,
      if (markedByName != null) 'marked_by_name': markedByName,
    };
  }

  // Convenience getters for backward compatibility
  String get studentDisplayName => studentName ?? 'Unknown Student';
  int get studentId => userId;
  DateTime get checkedInAt => markedAt;

  // Check if student attended
  bool get isPresent => status == 'attended';
  bool get isMissed => status == 'missed';
  bool get isExcused => status == 'excused';

  // Copy with method for updates
  Attendance copyWith({
    int? id,
    int? activityId,
    int? userId,
    String? status,
    DateTime? markedAt,
    int? markedBy,
    String? studentName,
    String? studentEmail,
    String? markedByName,
  }) {
    return Attendance(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
      markedBy: markedBy ?? this.markedBy,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      markedByName: markedByName ?? this.markedByName,
    );
  }

  @override
  String toString() {
    return 'Attendance(id: $id, activityId: $activityId, userId: $userId, status: $status, studentName: $studentName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance &&
        other.id == id &&
        other.activityId == activityId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ activityId.hashCode ^ userId.hashCode;
  }
}
