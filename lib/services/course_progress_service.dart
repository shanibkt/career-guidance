import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_module.dart';

class CourseProgressService {
  static const String _keyPrefix = 'course_progress_';

  // Save course progress
  static Future<void> saveProgress(
    String courseId,
    double watchedPercentage,
    bool isCompleted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'watchedPercentage': watchedPercentage,
      'isCompleted': isCompleted,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_keyPrefix$courseId', json.encode(data));
  }

  // Load course progress
  static Future<Map<String, dynamic>?> loadProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_keyPrefix$courseId');
    if (data == null) return null;
    return json.decode(data);
  }

  // Get all course modules for a career (demo data)
  static List<CourseModule> getCoursesForCareer(String careerTitle) {
    // For now, return empty list - courses should be fetched from API or generated dynamically
    // This removes all hardcoded courses
    print('⚠️ Getting courses for: $careerTitle');
    print(
      '⚠️ No hardcoded courses - implement API or dynamic course generation',
    );
    return [];
  }

  // Calculate overall progress for a career
  static Future<double> calculateOverallProgress(String careerTitle) async {
    final courses = getCoursesForCareer(careerTitle);
    if (courses.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (var course in courses) {
      final progress = await loadProgress(course.id);
      if (progress != null) {
        totalProgress += (progress['watchedPercentage'] as num).toDouble();
      }
    }

    return totalProgress / courses.length;
  }
}
