class CareerRecommendation {
  final int careerId;
  final String careerName;
  final double matchPercentage;
  final String reasoning;
  final List<String> strengths;
  final List<String> areasToDevelop;

  CareerRecommendation({
    required this.careerId,
    required this.careerName,
    required this.matchPercentage,
    required this.reasoning,
    required this.strengths,
    required this.areasToDevelop,
  });

  factory CareerRecommendation.fromJson(Map<String, dynamic> json) {
    return CareerRecommendation(
      careerId: json['careerId'],
      careerName: json['careerName'],
      matchPercentage: (json['matchPercentage'] as num).toDouble(),
      reasoning: json['reasoning'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      areasToDevelop: List<String>.from(json['areasToDevelop'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'careerId': careerId,
      'careerName': careerName,
      'matchPercentage': matchPercentage,
      'reasoning': reasoning,
      'strengths': strengths,
      'areasToDevelop': areasToDevelop,
    };
  }
}

class RecommendationsResponse {
  final List<CareerRecommendation> recommendations;

  RecommendationsResponse({required this.recommendations});

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationsResponse(
      recommendations: (json['recommendations'] as List)
          .map((r) => CareerRecommendation.fromJson(r))
          .toList(),
    );
  }
}
