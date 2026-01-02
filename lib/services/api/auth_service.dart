import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../models/user.dart';
import '../../core/config/api_config.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final DateTime? tokenExpiration;
  final User? user;
  final String? message;

  AuthResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.tokenExpiration,
    this.user,
    this.message,
  });
}

class AuthService {
  // Use centralized API configuration
  static String get _effectiveBaseUrl {
    debugPrint('🔵 AuthService using base URL: ${ApiConfig.baseUrl}');
    return ApiConfig.baseUrl;
  }

  // Public method to get API URL for debugging
  static String getApiUrl() => ApiConfig.baseUrl;

  /// POST /api/auth/login
  /// body: { "email": "...", "password": "..." }
  /// expected success response (flexible):
  /// - { "token": "<jwt>", "user": { ... } }
  /// - { "accessToken": "<jwt>", "data": { ... } }
  /// - { "access_token": "<jwt>", "result": { ... } }
  static Future<AuthResult> login(String email, String password) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/auth/login');

    try {
      // Debug: log request
      try {
        debugPrint('AuthService.login -> POST $uri');
        debugPrint(
          'AuthService.login payload: ${json.encode({'email': email, 'password': password})}',
        );
      } catch (_) {}

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      // Debug: log response
      try {
        debugPrint('AuthService.login <- status ${resp.statusCode}');
        debugPrint('AuthService.login body: ${resp.body}');
      } catch (_) {}

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);

        // Be tolerant of token and user keys, similar to signup()
        String? token = body['token'] as String?;
        token ??= body['accessToken'] as String?;
        token ??= body['access_token'] as String?;

        // Extract refresh token
        String? refreshToken = body['refreshToken'] as String?;
        refreshToken ??= body['refresh_token'] as String?;

        // Extract token expiration
        DateTime? tokenExpiration;
        if (body['tokenExpiration'] != null) {
          tokenExpiration = DateTime.parse(body['tokenExpiration'].toString());
        } else if (body['token_expiration'] != null) {
          tokenExpiration = DateTime.parse(body['token_expiration'].toString());
        }

        Map<String, dynamic>? userJson;
        if (body['user'] is Map<String, dynamic>) {
          userJson = body['user'] as Map<String, dynamic>;
        }
        userJson ??= (body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>
            : null;
        userJson ??= (body['result'] is Map<String, dynamic>)
            ? body['result'] as Map<String, dynamic>
            : null;

        final user = userJson != null ? User.fromJson(userJson) : null;

        // If either token or user is present, return success with what we have
        if (token != null || user != null) {
          return AuthResult(
            success: true,
            token: token,
            refreshToken: refreshToken,
            tokenExpiration: tokenExpiration,
            user: user,
          );
        }

        return AuthResult(
          success: false,
          message: 'Malformed response from server',
        );
      }

      // Try to parse error message
      String message = 'Login failed (${resp.statusCode})';
      try {
        final Map<String, dynamic> body = json.decode(resp.body);
        if (body.containsKey('message')) {
          message = body['message'].toString();
        } else if (body.containsKey('error')) {
          message = body['error'].toString();
        } else {
          message = resp.body.toString();
        }
      } catch (_) {
        message = resp.body.toString();
      }

      return AuthResult(success: false, message: message);
    } on SocketException catch (e) {
      return AuthResult(
        success: false,
        message:
            'Connection refused — is the API running at $_effectiveBaseUrl? (${e.message})',
      );
    } on FormatException catch (e) {
      return AuthResult(
        success: false,
        message: 'Bad response format: ${e.message}',
      );
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  /// POST /api/auth/forgot-password
  /// Sends email for password reset
  /// { "email": "user@example.com" }
  static Future<AuthResult> forgotPassword(String email) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/auth/forgot-password');

    try {
      debugPrint('AuthService.forgotPassword -> POST $uri');
      debugPrint('AuthService.forgotPassword email: $email');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      debugPrint('AuthService.forgotPassword <- status ${resp.statusCode}');
      debugPrint('AuthService.forgotPassword body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final message =
            body['message']?.toString() ?? 'Reset link sent to your email';
        return AuthResult(success: true, message: message);
      }

      // Handle error
      String message = 'Failed to send reset link (${resp.statusCode})';
      try {
        final Map<String, dynamic> body = json.decode(resp.body);
        if (body.containsKey('message')) {
          message = body['message'].toString();
        } else if (body.containsKey('error')) {
          message = body['error'].toString();
        }
      } catch (_) {
        message = resp.body.toString();
      }

      return AuthResult(success: false, message: message);
    } on SocketException catch (e) {
      return AuthResult(
        success: false,
        message:
            'Connection refused — is the API running at $_effectiveBaseUrl? (${e.message})',
      );
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  /// POST /api/auth/signup
  /// Sends a map of signup fields and expects similar response to login:
  /// { "token": "<jwt>", "user": { ... } }
  static Future<AuthResult> signup(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/auth/signup');

    try {
      // Debug: print payload being sent so we can inspect if fields are present
      try {
        // Use debugPrint to avoid flooding release logs
        debugPrint(
          'AuthService.signup - sending payload: ${json.encode(payload)}',
        );
      } catch (_) {}

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      // Debug: print response status and body for diagnosis
      try {
        debugPrint(
          'AuthService.signup - response (${resp.statusCode}): ${resp.body}',
        );
      } catch (_) {}

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Be tolerant of different backend response shapes. Try common keys.
        final Map<String, dynamic> body = json.decode(resp.body);

        // token may be under several keys
        String? token = body['token'] as String?;
        token ??= body['accessToken'] as String?;
        token ??= body['access_token'] as String?;

        // Extract refresh token
        String? refreshToken = body['refreshToken'] as String?;
        refreshToken ??= body['refresh_token'] as String?;

        // Extract token expiration
        DateTime? tokenExpiration;
        if (body['tokenExpiration'] != null) {
          tokenExpiration = DateTime.parse(body['tokenExpiration'].toString());
        } else if (body['token_expiration'] != null) {
          tokenExpiration = DateTime.parse(body['token_expiration'].toString());
        }

        // user may be under 'user', 'data', or 'result'
        Map<String, dynamic>? userJson;
        if (body['user'] is Map<String, dynamic>) {
          userJson = body['user'] as Map<String, dynamic>?;
        }
        userJson ??= (body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>?
            : null;
        userJson ??= (body['result'] is Map<String, dynamic>)
            ? body['result'] as Map<String, dynamic>?
            : null;

        final user = userJson != null ? User.fromJson(userJson) : null;

        // If we have at least token or user, return them.
        if (token != null || user != null) {
          return AuthResult(
            success: true,
            token: token,
            refreshToken: refreshToken,
            tokenExpiration: tokenExpiration,
            user: user,
          );
        }

        // No token/user provided but HTTP status is success: treat as signup success
        // and pass along any server message if present. This supports backends that
        // simply return a message on signup (e.g. { "message": "User created" }).
        final serverMessage = (body['message'] ?? body['msg'] ?? body['status'])
            ?.toString();
        return AuthResult(
          success: true,
          message: serverMessage ?? 'Signup succeeded',
        );
      }

      String message = 'Signup failed (${resp.statusCode})';
      try {
        final Map<String, dynamic> body = json.decode(resp.body);
        if (body.containsKey('message')) {
          message = body['message'].toString();
        } else if (body.containsKey('error')) {
          message = body['error'].toString();
        } else {
          message = resp.body.toString();
        }
      } catch (_) {
        message = resp.body.toString();
      }

      return AuthResult(success: false, message: message);
    } on SocketException catch (e) {
      return AuthResult(
        success: false,
        message:
            'Connection refused — is the API running at $_effectiveBaseUrl? (${e.message})',
      );
    } on FormatException catch (e) {
      return AuthResult(
        success: false,
        message: 'Bad response format: ${e.message}',
      );
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  /// POST /api/auth/reset-password
  /// Reset password with token/OTP and new password
  static Future<AuthResult> resetPassword(
    String token,
    String newPassword,
  ) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/auth/reset-password');

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'newPassword': newPassword}),
      );

      debugPrint('AuthService.resetPassword status: ${resp.statusCode}');
      debugPrint('AuthService.resetPassword body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final message =
            body['message']?.toString() ?? 'Password reset successfully';
        return AuthResult(success: true, message: message);
      }

      // Handle error
      String message = 'Failed to reset password (${resp.statusCode})';
      try {
        final Map<String, dynamic> body = json.decode(resp.body);
        if (body.containsKey('message')) {
          message = body['message'].toString();
        } else if (body.containsKey('error')) {
          message = body['error'].toString();
        }
      } catch (_) {
        message = resp.body.toString();
      }

      return AuthResult(success: false, message: message);
    } on SocketException catch (e) {
      return AuthResult(
        success: false,
        message:
            'Connection refused — is the API running at $_effectiveBaseUrl? (${e.message})',
      );
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  /// POST /api/auth/refresh
  /// Refresh the access token using refresh token
  static Future<AuthResult> refreshAccessToken(String refreshToken) async {
    final uri = Uri.parse('$_effectiveBaseUrl/api/auth/refresh');

    try {
      debugPrint('AuthService.refreshAccessToken -> POST $uri');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      debugPrint('AuthService.refreshAccessToken <- status ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);

        // Extract new token
        String? token = body['token'] as String?;
        token ??= body['accessToken'] as String?;
        token ??= body['access_token'] as String?;

        // Extract new refresh token
        String? newRefreshToken = body['refreshToken'] as String?;
        newRefreshToken ??= body['refresh_token'] as String?;

        // Extract token expiration
        DateTime? tokenExpiration;
        if (body['tokenExpiration'] != null) {
          tokenExpiration = DateTime.parse(body['tokenExpiration'].toString());
        } else if (body['token_expiration'] != null) {
          tokenExpiration = DateTime.parse(body['token_expiration'].toString());
        }

        // Extract user if provided
        Map<String, dynamic>? userJson;
        if (body['user'] is Map<String, dynamic>) {
          userJson = body['user'] as Map<String, dynamic>;
        }
        final user = userJson != null ? User.fromJson(userJson) : null;

        if (token != null) {
          return AuthResult(
            success: true,
            token: token,
            refreshToken: newRefreshToken,
            tokenExpiration: tokenExpiration,
            user: user,
          );
        }

        return AuthResult(
          success: false,
          message: 'No token in refresh response',
        );
      }

      // Token expired or invalid
      String message = 'Token refresh failed (${resp.statusCode})';
      try {
        final Map<String, dynamic> body = json.decode(resp.body);
        if (body.containsKey('message')) {
          message = body['message'].toString();
        } else if (body.containsKey('error')) {
          message = body['error'].toString();
        }
      } catch (_) {
        message = resp.body.toString();
      }

      return AuthResult(success: false, message: message);
    } on SocketException catch (e) {
      return AuthResult(
        success: false,
        message:
            'Connection refused — is the API running at $_effectiveBaseUrl? (${e.message})',
      );
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }
}
