// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num?)?.toInt() ?? 0,
  username: json['username'] as String? ?? '',
  email: json['email'] as String? ?? '',
  firstName: json['first_name'] as String? ?? '',
  lastName: json['last_name'] as String? ?? '',
  phoneNumber: json['phone_number'] as String? ?? json['phone'] as String?,
  department: json['department'] as String?,
  registrationNumber: json['registration_number'] as String?,
  role: json['role'] as String? ?? 'student',
  profileImage: json['profile_image'] as String?,
  dateJoined:
      json['date_joined'] != null
          ? DateTime.parse(json['date_joined'] as String)
          : DateTime.now(),
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'phone_number': instance.phoneNumber,
  'department': instance.department,
  'registration_number': instance.registrationNumber,
  'role': instance.role,
  'profile_image': instance.profileImage,
  'date_joined': instance.dateJoined.toIso8601String(),
  'is_active': instance.isActive,
};
