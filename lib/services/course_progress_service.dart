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
    switch (careerTitle.toLowerCase()) {
      case 'software developer':
        return [
          CourseModule(
            id: 'py_001',
            title: 'Python Full Course',
            skillName: 'Python',
            description:
                'Complete Python programming course from basics to advanced',
            youtubeVideoId: '_uQrJ0TkZlc',
            durationMinutes: 280,
          ),
          CourseModule(
            id: 'java_001',
            title: 'Java Programming Tutorial',
            skillName: 'Java',
            description: 'Comprehensive Java tutorial for beginners',
            youtubeVideoId: 'eIrMbAQSU34',
            durationMinutes: 200,
          ),
          CourseModule(
            id: 'js_001',
            title: 'JavaScript Full Course',
            skillName: 'JavaScript',
            description: 'Master JavaScript from scratch',
            youtubeVideoId: 'PkZNo7MFNFg',
            durationMinutes: 195,
          ),
          CourseModule(
            id: 'sql_001',
            title: 'SQL Tutorial for Beginners',
            skillName: 'SQL',
            description: 'Learn SQL database fundamentals',
            youtubeVideoId: 'HXV3zeQKqGY',
            durationMinutes: 240,
          ),
          CourseModule(
            id: 'react_001',
            title: 'React Course for Beginners',
            skillName: 'React',
            description: 'Build modern web apps with React',
            youtubeVideoId: 'bMknfKXIFA8',
            durationMinutes: 144,
          ),
          CourseModule(
            id: 'django_001',
            title: 'Django Tutorial',
            skillName: 'Django',
            description: 'Python Django framework tutorial',
            youtubeVideoId: 'rHux0gMZ3Eg',
            durationMinutes: 90,
          ),
        ];
      case 'data scientist':
        return [
          CourseModule(
            id: 'py_ds_001',
            title: 'Python for Data Science',
            skillName: 'Python',
            description: 'Python programming for data science',
            youtubeVideoId: '_uQrJ0TkZlc',
            durationMinutes: 280,
          ),
          CourseModule(
            id: 'sql_ds_001',
            title: 'SQL for Data Analysis',
            skillName: 'SQL',
            description: 'SQL queries for data analysis',
            youtubeVideoId: 'HXV3zeQKqGY',
            durationMinutes: 240,
          ),
        ];
      default:
        return [];
    }
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
