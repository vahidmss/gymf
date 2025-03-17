import 'package:flutter/material.dart';
import 'package:gymf/core/services/CoachService.dart';
import 'package:gymf/data/models/CoachModel.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CoachProvider with ChangeNotifier {
  final CoachService _service = CoachService();
  List<CoachModel> _coaches = [];
  bool _isLoading = false;

  List<CoachModel> get coaches => _coaches;
  bool get isLoading => _isLoading;

  late AuthProvider authProvider;

  CoachProvider(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  Future<void> fetchCoaches() async {
    try {
      _isLoading = true;
      notifyListeners();
      _coaches = await _service.getCoaches();
    } catch (e) {
      print('❌ خطا در گرفتن مربی‌ها: $e');
      _coaches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCoachProfile(Map<String, dynamic> updates) async {
    final userId = authProvider.userId;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است!');
    }

    try {
      _isLoading = true;
      notifyListeners();
      await _service.updateCoachProfile(userId, updates);
      await fetchCoaches();
    } catch (e) {
      print('❌ خطا در آپدیت پروفایل: $e');
      throw Exception('خطا در آپدیت پروفایل: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendConsultationRequest(
    String coachId,
    String type,
    String? message,
  ) async {
    final userId = authProvider.userId;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است!');
    }

    try {
      _isLoading = true;
      notifyListeners();
      await _service.sendConsultationRequest(coachId, type, message);
    } catch (e) {
      print('❌ خطا در ارسال درخواست: $e');
      throw Exception('خطا در ارسال درخواست: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview(String coachId, int rating, String? comment) async {
    final userId = authProvider.userId;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است!');
    }

    try {
      _isLoading = true;
      notifyListeners();
      await _service.addReview(coachId, rating, comment);
      await fetchCoaches(); // برای به‌روزرسانی ریتینگ
    } catch (e) {
      print('❌ خطا در افزودن نظر: $e');
      throw Exception('خطا در افزودن نظر: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
