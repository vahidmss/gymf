class UserModel {
  final String userId;
  final String phone;
  final String username;
  final String role;
  final bool isVerified;
  final DateTime createdAt;
  final String password;

  UserModel({
    required this.userId,
    required this.phone,
    required this.username,
    required this.role,
    required this.isVerified,
    required this.createdAt,
    required this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['id'] as String,
      phone: map['phone'] as String,
      username: map['username'] as String,
      role: map['role'] as String,
      isVerified: map['is_verified'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'phone': phone,
      'username': username,
      'role': role,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'password': password,
    };
  }

  UserModel copyWith({
    String? userId,
    String? phone,
    String? username,
    String? role,
    bool? isVerified,
    DateTime? createdAt,
    String? password,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      password: password ?? this.password,
    );
  }
}
