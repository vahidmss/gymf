import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gymf/core/services/WorkoutPlanService.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // اضافه کردن ایمپورت برای Uuid

class WorkoutPlanProvider with ChangeNotifier {
  List<WorkoutPlanModel> _plans = [];
  List<WorkoutPlanModel> get plans => _plans;

  // اضافه کردن متغیر برای مدیریت سوپرست‌ها
  final Map<String, String> _supersetGroups = {}; // گروه‌های سوپرست
  Map<String, String> get supersetGroups => _supersetGroups;

  static const String _localPlansKey = 'athlete_workout_plans';

  final WorkoutPlanService _workoutPlanService = WorkoutPlanService();
  final Uuid _uuid = const Uuid(); // تعریف نمونه Uuid برای تولید شناسه‌ها
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
          _plans =
              decoded
                  .map(
                    (e) => WorkoutPlanModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList();
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
              .from('users')
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
    required List<WorkoutDay> days, // تغییر از day به List<WorkoutDay>
    String? assignedToUsername,
    required String username,
    required String role,
  }) async {
    try {
      if (userId.isEmpty || planName.isEmpty || days.isEmpty) {
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
        id: _uuid.v4(), // تولید شناسه جدید با نمونه Uuid
        createdBy: userId,
        assignedTo: assignedToId,
        planName: planName,
        days: days,
        notes: null, // می‌تونی بعداً اضافه کنی
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      // جمع‌آوری سوپرست‌ها از تمرین‌ها
      for (var day in days) {
        for (var exercise in day.exercises) {
          if (exercise.supersetGroupId != null &&
              !_supersetGroups.containsKey(exercise.supersetGroupId)) {
            _supersetGroups[exercise.supersetGroupId!] = 'سوپرست';
          }
        }
      }

      // دیباگ برای چک کردن برنامه قبل از ذخیره
      print('برنامه برای ذخیره در Supabase: ${plan.toJson()}');
      print('گروه‌های سوپرست: $_supersetGroups');

      // ذخیره برنامه
      await _workoutPlanService.createPlan(plan, userId, assignedToId);

      _plans.add(plan);
      notifyListeners();
      if (_isAthlete()) await _saveLocalPlans();
    } catch (e) {
      debugPrint('❌ خطا در ایجاد برنامه: $e');
      rethrow;
    }
  }

  Future<void> fetchPlans(String userId) async {
    if (userId.isEmpty) return;

    if (!_isAthlete()) {
      try {
        final plans = await _workoutPlanService.getPlans(userId);
        _plans = plans;
        // بازگرداندن سوپرست‌ها از تمرین‌ها
        _supersetGroups.clear();
        for (var plan in _plans) {
          for (var day in plan.days) {
            for (var exercise in day.exercises) {
              if (exercise.supersetGroupId != null &&
                  !_supersetGroups.containsKey(exercise.supersetGroupId)) {
                _supersetGroups[exercise.supersetGroupId!] = 'سوپرست';
              }
            }
          }
        }
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
    List<WorkoutDay> days, // تغییر از exercises به days
  ) async {
    try {
      if (!_isValidUUID(plan.id)) {
        throw Exception('فرمت plan_id نامعتبر است: ${plan.id}');
      }

      final updatedPlan = plan.copyWith(days: days, updatedAt: DateTime.now());

      await _workoutPlanService.updatePlan(updatedPlan, plan.createdBy);
      final planIndex = _plans.indexWhere((p) => p.id == plan.id);
      if (planIndex != -1) {
        _plans[planIndex] = updatedPlan;
      }
      // به‌روزرسانی سوپرست‌ها
      _supersetGroups.clear();
      for (var day in days) {
        for (var exercise in day.exercises) {
          if (exercise.supersetGroupId != null &&
              !_supersetGroups.containsKey(exercise.supersetGroupId)) {
            _supersetGroups[exercise.supersetGroupId!] = 'سوپرست';
          }
        }
      }
      notifyListeners();
      if (_isAthlete()) await _saveLocalPlans();
    } catch (e) {
      debugPrint('❌ خطا در به‌روزرسانی برنامه: $e');
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      if (!_isValidUUID(planId)) {
        throw Exception('فرمت plan_id نامعتبر است: $planId');
      }

      final userId = _authProvider?.userId ?? '';
      if (userId.isEmpty) {
        throw Exception('کاربر مقداردهی نشده است.');
      }

      await _workoutPlanService.deletePlan(planId, userId);
      _plans.removeWhere((plan) => plan.id == planId);
      notifyListeners();
      if (_isAthlete()) await _saveLocalPlans();
    } catch (e) {
      debugPrint('❌ خطا در حذف برنامه: $e');
    }
  }

  Future<List<WorkoutExercise>> fetchPlanExercises(String planId) async {
    try {
      if (!_isValidUUID(planId)) {
        throw Exception('فرمت plan_id نامعتبر است: $planId');
      }

      final plan = await _workoutPlanService.getPlanDetails(planId);
      // جمع‌آوری تمام تمرین‌ها از تمام روزها
      final allExercises = plan.days.expand((day) => day.exercises).toList();
      print('تمرین‌های دریافت‌شده برای planId $planId: $allExercises');
      return allExercises;
    } catch (e) {
      debugPrint('❌ خطا در دریافت تمرینات برنامه: $e');
      return [];
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
