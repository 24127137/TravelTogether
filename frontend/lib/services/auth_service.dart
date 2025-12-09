import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static VoidCallback? onAuthFailure;
  static DateTime? _lastFailureTime;

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
      const bufferSeconds = 300;

      return exp > now + bufferSeconds; 
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getValidAccessToken({bool forceRefreshIfExpired = true}) async {
    final prefs = await SharedPreferences.getInstance();

    String? access = prefs.getString('access_token');
    String? refresh = prefs.getString('refresh_token');

    if (access != null && isTokenValid(access)) {
      return access;
    }

    if (refresh == null || !isTokenValid(refresh)) {
      await clearTokens();
      _triggerAuthFailure();
      return null;
    }

    final newAccess = await refreshAccessToken(refresh);
    if (newAccess != null) {
      return newAccess;
    }

    await clearTokens();
    _triggerAuthFailure();
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
      } else {
        await clearTokens();
      }
    } catch (_) {
      await clearTokens();
    }

    return null;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_fullname'); // Clear cached user name
    await prefs.remove('user_id'); // Clear cached user id
  }

  static void _triggerAuthFailure() {
    if (_lastFailureTime == null || DateTime.now().difference(_lastFailureTime!) > const Duration(seconds: 5)) {
      _lastFailureTime = DateTime.now();
      if (onAuthFailure != null) {
        onAuthFailure!();
      }
    }
  }

  /// Lấy tên hiển thị của user hiện tại
  static Future<String?> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Luôn gọi API để lấy tên mới nhất
      final accessToken = await getValidAccessToken();
      if (accessToken == null) {
        // Nếu không có token, thử lấy từ cache
        return prefs.getString('user_fullname');
      }

      final url = ApiConfig.getUri(ApiConfig.userProfile);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final fullname = data['fullname']?.toString();

        // Lưu vào cache
        if (fullname != null && fullname.isNotEmpty) {
          await prefs.setString('user_fullname', fullname);
          print('✅ Got user fullname from API: $fullname');
          return fullname;
        }
      }

      // Fallback to cache if API fails
      return prefs.getString('user_fullname');
    } catch (e) {
      print('❌ Error getting current user name: $e');
      // Fallback to cache on error
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_fullname');
    }
  }
}