class CourseModule {
  final String id;
  final String title;
  final String skillName;
  final String description;
  final String youtubeVideoId;
  final int durationMinutes;
  double watchedPercentage;
  bool isCompleted;

  CourseModule({
    required this.id,
    required this.title,
    required this.skillName,
    required this.description,
    required this.youtubeVideoId,
    required this.durationMinutes,
    this.watchedPercentage = 0.0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'skillName': skillName,
    'description': description,
    'youtubeVideoId': youtubeVideoId,
    'durationMinutes': durationMinutes,
    'watchedPercentage': watchedPercentage,
    'isCompleted': isCompleted,
  };

  factory CourseModule.fromJson(Map<String, dynamic> json) => CourseModule(
    id: json['id'],
    title: json['title'],
    skillName: json['skillName'],
    description: json['description'],
    youtubeVideoId: json['youtubeVideoId'],
    durationMinutes: json['durationMinutes'],
    watchedPercentage: json['watchedPercentage'] ?? 0.0,
    isCompleted: json['isCompleted'] ?? false,
  );
}
