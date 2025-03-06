import 'package:gymf/data/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addExercise(ExerciseModel exercise) async {
    try {
      await supabase.from('exercises').insert({
        'id': exercise.id,
        'name': exercise.name,
        'category': exercise.category,
        'target_muscle': exercise.targetMuscle, // هماهنگ با مدل
        'created_by':
            exercise.createdBy, // تغییر از coach_username به created_by
        'description': exercise.description,
        'image_url': exercise.imageUrl,
        'video_url': exercise.videoUrl,
        'counting_type': exercise.countingType, // نوع شمارش
        'created_at': exercise.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(), // اضافه کردن updated_at
      });
    } catch (e, stacktrace) {
      print('🔴 خطا در ذخیره تمرین: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      throw Exception('خطا در ذخیره تمرین: $e');
    }
  }

  Future<List<ExerciseModel>> getExercises() async {
    try {
      final response = await supabase.from('exercises').select();
      return response.map((e) => ExerciseModel.fromJson(e)).toList();
    } catch (e, stacktrace) {
      print('🔴 خطا در دریافت تمرینات: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      return [];
    }
  }

  Future<bool> updateExercise(String id, Map<String, dynamic> updates) async {
    try {
      // اضافه کردن updated_at به آپدیت‌ها
      final updatedData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('exercises').update(updatedData).match({'id': id});
      return true;
    } catch (e, stacktrace) {
      print('🔴 خطا در بروزرسانی تمرین: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      return false;
    }
  }

  Future<bool> deleteExercise(String id) async {
    try {
      await supabase.from('exercises').delete().match({'id': id});
      return true;
    } catch (e, stacktrace) {
      print('🔴 خطا در حذف تمرین: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      return false;
    }
  }
}
