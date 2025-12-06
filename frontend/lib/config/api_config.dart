/// API Configuration
/// Central place to manage all API endpoints
class ApiConfig {
  // Base URL for the API
  // static const String baseUrl = 'https://ddl23gmg-8000.asse.devtunnels.ms';
  // static const String baseUrl = 'http://172.25.19.7:8000';
  static const String baseUrl = 'http://10.132.240.17:8000'; // emulator local

  static const String supabaseUrl = 'https://meuqntvawakdzntewscp.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldXFudHZhd2FrZHpudGV3c2NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MzUxOTEsImV4cCI6MjA3NzIxMTE5MX0.w0wtRkKTelo9iHQfLtJ61H5xLCUu2VVMKr8BV4Ljcgw';

  // Auth endpoints
  static const String signIn = '$baseUrl/auth/signin';
  static const String createProfile = '$baseUrl/auth/signup';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String authSignout = '$baseUrl/auth/signout';

  // User endpoints
  static const String userProfile = '$baseUrl/users/me';

  // Chat endpoints
  static const String chatHistory = '$baseUrl/chat/history'; // Deprecated, use chatHistoryByGroup
  // static const String chatWebSocket = 'ws://172.25.19.7:8000/chat/ws'; // Websocket endpoint
  static const String chatWebSocket = 'ws://10.132.240.17:8000/chat/ws'; // emulator local

  // Helper method to get chat history URL with group_id
  static String chatHistoryByGroup(String groupId) => '$baseUrl/chat/$groupId/history';

  // Helper method to get WebSocket URL with group_id
  static String chatWebSocketByGroup(String groupId) => 'ws://10.132.240.17:8000/chat/$groupId';

  // Group endpoints
  static const String myGroup = '$baseUrl/groups/mine';
  static const String createGroup = '$baseUrl/groups/create';
  static const String suggest = '$baseUrl/groups/suggest';
  static const String joinGroup = '$baseUrl/groups/request-join';
  static const String groupRequestCancel = '$baseUrl/groups/request-cancel';
  static const String groupManageRequests = '$baseUrl/groups/manage/requests';
  static const String groupManage = '$baseUrl/groups/manage';

  // AI Chat endpoints
  static const String aiNewSession = '$baseUrl/ai/new_session';
  static const String aiSend = '$baseUrl/ai/send';

  // Feedback endpoints
  static const String feedbackBaseUrl = '$baseUrl/feedbacks';

  // Helper method to parse URI
  static Uri getUri(String endpoint) {
    return Uri.parse(endpoint);
  }

  static String supabaseStoragePublic(String path) {
    if (path.startsWith('http')) return path;
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$supabaseUrl/storage/v1/object/public/$normalized';
  }
}