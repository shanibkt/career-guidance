import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../models/course_module.dart';

class LearningVideoService {
  /// Fetch all learning videos
  static Future<List<CourseModule>> getAllVideos() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/learningvideos');
      print('📡 Fetching all learning videos from: $url');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videosJson = data['videos'] as List<dynamic>;

        final videos = videosJson.map((videoJson) {
          return CourseModule(
            id: videoJson['id'].toString(),
            title: videoJson['videoTitle'] as String,
            skillName: videoJson['skillName'] as String,
            description: videoJson['videoDescription'] as String? ?? '',
            youtubeVideoId: videoJson['youtubeVideoId'] as String,
            durationMinutes: videoJson['durationMinutes'] as int,
          );
        }).toList();

        print('✅ Successfully loaded ${videos.length} videos');
        return videos;
      } else {
        print('❌ Failed to load videos: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching all videos: $e');
      rethrow;
    }
  }

  /// Fetch videos by skill names
  static Future<List<CourseModule>> getVideosBySkills(
    List<String> skills,
  ) async {
    try {
      if (skills.isEmpty) {
        print('⚠️ No skills provided');
        return [];
      }

      // URL encode the JSON skills array
      final skillsJson = json.encode(skills);
      final encodedSkills = Uri.encodeComponent(skillsJson);

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/learningvideos/skills?skills=$encodedSkills',
      );

      print('📡 Fetching videos for skills: $skills');
      print('URL: $url');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videosJson = data['videos'] as List<dynamic>;

        final videos = videosJson.map((videoJson) {
          return CourseModule(
            id: videoJson['id'].toString(),
            title: videoJson['videoTitle'] as String,
            skillName: videoJson['skillName'] as String,
            description: videoJson['videoDescription'] as String? ?? '',
            youtubeVideoId: videoJson['youtubeVideoId'] as String,
            durationMinutes: videoJson['durationMinutes'] as int,
          );
        }).toList();

        print('✅ Successfully loaded ${videos.length} videos for skills');
        return videos;
      } else {
        print('❌ Failed to load videos by skills: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching videos by skills: $e');
      rethrow;
    }
  }

  /// Fetch single video by skill name
  static Future<CourseModule?> getVideoBySkill(String skillName) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/learningvideos/${Uri.encodeComponent(skillName)}',
      );

      print('📡 Fetching video for skill: $skillName');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final videoJson = json.decode(response.body);

        final video = CourseModule(
          id: videoJson['id'].toString(),
          title: videoJson['videoTitle'] as String,
          skillName: videoJson['skillName'] as String,
          description: videoJson['videoDescription'] as String? ?? '',
          youtubeVideoId: videoJson['youtubeVideoId'] as String,
          durationMinutes: videoJson['durationMinutes'] as int,
        );

        print('✅ Successfully loaded video for $skillName');
        return video;
      } else if (response.statusCode == 404) {
        print('⚠️ No video found for skill: $skillName');
        return null;
      } else {
        print('❌ Failed to load video: ${response.statusCode}');
        throw Exception('Failed to load video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching video for skill: $e');
      return null;
    }
  }
}
