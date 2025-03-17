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
    this.avatarUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '', // برای جلوگیری از null
      username: json['username'] as String? ?? 'نامشخص',
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      isCoach: json['is_coach'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
      certifications:
          (json['certifications'] as List<dynamic>?)?.cast<String>() ?? [],
      achievements:
          (json['achievements'] as List<dynamic>?)?.cast<String>() ?? [],
      experienceYears: json['experience_years'] as int?,
      studentCount: json['student_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: json['avatar_url'] as String?,
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
      'experience_years': experienceYears,
      'student_count': studentCount,
      'rating': rating,
      'avatar_url': avatarUrl,
    };
  }
}
