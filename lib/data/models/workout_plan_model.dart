import 'package:uuid/uuid.dart';

// workout_plan_model.dart
class WorkoutPlanModel {
  final String id;
  final String createdBy;
  final String? assignedTo;
  final String planName;
  final List<WorkoutDay> days;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkoutPlanModel({
    String? id,
    required this.createdBy,
    this.assignedTo,
    required this.planName,
    required this.days,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    // اعتبارسنجی فیلدهای اجباری
    if (json['id'] == null || json['id'] is! String) {
      throw ArgumentError('id نمی‌تواند خالی باشد');
    }
    if (json['plan_name'] == null || json['plan_name'] is! String) {
      throw ArgumentError('plan_name نمی‌تواند خالی باشد');
    }
    if (json['created_by'] == null || json['created_by'] is! String) {
      throw ArgumentError('created_by نمی‌تواند خالی باشد');
    }

    return WorkoutPlanModel(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      planName: json['plan_name'] as String,
      days:
          (json['days'] as List<dynamic>)
              .map((day) => WorkoutDay.fromJson(day as Map<String, dynamic>))
              .toList(),
      notes: json['notes'] as String?,
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
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'plan_name': planName,
      'days': days.map((day) => day.toJson()).toList(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  WorkoutPlanModel copyWith({
    String? id,
    String? createdBy,
    String? assignedTo,
    String? planName,
    List<WorkoutDay>? days,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      planName: planName ?? this.planName,
      days: days ?? this.days,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WorkoutPlanModel(id: $id, createdBy: $createdBy, assignedTo: $assignedTo, planName: $planName, days: $days, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class WorkoutDay {
  final String dayName;
  final List<WorkoutExercise> exercises;

  WorkoutDay({required this.dayName, required this.exercises});

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dayName: json['day_name'] as String? ?? '',
      exercises:
          (json['exercises'] as List<dynamic>)
              .map(
                (exercise) =>
                    WorkoutExercise.fromJson(exercise as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_name': dayName,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'WorkoutDay(dayName: $dayName, exercises: $exercises)';
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String name;
  final String category; // اضافه کردن
  final int sets;
  final int? reps;
  final int? duration;
  final double? weight; // برای پشتیبانی از وزن (kg)
  final String countingType; // "وزن (kg)"، "تایم"، "تعداد"
  final String? supersetGroupId;
  final String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.category, // اجباری
    required this.sets,
    this.reps,
    this.duration,
    this.weight,
    required this.countingType,
    this.supersetGroupId,
    this.notes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exercise_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '', // پیش‌فرض خالی
      sets: json['sets'] as int? ?? 0,
      reps: json['reps'] as int?,
      duration: json['duration'] as int?,
      weight: json['weight'] as double?, // جدید
      countingType: json['counting_type'] as String? ?? '',
      supersetGroupId: json['superset_group_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'name': name,
      'category': category, // اضافه کردن به JSON
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'weight': weight, // جدید
      'counting_type': countingType,
      'superset_group_id': supersetGroupId,
      'notes': notes,
    };
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    String? category,
    int? sets,
    int? reps,
    int? duration,
    double? weight,
    String? countingType,
    String? supersetGroupId,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      weight: weight ?? this.weight,
      countingType: countingType ?? this.countingType,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'WorkoutExercise(exerciseId: $exerciseId, name: $name, category: $category, sets: $sets, reps: $reps, duration: $duration, weight: $weight, countingType: $countingType, supersetGroupId: $supersetGroupId, notes: $notes)';
  }
}
