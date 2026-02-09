import 'package:flutter/foundation.dart';
import '../models/hiring_notification.dart';
import '../services/api/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<HiringNotification> _notifications = [];
  List<StudentApplication> _applications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<HiringNotification> get notifications => _notifications;
  List<StudentApplication> get applications => _applications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all hiring notifications for this student
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await NotificationService.getNotifications();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch just the unread count (lightweight, for badge)
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    if (success) {
      final index = _notifications.indexWhere(
        (n) => n.hiringNotificationId == notificationId,
      );
      if (index != -1) {
        // Update locally
        final old = _notifications[index];
        _notifications[index] = HiringNotification(
          id: old.id,
          hiringNotificationId: old.hiringNotificationId,
          isRead: true,
          readAt: DateTime.now(),
          createdAt: old.createdAt,
          title: old.title,
          description: old.description,
          position: old.position,
          location: old.location,
          salaryRange: old.salaryRange,
          requirements: old.requirements,
          applicationDeadline: old.applicationDeadline,
          companyName: old.companyName,
          companyLogo: old.companyLogo,
          companyWebsite: old.companyWebsite,
          hasApplied: old.hasApplied,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    }
  }

  /// Apply to a hiring notification
  Future<String?> applyToJob(int notificationId, String? coverMessage) async {
    final result = await NotificationService.apply(
      notificationId,
      coverMessage,
    );
    if (result == null) return 'Failed to apply';

    if (result.containsKey('error')) {
      return result['error'];
    }

    // Update local state to show as applied
    final index = _notifications.indexWhere(
      (n) => n.hiringNotificationId == notificationId,
    );
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = HiringNotification(
        id: old.id,
        hiringNotificationId: old.hiringNotificationId,
        isRead: true,
        readAt: old.readAt,
        createdAt: old.createdAt,
        title: old.title,
        description: old.description,
        position: old.position,
        location: old.location,
        salaryRange: old.salaryRange,
        requirements: old.requirements,
        applicationDeadline: old.applicationDeadline,
        companyName: old.companyName,
        companyLogo: old.companyLogo,
        companyWebsite: old.companyWebsite,
        hasApplied: true,
      );
      notifyListeners();
    }

    return null; // null means success
  }

  /// Fetch student's application history
  Future<void> fetchMyApplications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _applications = await NotificationService.getMyApplications();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
