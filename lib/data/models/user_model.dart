class UserProfileModel {
  final String id;
  final String username;
  final String? email;
  final String? profileImageUrl;
  final String? bio;
  final bool isCoach;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> certifications; // برای مربی‌ها
  final List<String> achievements; // برای مربی‌ها
  final int? experienceYears; // برای مربی‌ها
  final int studentCount; // برای مربی‌ها
  final double rating; // برای مربی‌ها
  final String? avatarUrl; // اضافه کردن فیلد avatarUrl
  UserProfileModel({
    required this.id,
    required this.username,
    this.email,
    this.profileImageUrl,
    this.bio,
    required this.isCoach,
    required this.isAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.certifications = const [],
    this.achievements = const [],
    this.experienceYears,
    this.studentCount = 0,
    this.rating = 0.0,
    this.avatarUrl, // اضافه کردن به سازنده
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      username: json['username'] ?? 'نامشخص',
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
      bio: json['bio'],
      isCoach: json['is_coach'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      avatarUrl: json['avatar_url'] as String?, // خواندن از JSON
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      certifications: List<String>.from(json['certifications'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      experienceYears: json['experience_years'],
      studentCount: json['student_count'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'is_coach': isCoach,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'certifications': certifications,
      'achievements': achievements,
      'avatar_url': avatarUrl, // اضافه کردن به JSON
      'experience_years': experienceYears,
      'student_count': studentCount,
      'rating': rating,
    };
  }
}
