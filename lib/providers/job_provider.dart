import 'package:flutter/foundation.dart';
import '../../models/job.dart';
import '../../models/job_filter.dart';
import '../../services/api/job_service.dart';

class JobProvider extends ChangeNotifier {
  JobService jobService = JobService();

  List<Job> _jobs = [];
  List<Job> _savedJobs = [];
  List<Job> _personalizedJobs = [];
  JobSearchFilter _currentFilter = JobSearchFilter();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;

  // Getters
  List<Job> get jobs => _jobs;
  List<Job> get savedJobs => _savedJobs;
  List<Job> get personalizedJobs => _personalizedJobs;
  JobSearchFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNextPage => _currentPage < _totalPages;

  // Search jobs with filters
  Future<void> searchJobs(JobSearchFilter filter) async {
    debugPrint('🔎 JobProvider: Searching jobs with filter: ${filter.query}');
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentFilter = filter;
      _currentPage = 1;
      notifyListeners();

      final response = await JobService.searchJobs(filter);
      _jobs = response.jobs;
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      debugPrint(
        '✅ JobProvider: Found ${_jobs.length} jobs (page $_currentPage of $_totalPages)',
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ JobProvider: Search error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load next page
  Future<void> loadMore() async {
    if (!hasNextPage || _isLoadingMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPageFilter = _currentFilter.copyWith(page: _currentPage + 1);
      final response = await JobService.searchJobs(nextPageFilter);

      _jobs.addAll(response.jobs);
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Get personalized job recommendations based on career and skills
  Future<void> getPersonalizedJobs(
    String? careerTitle,
    List<String>? skills,
  ) async {
    debugPrint(
      '📋 JobProvider: Getting personalized jobs for career: $careerTitle, skills: $skills',
    );
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _personalizedJobs = await JobService.getPersonalizedJobs(
        careerTitle,
        skills,
      );
      debugPrint(
        '✅ JobProvider: Loaded ${_personalizedJobs.length} personalized jobs',
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ JobProvider: Error loading personalized jobs: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save/unsave job
  Future<void> toggleSaveJob(Job job) async {
    try {
      final newSavedStatus = !job.isSaved;
      final response = await JobService.toggleSaveJob(
        job.id,
        newSavedStatus,
        job,
      );

      // Use the response job which has the updated saved status
      final updatedJob = response;

      // Update search results list
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = updatedJob;
      }

      // Update personalized jobs list
      final personalizedIndex = _personalizedJobs.indexWhere(
        (j) => j.id == job.id,
      );
      if (personalizedIndex != -1) {
        _personalizedJobs[personalizedIndex] = updatedJob;
      }

      // Update saved jobs list
      if (updatedJob.isSaved) {
        // Add to saved jobs if not already there
        if (!_savedJobs.any((j) => j.id == updatedJob.id)) {
          _savedJobs.add(updatedJob);
        } else {
          // Update existing saved job
          final savedIndex = _savedJobs.indexWhere(
            (j) => j.id == updatedJob.id,
          );
          if (savedIndex != -1) {
            _savedJobs[savedIndex] = updatedJob;
          }
        }
      } else {
        _savedJobs.removeWhere((j) => j.id == job.id);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load saved jobs
  Future<void> loadSavedJobs() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _savedJobs = await JobService.getSavedJobs();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get job details
  Future<Job?> getJobDetails(String jobId) async {
    try {
      return await JobService.getJobDetails(jobId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update filter
  void updateFilter(JobSearchFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _currentFilter = _currentFilter.clearFilters();
    _currentPage = 1;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
