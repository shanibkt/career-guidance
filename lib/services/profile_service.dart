import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

class ProfileService {
  // Base URL - MUST match your PC's IP address (same as AuthService)
  // Use this for both emulator and physical devices
  static const String _baseUrl = 'http://192.168.1.101:5001';

  static String get _effectiveBaseUrl => _baseUrl;

  // Public getter for building image URLs
  static String get effectiveBaseUrl => _effectiveBaseUrl;

  /// GET /api/userprofile/{userId}
  /// Returns profile data: phone, age, gender, education, field, skills, areas, image
  static Future<Map<String, dynamic>?> getProfile(
    int userId,
    String token,
  ) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/userprofile/$userId');

    try {
      debugPrint('ProfileService.getProfile -> GET $uri');

      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('ProfileService.getProfile <- status ${resp.statusCode}');
      debugPrint('ProfileService.getProfile body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return data;
      } else if (resp.statusCode == 404) {
        // Profile doesn't exist yet - return empty
        return {};
      }

      return null;
    } on SocketException catch (e) {
      debugPrint('ProfileService.getProfile - Connection error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('ProfileService.getProfile - Error: $e');
      return null;
    }
  }

  /// PUT /api/profile/{userId}
  /// Updates user fields: fullName, username, email
  static Future<bool> updateUser(
    int userId,
    String token,
    Map<String, dynamic> userData,
  ) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/profile/$userId');

    try {
      debugPrint('ProfileService.updateUser -> PUT $uri');
      debugPrint('ProfileService.updateUser payload: ${json.encode(userData)}');

      final resp = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      debugPrint('ProfileService.updateUser <- status ${resp.statusCode}');
      debugPrint('ProfileService.updateUser body: ${resp.body}');

      return resp.statusCode == 200 || resp.statusCode == 204;
    } on SocketException catch (e) {
      debugPrint('ProfileService.updateUser - Connection error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('ProfileService.updateUser - Error: $e');
      return false;
    }
  }

  /// POST /api/userprofile
  /// Creates or updates profile: phone, age, gender, education, field, skills, areas
  static Future<bool> updateProfile(
    int userId,
    String token,
    Map<String, dynamic> profileData,
  ) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/userprofile');

    try {
      // Add userId to payload - CRITICAL for backend
      final payload = {...profileData, 'userId': userId};

      debugPrint('=== ProfileService.updateProfile ===');
      debugPrint('Updating profile for userId: $userId');
      debugPrint('URL: $uri');
      debugPrint('Request body: ${json.encode(payload)}');
      debugPrint('Token: ${token.substring(0, 20)}...');

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      debugPrint('Response status: ${resp.statusCode}');
      debugPrint('Response body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final data = json.decode(resp.body);
          debugPrint('✅ Profile saved - profileId: ${data['profileId']}');
        } catch (_) {
          debugPrint('✅ Profile updated successfully');
        }
        return true;
      } else if (resp.statusCode == 401) {
        debugPrint('❌ Unauthorized - token expired or missing');
        return false;
      } else if (resp.statusCode == 500) {
        debugPrint('❌ Backend error: ${resp.body}');
        return false;
      } else {
        debugPrint('❌ Unexpected status: ${resp.statusCode}');
        return false;
      }
    } on SocketException catch (e) {
      debugPrint('❌ Connection error: ${e.message}');
      debugPrint('   Make sure backend is running and phone is on same WiFi');
      return false;
    } catch (e) {
      debugPrint('❌ Exception updating profile: $e');
      return false;
    }
  }

  /// POST /api/userprofile/upload-image?userId={userId}
  /// Uploads profile image (multipart form)
  static Future<String?> uploadProfileImage(
    int userId,
    String token,
    String imagePath,
  ) async {
    final uri = Uri.parse(
      '$_effectiveBaseUrl/api/userprofile/upload-image?userId=$userId',
    );

    try {
      debugPrint('=== ProfileService.uploadProfileImage ===');
      debugPrint('Uploading image for userId: $userId');
      debugPrint('URL: $uri');
      debugPrint('Image path: $imagePath');
      debugPrint('Token: ${token.substring(0, 20)}...');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      debugPrint('Sending multipart request...');

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          var jsonResponse = jsonDecode(responseData);
          final imagePath = jsonResponse['imagePath'] as String?;
          debugPrint('✅ Image uploaded - path: $imagePath');
          return imagePath;
        } catch (e) {
          debugPrint('❌ Failed to parse response: $e');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - token expired or missing');
        return null;
      } else if (response.statusCode == 404) {
        debugPrint('❌ Endpoint not found - backend may not have this route');
        return null;
      } else if (response.statusCode == 500) {
        debugPrint('❌ Backend error: $responseData');
        return null;
      } else {
        debugPrint('❌ Unexpected status: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('❌ Connection error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Exception uploading image: $e');
      return null;
    }
  }

  /// DELETE /api/profile/{userId}
  /// Deletes user account
  static Future<bool> deleteAccount(int userId, String token) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/profile/$userId');

    try {
      debugPrint('ProfileService.deleteAccount -> DELETE $uri');

      final resp = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('ProfileService.deleteAccount <- status ${resp.statusCode}');

      return resp.statusCode == 200 || resp.statusCode == 204;
    } on SocketException catch (e) {
      debugPrint(
        'ProfileService.deleteAccount - Connection error: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('ProfileService.deleteAccount - Error: $e');
      return false;
    }
  }
}
