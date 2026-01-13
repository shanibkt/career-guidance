class Career {
  final int id;
  final String name;
  final String description;
  final List<String> requiredSkills;
  final double matchPercentage;

  Career({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredSkills,
    this.matchPercentage = 0.0,
  });

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      requiredSkills:
          (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      matchPercentage: (json['matchPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requiredSkills': requiredSkills,
      'matchPercentage': matchPercentage,
    };
  }

  /// Calculate match percentage based on user skills
  Career copyWithMatchPercentage(List<String> userSkills) {
    if (requiredSkills.isEmpty) {
      return Career(
        id: id,
        name: name,
        description: description,
        requiredSkills: requiredSkills,
        matchPercentage: 0.0,
      );
    }

    // Count matching skills (case-insensitive)
    int matchCount = 0;
    for (final requiredSkill in requiredSkills) {
      for (final userSkill in userSkills) {
        if (requiredSkill.toLowerCase().trim() ==
            userSkill.toLowerCase().trim()) {
          matchCount++;
          break;
        }
      }
    }

    final percentage = (matchCount / requiredSkills.length) * 100;

    return Career(
      id: id,
      name: name,
      description: description,
      requiredSkills: requiredSkills,
      matchPercentage: percentage,
    );
  }
}

class CareersResponse {
  final List<Career> careers;

  CareersResponse({required this.careers});

  factory CareersResponse.fromJson(Map<String, dynamic> json) {
    return CareersResponse(
      careers: (json['careers'] as List<dynamic>)
          .map((item) => Career.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
