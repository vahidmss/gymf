import 'package:uuid/uuid.dart';

class LogSetModel {
  String id;
  String logId;
  int setNumber;
  int weight;
  int reps;
  DateTime createdAt;

  LogSetModel({
    String? id,
    required this.logId,
    required this.setNumber,
    this.weight = 0,
    this.reps = 0,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory LogSetModel.fromJson(Map<String, dynamic> json) => LogSetModel(
    id: json['id'],
    logId: json['log_id'],
    setNumber: json['set_number'],
    weight: json['weight'] ?? 0,
    reps: json['reps'] ?? 0,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'log_id': logId,
    'set_number': setNumber,
    'weight': weight,
    'reps': reps,
    'created_at': createdAt.toIso8601String(),
  };
}
