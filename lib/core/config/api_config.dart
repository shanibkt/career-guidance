class ApiConfig {
  // ========================================
  // CONFIGURATION - UPDATE THIS
  // ========================================

  /// Base URL for the backend API

  /// Android Emulator: Use 10.0.2.2 (maps to host machine's localhost)
  /// Physical Device: Use your PC's local IP address (e.g., 192.168.1.4)

  /// To find your PC's IP:
  /// - Windows: Run `ipconfig` in terminal, look for IPv4 Address
  /// - Mac/Linux: Run `ifconfig` in terminal
  ////mmmmmmmm
  /// Make sure:
  /// 1. Your backend is running on port 5001
  /// 2. Device and PC are on the same WiFi network (for physical devices)
  /// 3. Firewall allows port 5001

  // TEMPORARY: Using local backend
  static const String baseUrl = 'http://10.0.2.2:5001'; // Android Emulator
  // static const String baseUrl = 'http://192.168.1.59:5001'; // Physical device - change to your PC's IP
  // static const String baseUrl = 'https://career-guaidance-ahemf5fqfgayg0fw.canadacentral-01.azurewebsites.net'; // Azure production

  // ========================================
  // ENDPOINTS--
  // ========================================

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // Profile
  static const String profile = '/api/profile';
  static const String userProfile = '/api/userprofile';
  static const String uploadImage = '/api/userprofile/upload-image';

  // Career
  static const String careers = '/api/recommendations/careers';
  static const String careerProgress = '/api/careerprogress';
  static const String selectCareer =
      '/api/careerprogress/select'; // Fixed: backend uses /select not /select-career

  // Learning
  static const String learningVideos = '/api/learningvideos';
  static const String learningVideosBySkills = '/api/learningvideos/skills';

  // Video Progress
  static const String videoProgress = '/api/videoprogress';
  static const String videoProgressSave = '/api/videoprogress/save';

  // Quiz
  static const String quizGenerate = '/api/quiz/generate';
  static const String quizSubmit = '/api/quiz/submit';
  static const String quizResults = '/api/quiz/results';

  // Chat
  static const String chat = '/api/chat';
  static const String chatSessions = '/api/chat/sessions'; // GET/POST sessions
  static const String chatMessages = '/api/chat/messages'; // POST messages
  static const String chatHistory =
      '/api/chat/sessions'; // Fixed: same as sessions endpoint

  // Jobs
  static const String jobSearch = '/api/jobs/search';
  static const String jobPersonalized = '/api/jobs/personalized';
  static const String jobSaved = '/api/jobs/saved';

  // Resume
  static const String resumeSave = '/api/resume/save';
  static const String resumeGet = '/api/resume';
  static const String resumeGenerate = '/api/resume/generate';

  // Admin
  static const String adminUsers = '/api/admin/users';
  static const String adminStats = '/api/admin/stats';

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Get full URL for an endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Get user-specific URL
  static String getUserUrl(int userId) => '$baseUrl/api/profile/$userId';

  /// Get user profile URL
  static String getUserProfileUrl(int userId) =>
      '$baseUrl/api/userprofile/$userId';

  /// Get upload image URL
  static String getUploadImageUrl(int userId) =>
      '$baseUrl/api/userprofile/upload-image?userId=$userId';

  /// Get career-specific URL
  static String getCareerUrl(int careerId) => '$baseUrl/api/careers/$careerId';

  /// Get video by skill URL
  static String getVideosBySkillUrl(String skillName) =>
      '$baseUrl/api/learningvideos/${Uri.encodeComponent(skillName)}';

  /// Get videos by multiple skills URL
  static String getVideosBySkillsUrl(List<String> skills) {
    final encodedSkills = Uri.encodeComponent(skills.join(','));
    return '$baseUrl/api/learningvideos/skills?skills=$encodedSkills';
  }

  /// Get chat session messages URL
  static String getChatSessionMessagesUrl(String sessionId) =>
      '$baseUrl/api/chat/sessions/$sessionId/messages';

  /// Get delete chat session URL
  static String getDeleteChatSessionUrl(String sessionId) =>
      '$baseUrl/api/chat/sessions/$sessionId';

  /// Get job details URL
  static String getJobUrl(String jobId) => '$baseUrl/api/jobs/$jobId';

  /// Get save job URL
  static String getSaveJobUrl(String jobId) => '$baseUrl/api/jobs/$jobId/save';

  /// Get apply job URL
  static String getApplyJobUrl(String jobId) =>
      '$baseUrl/api/jobs/$jobId/apply';

  // ========================================
  // TIMEOUT CONFIGURATION
  // ========================================

  /// Default timeout for API requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Timeout for upload operations
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// Timeout for chat/AI operations (longer due to AI processing)
  static const Duration aiTimeout = Duration(seconds: 45);

  // ========================================
  // HEADERS
  // ========================================

  /// Get standard JSON headers
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get headers with authorization token
  static Map<String, String> getAuthHeaders(String token) => {
    ...jsonHeaders,
    'Authorization': 'Bearer $token',
  };

  /// Get multipart headers with authorization
  static Map<String, String> getMultipartHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };
}
