import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class AdminService {
  static String get _base => ApiConfig.baseUrl;

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// GET /api/admin/users?page=&pageSize=&search=
  static Future<Map<String, dynamic>?> getUsers({
    required String token,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse(
        '$_base${ApiConfig.adminUsers}',
      ).replace(queryParameters: params);
      final resp = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(ApiConfig.defaultTimeout);

      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// GET /api/admin/stats
  static Future<Map<String, dynamic>?> getStats({required String token}) async {
    try {
      final uri = Uri.parse('$_base${ApiConfig.adminStats}');
      final resp = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(ApiConfig.defaultTimeout);

      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// DELETE /api/admin/users/{userId}
  static Future<bool> deleteUser({
    required String token,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$_base${ApiConfig.adminUsers}/$userId');
      final resp = await http
          .delete(uri, headers: _authHeaders(token))
          .timeout(ApiConfig.defaultTimeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
