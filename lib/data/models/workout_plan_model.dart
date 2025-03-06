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
    required this.id,
    required this.createdBy,
    this.assignedTo,
    required this.planName,
    required this.days,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

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

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'],
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      planName: json['plan_name'],
      days:
          (json['days'] as List)
              .map((day) => WorkoutDay.fromJson(day as Map<String, dynamic>))
              .toList(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
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
}

class WorkoutDay {
  final String dayName;
  final List<WorkoutExercise> exercises;

  WorkoutDay({required this.dayName, required this.exercises});

  Map<String, dynamic> toJson() {
    return {
      'day_name': dayName,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dayName: json['day_name'],
      exercises:
          (json['exercises'] as List)
              .map(
                (exercise) =>
                    WorkoutExercise.fromJson(exercise as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String name;
  final int sets;
  final int? reps;
  final int? duration;
  final String countingType;
  final String? supersetGroupId;
  final String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.reps,
    this.duration,
    required this.countingType,
    this.supersetGroupId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'duration': duration,
      'counting_type': countingType,
      'superset_group_id': supersetGroupId,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exercise_id'],
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      duration: json['duration'],
      countingType: json['counting_type'],
      supersetGroupId: json['superset_group_id'],
      notes: json['notes'],
    );
  }

  // اضافه کردن متد copyWith
  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    int? sets,
    int? reps,
    int? duration,
    String? countingType,
    String? supersetGroupId,
    String? notes,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      countingType: countingType ?? this.countingType,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      notes: notes ?? this.notes,
    );
  }
}
