import 'package:flutter/material.dart';
import '../../../models/quiz_models.dart';

class QuizReviewScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  final Map<int, String> userAnswers;

  const QuizReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswer = userAnswers[question.id] ?? '';
          final isCorrect = userAnswer == question.correctAnswer;

          return _buildQuestionCard(question, userAnswer, isCorrect, index);
        },
      ),
    );
  }

  Widget _buildQuestionCard(
    QuizQuestion question,
    String userAnswer,
    bool isCorrect,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCorrect ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with result indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question number and status
                      Row(
                        children: [
                          Text(
                            'Question ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCorrect ? 'Correct' : 'Wrong',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Skill category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.code,
                              size: 14,
                              color: Colors.blue.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              question.skillCategory,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            ...question.options.map((option) {
              final letter = option.substring(0, 1);
              final isUserAnswer = userAnswer == letter;
              final isCorrectAnswer = question.correctAnswer == letter;

              Color backgroundColor;
              Color borderColor;
              Color textColor;
              Widget? trailingIcon;

              if (isCorrectAnswer) {
                // Correct answer - always show in green
                backgroundColor = Colors.green.shade50;
                borderColor = Colors.green.shade700;
                textColor = Colors.green.shade900;
                trailingIcon = Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 24,
                );
              } else if (isUserAnswer && !isCorrect) {
                // User's wrong answer - show in red
                backgroundColor = Colors.red.shade50;
                borderColor = Colors.red.shade700;
                textColor = Colors.red.shade900;
                trailingIcon = Icon(
                  Icons.cancel,
                  color: Colors.red.shade700,
                  size: 24,
                );
              } else {
                // Other options - neutral
                backgroundColor = Colors.grey.shade100;
                borderColor = Colors.grey.shade300;
                textColor = Colors.black87;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      // Letter circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCorrectAnswer
                              ? Colors.green.shade700
                              : isUserAnswer && !isCorrect
                              ? Colors.red.shade700
                              : Colors.grey.shade400,
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Option text
                      Expanded(
                        child: Text(
                          option.substring(3), // Remove "A) " prefix
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: (isCorrectAnswer || isUserAnswer)
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                      // Trailing icon for correct/wrong
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        trailingIcon,
                      ],
                    ],
                  ),
                ),
              );
            }),

            // Explanation section (if user got it wrong)
            if (!isCorrect) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correct Answer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The correct answer is option ${question.correctAnswer}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
