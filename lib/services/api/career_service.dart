import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/constants/api_constants.dart';
import '../../models/career.dart';

class CareerService {
  static const String _careersPath = '/api/recommendations/careers';

  /// Fetch all careers from the backend
  static Future<List<Career>> getAllCareers() async {
    try {
      print('🔵 Fetching all careers...');
      print('🔵 URL: ${ApiConstants.baseUrl}$_careersPath');

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}$_careersPath'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out. Please check your internet connection.',
              );
            },
          );

      print('🔵 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Careers fetched successfully');

        final careersResponse = CareersResponse.fromJson(data);
        return careersResponse.careers;
      } else {
        print('❌ Failed to fetch careers: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch careers: ${response.statusCode}');
      }
    } on TimeoutException {
      print('⏱️ Request timed out');
      rethrow;
    } catch (e) {
      print('❌ Error fetching careers: $e');
      rethrow;
    }
  }
}
