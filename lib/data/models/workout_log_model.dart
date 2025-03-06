// workout_log_model.dart
class WorkoutLog {
  final String id;
  final String exerciseId; // UUID تمرین (ارجاع به جدول exercises)
  final String value; // مقدار واردشده (مثلاً "50 کیلوگرم")
  final String countingType; // نوع شمارش (وزن، تعداد، یا تایم)
  final String planId; // UUID برنامه (ارجاع به جدول workout_plans)
  final String day; // نام روز (مثلاً "روز 1")
  final String? notes; // توضیحات و نکات (اختیاری)
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkoutLog({
    required this.id,
    required this.exerciseId,
    required this.value,
    required this.countingType,
    required this.planId,
    required this.day,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    // اعتبارسنجی فرمت UUID برای id، exerciseId، و planId
    if (json['id'] != null &&
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(json['id'])) {
      throw Exception('فرمت id نامعتبر است!');
    }
    if (json['exercise_id'] != null &&
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(json['exercise_id'])) {
      throw Exception('فرمت exercise_id نامعتبر است!');
    }
    if (json['plan_id'] != null &&
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(json['plan_id'])) {
      throw Exception('فرمت plan_id نامعتبر است!');
    }

    return WorkoutLog(
      id: json['id'],
      exerciseId: json['exercise_id'],
      value: json['value'],
      countingType: json['counting_type'],
      planId: json['plan_id'],
      day: json['day'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'value': value,
      'counting_type': countingType,
      'plan_id': planId,
      'day': day,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
