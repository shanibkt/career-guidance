class HiringNotification {
  final int id;
  final int hiringNotificationId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String title;
  final String? description;
  final String position;
  final String? location;
  final String? salaryRange;
  final String? requirements;
  final String? applicationDeadline;
  final String companyName;
  final String? companyLogo;
  final String? companyWebsite;
  final bool hasApplied;

  HiringNotification({
    required this.id,
    required this.hiringNotificationId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.title,
    this.description,
    required this.position,
    this.location,
    this.salaryRange,
    this.requirements,
    this.applicationDeadline,
    required this.companyName,
    this.companyLogo,
    this.companyWebsite,
    this.hasApplied = false,
  });

  factory HiringNotification.fromJson(Map<String, dynamic> json) {
    return HiringNotification(
      id: json['id'] ?? 0,
      hiringNotificationId: json['hiringNotificationId'] ?? 0,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      title: json['title'] ?? '',
      description: json['description'],
      position: json['position'] ?? '',
      location: json['location'],
      salaryRange: json['salaryRange'],
      requirements: json['requirements'],
      applicationDeadline: json['applicationDeadline'],
      companyName: json['companyName'] ?? '',
      companyLogo: json['companyLogo'],
      companyWebsite: json['companyWebsite'],
      hasApplied: json['hasApplied'] ?? false,
    );
  }
}

class StudentApplication {
  final int id;
  final int hiringNotificationId;
  final int companyId;
  final String? coverMessage;
  final String status;
  final DateTime appliedAt;
  final String? notificationTitle;
  final String? position;
  final String? companyName;

  StudentApplication({
    required this.id,
    required this.hiringNotificationId,
    required this.companyId,
    this.coverMessage,
    required this.status,
    required this.appliedAt,
    this.notificationTitle,
    this.position,
    this.companyName,
  });

  factory StudentApplication.fromJson(Map<String, dynamic> json) {
    return StudentApplication(
      id: json['id'] ?? 0,
      hiringNotificationId: json['hiringNotificationId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      coverMessage: json['coverMessage'],
      status: json['status'] ?? 'pending',
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'])
          : DateTime.now(),
      notificationTitle: json['notificationTitle'],
      position: json['position'],
      companyName: json['companyName'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'reviewed':
        return 'Reviewed';
      case 'shortlisted':
        return 'Shortlisted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
