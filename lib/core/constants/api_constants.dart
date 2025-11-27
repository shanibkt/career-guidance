class ApiConstants {
  // Base URL - Update this to match your backend IP address
  // For Android Emulator: use your PC's IP (e.g., 192.168.1.59)
  // For Physical Device: use your PC's IP on same WiFi network
  static const String baseUrl = 'http://192.168.1.80:5001';

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String verifyOtp = '/api/auth/verify-otp';

  // User endpoints
  static const String userProfile = '/api/userprofile';
  static const String updateUser = '/api/users';

  // Profile endpoints
  static const String profile = '/api/userprofile';
  static const String uploadImage = '/api/userprofile/upload-image';

  // Career endpoints
  static const String careers = '/api/careers';
  static const String careerDetails = '/api/careers';

  // Course endpoints
  static const String courses = '/api/courses';
  static const String courseProgress = '/api/course-progress';

  // Quiz endpoints
  static const String quizGenerate = '/api/quiz/generate';
  static const String quizSubmit = '/api/quiz/submit';

  // Recommendations endpoints
  static const String recommendationsGenerate = '/api/recommendations/generate';
  static const String recommendations = '/api/recommendations';

  // Chat endpoints
  static const String chat = '/api/chat';
  static const String chatHistory = '/api/chat/history';

  // Helper method to build full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method for dynamic endpoints
  static String getUserUrl(int userId) => '$baseUrl/api/users/$userId';
  static String getCareerUrl(int careerId) => '$baseUrl/api/careers/$careerId';
  static String getCourseUrl(int courseId) => '$baseUrl/api/courses/$courseId';
  static String getUploadImageUrl(int userId) =>
      '$baseUrl/api/userprofile/$userId/upload-image';
}
