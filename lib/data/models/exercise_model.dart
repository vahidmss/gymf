import 'package:uuid/uuid.dart';

class ExerciseModel {
  final String id;
  final String category;
  final String? targetMuscle; // فقط برای تمرین‌های قدرتی
  final String name;
  final String
  createdBy; // تغییر از coachUsername به createdBy (UUID به‌صورت String)
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? countingType; // نوع شمارش (تعدادی، kg، یا زمان)
  final DateTime createdAt;
  final DateTime? updatedAt; // اضافه کردن updatedAt برای هماهنگی با دیتابیس

  // سازنده اصلی
  ExerciseModel({
    String? id,
    required this.category,
    this.targetMuscle,
    required this.name,
    required this.createdBy, // تغییر از coachUsername به createdBy
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.countingType,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // سازنده خالی برای استفاده در شرایطی که نیاز به مدل خالی داریم
  factory ExerciseModel.empty() {
    return ExerciseModel(
      id: '',
      category: '',
      name: '',
      createdBy: '',
      description: null,
      imageUrl: null,
      videoUrl: null,
      countingType: null,
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  // تبدیل از JSON به مدل
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] ?? const Uuid().v4(),
      category: json['category'] ?? 'بدون دسته‌بندی',
      targetMuscle: json['target_muscle'],
      name: json['name'] ?? 'بدون نام',
      createdBy:
          json['created_by'] ?? '', // تغییر از coach_username به created_by
      description: json['description'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      countingType: json['counting_type'],
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'])
              : null,
    );
  }

  // تبدیل از مدل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'target_muscle': targetMuscle,
      'name': name,
      'created_by': createdBy, // تغییر از coach_username به created_by
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'counting_type': countingType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // امکان تغییر مقادیر خاص در مدل بدون تغییر کل داده‌ها
  ExerciseModel copyWith({
    String? id,
    String? category,
    String? targetMuscle,
    String? name,
    String? createdBy, // تغییر از coachUsername به createdBy
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? countingType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      name: name ?? this.name,
      createdBy:
          createdBy ?? this.createdBy, // تغییر از coachUsername به createdBy
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      countingType: countingType ?? this.countingType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // متد نمایش اطلاعات مدل در لاگ‌ها
  @override
  String toString() {
    return 'ExerciseModel(id: $id, category: $category, targetMuscle: $targetMuscle, name: $name, createdBy: $createdBy, countingType: $countingType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
