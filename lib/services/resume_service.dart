import 'dart:convert';
import 'dart:math' show min;
import 'dart:async' show TimeoutException;
import 'package:http/http.dart' as http;
import 'local/storage_service.dart';
import '../core/config/api_config.dart';

// Experience model
class Experience {
  final String role;
  final String company;
  final String period;
  final String description;

  Experience({
    required this.role,
    required this.company,
    required this.period,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'company': company,
    'period': period,
    'description': description,
  };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
    role: json['role'] ?? '',
    company: json['company'] ?? '',
    period: json['period'] ?? '',
    description: json['description'] ?? '',
  );
}

// Education model
class Education {
  final String degree;
  final String institution;
  final String year;

  Education({
    required this.degree,
    required this.institution,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
    'degree': degree,
    'institution': institution,
    'year': year,
  };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
    degree: json['degree'] ?? '',
    institution: json['institution'] ?? '',
    year: json['year'] ?? '',
  );
}

// Certification model
class CertificationData {
  final String name;
  final String issuer;
  final String date;
  final String credentialId;

  CertificationData({
    required this.name,
    required this.issuer,
    required this.date,
    this.credentialId = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'issuer': issuer,
    'date': date,
    'credentialId': credentialId,
  };

  factory CertificationData.fromJson(Map<String, dynamic> json) =>
      CertificationData(
        name: json['name'] ?? '',
        issuer: json['issuer'] ?? '',
        date: json['date'] ?? '',
        credentialId: json['credentialId'] ?? '',
      );
}

// Project model
class ProjectData {
  final String name;
  final String description;
  final String technologies;
  final String link;

  ProjectData({
    required this.name,
    required this.description,
    required this.technologies,
    this.link = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'technologies': technologies,
    'link': link,
  };

  factory ProjectData.fromJson(Map<String, dynamic> json) => ProjectData(
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    technologies: json['technologies'] ?? '',
    link: json['link'] ?? '',
  );
}

// Language model
class LanguageData {
  final String name;
  final String proficiency;

  LanguageData({required this.name, required this.proficiency});

  Map<String, dynamic> toJson() => {'name': name, 'proficiency': proficiency};

  factory LanguageData.fromJson(Map<String, dynamic> json) => LanguageData(
    name: json['name'] ?? '',
    proficiency: json['proficiency'] ?? '',
  );
}

// Achievement model
class AchievementData {
  final String title;
  final String description;
  final String date;

  AchievementData({
    required this.title,
    required this.description,
    this.date = '',
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date,
  };

  factory AchievementData.fromJson(Map<String, dynamic> json) =>
      AchievementData(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        date: json['date'] ?? '',
      );
}

// Resume data model
class ResumeData {
  final String fullName;
  final String jobTitle;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String professionalSummary;
  final List<String> skills;
  final List<Experience> experiences;
  final List<Education> education;
  final List<CertificationData> certifications;
  final List<ProjectData> projects;
  final List<LanguageData> languages;
  final List<AchievementData> achievements;

  ResumeData({
    required this.fullName,
    required this.jobTitle,
    required this.email,
    required this.phone,
    required this.location,
    required this.linkedin,
    required this.professionalSummary,
    required this.skills,
    required this.experiences,
    required this.education,
    this.certifications = const [],
    this.projects = const [],
    this.languages = const [],
    this.achievements = const [],
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'jobTitle': jobTitle,
    'email': email,
    'phone': phone,
    'location': location,
    'linkedin': linkedin,
    'professionalSummary': professionalSummary,
    'skills': skills,
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'education': education.map((e) => e.toJson()).toList(),
    'certifications': certifications.map((e) => e.toJson()).toList(),
    'projects': projects.map((e) => e.toJson()).toList(),
    'languages': languages.map((e) => e.toJson()).toList(),
    'achievements': achievements.map((e) => e.toJson()).toList(),
  };

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    return ResumeData(
      fullName: json['fullName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      linkedin: json['linkedin'] ?? '',
      professionalSummary: json['professionalSummary'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experiences:
          (json['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education:
          (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      certifications:
          (json['certifications'] as List<dynamic>?)
              ?.map(
                (e) => CertificationData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      projects:
          (json['projects'] as List<dynamic>?)
              ?.map((e) => ProjectData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => LanguageData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map((e) => AchievementData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ResumeService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Get authentication headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.loadAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Save or update resume
  Future<Map<String, dynamic>> saveResume(ResumeData resumeData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/resume/save'),
        headers: headers,
        body: jsonEncode(resumeData.toJson()),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Resume saved successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to save resume',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's resume
  Future<Map<String, dynamic>> getResume() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/resume'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': ResumeData.fromJson(data)};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No resume found',
          'notFound': true,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch resume',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Delete resume
  Future<Map<String, dynamic>> deleteResume() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/resume'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Resume deleted successfully'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to delete resume',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Auto-save resume with debouncing
  Future<void> autoSaveResume(ResumeData resumeData) async {
    // Debounce implementation - save after 2 seconds of inactivity
    await Future.delayed(const Duration(seconds: 2));
    await saveResume(resumeData);
  }

  // Export resume (future implementation for PDF/DOCX)
  Future<Map<String, dynamic>> exportResume(
    String format,
    ResumeData resumeData,
  ) async {
    // TODO: Implement PDF/DOCX export
    return {'success': false, 'message': 'Export feature coming soon'};
  }

  // Calculate resume completion percentage
  double calculateCompletionPercentage(ResumeData resumeData) {
    int completedSections = 0;
    const int totalSections = 8;

    if (resumeData.fullName.isNotEmpty) completedSections++;
    if (resumeData.jobTitle.isNotEmpty) completedSections++;
    if (resumeData.email.isNotEmpty) completedSections++;
    if (resumeData.phone.isNotEmpty) completedSections++;
    if (resumeData.professionalSummary.isNotEmpty) completedSections++;
    if (resumeData.skills.isNotEmpty) completedSections++;
    if (resumeData.experiences.isNotEmpty) completedSections++;
    if (resumeData.education.isNotEmpty) completedSections++;

    return (completedSections / totalSections) * 100;
  }

  // Validate resume data
  Map<String, dynamic> validateResume(ResumeData resumeData) {
    List<String> errors = [];
    List<String> warnings = [];

    // Required fields
    if (resumeData.fullName.isEmpty) errors.add('Full name is required');
    if (resumeData.email.isEmpty) errors.add('Email is required');
    if (resumeData.phone.isEmpty) errors.add('Phone number is required');

    // Warnings for better resume
    if (resumeData.professionalSummary.isEmpty) {
      warnings.add(
        'Professional summary helps recruiters understand your profile',
      );
    }
    if (resumeData.skills.isEmpty) {
      warnings.add('Add your skills to stand out');
    }
    if (resumeData.experiences.isEmpty) {
      warnings.add('Add work experience to strengthen your resume');
    }
    if (resumeData.education.isEmpty) {
      warnings.add('Add your educational background');
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (resumeData.email.isNotEmpty && !emailRegex.hasMatch(resumeData.email)) {
      errors.add('Invalid email format');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'completionPercentage': calculateCompletionPercentage(resumeData),
    };
  }

  // Get ATS score (based on completeness and keywords)
  Future<Map<String, dynamic>> getATSScore(ResumeData resumeData) async {
    int score = 0;
    List<String> suggestions = [];

    // Completion score (40 points)
    double completion = calculateCompletionPercentage(resumeData);
    score += (completion * 0.4).round();

    // Professional summary score (15 points)
    if (resumeData.professionalSummary.isNotEmpty) {
      int wordCount = resumeData.professionalSummary.split(' ').length;
      if (wordCount >= 50 && wordCount <= 150) {
        score += 15;
      } else if (wordCount > 0) {
        score += 8;
        suggestions.add('Professional summary should be 50-150 words');
      }
    } else {
      suggestions.add('Add a professional summary');
    }

    // Skills score (20 points)
    if (resumeData.skills.length >= 5) {
      score += 20;
    } else if (resumeData.skills.isNotEmpty) {
      score += (resumeData.skills.length * 4);
      suggestions.add('Add at least 5 relevant skills');
    } else {
      suggestions.add('Add your technical and soft skills');
    }

    // Experience score (15 points)
    if (resumeData.experiences.isNotEmpty) {
      score += 15;
      // Check for quantifiable achievements
      bool hasNumbers = resumeData.experiences.any(
        (exp) => RegExp(r'\d+').hasMatch(exp.description),
      );
      if (!hasNumbers) {
        suggestions.add('Use numbers to quantify your achievements');
      }
    } else {
      suggestions.add('Add work experience with measurable achievements');
    }

    // Education score (10 points)
    if (resumeData.education.isNotEmpty) {
      score += 10;
    } else {
      suggestions.add('Add your educational qualifications');
    }

    // Contact info completeness
    if (resumeData.linkedin.isEmpty) {
      suggestions.add('Add LinkedIn profile for better visibility');
    }
    if (resumeData.location.isEmpty) {
      suggestions.add('Add your location/city');
    }

    return {
      'score': score > 100 ? 100 : score,
      'grade': _getGrade(score),
      'suggestions': suggestions,
      'completionPercentage': completion,
    };
  }

  String _getGrade(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Improvement';
  }

  // AI Enhance Professional Summary
  Future<Map<String, dynamic>> enhanceSummary({
    required String currentSummary,
    required String jobTitle,
    required List<String> skills,
    required List<String> experiences,
  }) async {
    try {
      final headers = await _getHeaders();

      // Convert experience strings to the expected format
      // Format: "Role at Company: Description"
      List<Map<String, String>> experienceList = [];
      for (var exp in experiences) {
        // Parse "Role at Company: Description" format
        if (exp.contains(' at ') && exp.contains(':')) {
          final parts = exp.split(':');
          final roleCompany = parts[0];
          final description = parts.length > 1 ? parts[1].trim() : '';

          if (roleCompany.contains(' at ')) {
            final roleCompanyParts = roleCompany.split(' at ');
            experienceList.add({
              'role': roleCompanyParts[0].trim(),
              'company': roleCompanyParts.length > 1
                  ? roleCompanyParts[1].trim()
                  : '',
              'period': '',
              'description': description,
            });
          }
        }
      }

      final body = jsonEncode({
        'currentSummary': currentSummary,
        'jobTitle': jobTitle,
        'skills': skills,
        'experiences': experienceList,
      });

      print('🔵 ResumeService.enhanceSummary - Sending request');
      print('🔵 URL: $baseUrl/api/resume/enhance-summary');
      print('🔵 Experiences parsed: ${experienceList.length}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/resume/enhance-summary'),
            headers: headers,
            body: body,
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      print('🟢 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['enhancedSummary'] ?? data['summary'] ?? '';

        if (summary.isEmpty) {
          print('❌ Empty summary in response: ${response.body}');
          return {'success': false, 'message': 'Empty AI response'};
        }

        print(
          '✅ Enhanced summary received: ${summary.substring(0, min(100, summary.length))}...',
        );
        return {'success': true, 'enhancedSummary': summary};
      } else {
        print('❌ Error status ${response.statusCode}: ${response.body}');
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Server error',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
