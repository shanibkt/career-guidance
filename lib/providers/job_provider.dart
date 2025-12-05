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
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
  Future<void> getPersonalizedJobs(String? careerTitle, List<String>? skills) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _personalizedJobs =
          await JobService.getPersonalizedJobs(careerTitle, skills);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save/unsave job
  Future<void> toggleSaveJob(Job job) async {
    try {
      final updatedJob = await JobService.toggleSaveJob(
        job.id,
        !job.isSaved,
      );

      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = updatedJob;
      }

      // Update saved jobs list
      if (updatedJob.isSaved) {
        _savedJobs.add(updatedJob);
      } else {
        _savedJobs.removeWhere((j) => j.id == job.id);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Apply for a job
  Future<void> applyForJob(Job job) async {
    try {
      final updatedJob = await JobService.applyForJob(job.id);

      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1 && updatedJob != null) {
        _jobs[index] = updatedJob;
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
