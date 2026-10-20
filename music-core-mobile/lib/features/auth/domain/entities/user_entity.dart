import 'package:meta/meta.dart';

/// Represents an authenticated user in the system.
@immutable
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.homeAddress,
    this.roles = const ['user'],
  });

  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? homeAddress;
  final List<String> roles;

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] as String? ?? json['full_name'] as String? ?? 'User';
    final avatarUrl = profile?['avatar_url'] as String? ?? json['avatar_url'] as String?;
    final phoneNumber = profile?['phone_number'] as String? ?? json['phone_number'] as String?;
    final homeAddress = profile?['home_address'] as String? ?? json['home_address'] as String?;

    final rolesRaw = json['roles'];
    List<String> roles = const ['user'];
    if (rolesRaw is List) {
      roles = rolesRaw.map((r) => r.toString()).toList();
    }

    return UserEntity(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: fullName,
      avatarUrl: avatarUrl,
      phoneNumber: phoneNumber,
      homeAddress: homeAddress,
      roles: roles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'home_address': homeAddress,
      'roles': roles,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
