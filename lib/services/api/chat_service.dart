import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/config/api_config.dart';
import '../../services/local/storage_service.dart';

class ChatService {
  static String? _currentSessionId;

  static Future<String?> _getToken() async {
    return await StorageService.loadAuthToken();
  }

  /// Start a new chat session
  static void startNewSession() {
    _currentSessionId = null;
  }

  /// Get current session ID
  static String? get currentSessionId => _currentSessionId;

  /// Send message to AI chatbot and get response
  static Future<String?> sendMessage(String message) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '${ApiConfig.baseUrl}${ApiConfig.chat}';
      final requestBody = {
        'message': message,
        if (_currentSessionId != null) 'sessionId': _currentSessionId,
      };

      print('💬 Sending chat message...');
      print('📍 URL: $url');
      print('📦 Request body: $requestBody');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 90));

      print('✅ Chat response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('📊 Parsed data: $data');

          // Save session ID for conversation continuity
          if (data['sessionId'] != null) {
            _currentSessionId = data['sessionId'] as String;
            print('💾 Session ID saved: $_currentSessionId');
          }

          final aiResponse = data['response'] as String?;
          if (aiResponse == null || aiResponse.isEmpty) {
            throw Exception('Empty response from AI');
          }

          print(
            '✅ AI Response received: ${aiResponse.substring(0, aiResponse.length > 50 ? 50 : aiResponse.length)}...',
          );
          return aiResponse;
        } catch (e) {
          print('❌ Error parsing response: $e');
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token may be expired');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ 404 Not Found - Chat endpoint not available');
        throw Exception('Chat service not available. Please contact support.');
      } else if (response.statusCode == 500) {
        // Try to extract error message from backend
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['error'] ?? errorData['message'] ?? 'Server error';
          print('❌ 500 Server Error: $errorMsg');
          throw Exception('Backend error: $errorMsg');
        } catch (e) {
          print('❌ 500 Server Error (unparseable): ${response.body}');
          throw Exception(
            'Server error. The backend AI service may not be configured properly.',
          );
        }
      } else {
        print('❌ Unexpected status ${response.statusCode}: ${response.body}');
        throw Exception(
          'Failed to get AI response (Status: ${response.statusCode})',
        );
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout after 90 seconds: $e');
      throw Exception(
        'Request timeout. Please check your internet connection and try again.',
      );
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('❌ Format error: $e');
      throw Exception('Invalid data format from server.');
    } catch (e) {
      print('❌ Unexpected error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Get chat history
  static Future<List<Map<String, dynamic>>?> getChatHistory() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('📜 Fetching chat history...');

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatHistory}'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      print('Chat history status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      } else if (response.statusCode == 404) {
        // No history found yet
        return [];
      }
      return null;
    } catch (e) {
      print('❌ Error getting chat history: $e');
      return null;
    }
  }
}
