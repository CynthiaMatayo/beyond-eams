// lib/models/volunteer_application.dart
enum ApplicationStatus { pending, approved, rejected, completed }

class VolunteerApplication {
  final String id;
  final String opportunityId;
  final String firstName;
  final String lastName;
  final String email;
  final String studentId;
  final String phonePrimary;
  final String? phoneSecondary;
  final String department;
  final String academicYear;
  final String interestReason;
  final String skillsExperience;
  final String availability;
  final ApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewerNotes;
  final double? hoursCompleted;

  const VolunteerApplication({
    required this.id,
    required this.opportunityId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.studentId,
    required this.phonePrimary,
    this.phoneSecondary,
    required this.department,
    required this.academicYear,
    required this.interestReason,
    required this.skillsExperience,
    required this.availability,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewerNotes,
    this.hoursCompleted,
  });

  // Manual JSON serialization (no code generation needed)
  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: json['id'] ?? '',
      opportunityId: json['opportunity_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      studentId: json['student_id'] ?? '',
      phonePrimary: json['phone_primary'] ?? '',
      phoneSecondary: json['phone_secondary'],
      department: json['department'] ?? '',
      academicYear: json['academic_year'] ?? '',
      interestReason: json['interest_reason'] ?? '',
      skillsExperience: json['skills_experience'] ?? '',
      availability: json['availability'] ?? '',
      status: _statusFromString(json['status'] ?? 'pending'),
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'])
              : DateTime.now(),
      reviewedAt:
          json['reviewed_at'] != null
              ? DateTime.parse(json['reviewed_at'])
              : null,
      reviewedBy: json['reviewed_by'],
      reviewerNotes: json['reviewer_notes'],
      hoursCompleted: json['hours_completed']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opportunity_id': opportunityId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'student_id': studentId,
      'phone_primary': phonePrimary,
      'phone_secondary': phoneSecondary,
      'department': department,
      'academic_year': academicYear,
      'interest_reason': interestReason,
      'skills_experience': skillsExperience,
      'availability': availability,
      'status': _statusToString(status),
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewer_notes': reviewerNotes,
      'hours_completed': hoursCompleted,
    };
  }

  static ApplicationStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'completed':
        return ApplicationStatus.completed;
      default:
        return ApplicationStatus.pending;
    }
  }

  static String _statusToString(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'pending';
      case ApplicationStatus.approved:
        return 'approved';
      case ApplicationStatus.rejected:
        return 'rejected';
      case ApplicationStatus.completed:
        return 'completed';
    }
  }

  VolunteerApplication copyWith({
    String? id,
    String? opportunityId,
    String? firstName,
    String? lastName,
    String? email,
    String? studentId,
    String? phonePrimary,
    String? phoneSecondary,
    String? department,
    String? academicYear,
    String? interestReason,
    String? skillsExperience,
    String? availability,
    ApplicationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewerNotes,
    double? hoursCompleted,
  }) {
    return VolunteerApplication(
      id: id ?? this.id,
      opportunityId: opportunityId ?? this.opportunityId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      phonePrimary: phonePrimary ?? this.phonePrimary,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      interestReason: interestReason ?? this.interestReason,
      skillsExperience: skillsExperience ?? this.skillsExperience,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      hoursCompleted: hoursCompleted ?? this.hoursCompleted,
    );
  }

  // Helper getters
  String get fullName => '$firstName $lastName';

  bool get isPending => status == ApplicationStatus.pending;
  bool get isAccepted => status == ApplicationStatus.approved;
  bool get isRejected => status == ApplicationStatus.rejected;
  bool get isCompleted => status == ApplicationStatus.completed;

  String get statusDisplayName {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.completed:
        return 'Completed';
    }
  }

  @override
  String toString() {
    return 'VolunteerApplication{id: $id, fullName: $fullName, status: $status, opportunityId: $opportunityId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolunteerApplication &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
