import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://addiscinema-api.onrender.com/api';

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
    print('API headers - token: $token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> removeAvatar() async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/upload/avatar'),
        headers: await _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      } else {
        return {'message': 'Server error: ${res.statusCode}'};
      }
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
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
    ).timeout(const Duration(seconds: 15));
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
    ).timeout(const Duration(seconds: 15));
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

  // ── Favorites ────────────────────────────────────────────────────────────

  static Future<List<String>> getFavorites() async {
    try {
      final headers = await _headers();
      print('Getting favorites with headers: $headers');
      final res = await http.get(
        Uri.parse('$baseUrl/profile/favorites'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('Favorites response status: ${res.statusCode}');
      print('Favorites response body: ${res.body}');
      
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((item) => item.toString()).toList();
      } else {
        print('Failed to get favorites: ${res.statusCode} - ${res.body}');
        return [];
      }
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  static Future<List<String>> addFavorite(String movieId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/profile/favorites'),
        headers: await _headers(),
        body: jsonEncode({'movieId': movieId}),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> favorites = data['favorites'] ?? [];
        return favorites.map((item) => item.toString()).toList();
      } else {
        print('Failed to add favorite: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error adding favorite: $e');
      return [];
    }
  }

  static Future<List<String>> removeFavorite(String movieId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/profile/favorites/$movieId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> favorites = data['favorites'] ?? [];
        return favorites.map((item) => item.toString()).toList();
      } else {
        print('Failed to remove favorite: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error removing favorite: $e');
      return [];
    }
  }

  static Future<void> syncFavorites(List<String> favorites) async {
    try {
      // First get current favorites from server
      final serverFavorites = await getFavorites();
      print('Syncing favorites: local=$favorites, server=$serverFavorites');
      
      // Only add local favorites that aren't on server
      // Don't remove server favorites - server is source of truth
      for (final movieId in favorites) {
        if (!serverFavorites.contains(movieId)) {
          print('Adding missing favorite to server: $movieId');
          await addFavorite(movieId);
        }
      }
      
      print('Sync completed - only added missing favorites, did not remove any');
    } catch (e) {
      print('Error syncing favorites: $e');
    }
  }
}
