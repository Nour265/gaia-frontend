import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gaia/services/auth_session.dart';

class ApiService {
  // Get base URL from build environment or use defaults
  // For Android/iOS: pass --dart-define=API_BASE_URL=http://YOUR_IP:8000
  // For web/desktop: defaults to localhost:8000 (safe for local dev)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const Duration _requestTimeout = Duration(seconds: 20);

  static Future<Map<String, dynamic>> createAssessment({
    required int age,
    required String gender,
    required List<Map<String, dynamic>> symptoms,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/assessments"),
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
    final response = await _post(
      Uri.parse("$baseUrl/auth/signup"),
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
      throw _buildApiException("Auth", response);
    }
  }

  static Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/auth/login"),
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
      throw _buildApiException("Auth", response);
    }
  }

  static Future<AuthUser> authenticateWithGoogle({
    required String idToken,
    int? age,
    String? gender,
    String? phone,
    String? location,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/auth/google"),
      body: jsonEncode({
        "id_token": idToken,
        if (age != null) "age": age,
        if (gender != null) "gender": gender,
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
      throw _buildApiException("Auth", response);
    }
  }

  static Future<AuthUser> authenticateWithGoogleAccessToken({
    required String accessToken,
    int? age,
    String? gender,
    String? phone,
    String? location,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/auth/google/access"),
      body: jsonEncode({
        "access_token": accessToken,
        if (age != null) "age": age,
        if (gender != null) "gender": gender,
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
      throw _buildApiException("Auth", response);
    }
  }

  static Future<AuthUser> fetchMe() async {
    if (AuthSession.token == null) {
      throw Exception("Auth error 401: Missing token");
    }
    final response = await _get(Uri.parse("$baseUrl/auth/me"));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data);
      AuthSession.updateUser(user);
      return user;
    } else {
      throw _buildApiException("Auth", response);
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
    double? latitude,
    double? longitude,
  }) async {
    final response = await _put(
      Uri.parse("$baseUrl/auth/me"),
      body: jsonEncode({
        if (name != null) "name": name,
        if (email != null) "email": email,
        if (password != null) "password": password,
        if (age != null) "age": age,
        if (gender != null) "gender": gender,
        if (phone != null) "phone": phone,
        if (location != null) "location": location,
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data);
      AuthSession.updateUser(user);
      return user;
    } else {
      throw _buildApiException("Auth", response);
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
    final response = await _post(
      Uri.parse("$baseUrl/auth/forgot"),
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException("Auth", response);
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/auth/reset"),
      body: jsonEncode({
        "email": email,
        "code": code,
        "new_password": newPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException("Auth", response);
    }
  }

  // Admin API methods
  static Future<Map<String, dynamic>> getAdminDashboardSummary() async {
    final response = await _get(Uri.parse("$baseUrl/admin/dashboard-summary"));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<List<dynamic>> getDoctors() async {
    final response = await _get(Uri.parse("$baseUrl/admin/doctors"));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<Map<String, dynamic>> createDoctor({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? location,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/admin/doctors"),
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        if (phone != null && phone.isNotEmpty) "phone": phone,
        if (location != null && location.isNotEmpty) "location": location,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<Map<String, dynamic>> updateDoctorStatus({
    required int doctorId,
    required bool isActive,
  }) async {
    final response = await _patch(
      Uri.parse("$baseUrl/admin/doctors/$doctorId/status"),
      body: jsonEncode({
        "is_active": isActive,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  // User management endpoints
  static Future<List<dynamic>> getUsers() async {
    final response = await _get(Uri.parse("$baseUrl/admin/users"));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? specialty,
    String? phone,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/admin/users"),
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": role,
        if (specialty != null && specialty.isNotEmpty) "specialty": specialty,
        if (phone != null && phone.isNotEmpty) "phone": phone,
        if (location != null && location.isNotEmpty) "location": location,
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<Map<String, dynamic>> updateUserRole({
    required int userId,
    required String role,
  }) async {
    final response = await _patch(
      Uri.parse("$baseUrl/admin/users/$userId/role"),
      body: jsonEncode({"role": role}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    final response = await _patch(
      Uri.parse("$baseUrl/admin/users/$userId/status"),
      body: jsonEncode({"is_active": isActive}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Admin", response);
    }
  }

  static Future<void> deleteUser({required int userId}) async {
    final response = await _delete(Uri.parse("$baseUrl/admin/users/$userId"));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildApiException("Admin", response);
    }
  }

  // ── Nearby doctors ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> getNearbyDoctors({
    required double lat,
    required double lng,
    String? condition,
    double radiusKm = 50.0,
  }) async {
    final uri = Uri.parse("$baseUrl/doctors/nearby").replace(queryParameters: {
      "lat": lat.toString(),
      "lng": lng.toString(),
      if (condition != null && condition.isNotEmpty) "condition": condition,
      "radius_km": radiusKm.toString(),
    });
    final response = await _get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw _buildApiException("Doctors", response);
    }
  }

  // ── Appointments ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> bookAppointment({
    required int doctorId,
    String? condition,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/appointments"),
      body: jsonEncode({
        "doctor_id": doctorId,
        if (condition != null && condition.isNotEmpty) "condition": condition,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Appointment", response);
    }
  }

  static Future<List<dynamic>> getMyAppointments() async {
    final response = await _get(Uri.parse("$baseUrl/appointments/my"));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw _buildApiException("Appointments", response);
    }
  }

  static Future<List<dynamic>> getDoctorAppointments() async {
    final response = await _get(Uri.parse("$baseUrl/doctor/appointments"));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw _buildApiException("Appointments", response);
    }
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required int appointmentId,
    required String status,
  }) async {
    final uri = Uri.parse("$baseUrl/appointments/$appointmentId/status")
        .replace(queryParameters: {"status": status});
    final response = await _patch(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Appointment", response);
    }
  }

  // ── Messages ────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMessages({required int appointmentId}) async {
    final response = await _get(Uri.parse("$baseUrl/appointments/$appointmentId/messages"));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw _buildApiException("Messages", response);
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int appointmentId,
    required String content,
  }) async {
    final response = await _post(
      Uri.parse("$baseUrl/appointments/$appointmentId/messages"),
      body: jsonEncode({"content": content}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _buildApiException("Messages", response);
    }
  }

  static Exception _buildApiException(String prefix, http.Response response) {
    final status = response.statusCode;
    final body = response.body.trim();

    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final detail = decoded["detail"];
          if (detail is String && detail.isNotEmpty) {
            return Exception("$prefix error $status: $detail");
          }
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map<String, dynamic>) {
              final msg = first["msg"];
              if (msg is String && msg.isNotEmpty) {
                return Exception("$prefix error $status: $msg");
              }
            }
          }
          final message = decoded["message"];
          if (message is String && message.isNotEmpty) {
            return Exception("$prefix error $status: $message");
          }
        }
      } catch (_) {
        // Keep raw body fallback below.
      }
    }

    return Exception("$prefix error $status: ${body.isEmpty ? "Unknown error" : body}");
  }

  static Future<http.Response> _post(
    Uri url, {
    Object? body,
  }) {
    return http
        .post(
          url,
          headers: _headers(),
          body: body,
        )
        .timeout(_requestTimeout);
  }

  static Future<http.Response> _get(Uri url) {
    return http
        .get(
          url,
          headers: _headers(),
        )
        .timeout(_requestTimeout);
  }

  static Future<http.Response> _put(
    Uri url, {
    Object? body,
  }) {
    return http
        .put(
          url,
          headers: _headers(),
          body: body,
        )
        .timeout(_requestTimeout);
  }

  static Future<http.Response> _patch(
    Uri url, {
    Object? body,
  }) {
    return http
        .patch(
          url,
          headers: _headers(),
          body: body,
        )
        .timeout(_requestTimeout);
  }

  static Future<http.Response> _delete(Uri url) {
    return http
        .delete(
          url,
          headers: _headers(),
        )
        .timeout(_requestTimeout);
  }
  
  static Future<int> fetchTodaysWater(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/water/today'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['intake_ml'] ?? 0;
    }
    return 0;
  }

  static Future<void> syncWater(String token, int intakeMl) async {
    await http.post(
      Uri.parse('$baseUrl/water/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'intake_ml': intakeMl}),
    );
  }
}
