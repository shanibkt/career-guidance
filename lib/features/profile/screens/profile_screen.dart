import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../models/user.dart';
import '../../../services/local/storage_service.dart';
import '../../../services/api/profile_service.dart';
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

  User? _serverUser;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Show widget.user immediately if available
    setState(() {
      _serverUser = widget.user;
    });

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
          setState(() {
            _profile = serverProfile;
            _serverUser = cachedUser;
            _imagePath = fullImageUrl;
          });
        } else {
          setState(() {
            _profile = serverProfile;
            _serverUser = cachedUser;
          });
        }
        debugPrint('ProfilePage._loadAll - loaded from backend: $_profile');
        debugPrint('ProfilePage._loadAll - image path: $_imagePath');
      } else {
        // Backend didn't return profile - use local cache
        final profile = await StorageService.loadProfile();
        final imagePath = await StorageService.loadProfileImagePath();
        setState(() {
          _profile = profile;
          _serverUser = cachedUser;
          _imagePath = imagePath;
        });
        debugPrint('ProfilePage._loadAll - loaded from local cache: $_profile');
      }
    } else {
      // No token or user - use local cache only
      final profile = await StorageService.loadProfile();
      final imagePath = await StorageService.loadProfileImagePath();
      setState(() {
        _profile = profile;
        _serverUser = cachedUser;
        _imagePath = imagePath;
      });
      debugPrint(
        'ProfilePage._loadAll - no token, loaded from local: $_profile',
      );
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
                    backgroundImage: _imagePath != null
                        ? (_imagePath!.startsWith('http')
                              ? NetworkImage(_imagePath!) as ImageProvider
                              : FileImage(File(_imagePath!)))
                        : null,
                    child: _imagePath == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.blueAccent,
                            size: 36,
                          )
                        : null,
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
                    backgroundImage: _imagePath != null
                        ? (_imagePath!.startsWith('http')
                              ? NetworkImage(_imagePath!) as ImageProvider
                              : FileImage(File(_imagePath!)))
                        : null,
                    child: _imagePath == null
                        ? Icon(Icons.person, size: 80, color: Colors.blue[700])
                        : null,
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
                  if (_profile != null &&
                      ((_profile!['areasOfInterest'] ?? _profile!['areas'])
                              ?.isNotEmpty ==
                          true))
                    _buildSection('Areas of Interest', [
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          (_profile!['areasOfInterest'] ?? _profile!['areas'])
                                  ?.toString() ??
                              '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ]),
                  if (_profile == null ||
                      ((_profile!['areasOfInterest'] ?? _profile!['areas'])
                              ?.isEmpty !=
                          false))
                    _buildSection('Areas of Interest', [
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'No areas of interest specified. Tap edit to add your career aspirations.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
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
