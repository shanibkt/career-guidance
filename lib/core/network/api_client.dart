import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Base API client with common functionality
/// All API services should extend or use this class
class ApiClient {
  /// Make a GET request
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Duration? timeout,
  }) async {
    try {
      Uri uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      debugPrint('🌐 GET: $uri');

      final response = await http
          .get(uri, headers: headers ?? ApiConfig.jsonHeaders)
          .timeout(
            timeout ?? ApiConfig.defaultTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      _logResponse('GET', uri.toString(), response);
      return response;
    } on SocketException {
      throw const SocketException(
        'No internet connection or server unreachable',
      );
    } on TimeoutException {
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      rethrow;
    }
  }

  /// Make a POST request
  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      debugPrint('🌐 POST: $uri');
      if (body != null) {
        debugPrint('📤 Body: ${json.encode(body)}');
      }

      final response = await http
          .post(
            uri,
            headers: headers ?? ApiConfig.jsonHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            timeout ?? ApiConfig.defaultTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      _logResponse('POST', uri.toString(), response);
      return response;
    } on SocketException {
      throw const SocketException(
        'No internet connection or server unreachable',
      );
    } on TimeoutException {
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      rethrow;
    }
  }

  /// Make a PUT request
  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      debugPrint('🌐 PUT: $uri');

      final response = await http
          .put(
            uri,
            headers: headers ?? ApiConfig.jsonHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            timeout ?? ApiConfig.defaultTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      _logResponse('PUT', uri.toString(), response);
      return response;
    } on SocketException {
      throw const SocketException(
        'No internet connection or server unreachable',
      );
    } on TimeoutException {
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('❌ PUT Error: $e');
      rethrow;
    }
  }

  /// Make a DELETE request
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      debugPrint('🌐 DELETE: $uri');

      final response = await http
          .delete(uri, headers: headers ?? ApiConfig.jsonHeaders)
          .timeout(
            timeout ?? ApiConfig.defaultTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      _logResponse('DELETE', uri.toString(), response);
      return response;
    } on SocketException {
      throw const SocketException(
        'No internet connection or server unreachable',
      );
    } on TimeoutException {
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('❌ DELETE Error: $e');
      rethrow;
    }
  }

  /// Upload a file with multipart request
  static Future<http.StreamedResponse> uploadFile(
    String endpoint, {
    required Map<String, String> headers,
    required File file,
    required String fieldName,
    Map<String, String>? fields,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      debugPrint('🌐 UPLOAD: $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Add file
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(
        timeout ?? ApiConfig.uploadTimeout,
        onTimeout: () => throw TimeoutException('Upload timed out'),
      );

      debugPrint('📥 Response status: ${streamedResponse.statusCode}');
      return streamedResponse;
    } on SocketException {
      throw const SocketException(
        'No internet connection or server unreachable',
      );
    } on TimeoutException {
      throw TimeoutException('Upload timed out. Please try again.');
    } catch (e) {
      debugPrint('❌ Upload Error: $e');
      rethrow;
    }
  }

  /// Parse response body as JSON
  static Map<String, dynamic> parseJson(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ JSON Parse Error: $e');
      debugPrint('Response body: ${response.body}');
      throw FormatException('Invalid JSON response from server');
    }
  }

  /// Parse response body as JSON list
  static List<dynamic> parseJsonList(http.Response response) {
    try {
      return json.decode(response.body) as List<dynamic>;
    } catch (e) {
      debugPrint('❌ JSON List Parse Error: $e');
      debugPrint('Response body: ${response.body}');
      throw FormatException('Invalid JSON array response from server');
    }
  }

  /// Extract error message from response
  static String getErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['message'] as String? ??
          data['error'] as String? ??
          data['details'] as String? ??
          'Request failed with status ${response.statusCode}';
    } catch (e) {
      return 'Request failed with status ${response.statusCode}';
    }
  }

  /// Check if response is successful (2xx status code)
  static bool isSuccess(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Log response details (only in debug mode)
  static void _logResponse(String method, String url, http.Response response) {
    if (kDebugMode) {
      debugPrint('📥 $method $url');
      debugPrint('   Status: ${response.statusCode}');
      if (response.body.length < 500) {
        debugPrint('   Body: ${response.body}');
      } else {
        debugPrint('   Body: ${response.body.substring(0, 500)}...');
      }
    }
  }

  /// Test connection to backend
  static Future<bool> testConnection() async {
    try {
      final response = await get(
        ApiConfig.careers,
        timeout: const Duration(seconds: 5),
      );
      return isSuccess(response);
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Get user-friendly error message
  static String getErrorFromException(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid response from server.';
    } else if (error is HttpException) {
      return 'Network error occurred.';
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
}
