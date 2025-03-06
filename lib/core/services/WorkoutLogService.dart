import 'package:gymf/data/models/workout_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutLogService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ذخیره لاگ‌های تمرین
  Future<void> saveWorkoutLogs(
    String planId,
    String day,
    List<Map<String, dynamic>> logs,
  ) async {
    try {
      if (!_isValidUUID(planId)) {
        throw Exception('فرمت plan_id نامعتبر است: $planId');
      }

      final batchLogs =
          logs.map((log) {
            if (!_isValidUUID(log['exerciseId'])) {
              throw Exception(
                'فرمت exercise_id نامعتبر است: ${log['exerciseId']}',
              );
            }
            return {
              'id': _uuid.v4(),
              'exercise_id': log['exerciseId'],
              'value': log['value'],
              'counting_type': log['countingType'],
              'plan_id': planId,
              'day': day,
              'notes': log['notes'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
          }).toList();

      await supabase.from('workout_logs').insert(batchLogs);
    } catch (e) {
      throw Exception('خطا در ذخیره لاگ‌ها: $e');
    }
  }

  // دریافت لاگ‌های تمرینات یک روز
  Future<List<WorkoutLog>> fetchWorkoutLogs(String planId, String day) async {
    try {
      if (!_isValidUUID(planId)) {
        throw Exception('فرمت plan_id نامعتبر است: $planId');
      }

      final List response = await supabase
          .from('workout_logs')
          .select()
          .eq('plan_id', planId)
          .eq('day', day)
          .order('created_at', ascending: true);

      return response.map((log) => WorkoutLog.fromJson(log)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت لاگ‌ها: $e');
    }
  }

  // دریافت لاگ‌های تمرین خاص
  Future<List<WorkoutLog>> fetchExerciseLogs(String exerciseId) async {
    try {
      if (!_isValidUUID(exerciseId)) {
        throw Exception('فرمت exercise_id نامعتبر است: $exerciseId');
      }

      final List response = await supabase
          .from('workout_logs')
          .select()
          .eq('exercise_id', exerciseId)
          .order('created_at', ascending: true);

      return response.map((log) => WorkoutLog.fromJson(log)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت لاگ‌های تمرین: $e');
    }
  }

  // به‌روزرسانی لاگ تمرین
  Future<void> updateWorkoutLog(
    String logId,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (!_isValidUUID(logId)) {
        throw Exception('فرمت log_id نامعتبر است: $logId');
      }

      await supabase
          .from('workout_logs')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', logId);
    } catch (e) {
      throw Exception('خطا در به‌روزرسانی لاگ: $e');
    }
  }

  // حذف لاگ تمرین
  Future<void> deleteWorkoutLog(String logId) async {
    try {
      if (!_isValidUUID(logId)) {
        throw Exception('فرمت log_id نامعتبر است: $logId');
      }

      await supabase.from('workout_logs').delete().eq('id', logId);
    } catch (e) {
      throw Exception('خطا در حذف لاگ: $e');
    }
  }

  // تابع کمکی برای بررسی UUID معتبر
  bool _isValidUUID(String? value) {
    return value != null &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(value);
  }
}
