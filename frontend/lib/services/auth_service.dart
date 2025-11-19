import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {

  static bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );

      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return exp > now; 
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();

    String? access = prefs.getString('access_token');
    String? refresh = prefs.getString('refresh_token');

    if (isTokenValid(access)) return access;

    if (isTokenValid(refresh)) {
      final newAccess = await refreshAccessToken(refresh!);
      return newAccess;
    }

    return null;
  }

  static Future<String?> refreshAccessToken(String refreshToken) async {
    try {
      final url = ApiConfig.getUri(ApiConfig.refreshToken);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);

        return data['access_token']; 
      }
    } catch (_) {}

    return null;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
