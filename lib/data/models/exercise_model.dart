import 'package:uuid/uuid.dart';

class ExerciseModel {
  final String id;
  final String category;
  final String? targetMuscle;
  final String name;
  final String createdBy;
  final String? creatorUsername; // اضافه کردن نام کاربر برای نمایش
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? countingType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExerciseModel({
    String? id,
    required this.category,
    this.targetMuscle,
    required this.name,
    required this.createdBy,
    this.creatorUsername, // جدید
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.countingType,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory ExerciseModel.empty() {
    return ExerciseModel(
      id: '',
      category: '',
      name: '',
      createdBy: '',
      creatorUsername: null,
      description: null,
      imageUrl: null,
      videoUrl: null,
      countingType: null,
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      category: json['category'] as String? ?? 'بدون دسته‌بندی',
      targetMuscle: json['target_muscle'] as String?,
      name: json['name'] as String? ?? 'بدون نام',
      createdBy: json['created_by'] as String? ?? '',
      creatorUsername: json['creator_username'] as String?, // جدید
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      countingType: json['counting_type'] as String?,
      createdAt:
          (json['created_at'] != null)
              ? DateTime.tryParse(json['created_at'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      updatedAt:
          (json['updated_at'] != null)
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'target_muscle': targetMuscle,
      'name': name,
      'created_by': createdBy,
      'creator_username': creatorUsername, // جدید
      'description': description,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'counting_type': countingType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExerciseModel copyWith({
    String? id,
    String? category,
    String? targetMuscle,
    String? name,
    String? createdBy,
    String? creatorUsername, // جدید
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
      createdBy: createdBy ?? this.createdBy,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      countingType: countingType ?? this.countingType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ExerciseModel(id: $id, category: $category, targetMuscle: $targetMuscle, name: $name, createdBy: $createdBy, creatorUsername: $creatorUsername, countingType: $countingType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
