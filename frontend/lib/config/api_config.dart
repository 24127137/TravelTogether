/// API Configuration
/// Central place to manage all API endpoints
class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://ddl23gmg-8000.asse.devtunnels.ms';

  // Auth endpoints
  static const String signIn = '$baseUrl/auth/signin';
  static const String createProfile = '$baseUrl/auth/signup';

  // User endpoints
  static const String userProfile = '$baseUrl/users/me';

  // Helper method to parse URI
  static Uri getUri(String endpoint) {
    return Uri.parse(endpoint);
  }
}

