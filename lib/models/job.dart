class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String? url;
  final String? description;
  final String? jobType; // Full-time, Part-time, Contract, Temporary
  final String? salaryMin;
  final String? salaryMax;
  final String? salaryCurrency;
  final String? experienceLevel; // Entry, Mid, Senior
  final List<String> requiredSkills;
  final String? postedDate;
  final String? jobRole;
  final String? employmentType;
  final bool isSaved;
  final bool isApplied;
  final double? matchPercentage; // For personalized recommendations

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    this.url,
    this.description,
    this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.experienceLevel,
    this.requiredSkills = const [],
    this.postedDate,
    this.jobRole,
    this.employmentType,
    this.isSaved = false,
    this.isApplied = false,
    this.matchPercentage,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        company: json['company'] as String? ?? '',
        location: json['location'] as String? ?? '',
        url: json['url'] as String?,
        description: json['description'] as String?,
        jobType: json['jobType'] as String?,
        salaryMin: json['salaryMin'] as String?,
        salaryMax: json['salaryMax'] as String?,
        salaryCurrency: json['salaryCurrency'] as String?,
        experienceLevel: json['experienceLevel'] as String?,
        requiredSkills:
            (json['requiredSkills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        postedDate: json['postedDate'] as String?,
        jobRole: json['jobRole'] as String?,
        employmentType: json['employmentType'] as String?,
        isSaved: json['isSaved'] as bool? ?? false,
        isApplied: json['isApplied'] as bool? ?? false,
        matchPercentage: (json['matchPercentage'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'location': location,
        'url': url,
        'description': description,
        'jobType': jobType,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'salaryCurrency': salaryCurrency,
        'experienceLevel': experienceLevel,
        'requiredSkills': requiredSkills,
        'postedDate': postedDate,
        'jobRole': jobRole,
        'employmentType': employmentType,
        'isSaved': isSaved,
        'isApplied': isApplied,
        'matchPercentage': matchPercentage,
      };

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? url,
    String? description,
    String? jobType,
    String? salaryMin,
    String? salaryMax,
    String? salaryCurrency,
    String? experienceLevel,
    List<String>? requiredSkills,
    String? postedDate,
    String? jobRole,
    String? employmentType,
    bool? isSaved,
    bool? isApplied,
    double? matchPercentage,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      url: url ?? this.url,
      description: description ?? this.description,
      jobType: jobType ?? this.jobType,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      postedDate: postedDate ?? this.postedDate,
      jobRole: jobRole ?? this.jobRole,
      employmentType: employmentType ?? this.employmentType,
      isSaved: isSaved ?? this.isSaved,
      isApplied: isApplied ?? this.isApplied,
      matchPercentage: matchPercentage ?? this.matchPercentage,
    );
  }
}
