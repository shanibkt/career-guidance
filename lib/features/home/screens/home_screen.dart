import 'dart:io';
import '../../career/screens/career_suggestions_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../learning_path/screens/learning_path_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../resume_builder/screens/resume_builder_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/local/storage_service.dart';
import '../../../services/api/profile_service.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _cachedUser;
  Map<String, dynamic>? _cachedProfile;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    // show any user passed via constructor immediately
    setState(() {
      _cachedUser = widget.user;
    });

    final userMap = await StorageService.loadUser();
    final profile = await StorageService.loadProfile();
    final imagePath = await StorageService.loadProfileImagePath();

    setState(() {
      _cachedUser = userMap != null
          ? User.fromJson(userMap)
          : (_cachedUser ?? widget.user);
      _cachedProfile = profile;
      _profileImagePath = imagePath;
    });

    // Fetch updated profile image from backend
    final token = await StorageService.loadAuthToken();
    final cachedUser = userMap != null ? User.fromJson(userMap) : widget.user;

    if (token != null && cachedUser?.id != null) {
      final serverProfile = await ProfileService.getProfile(
        cachedUser!.id,
        token,
      );

      if (serverProfile != null && serverProfile.isNotEmpty) {
        final backendImagePath = serverProfile['profileImagePath'] as String?;
        if (backendImagePath != null && backendImagePath.isNotEmpty) {
          // Remove leading slash to avoid double slashes
          final cleanPath = backendImagePath.startsWith('/')
              ? backendImagePath.substring(1)
              : backendImagePath;
          final fullImageUrl = '${ProfileService.effectiveBaseUrl}/$cleanPath';
          await StorageService.saveProfileImagePath(fullImageUrl);
          setState(() {
            _profileImagePath = fullImageUrl;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _getSelectedPage()),

            // Bottom Navigation Bar - Fixed
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 0),
                  _buildNavItem(Icons.chat_bubble_outline, 1),
                  _buildNavItem(Icons.person_outline, 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return ChatPage();
      case 2:
        return ProfilePage(user: _cachedUser ?? widget.user);
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final displayName =
        _cachedUser?.fullName ??
        _cachedUser?.username ??
        widget.user?.fullName ??
        widget.user?.username ??
        _cachedProfile?['field'] ??
        'Name';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Career Pathfinder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Profile avatar: switch to profile tab (keeps bottom nav)
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 2; // Switch to profile tab
                  });
                },
                borderRadius: BorderRadius.circular(22),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImagePath != null
                      ? (_profileImagePath!.startsWith('http')
                            ? NetworkImage(_profileImagePath!)
                            : FileImage(File(_profileImagePath!)))
                      : null,
                  child: _profileImagePath == null
                      ? Icon(Icons.person, color: Colors.grey[600], size: 28)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Welcome section with name
          Text(
            'Hi, $displayName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Progress card with blue background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A7DFF), Color(0xFF5B8EFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'learning progress 0%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Career Quiz section
          _buildCard(
            icon: Icons.help_outline,
            title: 'Career Quiz',
            buttonText: 'Start',
            buttonColor: const Color(0xFFB8A67A),
            onPressed: () {
              Navigator.of(context).pushNamed('/quiz');
            },
          ),
          const SizedBox(height: 16),

          // Career suggestions section
          _buildCard(
            icon: Icons.school_outlined,
            title: 'Career suggestions',
            buttonText: '3 New',
            buttonColor: const Color(0xFFB8A67A),
            onPressed: () {
              // Navigate to your career suggestions page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CareerSuggestionsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Learning Path section
          _buildCard(
            icon: Icons.route_outlined,
            title: 'Learning Path',
            buttonText: 'Check',
            buttonColor: const Color(0xFFB8A67A),
            onPressed: () {
              // Navigate to your learning path page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const LearningPathPage(careerTitle: 'Software Developer'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Resume Builder section
          _buildCard(
            icon: Icons.description_outlined,
            title: 'Resume Builder',
            buttonText: 'Build',
            buttonColor: const Color(0xFFB8A67A),
            onPressed: () {
              // Navigate to your resume builder page
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isActive = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black87 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: isActive ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(
              icon,
              key: ValueKey<bool>(isActive),
              color: isActive ? Colors.white : Colors.black54,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
