import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.104:3000/api'; // Real device on same WiFi

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('current_user_id');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final token = await getToken();
    if (token == null) return {'message': 'Not logged in'};

    try {
      final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/upload/avatar'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        return jsonDecode(body);
      } else {
        return {'message': 'Server error ${streamedResponse.statusCode}: $body'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/profile/password'),
      headers: await _headers(),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    return jsonDecode(res.body);
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getBookings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile/bookings'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addBooking(Map<String, dynamic> booking) async {
    final res = await http.post(
      Uri.parse('$baseUrl/profile/bookings'),
      headers: await _headers(),
      body: jsonEncode(booking),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteBooking(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/profile/bookings/$id'),
      headers: await _headers(),
    );
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getPaymentMethods() async {
    final res = await http.get(
      Uri.parse('$baseUrl/profile/payments'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> addPaymentMethod(Map<String, dynamic> method) async {
    final res = await http.post(
      Uri.parse('$baseUrl/profile/payments'),
      headers: await _headers(),
      body: jsonEncode(method),
    );
    return jsonDecode(res.body);
  }

  static Future<void> removePaymentMethod(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/profile/payments/$id'),
      headers: await _headers(),
    );
  }
}
