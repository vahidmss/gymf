class PendingCoachModel {
  final String id;
  final String? name;
  final String? bio;
  final List<String> certifications;
  final List<String> achievements;
  final int? experienceYears;
  final int studentCount;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  PendingCoachModel({
    required this.id,
    this.name,
    this.bio,
    this.certifications = const [],
    this.achievements = const [],
    this.experienceYears,
    this.studentCount = 0,
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingCoachModel.fromJson(Map<String, dynamic> json) {
    return PendingCoachModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      certifications:
          (json['certifications'] as List<dynamic>?)?.cast<String>() ?? [],
      achievements:
          (json['achievements'] as List<dynamic>?)?.cast<String>() ?? [],
      experienceYears: json['experience_years'] as int?,
      studentCount: json['student_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'certifications': certifications,
      'achievements': achievements,
      'experience_years': experienceYears,
      'student_count': studentCount,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
