import 'package:flutter/foundation.dart';
import '../services/local/storage_service.dart';
import '../services/api/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profileData;
  String? _profileImagePath;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get profileData => _profileData;
  String? get profileImagePath => _profileImagePath;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Specific getters for profile fields
  String? get phoneNumber => _profileData?['phoneNumber'] as String?;
  int? get age => _profileData?['age'] as int?;
  String? get gender => _profileData?['gender'] as String?;
  String? get educationLevel => _profileData?['educationLevel'] as String?;
  String? get fieldOfStudy => _profileData?['fieldOfStudy'] as String?;
  List<String> get skills {
    final skillsData = _profileData?['skills'];
    if (skillsData is List) {
      return skillsData.map((e) => e.toString()).toList();
    }
    return [];
  }

  String? get areasOfInterest => _profileData?['areasOfInterest'] as String?;

  /// Initialize provider - load saved profile data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profileData = await StorageService.loadProfile();
      _profileImagePath = await StorageService.loadProfileImagePath();
    } catch (e) {
      debugPrint('Error initializing profile: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile data
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to sync with backend if logged in
      final token = await StorageService.loadAuthToken();
      final userMap = await StorageService.loadUser();
      final userId = userMap?['id'] as int?;

      if (token != null && userId != null) {
        await ProfileService.updateProfile(userId, token, profileData);
      }

      // Save locally
      await StorageService.saveProfile(profileData);
      _profileData = profileData;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to upload to backend
      final token = await StorageService.loadAuthToken();
      final userMap = await StorageService.loadUser();
      final userId = userMap?['id'] as int?;

      if (token != null && userId != null) {
        await ProfileService.uploadProfileImage(userId, token, imagePath);
      }

      // Save locally
      await StorageService.saveProfileImagePath(imagePath);
      _profileImagePath = imagePath;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update specific field
  Future<void> updateField(String key, dynamic value) async {
    _profileData ??= {};
    _profileData![key] = value;
    await StorageService.saveProfile(_profileData!);
    notifyListeners();
  }

  /// Add skill
  Future<void> addSkill(String skill) async {
    _profileData ??= {};

    final currentSkills = skills;
    if (!currentSkills.contains(skill)) {
      currentSkills.add(skill);
      _profileData!['skills'] = currentSkills;
      await StorageService.saveProfile(_profileData!);
      notifyListeners();
    }
  }

  /// Remove skill
  Future<void> removeSkill(int index) async {
    final currentSkills = skills;
    if (index >= 0 && index < currentSkills.length) {
      currentSkills.removeAt(index);
      if (_profileData != null) {
        _profileData!['skills'] = currentSkills;
        await StorageService.saveProfile(_profileData!);
        notifyListeners();
      }
    }
  }

  /// Clear profile
  Future<void> clearProfile() async {
    _profileData = null;
    _profileImagePath = null;
    _error = null;
    await StorageService.clearProfile();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
