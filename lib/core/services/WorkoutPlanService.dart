import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutPlanService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ایجاد برنامه جدید
  Future<void> createPlan(
    WorkoutPlanModel plan,
    String currentUserId, // شناسه کاربر فعلی (سازنده)
    String? assignedUserId, // شناسه کاربر گیرنده (اختیاری)
  ) async {
    try {
      if (!_isValidUUID(currentUserId)) {
        throw Exception('فرمت current_user_id نامعتبر است: $currentUserId');
      }
      if (assignedUserId != null && !_isValidUUID(assignedUserId)) {
        throw Exception('فرمت assigned_user_id نامعتبر است: $assignedUserId');
      }

      final planData =
          plan.toJson()
            ..['created_by'] = currentUserId
            ..['assigned_to'] = assignedUserId;

      await supabase.from('workout_plans').insert(planData);
    } catch (e) {
      throw Exception('خطا در ایجاد برنامه: $e');
    }
  }

  // دریافت تمام برنامه‌های یک کاربر
  Future<List<WorkoutPlanModel>> getPlans(String userId) async {
    try {
      if (!_isValidUUID(userId)) {
        throw Exception('فرمت user_id نامعتبر است: $userId');
      }

      final List response = await supabase
          .from('workout_plans')
          .select()
          .or('created_by.eq.$userId,assigned_to.eq.$userId')
          .order('created_at', ascending: true);

      return response.map((e) => WorkoutPlanModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت برنامه‌ها: $e');
    }
  }

  // به‌روزرسانی برنامه
  Future<void> updatePlan(
    WorkoutPlanModel plan,
    String currentUserId, // شناسه کاربر فعلی (برای تأیید دسترسی)
  ) async {
    try {
      if (!_isValidUUID(plan.id)) {
        throw Exception('فرمت plan_id نامعتبر است: ${plan.id}');
      }
      if (!_isValidUUID(currentUserId)) {
        throw Exception('فرمت current_user_id نامعتبر است: $currentUserId');
      }

      final planData =
          plan.toJson()..['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('workout_plans')
          .update(planData)
          .eq('id', plan.id)
          .eq(
            'created_by',
            currentUserId,
          ); // فقط سازنده می‌تونه به‌روزرسانی کنه
    } catch (e) {
      throw Exception('خطا در به‌روزرسانی برنامه: $e');
    }
  }

  // حذف برنامه
  Future<void> deletePlan(String planId, String currentUserId) async {
    try {
      if (!_isValidUUID(planId)) {
        throw Exception('فرمت plan_id نامعتبر است: $planId');
      }
      if (!_isValidUUID(currentUserId)) {
        throw Exception('فرمت current_user_id نامعتبر است: $currentUserId');
      }

      await supabase
          .from('workout_plans')
          .delete()
          .eq('id', planId)
          .eq('created_by', currentUserId); // فقط سازنده می‌تونه حذف کنه
    } catch (e) {
      throw Exception('خطا در حذف برنامه: $e');
    }
  }

  // دریافت جزئیات یک برنامه
  Future<WorkoutPlanModel> getPlanDetails(String planId) async {
    try {
      if (!_isValidUUID(planId)) {
        throw Exception('فرمت plan_id نامعتبر است: $planId');
      }

      final response =
          await supabase
              .from('workout_plans')
              .select()
              .eq('id', planId)
              .single();

      return WorkoutPlanModel.fromJson(response);
    } catch (e) {
      throw Exception('خطا در دریافت جزئیات برنامه: $e');
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
