import 'package:gymf/data/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addExercise(ExerciseModel exercise) async {
    await supabase.from('exercises').insert({
      'id': exercise.id,
      'name': exercise.name,
      'category': exercise.category,
      'target_muscle':
          exercise
              .targetMuscle, // تغییر از 'type' به 'target_muscle' (هماهنگ با مدل)
      'coach_username': exercise.coachUsername,
      'description': exercise.description,
      'image_url': exercise.imageUrl,
      'video_url': exercise.videoUrl,
      'counting_type': exercise.countingType, // جدید: نوع شمارش
      'created_at': exercise.createdAt.toIso8601String(),
    });
  }

  Future<List<ExerciseModel>> getExercises() async {
    try {
      final response = await supabase.from('exercises').select();
      return response
          .map((e) => ExerciseModel.fromJson(e))
          .toList(); // تغییر از fromMap به fromJson
    } catch (e, stacktrace) {
      print('🔴 خطا در دریافت تمرینات: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      return [];
    }
  }

  Future<bool> updateExercise(String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from('exercises').update(updates).match({'id': id});
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
