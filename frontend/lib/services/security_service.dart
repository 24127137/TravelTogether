import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class SecurityApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // GET /security/status
  static Future<SecurityStatusResponse> getSecurityStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/security/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return SecurityStatusResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get security status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting security status: $e');
    }
  }

  // POST /security/set-safe-pin
  static Future<void> setSafePin(String pin) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/security/set-safe-pin'),
        headers: headers,
        body: json.encode({'pin': pin}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to set safe PIN');
      }
    } catch (e) {
      throw Exception('Error setting safe PIN: $e');
    }
  }

  // POST /security/set-danger-pin
  static Future<void> setDangerPin(String pin) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/security/set-danger-pin'),
        headers: headers,
        body: json.encode({'pin': pin}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to set danger PIN');
      }
    } catch (e) {
      throw Exception('Error setting danger PIN: $e');
    }
  }

  // POST /security/verify-pin
  static Future<PinVerifyResponse> verifyPin(String pin, {LocationData? location}) async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) throw Exception('No token');

    final body = {
      'pin': pin,
      if (location != null) 'location': location.toJson(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/security/verify-pin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PinVerifyResponse.fromJson(data);
    } else if (response.statusCode == 400 || response.statusCode == 403) {
      final data = json.decode(response.body);
      throw PinVerifyException(data['detail'] ?? 'PIN không chính xác');
    }
    throw Exception('Failed to verify PIN');
  }
}

class SecurityStatusResponse {
  final String status;
  final bool isOverdue;
  final String? lastConfirmation;

  SecurityStatusResponse({
    required this.status,
    required this.isOverdue,
    this.lastConfirmation,
  });

  factory SecurityStatusResponse.fromJson(Map<String, dynamic> json) {
    return SecurityStatusResponse(
      status: json['status'],
      isOverdue: json['is_overdue'] ?? false,
      lastConfirmation: json['last_confirmation'],
    );
  }

  bool get needsSetup => status == 'setup_required';
  bool get isOverdueStatus => status == 'overdue' || isOverdue;
}

class PinVerifyResponse {
  final String status;
  final String action;
  final String message;

  PinVerifyResponse({
    required this.status,
    required this.action,
    required this.message,
  });

  factory PinVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PinVerifyResponse(
      status: json['status'],
      action: json['action'],
      message: json['message'],
    );
  }

  bool get isSafe => status == 'safe';
  bool get isDanger => status == 'danger';
}

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? deviceInfo;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    if (deviceInfo != null) 'device_info': deviceInfo,
  };
}

class PinVerifyException implements Exception {
  final String message;
  PinVerifyException(this.message);
  
  @override
  String toString() => message;
}
