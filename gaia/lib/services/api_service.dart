import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gaia/services/auth_session.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<Map<String, dynamic>> createAssessment({
    required int age,
    required String gender,
    required List<Map<String, dynamic>> symptoms,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/assessments"),
      headers: _headers(),
      body: jsonEncode({
        "age": age,
        "gender": gender,
        "symptoms": symptoms,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "API error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    String? phone,
    String? location,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/signup"),
      headers: _headers(),
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "age": age,
        "gender": gender,
        if (phone != null) "phone": phone,
        if (location != null) "location": location,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data["user"] as Map<String, dynamic>);
      AuthSession.setSession(token: data["token"] as String, user: user);
      return user;
    } else {
      throw Exception(
        "Auth error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: _headers(),
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data["user"] as Map<String, dynamic>);
      AuthSession.setSession(token: data["token"] as String, user: user);
      return user;
    } else {
      throw Exception(
        "Auth error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Future<AuthUser> fetchMe() async {
    if (AuthSession.token == null) {
      throw Exception("Auth error 401: Missing token");
    }
    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data);
      AuthSession.updateUser(user);
      return user;
    } else {
      throw Exception(
        "Auth error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? password,
    int? age,
    String? gender,
    String? phone,
    String? location,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/auth/me"),
      headers: _headers(),
      body: jsonEncode({
        if (name != null) "name": name,
        if (email != null) "email": email,
        if (password != null) "password": password,
        if (age != null) "age": age,
        if (gender != null) "gender": gender,
        if (phone != null) "phone": phone,
        if (location != null) "location": location,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data);
      AuthSession.updateUser(user);
      return user;
    } else {
      throw Exception(
        "Auth error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Map<String, String> _headers() {
    final headers = {"Content-Type": "application/json"};
    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  static Future<void> requestPasswordReset({required String email}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/forgot"),
      headers: _headers(),
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Auth error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/reset"),
      headers: _headers(),
      body: jsonEncode({
        "email": email,
        "code": code,
        "new_password": newPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Auth error ${response.statusCode}: ${response.body}",
      );
    }
  }
}
