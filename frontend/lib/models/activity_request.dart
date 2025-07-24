// lib/models/activity_request.dart
class ActivityCreateRequest {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final bool isVolunteering;
  final String status;
  final int? maxParticipants;
  final List<String>? tags;

  ActivityCreateRequest({
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.isVolunteering,
    this.status = 'upcoming',
    this.maxParticipants,
    this.tags,
  });

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_volunteering': isVolunteering,
      'status': status,
      'max_participants': maxParticipants,
      'tags': tags,
    };
  }

  // Create from JSON
  factory ActivityCreateRequest.fromJson(Map<String, dynamic> json) {
    return ActivityCreateRequest(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      isVolunteering: json['is_volunteering'] ?? false,
      status: json['status'] ?? 'upcoming',
      maxParticipants: json['max_participants'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  // Create a copy with updated fields
  ActivityCreateRequest copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? isVolunteering,
    String? status,
    int? maxParticipants,
    List<String>? tags,
  }) {
    return ActivityCreateRequest(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isVolunteering: isVolunteering ?? this.isVolunteering,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'ActivityCreateRequest(title: $title, location: $location, startTime: $startTime)';
  }
}

// For updating activities
class ActivityUpdateRequest extends ActivityCreateRequest {
  ActivityUpdateRequest({
    required super.title,
    required super.description,
    required super.location,
    required super.startTime,
    required super.endTime,
    required super.isVolunteering,
    super.status = 'upcoming',
    super.maxParticipants,
    super.tags,
  });

  // Create from ActivityCreateRequest
  factory ActivityUpdateRequest.fromCreateRequest(
    ActivityCreateRequest request,
  ) {
    return ActivityUpdateRequest(
      title: request.title,
      description: request.description,
      location: request.location,
      startTime: request.startTime,
      endTime: request.endTime,
      isVolunteering: request.isVolunteering,
      status: request.status,
      maxParticipants: request.maxParticipants,
      tags: request.tags,
    );
  }
}
