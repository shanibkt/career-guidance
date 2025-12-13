import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../learning_path/screens/learning_path_screen.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/local/storage_service.dart';
import '../../../services/api/career_progress_service.dart';

class CareerDetailPage extends StatelessWidget {
  final String careerTitle;
  final String overview;
  final List<String> requiredSkills;
  final List<String> userSkills;
  final Color accentColor;

  const CareerDetailPage({
    super.key,
    required this.careerTitle,
    required this.overview,
    required this.requiredSkills,
    required this.userSkills,
    this.accentColor = const Color(0xFF286ED8),
  });

  @override
  Widget build(BuildContext context) {
    // Get user skills from profile provider or use passed skills
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final profileSkills = profileProvider.skills;

    // Combine passed userSkills with profile skills (remove duplicates)
    final allUserSkills = {...userSkills, ...profileSkills}.toList();

    print('🔍 Career Detail Debug:');
    print('Career: $careerTitle');
    print('Required Skills: $requiredSkills');
    print('Passed User Skills: $userSkills');
    print('Profile Skills: $profileSkills');
    print('All User Skills: $allUserSkills');

    final matchedSkills = requiredSkills
        .where(
          (skill) => allUserSkills.any(
            (us) => us.toLowerCase().trim() == skill.toLowerCase().trim(),
          ),
        )
        .toList();

    print('Matched Skills: $matchedSkills');

    final matchPercentage = requiredSkills.isEmpty
        ? 0
        : ((matchedSkills.length / requiredSkills.length) * 100).round();

    print('Match Percentage: $matchPercentage%');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: accentColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                careerTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withOpacity(0.7)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCareerIcon(careerTitle),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match percentage card
                  _buildMatchCard(
                    matchPercentage,
                    matchedSkills.length,
                    requiredSkills.length,
                  ),

                  const SizedBox(height: 24),

                  // Career Overview
                  _buildSectionCard(
                    title: 'Career Overview',
                    icon: Icons.description_outlined,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/images/developer.png',
                              width: 50,
                              height: 50,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.work_outline,
                                    size: 50,
                                    color: accentColor,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              overview,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Required Skills
                  _buildSectionCard(
                    title: 'Required Skills',
                    icon: Icons.stars_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: requiredSkills.map((skill) {
                        final isMatched = matchedSkills.contains(skill);
                        return _buildSkillChip(
                          skill,
                          isMatched,
                          isMatched ? Colors.green : Colors.grey,
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Your Matching Skills
                  if (matchedSkills.isNotEmpty)
                    _buildSectionCard(
                      title: 'Your Matching Skills',
                      icon: Icons.check_circle_outline,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: matchedSkills.map((skill) {
                          return _buildSkillChip(skill, true, Colors.green);
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Skills to Learn
                  if (matchedSkills.length < requiredSkills.length)
                    _buildSectionCard(
                      title: 'Skills to Learn',
                      icon: Icons.lightbulb_outline,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: requiredSkills
                            .where((skill) => !matchedSkills.contains(skill))
                            .map((skill) {
                              return _buildSkillChip(
                                skill,
                                false,
                                Colors.orange,
                              );
                            })
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Start Learning Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.school, color: accentColor),
                                  const SizedBox(width: 8),
                                  const Text('Start Learning Path'),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to take this career path for "$careerTitle"?\n\nThis will be set as your active learning path.',
                                style: const TextStyle(fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          // Show loading indicator
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          // Save to local storage (backup)
                          await StorageService.saveSelectedCareer(
                            careerTitle,
                            requiredSkills,
                          );

                          // Save to database
                          await CareerProgressService.saveSelectedCareer(
                            careerName: careerTitle,
                            requiredSkills: requiredSkills,
                          );

                          // Navigate to learning path
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            // Pop all career screens and go to learning path
                            // This ensures back button from learning path goes to home
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LearningPathPage(
                                  careerTitle: careerTitle,
                                  requiredSkills: requiredSkills,
                                  accentColor: accentColor,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Start Learning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(int percentage, int matched, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.8), accentColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skill Match',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$matched out of $total skills matches',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill, bool isMatched, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatched)
            Icon(Icons.check_circle, size: 16, color: color)
          else
            Icon(Icons.circle_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            skill,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCareerIcon(String career) {
    switch (career.toLowerCase()) {
      case 'software developer':
        return Icons.computer;
      case 'data scientist':
        return Icons.analytics;
      case 'ux designer':
        return Icons.design_services;
      default:
        return Icons.work_outline;
    }
  }
}
