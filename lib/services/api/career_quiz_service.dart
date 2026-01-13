import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import '../../core/config/api_config.dart';
import '../../services/local/storage_service.dart';
import '../../models/quiz_models.dart';

class CareerQuizService {
  static const String _quizPath = '/api/quiz';

  static Future<String?> _getToken() async {
    return await StorageService.loadAuthToken();
  }

  /// Generate AI-powered quiz questions based on user profile
  static Future<QuizResponse> generateQuiz() async {
    try {
      print('🔵 Starting quiz generation...');
      print('🔵 Base URL: ${ApiConfig.baseUrl}');
      print('🔵 Full URL: ${ApiConfig.baseUrl}$_quizPath/generate');

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ No token found!');
        throw Exception('Not logged in. Please login first.');
      }

      print('🔵 Token length: ${token.length}');
      print(
        '🔵 Token preview: ${token.substring(0, min(20, token.length))}...',
      );

      print('🔵 Making HTTP POST request...');
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_quizPath/generate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              print('⏱️ Request timed out after 45 seconds!');
              throw TimeoutException(
                'Quiz generation timed out. Please check your internet connection and try again.',
              );
            },
          );

      print('📡 Response received!');
      print('📡 Status code: ${response.statusCode}');
      print('📡 Response body length: ${response.body.length} bytes');

      // Print first 300 characters of response
      final preview = response.body.length > 300
          ? '${response.body.substring(0, 300)}...'
          : response.body;
      print('📡 Response preview: $preview');

      if (response.statusCode == 200) {
        print('✅ Status 200 - Parsing JSON...');
        final data = jsonDecode(response.body);

        print('✅ Quiz ID: ${data['quizId']}');
        print('✅ Questions count: ${data['questions']?.length}');

        if (data['questions'] != null && data['questions'].isNotEmpty) {
          print('✅ First question: ${data['questions'][0]['question']}');
        }

        print('✅ Creating QuizResponse object...');
        final quizResponse = QuizResponse.fromJson(data);
        print('✅ Quiz generated successfully!');
        return quizResponse;
      } else if (response.statusCode == 400) {
        print('❌ Status 400 - Bad Request');
        final error = jsonDecode(response.body);
        print('❌ Error details: $error');
        throw Exception(
          error['details'] ?? 'Please add skills to your profile first',
        );
      } else if (response.statusCode == 401) {
        print('❌ Status 401 - Unauthorized');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 504 || response.statusCode == 503) {
        print('❌ Status ${response.statusCode} - Service Unavailable/Timeout');
        throw Exception('AI service timeout. Please try again in a moment.');
      } else if (response.statusCode == 500) {
        print('❌ Status 500 - Internal Server Error');
        final error = jsonDecode(response.body);
        print('❌ Error details: $error');
        throw Exception(error['details'] ?? 'Server error. Please try again.');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception(
          'Failed to generate quiz. Status: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      print('💥 TimeoutException: $e');
      throw Exception(
        'Request timed out. The AI is taking longer than expected. Please try again.',
      );
    } on SocketException catch (e) {
      print('💥 SocketException: $e');
      print('💥 This usually means:');
      print('   - Cannot reach server at ${ApiConfig.baseUrl}');
      print('   - Check if backend is running');
      print('   - Check if IP address is correct');
      print('   - Check if device/emulator is on same network');
      throw Exception('No internet connection. Please check your network.');
    } on FormatException catch (e) {
      print('💥 FormatException: $e');
      print('💥 Response was not valid JSON');
      throw Exception('Invalid response from server. Please try again.');
    } catch (e, stackTrace) {
      print('💥 UNEXPECTED EXCEPTION: $e');
      print('💥 Type: ${e.runtimeType}');
      print('💥 Stack trace:');
      print(stackTrace);
      rethrow;
    }
  }

  /// Generate quiz based on skill name (fallback when no transcript)
  static Future<QuizResponse> generateQuizFromSkillName({
    required String skillName,
    required String videoTitle,
  }) async {
    try {
      print('🔵 Starting skill-based quiz generation...');
      print('🔵 Skill: $skillName');
      print('🔵 Video: $videoTitle');
      print('🔵 Full URL: ${ApiConfig.baseUrl}$_quizPath/generate-from-skill');

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ No token found!');
        throw Exception('Not logged in. Please login first.');
      }

      print('🔵 Making HTTP POST request...');
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_quizPath/generate-from-skill'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'skill_name': skillName,
              'video_title': videoTitle,
            }),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              print('⏱️ Request timed out after 45 seconds!');
              throw TimeoutException(
                'Quiz generation timed out. Please check your internet connection and try again.',
              );
            },
          );

      print('📡 Response received!');
      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Status 200 - Parsing JSON...');
        final data = jsonDecode(response.body);
        print('✅ Quiz ID: ${data['quizId']}');
        print('✅ Questions count: ${data['questions']?.length}');
        return QuizResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        print('❌ Status 400 - Bad Request');
        final error = jsonDecode(response.body);
        throw Exception(error['details'] ?? 'Invalid request');
      } else if (response.statusCode == 401) {
        print('❌ Status 401 - Unauthorized');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 504 || response.statusCode == 503) {
        print('❌ Status ${response.statusCode} - Service Unavailable/Timeout');
        throw Exception('AI service timeout. Please try again in a moment.');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
        throw Exception('Failed to generate quiz: ${response.statusCode}');
      }
    } on SocketException {
      print('❌ Network error!');
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      print('❌ Request timed out!');
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      print('❌ Error generating skill-based quiz: $e');
      rethrow;
    }
  }

  /// Generate quiz with automatic retry on failure
  static Future<QuizResponse> generateQuizWithRetry({
    int maxRetries = 2,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await generateQuiz();
      } catch (e) {
        attempts++;
        print('⚠️ Attempt $attempts failed: $e');

        if (attempts >= maxRetries) {
          throw Exception(
            'Failed after $maxRetries attempts. Please try again later.',
          );
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: 2 * attempts));
        print('🔄 Retrying... (attempt ${attempts + 1})');
      }
    }

    throw Exception('Quiz generation failed');
  }

  /// Submit quiz answers to backend
  static Future<QuizResult> submitQuiz(
    String quizId,
    List<QuizAnswer> answers,
  ) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in. Please login first.');
    }

    try {
      print('📤 Submitting quiz answers for quiz $quizId...');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_quizPath/submit'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'quiz_id': quizId, // Backend expects snake_case
              'answers': answers.map((a) => a.toJson()).toList(),
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Quiz submission timed out');
            },
          );

      print('📡 Submit response: ${response.statusCode}');
      print('📡 Response body length: ${response.body.length} bytes');

      // Always print the response body for debugging
      final preview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('📡 Full response: $preview');

      if (response.statusCode == 200) {
        print('✅ Status 200 - Parsing submission result...');

        try {
          final data = jsonDecode(response.body);
          print('✅ JSON parsed successfully');
          print('✅ Response keys: ${data.keys.toList()}');

          print('✅ Creating QuizResult object...');
          final result = QuizResult.fromJson(data);
          print('✅ Quiz submitted successfully');
          print('✅ Total score: ${result.totalScore}/${result.totalQuestions}');
          print('✅ Career matches: ${result.careerMatches.length}');
          return result;
        } catch (e, stackTrace) {
          print('💥 Error parsing quiz result: $e');
          print('💥 Stack trace: $stackTrace');
          throw Exception('Failed to parse quiz results: $e');
        }
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['details'] ?? 'Invalid quiz data');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Quiz not found. Please try again.');
      } else if (response.statusCode == 500) {
        print('❌ Server error (500): ${response.body}');
        try {
          final error = jsonDecode(response.body);
          final details = error['details'] ?? error['error'] ?? 'Server error';
          print('❌ Error details: $details');
          throw Exception('Backend error: $details');
        } catch (parseError) {
          print('❌ Could not parse error: $parseError');
          // Show the raw response body if we can't parse it
          throw Exception('Backend error: ${response.body}');
        }
      } else {
        print('❌ Failed to submit quiz: ${response.body}');
        try {
          final error = jsonDecode(response.body);
          final details = error['details'] ?? error['error'] ?? 'Unknown error';
          throw Exception(details);
        } catch (e) {
          throw Exception('Failed to submit quiz. Please try again.');
        }
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      print('📡 Network error: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e, stackTrace) {
      print('❌ Error submitting quiz: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate quiz from video transcript
  static Future<QuizResponse> generateQuizFromTranscript({
    required String transcript,
    required String skillName,
    String? videoTitle,
  }) async {
    try {
      print('🎬 Starting transcript-based quiz generation...');
      print('🎬 Skill: $skillName');
      print('🎬 Video: ${videoTitle ?? "Unknown"}');
      print('🎬 Transcript length: ${transcript.length} characters');
      print(
        '🎬 Transcript preview (first 300 chars): ${transcript.substring(0, transcript.length > 300 ? 300 : transcript.length)}',
      );

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not logged in. Please login first.');
      }

      print(
        '📤 Sending POST request to: ${ApiConfig.baseUrl}$_quizPath/generate-from-transcript',
      );

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}$_quizPath/generate-from-transcript',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'transcript': transcript,
              'skill_name': skillName,
              'video_title': videoTitle,
            }),
          )
          .timeout(
            const Duration(seconds: 50),
            onTimeout: () {
              throw TimeoutException(
                'Transcript quiz generation timed out. Please try again.',
              );
            },
          );

      print('📡 Transcript quiz response: ${response.statusCode}');
      print(
        '📡 Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Transcript-based quiz generated successfully!');
        print('✅ Number of questions: ${data['questions']?.length ?? 0}');
        return QuizResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        print('❌ Bad request (400): ${error['details']}');
        throw Exception(error['details'] ?? 'Invalid request');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 504 || response.statusCode == 503) {
        throw Exception('AI service timeout. Please try again in a moment.');
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body);
        print('❌ Server error (500): ${error['details']}');
        throw Exception(error['details'] ?? 'Server error. Please try again.');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception(
          'Failed to generate quiz. Status: ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      print('💥 TimeoutException: $e');
      throw Exception(
        'Request timed out. The AI is taking longer than expected. Please try again.',
      );
    } on SocketException catch (e) {
      print('💥 SocketException: $e');
      throw Exception('No internet connection. Please check your network.');
    } catch (e, stackTrace) {
      print('💥 Error generating transcript quiz: $e');
      print('💥 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate quiz from video (backend extracts captions)
  /// This is the NEW method - backend handles caption extraction!
  static Future<QuizResponse> generateQuizFromVideo({
    required String videoId,
    required String skillName,
    String? videoTitle,
  }) async {
    try {
      print('🎥 Starting video-based quiz generation...');
      print('🎥 Video ID: $videoId');
      print('🎥 Skill: $skillName');
      print('🎥 Video: ${videoTitle ?? "Unknown"}');
      print('🎥 Full URL: ${ApiConfig.baseUrl}$_quizPath/generate-from-video');

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not logged in. Please login first.');
      }

      print('🎥 Making HTTP POST request to backend...');
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_quizPath/generate-from-video'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'video_id': videoId,
              'skill_name': skillName,
              'video_title': videoTitle,
            }),
          )
          .timeout(
            const Duration(
              seconds: 60,
            ), // Longer timeout for caption extraction
            onTimeout: () {
              throw TimeoutException(
                'Video processing timed out. Please try again.',
              );
            },
          );

      print('📡 Response received!');
      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Status 200 - Parsing JSON...');
        final data = jsonDecode(response.body);

        final transcriptAvailable = data['transcript_available'] ?? false;
        final message = data['message'] ?? '';

        print('✅ Quiz ID: ${data['quiz_id']}');
        print('✅ Questions count: ${data['questions']?.length}');
        print('📝 Transcript available: $transcriptAvailable');
        print('💬 Message: $message');

        return QuizResponse(
          quizId: data['quiz_id'] as String,
          questions: (data['questions'] as List)
              .map((q) => QuizQuestion.fromJson(q))
              .toList(),
        );
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['details'] ?? 'Invalid request');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 504 || response.statusCode == 503) {
        throw Exception('Service timeout. Please try again in a moment.');
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body);
        throw Exception(error['details'] ?? 'Server error. Please try again.');
      } else {
        throw Exception('Failed to generate quiz: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e, stackTrace) {
      print('❌ Error generating video quiz: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get all videos with transcript information (Admin only)
  static Future<List<dynamic>> getAllVideosWithTranscripts() async {
    try {
      print('📋 Fetching all videos with transcript info...');
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/learningvideos'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = data['videos'] as List;

        // Add transcript info to each video
        final videosWithInfo = <Map<String, dynamic>>[];
        for (var video in videos) {
          final transcriptInfo = await getVideoTranscript(video['id']);
          videosWithInfo.add({
            'id': video['id'],
            'skillName': video['skillName'],
            'videoTitle': video['videoTitle'],
            'youtubeVideoId': video['youtubeVideoId'],
            'hasTranscript': transcriptInfo['hasTranscript'] ?? false,
            'transcriptLength': transcriptInfo['transcriptLength'] ?? 0,
          });
        }

        print('✅ Loaded ${videosWithInfo.length} videos');
        return videosWithInfo;
      } else {
        throw Exception('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching videos: $e');
      rethrow;
    }
  }

  /// Get transcript for a specific video
  static Future<Map<String, dynamic>> getVideoTranscript(int videoId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/learningvideos/$videoId/transcript',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch transcript: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching transcript: $e');
      rethrow;
    }
  }

  /// Update video transcript (Admin only)
  static Future<void> updateVideoTranscript(
    int videoId,
    String transcript,
  ) async {
    try {
      print('💾 Updating transcript for video $videoId...');
      print('💾 Transcript length: ${transcript.length} characters');

      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/learningvideos/$videoId/transcript',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'transcript': transcript}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Transcript updated successfully');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Admin access required.');
      } else if (response.statusCode == 404) {
        throw Exception('Video not found');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update transcript');
      }
    } catch (e) {
      print('❌ Error updating transcript: $e');
      rethrow;
    }
  }
}
