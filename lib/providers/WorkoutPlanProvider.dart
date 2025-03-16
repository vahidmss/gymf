import 'package:flutter/material.dart';
import 'package:gymf/core/services/WorkoutPlanService.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class WorkoutPlanProvider with ChangeNotifier {
  final WorkoutPlanService _service = WorkoutPlanService();
  List<WorkoutPlanModel> _plans = [];
  List<WorkoutPlanModel> _coachPlans = [];
  bool _isLoading = false;

  List<WorkoutPlanModel> get plans => _plans;
  List<WorkoutPlanModel> get coachPlans => _coachPlans;
  bool get isLoading => _isLoading;

  late AuthProvider authProvider;

  WorkoutPlanProvider(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  void updateAuth(AuthProvider? auth) {
    if (auth != null) {
      authProvider = auth;
      fetchCoachPlans(authProvider.userId ?? '');
    }
  }

  Future<void> fetchAllPlans() async {
    try {
      _isLoading = true;
      notifyListeners();
      _plans = await _service.getWorkoutPlans();
      print('✅ تعداد برنامه‌های گرفته‌شده: ${_plans.length}');
    } catch (e) {
      print('❌ خطا در گرفتن برنامه‌ها: $e');
      _plans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCoachPlans(String userId) async {
    if (userId.isEmpty) return;
    try {
      _isLoading = true;
      notifyListeners();
      _coachPlans = await _service.getCoachPlans(userId);
      print('✅ تعداد برنامه‌های مربی: ${_coachPlans.length}');
    } catch (e) {
      print('❌ خطا در گرفتن برنامه‌های مربی: $e');
      _coachPlans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlan(
    WorkoutPlanModel plan, {
    required VoidCallback onSuccess,
    required Function(String) onFailure,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.addWorkoutPlan(plan);
      await fetchCoachPlans(authProvider.userId ?? '');
      onSuccess();
    } catch (e) {
      onFailure('خطا در ذخیره برنامه: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlan(
    String id,
    Map<String, dynamic> updates, {
    required VoidCallback onSuccess,
    required Function(String) onFailure,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.updateWorkoutPlan(id, updates);
      await fetchCoachPlans(authProvider.userId ?? '');
      onSuccess();
    } catch (e) {
      onFailure('خطا در آپدیت برنامه: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(
    String id, {
    required VoidCallback onSuccess,
    required Function(String) onFailure,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final plan = _coachPlans.firstWhere(
        (p) => p.id == id,
        orElse:
            () =>
                WorkoutPlanModel(id: '', createdBy: '', planName: '', days: []),
      );
      if (plan.createdBy != authProvider.userId) {
        throw Exception('شما اجازه حذف این برنامه را ندارید');
      }
      await _service.deleteWorkoutPlan(id);
      _coachPlans.removeWhere((p) => p.id == id);
      onSuccess();
    } catch (e) {
      onFailure('خطا در حذف برنامه: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
