import 'package:uuid/uuid.dart';

class ExerciseModel {
  final String id;
  final String category;
  final String? targetMuscle; // فقط برای تمرین‌های قدرتی
  final String name;
  final String coachUsername;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? countingType; // جدید: نوع شمارش (تعدادی، kg، یا زمان)
  final DateTime createdAt;

  // سازنده اصلی
  ExerciseModel({
    String? id,
    required this.category,
    this.targetMuscle,
    required this.name,
    required this.coachUsername,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.countingType,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // تبدیل از JSON به مدل
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] ?? const Uuid().v4(),
      category: json['category'] ?? 'بدون دسته‌بندی',
      targetMuscle: json['target_muscle'],
      name: json['name'] ?? 'بدون نام',
      coachUsername: json['coach_username'] ?? 'ناشناخته',
      description: json['description'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      countingType: json['counting_type'],
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  // تبدیل از مدل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'target_muscle': targetMuscle,
      'name': name,
      'coach_username': coachUsername,
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'counting_type': countingType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // امکان تغییر مقادیر خاص در مدل بدون تغییر کل داده‌ها
  ExerciseModel copyWith({
    String? id,
    String? category,
    String? targetMuscle,
    String? name,
    String? coachUsername,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? countingType,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      name: name ?? this.name,
      coachUsername: coachUsername ?? this.coachUsername,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      countingType: countingType ?? this.countingType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // متد نمایش اطلاعات مدل در لاگ‌ها
  @override
  String toString() {
    return 'ExerciseModel(id: $id, category: $category, targetMuscle: $targetMuscle, name: $name, coachUsername: $coachUsername, countingType: $countingType, createdAt: $createdAt)';
  }
}
