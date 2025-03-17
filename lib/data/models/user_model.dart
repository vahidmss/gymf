class UserModel {
  final String userId;
  final String username;
  final String? email;
  final String? profileImageUrl;
  final String? bio;
  final bool isCoach; // جایگزین role
  final bool isAdmin; // جایگزین role
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.username,
    this.email,
    this.profileImageUrl,
    this.bio,
    required this.isCoach,
    required this.isAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['id'],
      username: map['username'] ?? 'نامشخص',
      email: map['email'],
      profileImageUrl: map['profile_image_url'],
      bio: map['bio'],
      isCoach: map['is_coach'] ?? false,
      isAdmin: map['is_admin'] ?? false,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'username': username,
      'email': email,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'is_coach': isCoach,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? username,
    String? email,
    String? profileImageUrl,
    String? bio,
    bool? isCoach,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      isCoach: isCoach ?? this.isCoach,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
