import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api/auth_service.dart';
import '../services/local/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiration;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiration => _tokenExpiration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  /// Initialize provider - load saved auth data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await StorageService.loadAuthToken();
      _refreshToken = await StorageService.loadRefreshToken();
      _tokenExpiration = await StorageService.loadTokenExpiration();
      final userMap = await StorageService.loadUser();

      if (_token != null && userMap != null) {
        _user = User.fromJson(userMap);

        debugPrint('🔐 User loaded from storage: ${_user?.email}');
        debugPrint('🔑 Token loaded: ${_token?.substring(0, 20)}...');
        debugPrint('📅 Token expiration: $_tokenExpiration');

        // Only check expiration if we have the expiration date
        // If no expiration date, assume token is still valid (for backward compatibility)
        if (_tokenExpiration != null) {
          final isExpired = await StorageService.isTokenExpired();
          if (isExpired) {
            debugPrint('⏰ Token expired, attempting to refresh...');
            final refreshed = await refreshTokenIfNeeded();
            if (!refreshed) {
              debugPrint(
                '❌ Token refresh failed, user will need to login again',
              );
            }
          } else {
            debugPrint('✅ Token is still valid');
          }
        } else {
          debugPrint('⚠️ No token expiration found, assuming token is valid');
        }
      } else {
        debugPrint('ℹ️ No saved authentication found');
      }
    } catch (e) {
      debugPrint('❌ Error initializing auth: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check and refresh token if needed
  Future<bool> refreshTokenIfNeeded() async {
    // If token is not expired, no need to refresh
    final isExpired = await StorageService.isTokenExpired();
    if (!isExpired) {
      debugPrint('✅ Token is still valid, no refresh needed');
      return true;
    }

    // If no refresh token, can't refresh
    if (_refreshToken == null) {
      debugPrint('⚠️ No refresh token available, but token expired');
      // Don't logout immediately - let the API call fail naturally
      // This prevents logout on app restart for old tokens
      return false;
    }

    try {
      debugPrint('🔄 Refreshing access token...');
      final result = await AuthService.refreshAccessToken(_refreshToken!);

      if (result.success && result.token != null) {
        _token = result.token;
        if (result.refreshToken != null) {
          _refreshToken = result.refreshToken;
        }
        if (result.tokenExpiration != null) {
          _tokenExpiration = result.tokenExpiration;
        }
        if (result.user != null) {
          _user = result.user;
        }

        // Save to local storage
        await StorageService.saveAuthToken(_token!);
        if (_refreshToken != null) {
          await StorageService.saveRefreshToken(_refreshToken!);
        }
        if (_tokenExpiration != null) {
          await StorageService.saveTokenExpiration(_tokenExpiration!);
        }
        if (_user != null) {
          await StorageService.saveUser(_user!.toJson());
        }

        debugPrint('✅ Token refreshed successfully');
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Token refresh failed: ${result.message}');
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      await logout();
      return false;
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);

      if (result.success) {
        _user = result.user;
        _token = result.token;
        _refreshToken = result.refreshToken;
        _tokenExpiration = result.tokenExpiration;

        // Save to local storage
        if (_token != null) {
          await StorageService.saveAuthToken(_token!);
        }
        if (_refreshToken != null) {
          await StorageService.saveRefreshToken(_refreshToken!);
        }
        if (_tokenExpiration != null) {
          await StorageService.saveTokenExpiration(_tokenExpiration!);
        }
        if (_user != null) {
          await StorageService.saveUser(_user!.toJson());
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signup user
  Future<bool> signup(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.signup(userData);

      if (result.success) {
        _user = result.user;
        _token = result.token;
        _refreshToken = result.refreshToken;
        _tokenExpiration = result.tokenExpiration;

        // Save to local storage
        if (_token != null) {
          await StorageService.saveAuthToken(_token!);
        }
        if (_refreshToken != null) {
          await StorageService.saveRefreshToken(_refreshToken!);
        }
        if (_tokenExpiration != null) {
          await StorageService.saveTokenExpiration(_tokenExpiration!);
        }
        if (_user != null) {
          await StorageService.saveUser(_user!.toJson());
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'Signup failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear local storage
      await StorageService.clearAuthToken();
      await StorageService.clearUser();
      await StorageService.clearProfile();

      // Clear provider state
      _user = null;
      _token = null;
      _refreshToken = null;
      _tokenExpiration = null;
      _error = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user data
  void updateUser(User user) {
    _user = user;
    StorageService.saveUser(user.toJson());
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.forgotPassword(email);

      _isLoading = false;
      if (result.success) {
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.resetPassword(token, newPassword);

      _isLoading = false;
      if (result.success) {
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
