import 'package:flutter/foundation.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.phone,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.role,
    this.isActive,
    this.specialty,
  });

  final int id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final String? phone;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final String? role;
  final bool? isActive;
  final String? specialty;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json["id"] as int,
      name: json["name"] as String? ?? "",
      email: json["email"] as String? ?? "",
      age: json["age"] as int?,
      gender: json["gender"] as String?,
      phone: json["phone"] as String?,
      location: json["location"] as String?,
      latitude: (json["latitude"] as num?)?.toDouble(),
      longitude: (json["longitude"] as num?)?.toDouble(),
      createdAt: json["created_at"] as String?,
      role: json["role"] as String?,
      isActive: json["is_active"] as bool?,
      specialty: json["specialty"] as String?,
    );
  }

  bool get isAdmin => role == "admin";
  bool get isDoctor => role == "doctor";
}

class AuthSession {
  static String? token;
  static AuthUser? user;
  static final ValueNotifier<AuthUser?> userNotifier =
      ValueNotifier<AuthUser?>(null);

  static bool get isLoggedIn => token != null && user != null;

  static void setSession({required String token, required AuthUser user}) {
    AuthSession.token = token;
    AuthSession.user = user;
    userNotifier.value = user;
  }

  static void updateUser(AuthUser user) {
    AuthSession.user = user;
    userNotifier.value = user;
  }

  static void clear() {
    token = null;
    user = null;
    userNotifier.value = null;
  }
}
