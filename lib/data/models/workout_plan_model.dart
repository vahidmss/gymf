import 'package:uuid/uuid.dart';

class WorkoutPlanModel {
  String id;
  String userId;
  String? assignedTo; // برای شaگرد (اختیاری)
  String planName;
  String username; // یوزرنیم ثبت‌کننده
  String role; // نقش کاربر
  String day; // روز برنامه (اضافه کردن برای هماهنگی)
  DateTime createdAt;

  WorkoutPlanModel({
    String? id,
    required this.userId,
    this.assignedTo,
    required this.planName,
    required this.username,
    required this.role,
    required this.day, // اجباری کردن day
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory WorkoutPlanModel.fromJson(
    Map<String, dynamic> json,
  ) => WorkoutPlanModel(
    id: json['id'],
    userId: json['user_id'],
    assignedTo: json['assigned_to'],
    planName: json['plan_name'],
    username: json['username'],
    role: json['role'],
    day: json.containsKey('day') && json['day'] != null ? json['day'] : 'روز 1',
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'assigned_to': assignedTo,
    'plan_name': planName,
    'username': username,
    'role': role,
    'day': day, // اضافه کردن day به JSON
    'created_at': createdAt.toIso8601String(),
  };

  // آپدیت متد copyWith با اضافه کردن day
  WorkoutPlanModel copyWith({
    String? id,
    String? userId,
    String? assignedTo,
    String? planName,
    String? username,
    String? role,
    String? day, // اضافه کردن پارامتر day
    DateTime? createdAt,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      planName: planName ?? this.planName,
      username: username ?? this.username,
      role: role ?? this.role,
      day: day ?? this.day, // مقدار پیش‌فرض از خود مدل
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
