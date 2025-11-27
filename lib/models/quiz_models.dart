class QuizResponse {
  final String quizId;
  final List<QuizQuestion> questions;

  QuizResponse({required this.quizId, required this.questions});

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      quizId: json['quiz_id'] ?? json['quizId'], // Backend uses quiz_id
      questions: (json['questions'] as List<dynamic>)
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final String type; // "multiple_choice"
  final String skillCategory;
  final String correctAnswer; // "A", "B", "C", or "D"
  final List<String> options;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.skillCategory,
    required this.correctAnswer,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      skillCategory: json['skill_category'],
      correctAnswer: json['correct_answer'],
      options: List<String>.from(json['options']),
    );
  }
}

class QuizAnswer {
  final int questionId;
  final String answer;

  QuizAnswer({required this.questionId, required this.answer});

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId, // Backend expects snake_case
      'answer': answer,
    };
  }
}

class QuizResult {
  final int totalScore;
  final int totalQuestions;
  final double percentage;
  final List<SkillScore> skillBreakdown;
  final List<CareerMatch> careerMatches;

  QuizResult({
    required this.totalScore,
    required this.totalQuestions,
    required this.percentage,
    required this.skillBreakdown,
    required this.careerMatches,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      totalScore: json['total_score'] ?? json['totalScore'],
      totalQuestions: json['total_questions'] ?? json['totalQuestions'],
      percentage: (json['percentage'] as num).toDouble(),
      // ✅ FIX: Properly cast List<dynamic> and map each item
      skillBreakdown:
          ((json['skill_breakdown'] ?? json['skillBreakdown']) as List<dynamic>)
              .map((item) => SkillScore.fromJson(item as Map<String, dynamic>))
              .toList(),
      careerMatches:
          ((json['career_matches'] ?? json['careerMatches']) as List<dynamic>)
              .map((item) => CareerMatch.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class SkillScore {
  final String skill;
  final int correct;
  final int total;
  final double percentage;

  SkillScore({
    required this.skill,
    required this.correct,
    required this.total,
    required this.percentage,
  });

  factory SkillScore.fromJson(Map<String, dynamic> json) {
    return SkillScore(
      skill: json['skill'],
      correct: json['correct'],
      total: json['total'],
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class CareerMatch {
  final int careerId;
  final String careerName;
  final double matchPercentage;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final String? salaryRange;

  CareerMatch({
    required this.careerId,
    required this.careerName,
    required this.matchPercentage,
    required this.matchingSkills,
    required this.missingSkills,
    this.salaryRange,
  });

  factory CareerMatch.fromJson(Map<String, dynamic> json) {
    return CareerMatch(
      careerId: json['career_id'] ?? json['careerId'],
      careerName: json['career_name'] ?? json['careerName'],
      matchPercentage:
          (json['match_percentage'] ?? json['matchPercentage'] as num)
              .toDouble(),
      // ✅ FIX: Properly cast List<dynamic> to List<String>
      matchingSkills:
          ((json['matching_skills'] ?? json['matchingSkills']) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      missingSkills:
          ((json['missing_skills'] ?? json['missingSkills']) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      salaryRange: json['salary_range'] ?? json['salaryRange'],
    );
  }
}
