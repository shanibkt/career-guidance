import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/quiz_models.dart';
import '../../../services/api/career_quiz_service.dart';
import 'quiz_results_screen.dart';

class AiQuizScreen extends StatefulWidget {
  const AiQuizScreen({super.key});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  QuizResponse? _quiz;
  final Map<int, String> _answers = {};
  bool _loading = false;
  String? _error;
  int _currentQuestionIndex = 0;
  String _loadingMessage = 'Preparing your quiz...';
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _loadingMessage = 'Analyzing your skills...';
      _elapsedSeconds = 0;
    });

    // Update loading message periodically
    final timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      _elapsedSeconds += 5;
      setState(() {
        if (_elapsedSeconds == 5) {
          _loadingMessage = 'Generating technical questions...';
        } else if (_elapsedSeconds == 10) {
          _loadingMessage = 'Tailoring questions to your level...';
        } else if (_elapsedSeconds == 15) {
          _loadingMessage = 'Almost ready...';
        } else if (_elapsedSeconds >= 20) {
          _loadingMessage = 'This is taking longer than usual. Please wait...';
        }
      });
    });

    try {
      // Use retry logic for better reliability
      final quiz = await CareerQuizService.generateQuizWithRetry();
      timer.cancel();

      if (!mounted) return;

      setState(() {
        _quiz = quiz;
        _loading = false;
      });
    } catch (e) {
      timer.cancel();

      if (!mounted) return;

      final errorMsg = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _loading = false;
        _error = errorMsg;
      });

      // Show user-friendly error dialog
      _showErrorDialog(errorMsg);
    }
  }

  void _showErrorDialog(String errorMsg) {
    String title = 'Quiz Generation Failed';
    String message = errorMsg;
    String actionText = 'Try Again';
    VoidCallback? action;

    if (errorMsg.contains('timeout') || errorMsg.contains('timed out')) {
      title = '⏱️ Request Timed Out';
      message =
          'The AI is taking longer than usual. This sometimes happens when the server is busy.\n\nPlease try again.';
    } else if (errorMsg.contains('503') || errorMsg.contains('unavailable')) {
      title = '🔧 Service Unavailable';
      message =
          'AI service is temporarily unavailable.\n\nPlease wait a moment and try again.';
    } else if (errorMsg.contains('504')) {
      title = '⏳ Gateway Timeout';
      message = 'The request took too long to complete.\n\nPlease try again.';
    } else if (errorMsg.contains('skills') || errorMsg.contains('profile')) {
      title = '📝 No Skills Found';
      message =
          'No skills found in your profile.\n\nPlease add your skills in the profile section first.';
      actionText = 'Go to Profile';
      action = () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back to home
      };
    } else if (errorMsg.contains('SocketException') ||
        errorMsg.contains('network') ||
        errorMsg.contains('internet')) {
      title = '📡 No Internet Connection';
      message = 'Please check your network connection and try again.';
    } else if (errorMsg.contains('login') ||
        errorMsg.contains('Session expired')) {
      title = '🔐 Session Expired';
      message = 'Your session has expired.\n\nPlease login again to continue.';
      actionText = 'OK';
      action = () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back to home
      };
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed:
                action ??
                () {
                  Navigator.of(context).pop(); // Close dialog
                  _loadQuiz(); // Retry
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null || !mounted) return;

    if (!mounted) return;
    setState(() => _loading = true);

    // Convert to QuizAnswer list
    final answers = _answers.entries
        .map((e) => QuizAnswer(questionId: e.key, answer: e.value))
        .toList();

    try {
      print('🔵 Submitting quiz with ${answers.length} answers...');

      // Submit answers and get results
      final result = await CareerQuizService.submitQuiz(_quiz!.quizId, answers);

      print('✅ Quiz submitted successfully!');
      print('✅ Result - Score: ${result.totalScore}/${result.totalQuestions}');
      print('✅ Result - Percentage: ${result.percentage}');
      print(
        '✅ Result - Skill breakdown count: ${result.skillBreakdown.length}',
      );
      print('✅ Result - Career matches count: ${result.careerMatches.length}');

      if (!mounted) return;
      setState(() => _loading = false);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Quiz complete! Score: ${result.totalScore}/${result.totalQuestions} (${result.percentage.toStringAsFixed(1)}%)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      print('🔵 Navigating to results screen...');
      // Navigate to results screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizResultsScreen(result: result)),
      );
      print('✅ Navigation initiated');
    } catch (e, stackTrace) {
      print('❌ Error submitting quiz: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => _loading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Career Assessment'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _loadingMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take up to 30 seconds',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadQuiz, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_quiz == null) {
      return const Center(child: Text('Failed to load quiz'));
    }

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _quiz!.questions.length,
          backgroundColor: Colors.grey.shade200,
          color: Colors.blueAccent,
          minHeight: 8,
        ),

        // Question counter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(((_currentQuestionIndex + 1) / _quiz!.questions.length) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),

        // Current question
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildQuestion(_quiz!.questions[_currentQuestionIndex]),
          ),
        ),

        // Navigation buttons
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _currentQuestionIndex--);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final currentQuestion =
                          _quiz!.questions[_currentQuestionIndex];
                      final hasAnswer =
                          _answers.containsKey(currentQuestion.id) &&
                          _answers[currentQuestion.id]!.trim().isNotEmpty;

                      if (!hasAnswer) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please answer this question'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (_currentQuestionIndex < _quiz!.questions.length - 1) {
                        setState(() => _currentQuestionIndex++);
                      } else {
                        _submitQuiz();
                      }
                    },
                    icon: Icon(
                      _currentQuestionIndex == _quiz!.questions.length - 1
                          ? Icons.send
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentQuestionIndex == _quiz!.questions.length - 1
                          ? 'Submit'
                          : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(QuizQuestion question) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 16, color: Colors.blue.shade900),
                  const SizedBox(width: 6),
                  Text(
                    question.skillCategory,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Question text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Answer options (multiple choice)
            ...question.options.map((option) {
              final letter = option.substring(0, 1); // Extract "A", "B", etc.
              final isSelected = _answers[question.id] == letter;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() => _answers[question.id] = letter);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.substring(3), // Remove "A) " prefix
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
