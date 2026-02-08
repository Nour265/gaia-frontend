import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<Map<String, dynamic>> createAssessment({
    required int age,
    required String gender,
    required List<Map<String, dynamic>> symptoms,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/assessments"),
      headers: {"Content-Type": "application/json"},
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
}