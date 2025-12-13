import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user.dart';
import '../../../services/local/storage_service.dart';
import '../../../services/api/profile_service.dart';
import '../../../services/api/career_progress_service.dart';
import '../../../core/utils/auth_error_handler.dart';
import '../../auth/screens/login_screen.dart';
import 'reg_profile_screen.dart';

// Profile Page (shows saved profile information)
class ProfilePage extends StatefulWidget {
  final User? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  String? _imagePath;
  String? _selectedCareerTitle;

  User? _serverUser;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Show widget.user immediately if available
    if (mounted) {
      setState(() {
        _serverUser = widget.user;
      });
    }

    // Try to load from backend first
    final token = await StorageService.loadAuthToken();
    final userMap = await StorageService.loadUser();
    final cachedUser = userMap != null ? User.fromJson(userMap) : widget.user;

    debugPrint(
      'ProfilePage._loadAll - token: ${token != null ? "exists" : "null"}',
    );
    debugPrint('ProfilePage._loadAll - cachedUser.id: ${cachedUser?.id}');

    if (token != null && cachedUser?.id != null) {
      final serverProfile = await ProfileService.getProfile(
        cachedUser!.id,
        token,
      );

      debugPrint('ProfilePage._loadAll - serverProfile: $serverProfile');

      // Check for 401 Unauthorized
      if (serverProfile != null && serverProfile['_statusCode'] == 401) {
        if (mounted) {
          await AuthErrorHandler.handleUnauthorizedError(context);
        }
        return;
      }

      if (serverProfile != null && serverProfile.isNotEmpty) {
        // Backend returned profile - save locally and use it
        await StorageService.saveProfile(serverProfile);

        // Save profile image path from backend
        final backendImagePath = serverProfile['profileImagePath'] as String?;
        if (backendImagePath != null && backendImagePath.isNotEmpty) {
          // Convert backend relative path to full URL
          // Remove leading slash if present to avoid double slashes
          final cleanPath = backendImagePath.startsWith('/')
              ? backendImagePath.substring(1)
              : backendImagePath;
          final fullImageUrl = '${ProfileService.effectiveBaseUrl}/$cleanPath';
          await StorageService.saveProfileImagePath(fullImageUrl);
          if (mounted) {
            setState(() {
              _profile = serverProfile;
              _serverUser = cachedUser;
              _imagePath = fullImageUrl;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _profile = serverProfile;
              _serverUser = cachedUser;
            });
          }
        }
        debugPrint('ProfilePage._loadAll - loaded from backend: $_profile');
        debugPrint('ProfilePage._loadAll - image path: $_imagePath');
        debugPrint('🟢 CHECKPOINT 1: After image path, before else block');
      } else {
        debugPrint('🔴 CHECKPOINT 2: In else block - no server profile');
        // Backend didn't return profile - use local cache
        final profile = await StorageService.loadProfile();
        final imagePath = await StorageService.loadProfileImagePath();
        if (mounted) {
          setState(() {
            _profile = profile;
            _serverUser = cachedUser;
            _imagePath = imagePath;
          });
        }
        debugPrint('ProfilePage._loadAll - loaded from local cache: $_profile');
        debugPrint('🔴 CHECKPOINT 3: Loaded from local cache');
      }
      debugPrint(
        '🟡 CHECKPOINT 4: After serverProfile if-else, still in token block',
      );
    } else {
      debugPrint('🔴 CHECKPOINT 5: No token or user, loading local');
      // No token or user - use local cache only
      final profile = await StorageService.loadProfile();
      final imagePath = await StorageService.loadProfileImagePath();
      if (mounted) {
        setState(() {
          _profile = profile;
          _serverUser = cachedUser;
          _imagePath = imagePath;
        });
      }
      debugPrint(
        'ProfilePage._loadAll - no token, loaded from local: $_profile',
      );
      debugPrint('🔴 CHECKPOINT 6: After loading local without token');
    }

    debugPrint('⭐⭐⭐ CHECKPOINT 7: REACHED END OF TOKEN BLOCKS!');
    debugPrint('⭐ ProfilePage._loadAll - After all profile loading');

    // Load selected career from database or local storage
    try {
      debugPrint('🔵 ProfilePage._loadAll - About to call _loadSelectedCareer');
      await _loadSelectedCareer();
      debugPrint(
        '🔵 ProfilePage._loadAll - Finished _loadSelectedCareer, career: $_selectedCareerTitle',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR loading selected career: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadSelectedCareer() async {
    debugPrint('🔄 ProfilePage._loadSelectedCareer - START');
    try {
      final selectedCareer = await CareerProgressService.getSelectedCareer();
      debugPrint(
        '🔄 ProfilePage._loadSelectedCareer - Got career: $selectedCareer',
      );
      if (selectedCareer != null && selectedCareer['_statusCode'] != 401) {
        if (mounted) {
          setState(() {
            _selectedCareerTitle = selectedCareer['careerName'] as String?;
          });
          debugPrint(
            '✅ ProfilePage._loadSelectedCareer - Set career title: $_selectedCareerTitle',
          );
        }
      } else {
        debugPrint(
          '⚠️ ProfilePage._loadSelectedCareer - Career is null or 401',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ ProfilePage._loadSelectedCareer - Error: $e, trying local storage',
      );
      // Fallback to local storage
      final localCareer = await StorageService.loadSelectedCareer();
      debugPrint(
        '📦 ProfilePage._loadSelectedCareer - Local career: $localCareer',
      );
      if (mounted) {
        setState(() {
          _selectedCareerTitle = localCareer?['careerName'] as String?;
        });
        debugPrint(
          '✅ ProfilePage._loadSelectedCareer - Set from local: $_selectedCareerTitle',
        );
      }
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // If user confirmed, proceed with logout
    if (shouldLogout == true) {
      await StorageService.clearAll();
      // Also clear secure storage token if present
      try {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'auth_token');
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
    }
  }

  Future<void> _onEditProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const RegProfileScreen()),
    );
    debugPrint('ProfilePage._onEditProfile - result: $result');
    if (result != null) {
      await StorageService.saveProfile(result);
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _serverUser?.fullName ?? _profile?['field'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _onEditProfile,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: _imagePath == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.blueAccent,
                            size: 36,
                          )
                        : ClipOval(
                            child: _imagePath!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: _imagePath!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) =>
                                        const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                    errorWidget: (ctx, url, err) => const Icon(
                                      Icons.person,
                                      color: Colors.blueAccent,
                                      size: 36,
                                    ),
                                  )
                                : Image.file(
                                    File(_imagePath!),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with avatar and basic info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue[100],
                    child: _imagePath == null
                        ? Icon(Icons.person, size: 80, color: Colors.blue[700])
                        : ClipOval(
                            child: _imagePath!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: _imagePath!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (ctx, url, err) => Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.blue[700],
                                    ),
                                  )
                                : Image.file(
                                    File(_imagePath!),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _serverUser?.fullName ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _serverUser?.email ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // User details section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Personal Information', [
                    _buildInfoRow(
                      'Full Name',
                      _serverUser?.fullName ?? 'Not set',
                    ),
                    _buildInfoRow(
                      'Username',
                      _serverUser?.username ?? 'Not set',
                    ),
                    _buildInfoRow('Email', _serverUser?.email ?? 'Not set'),
                    _buildInfoRow(
                      'Phone Number',
                      (_profile?['phoneNumber'] ?? _profile?['phone'])
                              ?.toString() ??
                          'Not set',
                    ),
                    _buildInfoRow(
                      'Age',
                      _profile?['age']?.toString() ?? 'Not set',
                    ),
                    _buildInfoRow(
                      'Gender',
                      _profile?['gender']?.toString() ?? 'Not set',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  if (_profile != null &&
                      (_profile!['educationLevel'] != null ||
                          _profile!['education'] != null))
                    _buildSection('Education', [
                      _buildInfoRow(
                        'Education Level',
                        (_profile!['educationLevel'] ?? _profile!['education'])
                                ?.toString() ??
                            'Not set',
                      ),
                      _buildInfoRow(
                        'Field of Study',
                        (_profile!['fieldOfStudy'] ?? _profile!['field'])
                                ?.toString() ??
                            'Not set',
                      ),
                    ]),
                  const SizedBox(height: 24),
                  if (_profile != null &&
                      (_profile!['skills'] as List?)?.isNotEmpty == true)
                    _buildSection('Skills', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_profile!['skills'] as List? ?? [])
                            .map<Widget>((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  skill.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ]),
                  if (_profile == null ||
                      (_profile!['skills'] as List?)?.isEmpty == true)
                    _buildSection('Skills', [
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'No skills added yet. Tap edit to add your skills.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ]),
                  const SizedBox(height: 24),
                  _buildSection('Career', [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _selectedCareerTitle ?? 'career not selected',
                        style: TextStyle(
                          color: _selectedCareerTitle != null
                              ? Colors.black87
                              : Colors.black54,
                          fontStyle: _selectedCareerTitle != null
                              ? FontStyle.normal
                              : FontStyle.italic,
                          fontWeight: _selectedCareerTitle != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {Widget? action}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
