class CoachModel {
  final String id;
  final String name;
  final List<String> certifications;
  final List<String> titles;
  final List<String> achievements;
  final String? bio;
  final double rating;
  final int? experienceYears;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int studentCount; // اضافه کردن تعداد شاگردان
  final int likeCount; // اضافه کردن تعداد لایک‌ها

  CoachModel({
    required this.id,
    required this.name,
    required this.certifications,
    required this.titles,
    required this.achievements,
    this.bio,
    required this.rating,
    this.experienceYears,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.studentCount,
    required this.likeCount,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      id: json['id'],
      name: json['user_id']['username'] ?? 'نامشخص',
      certifications: List<String>.from(json['certifications'] ?? []),
      titles: List<String>.from(json['titles'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      bio: json['bio'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      experienceYears: json['experience_years'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      studentCount: json['student_count'] ?? 0, // تعداد شاگردان
      likeCount: json['like_count'] ?? 0, // تعداد لایک‌ها
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'certifications': certifications,
      'titles': titles,
      'achievements': achievements,
      'bio': bio,
      'rating': rating,
      'experience_years': experienceYears,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'student_count': studentCount,
      'like_count': likeCount,
    };
  }
}
