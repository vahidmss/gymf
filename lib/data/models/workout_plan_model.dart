import 'package:uuid/uuid.dart';

class WorkoutPlanModel {
  final String id;
  final String userId;
  final String? assignedTo; // اگر مربی برنامه را برای شاگرد تنظیم کند
  final String planName;
  final String username; // نام کاربری ثبت‌کننده
  final String role; // نقش کاربر (مربی یا شاگرد)
  final String day; // روز برنامه (مثلاً "روز 1")
  final DateTime createdAt;

  // سازنده اصلی مدل
  WorkoutPlanModel({
    String? id,
    required this.userId,
    this.assignedTo,
    required this.planName,
    required this.username,
    required this.role,
    required this.day,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(), // مقداردهی id اگر مقدار داده نشود
       createdAt =
           createdAt ?? DateTime.now(); // مقداردهی پیش‌فرض به تاریخ ایجاد

  // متد تبدیل از JSON به مدل
  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'] ?? const Uuid().v4(),
      userId: json['user_id'] ?? '',
      assignedTo: json['assigned_to'],
      planName: json['plan_name'] ?? 'بدون نام',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      day: json['day'] ?? 'روز 1',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  // متد تبدیل از مدل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assigned_to': assignedTo,
      'plan_name': planName,
      'username': username,
      'role': role,
      'day': day,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // متد برای کپی کردن مدل با تغییرات خاص (immutable)
  WorkoutPlanModel copyWith({
    String? id,
    String? userId,
    String? assignedTo,
    String? planName,
    String? username,
    String? role,
    String? day,
    DateTime? createdAt,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      planName: planName ?? this.planName,
      username: username ?? this.username,
      role: role ?? this.role,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // متد برای نمایش اطلاعات مدل در لاگ‌ها
  @override
  String toString() {
    return 'WorkoutPlanModel(id: $id, userId: $userId, assignedTo: $assignedTo, planName: $planName, username: $username, role: $role, day: $day, createdAt: $createdAt)';
  }
}
