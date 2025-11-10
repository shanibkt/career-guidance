import 'dart:io';

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart';

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

  @override
  void initState() {
    super.initState();
    StorageService.loadProfile().then((m) => setState(() => _profile = m));
    StorageService.loadProfileImagePath().then(
      (p) => setState(() => _imagePath = p),
    );
  }

  Future<void> _logout() async {
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

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user?.fullName ?? _profile?['field'] ?? 'User';
    final email =
        widget.user?.email ?? _profile?['email'] ?? 'email@example.com';

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
                        ? FileImage(File(_imagePath!))
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              backgroundImage: _imagePath != null
                  ? FileImage(File(_imagePath!))
                  : null,
              child: _imagePath == null
                  ? Icon(Icons.person, size: 80, color: Colors.blue[700])
                  : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              displayName,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (_profile != null) ...[
              Text('Education: ${_profile!['education'] ?? ''}'),
              const SizedBox(height: 6),
              Text('Field: ${_profile!['field'] ?? ''}'),
              const SizedBox(height: 6),
              Text(
                'Skills: ${((_profile!['skills'] ?? []) as List).join(', ')}',
              ),
              const SizedBox(height: 6),
              Text('Areas: ${_profile!['areas'] ?? ''}'),
            ],
          ],
        ),
      ),
    );
  }
}
