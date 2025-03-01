import 'package:uuid/uuid.dart';

class WorkoutExerciseModel {
  String id;
  String planId;
  String exerciseId;
  int sets;
  int? reps;
  int? duration;
  String countingType; // نوع شمارش (از تمرین اصلی)
  String? notes; // توضیحات اختیاری
  DateTime createdAt;

  WorkoutExerciseModel({
    String? id,
    required this.planId,
    required this.exerciseId,
    required this.sets,
    this.reps,
    this.duration,
    required this.countingType, // اجباری
    this.notes,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) =>
      WorkoutExerciseModel(
        id: json['id'],
        planId: json['plan_id'],
        exerciseId: json['exercise_id'],
        sets: json['sets'],
        reps: json['reps'],
        duration: json['duration'],
        countingType: json['counting_type'], // جدید
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'plan_id': planId,
    'exercise_id': exerciseId,
    'sets': sets,
    'reps': reps,
    'duration': duration,
    'counting_type': countingType, // جدید
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  // اضافه کردن متد copyWith
  WorkoutExerciseModel copyWith({
    String? id,
    String? planId,
    String? exerciseId,
    int? sets,
    int? reps,
    int? duration,
    String? countingType,
    String? notes,
    DateTime? createdAt,
  }) {
    return WorkoutExerciseModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      countingType: countingType ?? this.countingType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
