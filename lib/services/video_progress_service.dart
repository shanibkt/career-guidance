import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local/storage_service.dart';

// Video progress model
class VideoProgress {
  final String videoId;
  final String videoTitle;
  final String skillName;
  final String careerName;
  final int currentPositionSeconds;
  final int durationSeconds;
  final double watchPercentage;
  final bool isCompleted;
  final DateTime? lastWatched;

  VideoProgress({
    required this.videoId,
    required this.videoTitle,
    required this.skillName,
    required this.careerName,
    required this.currentPositionSeconds,
    required this.durationSeconds,
    required this.watchPercentage,
    required this.isCompleted,
    this.lastWatched,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'videoTitle': videoTitle,
    'skillName': skillName,
    'careerName': careerName,
    'currentPositionSeconds': currentPositionSeconds,
    'durationSeconds': durationSeconds,
    'watchPercentage': watchPercentage,
    'isCompleted': isCompleted,
  };

  factory VideoProgress.fromJson(Map<String, dynamic> json) {
    return VideoProgress(
      videoId: json['videoId'] ?? '',
      videoTitle: json['videoTitle'] ?? '',
      skillName: json['skillName'] ?? '',
      careerName: json['careerName'] ?? '',
      currentPositionSeconds: json['currentPositionSeconds'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
      watchPercentage: (json['watchPercentage'] ?? 0.0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
      lastWatched: json['lastWatched'] != null
          ? DateTime.parse(json['lastWatched'])
          : null,
    );
  }
}

// Learning path summary
class LearningPathSummary {
  final String careerName;
  final String skillName;
  final int totalVideos;
  final int completedVideos;
  final int totalDurationSeconds;
  final int watchedDurationSeconds;
  final double progressPercentage;
  final DateTime? lastAccessed;

  LearningPathSummary({
    required this.careerName,
    required this.skillName,
    required this.totalVideos,
    required this.completedVideos,
    required this.totalDurationSeconds,
    required this.watchedDurationSeconds,
    required this.progressPercentage,
    this.lastAccessed,
  });

  factory LearningPathSummary.fromJson(Map<String, dynamic> json) {
    return LearningPathSummary(
      careerName: json['careerName'] ?? '',
      skillName: json['skillName'] ?? '',
      totalVideos: json['totalVideos'] ?? 0,
      completedVideos: json['completedVideos'] ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      watchedDurationSeconds: json['watchedDurationSeconds'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : null,
    );
  }

  String get formattedTotalDuration => _formatDuration(totalDurationSeconds);
  String get formattedWatchedDuration =>
      _formatDuration(watchedDurationSeconds);
  String get formattedRemainingDuration =>
      _formatDuration(totalDurationSeconds - watchedDurationSeconds);

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

class VideoProgressService {
  static const String baseUrl = 'http://192.168.1.4:5087/api';

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.loadAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Save/Update video progress
  Future<Map<String, dynamic>> saveVideoProgress(VideoProgress progress) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/videoprogress/save'),
        headers: headers,
        body: jsonEncode(progress.toJson()),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Progress saved'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to save progress',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get video progress
  Future<Map<String, dynamic>> getVideoProgress(
    String videoId,
    String careerName,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videoprogress/$videoId?careerName=$careerName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': VideoProgress.fromJson(data)};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'notFound': true,
          'message': 'No progress found',
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch progress'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all videos progress for a career
  Future<Map<String, dynamic>> getAllVideoProgress(String careerName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videoprogress/career/$careerName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<VideoProgress> progressList = data
            .map((json) => VideoProgress.fromJson(json))
            .toList();
        return {'success': true, 'data': progressList};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch progress',
          'data': <VideoProgress>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'data': <VideoProgress>[],
      };
    }
  }

  // Get learning path summary
  Future<Map<String, dynamic>> getLearningPathSummary(
    String careerName,
    String skillName,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/videoprogress/summary?careerName=$careerName&skillName=$skillName',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': LearningPathSummary.fromJson(data)};
      } else {
        return {'success': false, 'message': 'Failed to fetch summary'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all learning paths summary for a career
  Future<Map<String, dynamic>> getAllLearningPathsSummary(
    String careerName,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videoprogress/career-summary/$careerName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<LearningPathSummary> summaries = data
            .map((json) => LearningPathSummary.fromJson(json))
            .toList();
        return {'success': true, 'data': summaries};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch summaries',
          'data': <LearningPathSummary>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'data': <LearningPathSummary>[],
      };
    }
  }

  // Auto-save progress every 10 seconds
  Future<void> autoSaveProgress({
    required String videoId,
    required String videoTitle,
    required String skillName,
    required String careerName,
    required int currentPosition,
    required int duration,
  }) async {
    final watchPercentage = duration > 0
        ? (currentPosition / duration) * 100
        : 0.0;
    final isCompleted = watchPercentage >= 90.0;

    final progress = VideoProgress(
      videoId: videoId,
      videoTitle: videoTitle,
      skillName: skillName,
      careerName: careerName,
      currentPositionSeconds: currentPosition,
      durationSeconds: duration,
      watchPercentage: watchPercentage,
      isCompleted: isCompleted,
    );

    await saveVideoProgress(progress);
  }

  // Mark video as completed
  Future<Map<String, dynamic>> markVideoCompleted({
    required String videoId,
    required String videoTitle,
    required String skillName,
    required String careerName,
    required int duration,
  }) async {
    final progress = VideoProgress(
      videoId: videoId,
      videoTitle: videoTitle,
      skillName: skillName,
      careerName: careerName,
      currentPositionSeconds: duration,
      durationSeconds: duration,
      watchPercentage: 100.0,
      isCompleted: true,
    );

    return await saveVideoProgress(progress);
  }

  // Get resume position for a video
  Future<int> getResumePosition(String videoId, String careerName) async {
    final result = await getVideoProgress(videoId, careerName);
    if (result['success'] == true && result['data'] != null) {
      final VideoProgress progress = result['data'];
      return progress.currentPositionSeconds;
    }
    return 0;
  }

  // Calculate overall career progress
  Future<Map<String, dynamic>> getOverallCareerProgress(
    String careerName,
  ) async {
    try {
      final result = await getAllVideoProgress(careerName);
      if (result['success'] == true) {
        final List<VideoProgress> progressList = result['data'];

        if (progressList.isEmpty) {
          return {
            'totalVideos': 0,
            'completedVideos': 0,
            'overallPercentage': 0.0,
            'totalWatchTime': 0,
            'totalDuration': 0,
          };
        }

        final completedVideos = progressList.where((p) => p.isCompleted).length;
        final totalWatchTime = progressList.fold<int>(
          0,
          (sum, p) => sum + p.currentPositionSeconds.toInt(),
        );
        final totalDuration = progressList.fold<int>(
          0,
          (sum, p) => sum + p.durationSeconds.toInt(),
        );
        final overallPercentage = totalDuration > 0
            ? (totalWatchTime / totalDuration) * 100
            : 0.0;

        return {
          'totalVideos': progressList.length,
          'completedVideos': completedVideos,
          'overallPercentage': overallPercentage,
          'totalWatchTime': totalWatchTime,
          'totalDuration': totalDuration,
          'formattedWatchTime': _formatDuration(totalWatchTime),
          'formattedTotalDuration': _formatDuration(totalDuration),
        };
      }
      return {
        'totalVideos': 0,
        'completedVideos': 0,
        'overallPercentage': 0.0,
        'totalWatchTime': 0,
        'totalDuration': 0,
      };
    } catch (e) {
      return {
        'totalVideos': 0,
        'completedVideos': 0,
        'overallPercentage': 0.0,
        'totalWatchTime': 0,
        'totalDuration': 0,
      };
    }
  }

  // Get recently watched videos
  Future<List<VideoProgress>> getRecentlyWatched({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videoprogress/recent?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VideoProgress.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Delete video progress
  Future<Map<String, dynamic>> deleteVideoProgress(
    String videoId,
    String careerName,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/videoprogress/$videoId?careerName=$careerName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Progress deleted'};
      } else {
        return {'success': false, 'message': 'Failed to delete progress'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Reset all progress for a career
  Future<Map<String, dynamic>> resetCareerProgress(String careerName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/videoprogress/career/$careerName/reset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Career progress reset'};
      } else {
        return {'success': false, 'message': 'Failed to reset progress'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Helper: Format duration to HH:MM:SS or MM:SS
  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Helper: Parse duration string to seconds
  static int parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    } else if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }
}
