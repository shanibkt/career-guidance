import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service class for Firebase Crashlytics integration
/// Provides easy-to-use methods for error tracking and crash reporting
class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize crashlytics (called in main.dart)
  static void initialize() {
    // Enable crash collection in debug mode (optional - usually disabled in debug)
    _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  /// Record a non-fatal error
  /// Use this for caught exceptions you want to track
  static Future<void> recordError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log a message that will appear in crash reports
  /// Useful for debugging the sequence of events leading to a crash
  static void log(String message) {
    _crashlytics.log(message);
  }

  /// Set user identifier for tracking which user experienced crashes
  /// Call this after user login
  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Clear user identifier (call on logout)
  static Future<void> clearUserId() async {
    await _crashlytics.setUserIdentifier('');
  }

  /// Set custom key-value pairs for additional context
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Set multiple custom keys at once
  static Future<void> setCustomKeys(Map<String, dynamic> data) async {
    for (var entry in data.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
  }

  /// Force a crash (for testing purposes only)
  /// DO NOT use in production code
  static void forceCrash() {
    if (kDebugMode) {
      _crashlytics.crash();
    }
  }

  /// Record a Flutter error
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterError(details);
  }

  /// Check if crash collection is enabled
  static bool isCrashlyticsCollectionEnabled() {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }

  /// Send unsent reports
  static Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
  }

  /// Delete unsent reports
  static Future<void> deleteUnsentReports() async {
    await _crashlytics.deleteUnsentReports();
  }

  // ========================================
  // CONVENIENCE METHODS FOR COMMON SCENARIOS
  // ========================================

  /// Record API error with additional context
  static Future<void> recordApiError(
    String endpoint,
    int? statusCode,
    dynamic error,
    StackTrace stackTrace,
  ) async {
    await setCustomKeys({
      'api_endpoint': endpoint,
      'status_code': statusCode ?? 'unknown',
      'error_type': 'api_error',
    });

    await recordError(
      error,
      stackTrace,
      reason: 'API Error: $endpoint (Status: $statusCode)',
    );
  }

  /// Record authentication error
  static Future<void> recordAuthError(
    String action,
    dynamic error,
    StackTrace stackTrace,
  ) async {
    await setCustomKey('auth_action', action);
    await recordError(error, stackTrace, reason: 'Auth Error: $action');
  }

  /// Record database error
  static Future<void> recordDatabaseError(
    String operation,
    dynamic error,
    StackTrace stackTrace,
  ) async {
    await setCustomKey('db_operation', operation);
    await recordError(error, stackTrace, reason: 'Database Error: $operation');
  }

  /// Record navigation error
  static Future<void> recordNavigationError(
    String route,
    dynamic error,
    StackTrace stackTrace,
  ) async {
    await setCustomKey('navigation_route', route);
    await recordError(error, stackTrace, reason: 'Navigation Error: $route');
  }

  /// Record user action with context
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    var logMessage = 'User Action: $action';
    if (context != null && context.isNotEmpty) {
      logMessage += ' | ${context.toString()}';
    }
    log(logMessage);
  }
}
