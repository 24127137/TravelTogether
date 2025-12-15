import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static VoidCallback? onAuthFailure;
  static DateTime? _lastFailureTime;
  
  static bool _isRefreshing = false;

  static bool isTokenValid(String? token, {bool checkBuffer = true}) {
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );

      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final bufferSeconds = checkBuffer ? 300 : 0; 

      return exp > (now + bufferSeconds); 
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getValidAccessToken({bool forceRefreshIfExpired = true}) async {
    final prefs = await SharedPreferences.getInstance();

    String? access = prefs.getString('access_token');
    String? refresh = prefs.getString('refresh_token');

    if (access != null && isTokenValid(access, checkBuffer: true)) {
      return access;
    }

    if (refresh == null || !isTokenValid(refresh, checkBuffer: false)) {
      if (refresh != null) {
        await clearTokens();
        _triggerAuthFailure();
      }
      return null;
    }

    if (_isRefreshing) {
      return null; 
    }

    _isRefreshing = true;
    final newAccess = await refreshAccessToken(refresh);
    _isRefreshing = false;

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
      print('🔄 Refreshing Access Token...');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final newAccess = data['access_token'];
        final newRefresh = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccess);
        
        if (newRefresh != null) {
          await prefs.setString('refresh_token', newRefresh);
        }

        print('✅ Token Refreshed Successfully');
        return newAccess; 
      } else {
        print('❌ Refresh Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Refresh Error: $e');
    }

    return null;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_fullname'); 
    await prefs.remove('user_id'); 
  }

  static void _triggerAuthFailure() {
    if (_lastFailureTime == null || DateTime.now().difference(_lastFailureTime!) > const Duration(seconds: 2)) {
      _lastFailureTime = DateTime.now();
      print('🚨 Auth Failure Triggered -> Navigating to Login');
      if (onAuthFailure != null) {
        onAuthFailure!();
      }
    }
  }

  static Future<String?> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? cachedName = prefs.getString('user_fullname');
      if (cachedName != null) return cachedName;

      String? accessToken;
      try {
         String? refresh = prefs.getString('refresh_token');
         if (refresh == null) return null; 
         
         accessToken = await getValidAccessToken();
      } catch (_) {
        return null;
      }

      if (accessToken == null) return null;

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

        if (fullname != null && fullname.isNotEmpty) {
          await prefs.setString('user_fullname', fullname);
          return fullname;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user name: $e');
      return null;
    }
  }
}