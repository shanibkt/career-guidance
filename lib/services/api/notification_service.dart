import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../models/hiring_notification.dart';
import '../local/storage_service.dart';

class NotificationService {
  /// Get all hiring notifications for the current student
  static Future<List<HiringNotification>> getNotifications() async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) return [];

      final response = await ApiClient.get(
        ApiConfig.notifications,
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HiringNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) return 0;

      final response = await ApiClient.get(
        ApiConfig.notificationsUnreadCount,
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) return false;

      final response = await ApiClient.put(
        '/api/notification/$notificationId/read',
        headers: ApiConfig.getAuthHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Apply to a hiring notification
  static Future<Map<String, dynamic>?> apply(
    int notificationId,
    String? coverMessage,
  ) async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) return null;

      final response = await ApiClient.post(
        '/api/notification/$notificationId/apply',
        headers: ApiConfig.getAuthHeaders(token),
        body: {'coverMessage': coverMessage},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        return {'error': data['message'] ?? 'Failed to apply'};
      }
    } catch (e) {
      print('Error applying: $e');
      return {'error': e.toString()};
    }
  }

  /// Get student's application history
  static Future<List<StudentApplication>> getMyApplications() async {
    try {
      final token = await StorageService.loadAuthToken();
      if (token == null) return [];

      final response = await ApiClient.get(
        ApiConfig.notificationsMyApplications,
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StudentApplication.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching applications: $e');
      return [];
    }
  }
}
