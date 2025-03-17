import 'package:gymf/data/models/CoachModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CoachModel>> getCoaches() async {
    try {
      final response = await _supabase.from('coaches').select('''
        *,
        user_id!inner(username),
        student_count:coach_students!coach_id(count),
        like_count:coach_reviews!coach_id(count)
      ''');
      return (response as List).map((json) {
        json['student_count'] =
            json['student_count'] != null ? json['student_count']['count'] : 0;
        json['like_count'] =
            json['like_count'] != null ? json['like_count']['count'] : 0;
        return CoachModel.fromJson(json);
      }).toList();
    } catch (e) {
      print('❌ خطا در گرفتن مربی‌ها: $e');
      throw Exception('خطا در گرفتن مربی‌ها: $e');
    }
  }

  Future<void> updateCoachProfile(
    String coachId,
    Map<String, dynamic> updates,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است!');
    }

    try {
      await _supabase
          .from('coaches')
          .update(updates)
          .eq('id', coachId)
          .eq('user_id', userId);
    } catch (e) {
      print('❌ خطا در آپدیت پروفایل مربی: $e');
      throw Exception('خطا در آپدیت پروفایل مربی: $e');
    }
  }

  Future<void> sendConsultationRequest(
    String coachId,
    String type,
    String? message,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است!');
    }

    try {
      await _supabase.from('consultation_requests').insert({
        'coach_id': coachId,
        'student_id': userId,
        'type': type,
        'message': message,
      });
    } catch (e) {
      print('❌ خطا در ارسال درخواست: $e');
      throw Exception('خطا در ارسال درخواست: $e');
    }
  }

  Future<void> addReview(String coachId, int rating, String? comment) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است!');
    }

    try {
      await _supabase.from('coach_reviews').insert({
        'coach_id': coachId,
        'student_id': userId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      print('❌ خطا در افزودن نظر: $e');
      throw Exception('خطا در افزودن نظر: $e');
    }
  }
}
