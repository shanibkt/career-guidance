import 'job.dart';

class JobSearchFilter {
  final String? query;
  final String? location;
  final String? jobType; // Full-time, Part-time, Contract, Temporary
  final String? experienceLevel; // Entry, Mid, Senior
  final String? salaryMin;
  final String? salaryMax;
  final String? salaryCurrency;
  final String? country;
  final String? datePosted; // all, 7, 30, 90
  final int page;
  final int pageSize;
  final List<String>? skills;

  JobSearchFilter({
    this.query,
    this.location,
    this.jobType,
    this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'USD',
    this.country,
    this.datePosted = 'all',
    this.page = 1,
    this.pageSize = 10,
    this.skills,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'location': location,
        'jobType': jobType,
        'experienceLevel': experienceLevel,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'salaryCurrency': salaryCurrency,
        'country': country,
        'datePosted': datePosted,
        'page': page,
        'pageSize': pageSize,
        'skills': skills,
      };

  JobSearchFilter copyWith({
    String? query,
    String? location,
    String? jobType,
    String? experienceLevel,
    String? salaryMin,
    String? salaryMax,
    String? salaryCurrency,
    String? country,
    String? datePosted,
    int? page,
    int? pageSize,
    List<String>? skills,
  }) {
    return JobSearchFilter(
      query: query ?? this.query,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      country: country ?? this.country,
      datePosted: datePosted ?? this.datePosted,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      skills: skills ?? this.skills,
    );
  }

  JobSearchFilter clearFilters() {
    return JobSearchFilter(
      query: query,
      page: 1,
      pageSize: pageSize,
    );
  }
}

class JobSearchResponse {
  final List<Job> jobs;
  final int totalResults;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;

  JobSearchResponse({
    required this.jobs,
    required this.totalResults,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory JobSearchResponse.fromJson(Map<String, dynamic> json) {
    return JobSearchResponse(
      jobs: (json['jobs'] as List<dynamic>? ?? [])
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalResults: json['totalResults'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'jobs': jobs.map((e) => e.toJson()).toList(),
        'totalResults': totalResults,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'hasNextPage': hasNextPage,
      };
}
