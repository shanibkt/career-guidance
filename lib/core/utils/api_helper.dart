import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';

/// Helper class to ensure tokens are refreshed before making API calls
class ApiHelper {
  /// Call this before making any authenticated API request
  /// It will automatically refresh the token if needed
  static Future<String?> getValidToken(AuthProvider authProvider) async {
    if (authProvider.token == null) {
      debugPrint('❌ No token available');
      return null;
    }

    // Check if token needs refresh and refresh it
    final refreshed = await authProvider.refreshTokenIfNeeded();

    if (!refreshed) {
      debugPrint('❌ Failed to refresh token');
      return null;
    }

    return authProvider.token;
  }

  /// Helper to check if user is authenticated with valid token
  static Future<bool> isAuthenticated(AuthProvider authProvider) async {
    if (!authProvider.isAuthenticated) {
      return false;
    }

    // Refresh token if needed
    return await authProvider.refreshTokenIfNeeded();
  }
}
