class Career {
  final int id;
  final String name;
  final String description;
  final List<String> requiredSkills;

  Career({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredSkills,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requiredSkills': requiredSkills,
    };
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
