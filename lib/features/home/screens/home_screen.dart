import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../career/screens/career_suggestions_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../learning_path/screens/learning_path_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../resume_builder/screens/resume_builder_screen.dart';
import '../../quiz/screens/ai_quiz_screen.dart';
import '../../jobs/screens/job_finder_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../admin/screens/admin_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
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
    // Fetch unread hiring notification count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnreadCount();
    });
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
          // Modern Header with profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $displayName 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Let\'s shape your future today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Consumer<NotificationProvider>(
                builder: (context, np, _) => InkWell(
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        )
                        .then((_) => np.fetchUnreadCount());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: NotificationBadge(
                      count: np.unreadCount,
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 26,
                        color: Color(0xFF4A7DFF),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Modern Profile avatar with gradient border
              InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = 2; // Switch to profile tab
                  });
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A7DFF), Color(0xFF5B8EFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: _profileImagePath == null
                        ? Icon(Icons.person, color: Colors.grey[600], size: 26)
                        : ClipOval(
                            child: _profileImagePath!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: _profileImagePath!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) =>
                                        const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                    errorWidget: (ctx, url, err) => Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 26,
                                    ),
                                  )
                                : Image.file(
                                    File(_profileImagePath!),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Admin Dashboard (only for admins)
          if (context.watch<AuthProvider>().isAdmin) ...[
            _buildCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin Dashboard',
              subtitle: 'Manage users & view stats',
              buttonText: 'Open',
              buttonColor: const Color(0xFF9B59B6),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Modern Icon with gradient
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        buttonColor.withOpacity(0.1),
                        buttonColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: buttonColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Modern Arrow Button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF4A7DFF), Color(0xFF5B8EFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black38,
          size: 26,
        ),
      ),
    );
  }
}
