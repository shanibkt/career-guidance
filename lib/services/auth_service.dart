import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/user.dart';

class AuthResult {
  final bool success;
  final String? token;
  final User? user;
  final String? message;

  AuthResult({required this.success, this.token, this.user, this.message});
}

class AuthService {
  // Base URL - change if needed
  static const String _baseUrl = 'http://localhost:5001';

  // On Android emulators `localhost` refers to the emulator itself; use 10.0.2.2
  static String get _effectiveBaseUrl {
    try {
      if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5001';
    } catch (_) {}
    return _baseUrl;
  }

  /// POST /api/auth/login
  /// body: { "email": "...", "password": "..." }
  /// expected success response: { "token": "<jwt>", "user": { ... } }
  static Future<AuthResult> login(String email, String password) async {
    final uri = Uri.parse('${_effectiveBaseUrl}/api/auth/login');

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final token = body['token'] as String?;
        final userJson = body['user'] as Map<String, dynamic>?;
        final user = userJson != null ? User.fromJson(userJson) : null;

        if (token != null && user != null) {
          return AuthResult(success: true, token: token, user: user);
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
            'Connection refused — is the API running at ${_effectiveBaseUrl}? (${e.message})',
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

  /// POST /api/auth/signup
  /// Sends a map of signup fields and expects similar response to login:
  /// { "token": "<jwt>", "user": { ... } }
  static Future<AuthResult> signup(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${_effectiveBaseUrl}/api/auth/signup');

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

        // user may be under 'user', 'data', or 'result'
        Map<String, dynamic>? userJson;
        if (body['user'] is Map<String, dynamic>)
          userJson = body['user'] as Map<String, dynamic>?;
        userJson ??= (body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>?
            : null;
        userJson ??= (body['result'] is Map<String, dynamic>)
            ? body['result'] as Map<String, dynamic>?
            : null;

        final user = userJson != null ? User.fromJson(userJson) : null;

        // If we have at least token or user, return them.
        if (token != null || user != null) {
          return AuthResult(success: true, token: token, user: user);
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
            'Connection refused — is the API running at ${_effectiveBaseUrl}? (${e.message})',
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
}
