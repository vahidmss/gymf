import 'package:uuid/uuid.dart';

class WorkoutLogModel {
  String id;
  String userId;
  String exerciseId;
  String planId;
  DateTime date;
  String? notes;

  WorkoutLogModel({
    String? id,
    required this.userId,
    required this.exerciseId,
    required this.planId,
    DateTime? date,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) =>
      WorkoutLogModel(
        id: json['id'],
        userId: json['user_id'],
        exerciseId: json['exercise_id'],
        planId: json['plan_id'],
        date: DateTime.parse(json['date']),
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'exercise_id': exerciseId,
    'plan_id': planId,
    'date': date.toIso8601String(),
    'notes': notes,
  };
}
