import 'package:flutter/material.dart';
import '../../services/local/storage_service.dart';
import '../../features/auth/screens/login_screen.dart';

/// Global auth error handler for 401 responses
class AuthErrorHandler {
  /// Check if response indicates unauthorized (401)
  static bool isUnauthorized(int statusCode) {
    return statusCode == 401;
  }

  /// Handle 401 errors by clearing auth data and redirecting to login
  static Future<void> handleUnauthorizedError(BuildContext context) async {
    // Check if already on login screen to avoid infinite loops
    if (ModalRoute.of(context)?.settings.name == '/login') {
      return;
    }

    // Clear auth data
    await StorageService.clearAuthToken();
    await StorageService.clearUser();

    if (!context.mounted) return;

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please log in again.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // Wait a bit for the snackbar to show
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Show a generic error message without logging out
  static void showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
