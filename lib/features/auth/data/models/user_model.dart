import 'package:djoulagest_mobile/features/auth/domain/entities/user_entity.dart';

class UserModel {
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
  final String? twoFactorMethod;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      depotId: json['depot_id'] as int?,
      depotName: json['depot_name'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatar'] as String?,
      phone: json['phone'] as String?,
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      twoFactorMethod: json['two_factor_method'] as String?,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        isActive: isActive,
        companyId: companyId,
        companyName: companyName,
        depotId: depotId,
        depotName: depotName,
        avatarUrl: avatarUrl,
        phone: phone,
        twoFactorEnabled: twoFactorEnabled,
        twoFactorMethod: twoFactorMethod,
      );
}
