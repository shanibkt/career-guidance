import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../local/storage_service.dart';

class CareerProgressService {
  /// Save selected career to database
  static Future<bool> saveSelectedCareer({
    required String careerName,
    required List<String> requiredSkills,
    int? careerId,
  }) async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) {
        print('❌ No auth token found');
        return false;
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/careerprogress/select',
      );
      print('📡 Saving selected career: $careerName');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'careerId': careerId,
              'careerName': careerName,
              'requiredSkills': requiredSkills,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Career saved successfully');
        return true;
      } else {
        print('❌ Failed to save career: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving selected career: $e');
      return false;
    }
  }

  /// Get selected career from database
  static Future<Map<String, dynamic>?> getSelectedCareer() async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) {
        print('❌ No auth token found');
        return null;
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/careerprogress/selected',
      );
      print('📡 Fetching selected career');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Selected career loaded: ${data['careerName']}');
        return data;
      } else if (response.statusCode == 404) {
        print('⚠️ No career selected');
        return null;
      } else {
        print('❌ Failed to load career: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching selected career: $e');
      return null;
    }
  }

  /// Save course progress to database
  static Future<bool> saveCourseProgress({
    required String careerName,
    required String courseId,
    required String skillName,
    required String videoTitle,
    required String youtubeVideoId,
    required double watchedPercentage,
    required int watchTimeSeconds,
    required int totalDurationSeconds,
    required bool isCompleted,
  }) async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) {
        print('⚠️ No auth token, skipping progress save');
        return false;
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/careerprogress/course',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'careerName': careerName,
              'courseId': courseId,
              'skillName': skillName,
              'videoTitle': videoTitle,
              'youtubeVideoId': youtubeVideoId,
              'watchedPercentage': watchedPercentage,
              'watchTimeSeconds': watchTimeSeconds,
              'totalDurationSeconds': totalDurationSeconds,
              'isCompleted': isCompleted,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print(
          '✅ Course progress saved: $skillName - ${watchedPercentage.toStringAsFixed(1)}%',
        );
        return true;
      } else {
        print('❌ Failed to save progress: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving course progress: $e');
      return false;
    }
  }

  /// Get all course progress for a career
  static Future<List<Map<String, dynamic>>> getCourseProgress({
    String? careerName,
  }) async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) {
        print('❌ No auth token found');
        return [];
      }

      final url = careerName != null
          ? Uri.parse(
              '${ApiConstants.baseUrl}/api/careerprogress/courses?careerName=${Uri.encodeComponent(careerName)}',
            )
          : Uri.parse('${ApiConstants.baseUrl}/api/careerprogress/courses');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final courses = (data['courses'] as List<dynamic>)
            .map((course) => course as Map<String, dynamic>)
            .toList();
        print('✅ Loaded ${courses.length} course progress records');
        return courses;
      } else {
        print('❌ Failed to load course progress: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching course progress: $e');
      return [];
    }
  }
}
