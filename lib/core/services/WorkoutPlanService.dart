import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymf/data/models/workout_plan_model.dart';

class WorkoutPlanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<WorkoutPlanModel>> getWorkoutPlans() async {
    try {
      final response = await _supabase
          .from('workout_plans')
          .select()
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => WorkoutPlanModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ خطا در گرفتن برنامه‌ها: $e');
      throw Exception('خطا در گرفتن برنامه‌ها: $e');
    }
  }

  Future<List<WorkoutPlanModel>> getCoachPlans(String userId) async {
    if (userId.isEmpty) {
      print('⚠️ userId نامعتبر است');
      return [];
    }
    try {
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => WorkoutPlanModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ خطا در گرفتن برنامه‌های مربی: $e');
      throw Exception('خطا در گرفتن برنامه‌های مربی: $e');
    }
  }

  Future<void> addWorkoutPlan(WorkoutPlanModel plan) async {
    try {
      await _supabase.from('workout_plans').insert(plan.toJson());
      print('✅ برنامه ذخیره شد: ${plan.planName}');
    } catch (e) {
      print('❌ خطا در ذخیره برنامه: $e');
      throw Exception('خطا در ذخیره برنامه: $e');
    }
  }

  Future<void> updateWorkoutPlan(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.from('workout_plans').update(updates).eq('id', id);
      print('✅ برنامه آپدیت شد: $id');
    } catch (e) {
      print('❌ خطا در آپدیت برنامه: $e');
      throw Exception('خطا در آپدیت برنامه: $e');
    }
  }

  Future<void> deleteWorkoutPlan(String id) async {
    try {
      await _supabase.from('workout_plans').delete().eq('id', id);
      print('✅ برنامه حذف شد: $id');
    } catch (e) {
      print('❌ خطا در حذف برنامه: $e');
      throw Exception('خطا در حذف برنامه: $e');
    }
  }
}
