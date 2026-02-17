import 'package:flutter/material.dart';
import '../../../models/quiz_models.dart';
import 'ai_quiz_screen.dart';
import 'quiz_review_screen.dart';
import '../../career/screens/career_detail_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  final QuizResult result;
  final List<QuizQuestion>? questions;
  final Map<int, String>? userAnswers;

  const QuizResultsScreen({
    super.key,
    required this.result,
    this.questions,
    this.userAnswers,
  });

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
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No matching careers found based on this quiz.'),
                ),
              )
            else
              ...result.careerMatches
                  .take(3)
                  .map((match) => _buildCareerMatchCard(context, match)),
            const SizedBox(height: 24),

            // Action Buttons
            if (questions != null && userAnswers != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizReviewScreen(
                          questions: questions!,
                          userAnswers: userAnswers!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.checklist),
                  label: const Text('Show Answers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (questions != null && userAnswers != null)
              const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to home and then to quiz screen for a new quiz
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiQuizScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Keep Practicing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
      label = 'Needs Improvement';
      color = Colors.red;
      icon = Icons.trending_up;
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

  Widget _buildCareerMatchCard(BuildContext context, CareerMatch match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.work_outline, color: Colors.blueAccent),
        ),
        title: Text(
          match.careerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Match: ${match.matchPercentage.toStringAsFixed(1)}%'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CareerDetailPage(
                careerTitle: match.careerName,
                overview: 'Career match based on your quiz results.',
                requiredSkills: match.matchingSkills + match.missingSkills,
                userSkills: match.matchingSkills,
                accentColor: Colors.blueAccent,
              ),
            ),
          );
        },
      ),
    );
  }
}
