import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service để cache tin nhắn chat, giúp load nhanh hơn
class ChatCacheService {
  static const String _cachePrefix = 'chat_cache_';
  static const String _cacheTimePrefix = 'chat_cache_time_';
  static const int _maxCacheMessages = 50; // Chỉ cache 50 tin nhắn gần nhất
  static const int _cacheExpireMinutes = 30; // Cache hết hạn sau 30 phút

  /// Lưu tin nhắn vào cache
  static Future<void> saveMessages(String groupId, List<dynamic> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Chỉ cache N tin nhắn gần nhất
      final messagesToCache = messages.length > _maxCacheMessages
          ? messages.sublist(messages.length - _maxCacheMessages)
          : messages;

      final jsonStr = jsonEncode(messagesToCache);
      await prefs.setString('$_cachePrefix$groupId', jsonStr);
      await prefs.setInt('$_cacheTimePrefix$groupId', DateTime.now().millisecondsSinceEpoch);

      print('💾 ChatCache: Saved ${messagesToCache.length} messages for group $groupId');
    } catch (e) {
      print('❌ ChatCache: Error saving cache: $e');
    }
  }

  /// Lấy tin nhắn từ cache
  static Future<List<dynamic>?> getMessages(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kiểm tra cache có hết hạn không
      final cacheTime = prefs.getInt('$_cacheTimePrefix$groupId');
      if (cacheTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        final cacheAgeMinutes = cacheAge ~/ 60000;

        if (cacheAgeMinutes > _cacheExpireMinutes) {
          print('⏰ ChatCache: Cache expired for group $groupId (${cacheAgeMinutes}m old)');
          await clearCache(groupId);
          return null;
        }
      }

      final jsonStr = prefs.getString('$_cachePrefix$groupId');
      if (jsonStr == null || jsonStr.isEmpty) {
        print('📭 ChatCache: No cache found for group $groupId');
        return null;
      }

      final messages = jsonDecode(jsonStr) as List<dynamic>;
      print('📦 ChatCache: Loaded ${messages.length} messages from cache for group $groupId');
      return messages;
    } catch (e) {
      print('❌ ChatCache: Error loading cache: $e');
      return null;
    }
  }

  /// Thêm tin nhắn mới vào cache (khi nhận từ WebSocket)
  static Future<void> addMessage(String groupId, Map<String, dynamic> message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_cachePrefix$groupId');

      List<dynamic> messages = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        messages = jsonDecode(jsonStr) as List<dynamic>;
      }

      messages.add(message);

      // Giữ tối đa N tin nhắn
      if (messages.length > _maxCacheMessages) {
        messages = messages.sublist(messages.length - _maxCacheMessages);
      }

      await prefs.setString('$_cachePrefix$groupId', jsonEncode(messages));
      await prefs.setInt('$_cacheTimePrefix$groupId', DateTime.now().millisecondsSinceEpoch);

      print('💾 ChatCache: Added new message to cache for group $groupId');
    } catch (e) {
      print('❌ ChatCache: Error adding message to cache: $e');
    }
  }

  /// Xóa cache của một group
  static Future<void> clearCache(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$groupId');
      await prefs.remove('$_cacheTimePrefix$groupId');
      print('🗑️ ChatCache: Cleared cache for group $groupId');
    } catch (e) {
      print('❌ ChatCache: Error clearing cache: $e');
    }
  }

  /// Xóa tất cả cache chat
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimePrefix)) {
          await prefs.remove(key);
        }
      }
      print('🗑️ ChatCache: Cleared all chat cache');
    } catch (e) {
      print('❌ ChatCache: Error clearing all cache: $e');
    }
  }
}

