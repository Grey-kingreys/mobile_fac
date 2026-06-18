import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final int? companyId;
  final String? companyName;
  final int? depotId;
  final String? depotName;
  final String? avatarUrl;
  final String? phone;
  final bool twoFactorEnabled;
  final String? twoFactorMethod; // 'totp' ou 'email'

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    this.companyId,
    this.companyName,
    this.depotId,
    this.depotName,
    this.avatarUrl,
    this.phone,
    this.twoFactorEnabled = false,
    this.twoFactorMethod,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  bool get isSuperAdmin => role == 'superadmin';
  bool get isAdmin => role == 'admin';
  bool get isCaissier => role == 'caissier';
  bool get isDriverRole => role == 'chauffeur';

  bool hasRole(List<String> roles) => roles.contains(role);

  @override
  List<Object?> get props => [id, email, role, twoFactorEnabled];
}
