import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/config/api_config.dart';
import '../../models/career.dart';
import '../../models/career_recommendation.dart';
import '../local/storage_service.dart';

class CareerService {
  static const String _careersPath = '/api/recommendations/careers';

  /// Fetch all careers from the backend
  static Future<List<Career>> getAllCareers() async {
    try {
      print('🔵 Fetching all careers...');
      print('🔵 URL: ${ApiConfig.baseUrl}$_careersPath');

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$_careersPath'),
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

  /// Fetch AI-generated career recommendations for the current user
  static Future<List<CareerRecommendation>> getAIRecommendations() async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) throw Exception('No authentication token found');

      print('🔵 Fetching AI recommendations...');
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/recommendations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recommendationsResponse = RecommendationsResponse.fromJson(data);
        return recommendationsResponse.recommendations;
      } else if (response.statusCode == 404) {
        // No recommendations yet
        return [];
      } else {
        throw Exception(
          'Failed to fetch recommendations: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching AI recommendations: $e');
      rethrow;
    }
  }
}
