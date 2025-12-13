import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../career/screens/career_suggestions_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../learning_path/screens/learning_path_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../resume_builder/screens/resume_builder_screen.dart';
import '../../quiz/screens/ai_quiz_screen.dart';
import '../../jobs/screens/job_finder_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/local/storage_service.dart';
import '../../../services/api/profile_service.dart';
import '../../../services/api/career_progress_service.dart';
import '../../../core/utils/auth_error_handler.dart';

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
  String? _selectedCareerTitle;

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

    // Load selected career from database first, fallback to local storage
    Map<String, dynamic>? selectedCareer;
    try {
      selectedCareer = await CareerProgressService.getSelectedCareer();
      print('📍 Loaded career from database: $selectedCareer');

      // Check for 401 Unauthorized
      if (selectedCareer != null && selectedCareer['_statusCode'] == 401) {
        if (mounted) {
          await AuthErrorHandler.handleUnauthorizedError(context);
        }
        return;
      }
    } catch (e) {
      print('⚠️ Failed to load career from database, using local storage: $e');
      selectedCareer = await StorageService.loadSelectedCareer();
    }

    setState(() {
      _cachedUser = userMap != null
          ? User.fromJson(userMap)
          : (_cachedUser ?? widget.user);
      _cachedProfile = profile;
      _profileImagePath = imagePath;
      _selectedCareerTitle = selectedCareer?['careerName'] as String?;
    });

    // Fetch updated profile image from backend
    final token = await StorageService.loadAuthToken();
    final cachedUser = userMap != null ? User.fromJson(userMap) : widget.user;

    if (token != null && cachedUser?.id != null) {
      final serverProfile = await ProfileService.getProfile(
        cachedUser!.id,
        token,
      );

      // Check for 401 Unauthorized
      if (serverProfile != null && serverProfile['_statusCode'] == 401) {
        if (mounted) {
          await AuthErrorHandler.handleUnauthorizedError(context);
        }
        return;
      }

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

  // Refresh selected career from database or local storage
  Future<void> _refreshSelectedCareer() async {
    try {
      final updatedCareer = await CareerProgressService.getSelectedCareer();
      if (updatedCareer != null && updatedCareer['_statusCode'] != 401) {
        if (mounted) {
          setState(() {
            _selectedCareerTitle = updatedCareer['careerName'] as String?;
          });
        }
      }
    } catch (e) {
      // Fallback to local storage
      final localCareer = await StorageService.loadSelectedCareer();
      if (mounted) {
        setState(() {
          _selectedCareerTitle = localCareer?['careerName'] as String?;
        });
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
                  child: _profileImagePath == null
                      ? Icon(Icons.person, color: Colors.grey[600], size: 28)
                      : ClipOval(
                          child: _profileImagePath!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: _profileImagePath!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, url) =>
                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                  errorWidget: (ctx, url, err) => Icon(
                                    Icons.person,
                                    color: Colors.grey[600],
                                    size: 28,
                                  ),
                                )
                              : Image.file(
                                  File(_profileImagePath!),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                        ),
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

          // AI Career Quiz section
          _buildCard(
            icon: Icons.psychology_outlined,
            title: 'AI Career Assessment',
            buttonText: 'Start Quiz',
            buttonColor: const Color(0xFF4A7DFF),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AiQuizScreen()));
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
              // Get user skills from cached profile
              final userSkills =
                  (_cachedProfile?['skills'] as List?)
                      ?.map((skill) => skill.toString())
                      .toList() ??
                  [];

              // Navigate to your career suggestions page with user skills
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CareerSuggestionsPage(userSkills: userSkills),
                    ),
                  )
                  .then((_) async {
                    // Reload selected career when returning from career suggestions
                    try {
                      final updatedCareer =
                          await CareerProgressService.getSelectedCareer();
                      if (updatedCareer != null &&
                          updatedCareer['_statusCode'] != 401) {
                        setState(() {
                          _selectedCareerTitle =
                              updatedCareer['careerName'] as String?;
                        });
                      }
                    } catch (e) {
                      // Fallback to local storage
                      final localCareer =
                          await StorageService.loadSelectedCareer();
                      setState(() {
                        _selectedCareerTitle =
                            localCareer?['careerTitle'] as String?;
                      });
                    }
                  });
            },
          ),
          const SizedBox(height: 16),

          // Learning Path section
          _buildCard(
            icon: Icons.route_outlined,
            title: 'Learning Path',
            subtitle: _selectedCareerTitle ?? 'No career selected',
            buttonText: 'Check',
            buttonColor: const Color(0xFFB8A67A),
            onPressed: () async {
              // Load selected career from storage
              final selectedCareer = await StorageService.loadSelectedCareer();

              if (selectedCareer != null) {
                // Navigate to learning path with selected career
                // Use careerName (new format) or careerTitle (old format) for backward compatibility
                final careerTitle =
                    (selectedCareer['careerName'] ??
                            selectedCareer['careerTitle'])
                        as String?;
                final requiredSkills =
                    (selectedCareer['requiredSkills'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList();

                if (careerTitle == null || requiredSkills == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a career first'),
                    ),
                  );
                  return;
                }

                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => LearningPathPage(
                          careerTitle: careerTitle,
                          requiredSkills: requiredSkills,
                        ),
                      ),
                    )
                    .then((_) async {
                      // Reload selected career when returning from learning path
                      final updatedCareer =
                          await StorageService.loadSelectedCareer();
                      setState(() {
                        _selectedCareerTitle =
                            updatedCareer?['careerTitle'] as String?;
                      });
                    });
              } else {
                // Show message that no career is selected
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No career selected yet. Please select a career from Career Suggestions first.',
                    ),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
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
          const SizedBox(height: 16),

          // Job Finder section
          _buildCard(
            icon: Icons.work_outline,
            title: 'Find Jobs',
            subtitle: 'Jobs based on your selected career',
            buttonText: 'Search',
            buttonColor: const Color(0xFF4A7DFF),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const JobFinderPage()));
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
    String? subtitle,
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
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
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
      onTap: () async {
        setState(() {
          _currentIndex = index;
        });

        // Refresh career selection when switching to home tab
        if (index == 0) {
          _refreshSelectedCareer();
        }
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
