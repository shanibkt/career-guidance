import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../services/local/storage_service.dart';

class ChatHistoryService {
  static Future<String?> _getToken() async {
    return await StorageService.loadAuthToken();
  }

  /// Get all chat sessions from server
  static Future<List<Map<String, dynamic>>?> getSessions() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('📜 Fetching chat sessions from server...');

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/chat/sessions'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      print('Chat sessions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = data['sessions'] as List;
        print('✅ Loaded ${sessions.length} sessions from server');
        return sessions.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        print('❌ Failed to get sessions: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting sessions: $e');
      return null;
    }
  }

  /// Get messages for a specific session
  static Future<List<Map<String, dynamic>>?> getSessionMessages(
    String sessionId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('📥 Fetching messages for session: $sessionId');

      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}/api/chat/sessions/$sessionId/messages',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      print('Session messages response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;
        print('✅ Loaded ${messages.length} messages');
        return messages.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        print('⚠️ Session not found');
        return [];
      } else {
        print('❌ Failed to get messages: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting messages: $e');
      return null;
    }
  }

  /// Create or update a chat session
  static Future<bool> saveSession({
    required String sessionId,
    required String title,
    required String lastMessage,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('💾 Saving session: $sessionId');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sessionId': sessionId,
          'title': title,
          'lastMessage': lastMessage,
        }),
      );

      print('Save session response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Session saved successfully');
        return true;
      } else {
        print('❌ Failed to save session: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving session: $e');
      return false;
    }
  }

  /// Save a chat message
  static Future<bool> saveMessage({
    required String sessionId,
    required String message,
    required bool isUser,
    DateTime? timestamp,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sessionId': sessionId,
          'message': message,
          'isUser': isUser,
          'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error saving message: $e');
      return false;
    }
  }

  /// Delete a specific chat session
  static Future<bool> deleteSession(String sessionId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🗑️ Deleting session: $sessionId');

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/sessions/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Delete session response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Session deleted successfully');
        return true;
      } else {
        print('❌ Failed to delete session: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting session: $e');
      return false;
    }
  }

  /// Clear all chat history
  static Future<Map<String, dynamic>?> clearAllHistory() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🗑️ Clearing all chat history...');

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/chat/sessions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Clear all response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '✅ Cleared ${data['deletedSessions']} sessions and ${data['deletedMessages']} messages',
        );
        return data;
      } else {
        print('❌ Failed to clear history: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error clearing history: $e');
      return null;
    }
  }

  /// Search chat history
  static Future<List<Map<String, dynamic>>?> searchChats(String query) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔍 Searching chats: $query');

      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}/api/chat/search?query=${Uri.encodeComponent(query)}',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        print('✅ Found ${results.length} results');
        return results.cast<Map<String, dynamic>>();
      } else {
        print('❌ Search failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error searching: $e');
      return null;
    }
  }

  /// Get chat statistics
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('📊 Fetching chat statistics...');

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/chat/stats'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '✅ Stats: ${data['totalSessions']} sessions, ${data['totalMessages']} messages',
        );
        return data;
      } else {
        print('❌ Failed to get stats: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting stats: $e');
      return null;
    }
  }
}
