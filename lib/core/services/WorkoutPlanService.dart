import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutPlanService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> createPlan(
    WorkoutPlanModel plan,
    List<WorkoutExerciseModel> exercises,
  ) async {
    final planJson = plan.toJson();
    final planResponse =
        await supabase
            .from('workout_plans')
            .insert(planJson)
            .select('id')
            .single();
    final planId = planResponse['id'] as String;

    for (var exercise in exercises) {
      exercise.planId = planId;
      await supabase.from('workout_exercises').insert(exercise.toJson());
    }
  }

  Future<List<WorkoutPlanModel>> getPlans(String userId) async {
    final response = await supabase
        .from('workout_plans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map((e) => WorkoutPlanModel.fromJson(e)).toList();
  }

  Future<void> updatePlan(
    WorkoutPlanModel plan,
    List<WorkoutExerciseModel> exercises,
  ) async {
    await supabase
        .from('workout_plans')
        .update(plan.toJson())
        .eq('id', plan.id);
    await supabase.from('workout_exercises').delete().eq('plan_id', plan.id);
    for (var exercise in exercises) {
      exercise.planId = plan.id;
      await supabase.from('workout_exercises').insert(exercise.toJson());
    }
  }

  Future<void> deletePlan(String planId) async {
    await supabase.from('workout_exercises').delete().eq('plan_id', planId);
    await supabase.from('workout_plans').delete().eq('id', planId);
  }

  Future<List<WorkoutExerciseModel>> getPlanExercises(String planId) async {
    final response = await supabase
        .from('workout_exercises')
        .select()
        .eq('plan_id', planId);
    return response.map((e) => WorkoutExerciseModel.fromJson(e)).toList();
  }
}
