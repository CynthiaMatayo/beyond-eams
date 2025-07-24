// lib/models/user.dart - WITH JSON SERIALIZATION ANNOTATIONS
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;

  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'last_name')
  final String lastName;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  final String? department;

  @JsonKey(name: 'registration_number')
  final String? registrationNumber;

  final String role;

  @JsonKey(name: 'profile_image')
  final String? profileImage;

  @JsonKey(name: 'date_joined')
  final DateTime dateJoined;

  @JsonKey(name: 'is_active')
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.department,
    this.registrationNumber,
    required this.role,
    this.profileImage,
    required this.dateJoined,
    this.isActive = true,
  });

  // Generated methods
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Computed property for full name
  String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) {
      return username; // Fallback to username if no name provided
    }
    return '$first $last'.trim();
  }

  // Role checking convenience methods
  bool get isStudent => role.toLowerCase() == 'student';
  bool get isInstructor => role.toLowerCase() == 'instructor';
  bool get isCoordinator => role.toLowerCase() == 'coordinator';
  bool get isAdmin => role.toLowerCase() == 'admin';

  // Method to create a copy with updated fields
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? department,
    String? registrationNumber,
    String? role,
    String? profileImage,
    DateTime? dateJoined,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      dateJoined: dateJoined ?? this.dateJoined,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, fullName: $fullName, email: $email, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
