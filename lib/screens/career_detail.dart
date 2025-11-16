import 'package:flutter/material.dart';
import 'learning_path.dart';

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
    final matchedSkills = requiredSkills
        .where(
          (skill) =>
              userSkills.any((us) => us.toLowerCase() == skill.toLowerCase()),
        )
        .toList();
    final matchPercentage =
        ((matchedSkills.length / requiredSkills.length) * 100).round();

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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LearningPathPage(
                              careerTitle: careerTitle,
                              accentColor: accentColor,
                            ),
                          ),
                        );
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
