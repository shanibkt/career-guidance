import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/job.dart';
import '../../models/job_filter.dart';
import '../../services/local/storage_service.dart';
import '../../core/config/api_config.dart';

class JobService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String jsearchApiKey =
      'c7176de2d9mshfd38021e3ce01a3p14702ejsn8dff493f4d86';
  static const String jsearchHost = 'jsearch.p.rapidapi.com';

  // Search jobs with filters
  static Future<JobSearchResponse> searchJobs(JobSearchFilter filter) async {
    try {
      final token = await StorageService.loadAuthToken();

      // Call backend to search jobs
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/jobs/search'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(filter.toJson()),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return JobSearchResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to search jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching jobs: $e');
    }
  }

  // Get personalized jobs based on career and skills
  static Future<List<Job>> getPersonalizedJobs(
    String? careerTitle,
    List<String>? skills,
  ) async {
    try {
      final token = await StorageService.loadAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/jobs/personalized'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'careerTitle': careerTitle,
              'skills': skills ?? [],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        debugPrint(
          '✅ Personalized jobs response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        );
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('📦 Response data keys: ${data.keys.toList()}');
        final jobsList = data['jobs'] as List<dynamic>? ?? [];
        debugPrint(
          '📋 Parsed ${jobsList.length} personalized jobs from response',
        );
        if (jobsList.isNotEmpty) {
          debugPrint('First job raw data: ${jobsList[0]}');
        }
        final jobs = jobsList.map((e) {
          try {
            final job = Job.fromJson(e as Map<String, dynamic>);
            debugPrint('✅ Parsed job: ${job.title} at ${job.company}');
            return job;
          } catch (parseError) {
            debugPrint('❌ Error parsing job: $parseError');
            debugPrint('Job data: $e');
            rethrow;
          }
        }).toList();
        debugPrint('✅ Converted to ${jobs.length} Job objects');
        return jobs;
      } else {
        debugPrint(
          '❌ Personalized jobs error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to get personalized jobs');
      }
    } catch (e) {
      throw Exception('Error getting personalized jobs: $e');
    }
  }

  // Toggle save job
  static Future<Job> toggleSaveJob(String jobId, bool save, Job job) async {
    try {
      final token = await StorageService.loadAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/jobs/$jobId/save'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'save': save, 'job': job.toJson()}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return Job.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to save job');
      }
    } catch (e) {
      throw Exception('Error saving job: $e');
    }
  }

  // Get saved jobs
  static Future<List<Job>> getSavedJobs() async {
    try {
      final token = await StorageService.loadAuthToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/jobs/saved'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final jobsList = data['jobs'] as List<dynamic>? ?? [];
        return jobsList
            .map((e) => Job.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get saved jobs');
      }
    } catch (e) {
      throw Exception('Error getting saved jobs: $e');
    }
  }

  // Get job details
  static Future<Job?> getJobDetails(String jobId) async {
    try {
      final token = await StorageService.loadAuthToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/jobs/$jobId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return Job.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get job details');
      }
    } catch (e) {
      throw Exception('Error getting job details: $e');
    }
  }

  // Legacy method for backwards compatibility
  static Future<List<Job>> getJobsForCareer(String? careerTitle) async {
    try {
      final filter = JobSearchFilter(query: careerTitle, pageSize: 20);
      final response = await searchJobs(filter);
      return response.jobs;
    } catch (e) {
      // Return mock data for offline mode
      await Future.delayed(const Duration(milliseconds: 300));

      final title = (careerTitle == null || careerTitle.isEmpty)
          ? 'General'
          : careerTitle;

      final samples = <Job>[
        Job(
          id: '1',
          title: '$title Engineer',
          company: 'Acme Corp',
          location: 'Remote',
          url: 'https://example.com/jobs/1',
          jobType: 'Full-time',
          experienceLevel: 'Mid',
        ),
        Job(
          id: '2',
          title: 'Junior $title Specialist',
          company: 'Beta LLC',
          location: 'Hybrid — City',
          url: 'https://example.com/jobs/2',
          jobType: 'Full-time',
          experienceLevel: 'Entry',
        ),
        Job(
          id: '3',
          title: '$title Analyst',
          company: 'Gamma Inc',
          location: 'Onsite — City',
          url: 'https://example.com/jobs/3',
          jobType: 'Full-time',
          experienceLevel: 'Senior',
        ),
      ];

      return samples;
    }
  }
}
