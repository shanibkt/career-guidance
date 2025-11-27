import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _profileKey = 'profile_data';
  static const _profileImageKey = 'profile_image';
  static const _authTokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _chatHistoryKey = 'chat_history';
  static const _chatMessagesPrefix = 'chat_messages_';

  /// Save profile map as JSON
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(profile));
    if (profile.containsKey('image') && profile['image'] is String) {
      await prefs.setString(_profileImageKey, profile['image'] as String);
    }
  }

  /// Load profile map or null
  static Future<Map<String, dynamic>?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_profileKey);
    if (s == null) return null;
    try {
      return json.decode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
  }

  static Future<String?> loadProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  static Future<String?> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Save authenticated user JSON map
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
  }

  /// Load authenticated user map or null
  static Future<Map<String, dynamic>?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_userKey);
    if (s == null) return null;
    try {
      return json.decode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_profileImageKey);
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userKey);
  }

  /// Clear auth token only
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  /// Clear user data only
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Clear profile data only
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_profileImageKey);
  }

  /// Save chat history sessions
  static Future<void> saveChatHistory(
    List<Map<String, dynamic>> sessions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatHistoryKey, json.encode(sessions));
  }

  /// Load chat history sessions
  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_chatHistoryKey);
    if (s == null) return [];
    try {
      final list = json.decode(s) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Save messages for a specific chat session
  static Future<void> saveChatMessages(
    String sessionId,
    List<Map<String, dynamic>> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_chatMessagesPrefix$sessionId',
      json.encode(messages),
    );
  }

  /// Load messages for a specific chat session
  static Future<List<Map<String, dynamic>>> loadChatMessages(
    String sessionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('$_chatMessagesPrefix$sessionId');
    if (s == null) return [];
    try {
      final list = json.decode(s) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clear all chat history
  static Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_chatMessagesPrefix)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_chatHistoryKey);
  }

  /// Delete a specific chat session
  static Future<void> deleteChatSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatMessagesPrefix$sessionId');
  }
}
