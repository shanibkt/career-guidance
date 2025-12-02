import 'package:flutter/material.dart';
import '../../../models/quiz_models.dart';
import '../../career/screens/career_suggestions_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  final QuizResult result;

  const QuizResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            Card(
              color: Colors.blue.shade50,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.totalScore} / ${result.totalQuestions} Correct',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceBadge(result.percentage),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Skill Breakdown
            const Text(
              'Skill Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...result.skillBreakdown.map(
              (skill) => _buildSkillScoreCard(skill),
            ),
            const SizedBox(height: 24),

            // Career Matches
            const Text(
              'Career Matches',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (result.careerMatches.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Collect all skills from skill breakdown
                      final userSkills = result.skillBreakdown
                          .where((skill) => skill.percentage >= 50)
                          .map((skill) => skill.skill)
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CareerSuggestionsPage(userSkills: userSkills),
                        ),
                      );
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Career Suggestions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...result.careerMatches.map(
                (career) => _buildCareerMatchCard(career),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBadge(double percentage) {
    String label;
    Color color;
    IconData icon;

    if (percentage >= 90) {
      label = 'Excellent!';
      color = Colors.green;
      icon = Icons.star;
    } else if (percentage >= 70) {
      label = 'Good Job!';
      color = Colors.blue;
      icon = Icons.thumb_up;
    } else if (percentage >= 50) {
      label = 'Not Bad';
      color = Colors.orange;
      icon = Icons.sentiment_satisfied;
    } else {
      label = 'Keep Practicing';
      color = Colors.red;
      icon = Icons.school;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillScoreCard(SkillScore skill) {
    final color = skill.percentage >= 70
        ? Colors.green
        : skill.percentage >= 50
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.code, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(
                      skill.skill,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${skill.correct}/${skill.total}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: skill.percentage / 100,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${skill.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerMatchCard(CareerMatch career) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    career.careerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.shade700,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${career.matchPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (career.salaryRange != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    career.salaryRange!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (career.matchingSkills.isNotEmpty) ...[
              const Text(
                'Matching Skills:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: career.matchingSkills
                    .map(
                      (skill) => Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.green.shade100,
                        avatar: Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (career.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Skills to Develop:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: career.missingSkills
                    .map(
                      (skill) => Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.orange.shade100,
                        avatar: Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
