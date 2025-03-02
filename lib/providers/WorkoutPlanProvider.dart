import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gymf/core/services/WorkoutPlanService.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class WorkoutPlanProvider with ChangeNotifier {
  List<WorkoutPlanModel> _plans = [];
  List<WorkoutPlanModel> get plans => _plans;

  static const String _localPlansKey = 'athlete_workout_plans';

  final WorkoutPlanService _workoutPlanService = WorkoutPlanService();
  AuthProvider? _authProvider;

  WorkoutPlanProvider(BuildContext context) {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _loadLocalPlans();
  }

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    _loadLocalPlans(); // ری‌لود برنامه‌ها با کاربر جدید
    notifyListeners();
  }

  Future<void> _loadLocalPlans() async {
    if (_authProvider == null || _authProvider!.currentUser == null) return;

    if (_isAthlete()) {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_localPlansKey);
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedData);
          _plans = decoded.map((e) => WorkoutPlanModel.fromJson(e)).toList();
          notifyListeners();
        } catch (e) {
          debugPrint('❌ خطا در بارگذاری کش برنامه‌های ورزشی: $e');
        }
      }
    } else {
      await fetchPlans(_authProvider!.userId ?? '');
    }
  }

  Future<void> _saveLocalPlans() async {
    if (_isAthlete()) {
      final prefs = await SharedPreferences.getInstance();
      final newData = jsonEncode(_plans.map((e) => e.toJson()).toList());
      if (prefs.getString(_localPlansKey) != newData) {
        await prefs.setString(_localPlansKey, newData);
      }
    }
  }

  bool _isAthlete() {
    return _authProvider?.currentUser?.role == 'athlete';
  }

  Future<String?> getUserIdByUsername(String username) async {
    try {
      final response =
          await Supabase.instance.client
              .from('auth.users')
              .select('id')
              .eq('username', username)
              .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      debugPrint('❌ خطا در دریافت ID کاربر: $e');
      return null;
    }
  }

  Future<void> createPlan({
    required String userId,
    required String planName,
    required String day,
    String? assignedToUsername,
    required String username,
    required String role,
    required List<WorkoutExerciseModel> exercises,
  }) async {
    try {
      if (userId.isEmpty || planName.isEmpty) {
        throw Exception('❌ اطلاعات برنامه ورزشی ناقص است.');
      }

      String? assignedToId;
      if (assignedToUsername != null && assignedToUsername.isNotEmpty) {
        assignedToId = await getUserIdByUsername(assignedToUsername);
        if (assignedToId == null) {
          throw Exception('❌ یوزرنیم شاگرد پیدا نشد!');
        }
      }

      final plan = WorkoutPlanModel(
        userId: userId,
        planName: planName,
        username: username,
        role: role,
        assignedTo: assignedToId,
        day: day,
      );

      await _workoutPlanService.createPlan(plan, exercises);

      _plans.add(plan);
      notifyListeners();
      if (_isAthlete()) await _saveLocalPlans();
    } catch (e) {
      debugPrint('❌ خطا در ایجاد برنامه: $e');
    }
  }

  Future<void> fetchPlans(String userId) async {
    if (userId.isEmpty) return;

    if (!_isAthlete()) {
      try {
        final plans = await _workoutPlanService.getPlans(userId);
        _plans = plans;
        notifyListeners();
      } catch (e) {
        debugPrint('❌ خطا در دریافت برنامه‌ها: $e');
      }
    } else {
      _loadLocalPlans();
    }
  }

  Future<void> updatePlan(
    WorkoutPlanModel plan,
    List<WorkoutExerciseModel> exercises,
  ) async {
    try {
      await _workoutPlanService.updatePlan(plan, exercises);
      final planIndex = _plans.indexWhere((p) => p.id == plan.id);
      if (planIndex != -1) {
        _plans[planIndex] = plan;
        notifyListeners();
      }
      if (_isAthlete()) await _saveLocalPlans();
    } catch (e) {
      debugPrint('❌ خطا در به‌روزرسانی برنامه: $e');
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await _workoutPlanService.deletePlan(planId);
      _plans.removeWhere((plan) => plan.id == planId);
      notifyListeners();
      if (_isAthlete()) await _saveLocalPlans();
    } catch (e) {
      debugPrint('❌ خطا در حذف برنامه: $e');
    }
  }

  Future<List<WorkoutExerciseModel>> fetchPlanExercises(String planId) async {
    try {
      return await _workoutPlanService.getPlanExercises(planId);
    } catch (e) {
      debugPrint('❌ خطا در دریافت تمرینات برنامه: $e');
      return [];
    }
  }
}
