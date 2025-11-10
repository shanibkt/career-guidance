import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _profileKey = 'profile_data';
  static const _profileImageKey = 'profile_image';
  static const _authTokenKey = 'auth_token';

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

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_profileImageKey);
    await prefs.remove(_authTokenKey);
  }
}
