import 'package:uuid/uuid.dart';

class ExerciseModel {
  String id;
  String category;
  String? targetMuscle; // فقط برای قدرتی
  String name;
  String coachUsername;
  String? description;
  String? imageUrl;
  String? videoUrl;
  String? countingType; // جدید: نوع شمارش (تعدادی، kg، یا زمان)
  DateTime createdAt;

  ExerciseModel({
    String? id,
    required this.category,
    this.targetMuscle,
    required this.name,
    required this.coachUsername,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.countingType, // جدید
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
    id: json['id'],
    category: json['category'],
    targetMuscle: json['target_muscle'],
    name: json['name'],
    coachUsername: json['coach_username'],
    description: json['description'],
    imageUrl: json['image_url'],
    videoUrl: json['video_url'],
    countingType: json['counting_type'], // جدید
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'target_muscle': targetMuscle,
    'name': name,
    'coach_username': coachUsername,
    'description': description,
    'image_url': imageUrl,
    'video_url': videoUrl,
    'counting_type': countingType, // جدید
    'created_at': createdAt.toIso8601String(),
  };
}
