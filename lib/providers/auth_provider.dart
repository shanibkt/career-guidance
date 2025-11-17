import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api/auth_service.dart';
import '../services/local/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  /// Initialize provider - load saved auth data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await StorageService.loadAuthToken();
      final userMap = await StorageService.loadUser();

      if (_token != null && userMap != null) {
        _user = User.fromJson(userMap);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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

        // Save to local storage
        if (_token != null) {
          await StorageService.saveAuthToken(_token!);
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

        // Save to local storage
        if (_token != null) {
          await StorageService.saveAuthToken(_token!);
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
