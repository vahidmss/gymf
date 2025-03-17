import 'package:gymf/data/models/PendingCoachModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PendingCoachModel>> fetchPendingCoaches() async {
    try {
      final response = await _supabase
          .from('pending_coaches')
          .select('*, user_id!inner(username)')
          .eq('status', 'pending');
      return (response as List)
          .map((json) => PendingCoachModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ خطا در گرفتن مربی‌های در انتظار: $e');
      throw Exception('خطا در گرفتن مربی‌های در انتظار: $e');
    }
  }

  Future<void> approveCoach(String pendingId, String userId) async {
    try {
      // انتقال اطلاعات به جدول coaches
      final pendingCoach =
          await _supabase
              .from('pending_coaches')
              .select()
              .eq('id', pendingId)
              .single();

      await _supabase.from('coaches').insert({
        'user_id': userId,
        'certifications': pendingCoach['certifications'],
        'achievements': pendingCoach['achievements'],
        'experience_years': pendingCoach['experience_years'],
        'profile_image_url': '', // می‌تونی از پروفایل کاربر بگیری
      });

      // آپدیت وضعیت درخواست
      await _supabase
          .from('pending_coaches')
          .update({'status': 'approved'})
          .eq('id', pendingId);
    } catch (e) {
      print('❌ خطا در تأیید مربی: $e');
      throw Exception('خطا در تأیید مربی: $e');
    }
  }

  Future<void> rejectCoach(String pendingId) async {
    try {
      await _supabase
          .from('pending_coaches')
          .update({'status': 'rejected'})
          .eq('id', pendingId);
    } catch (e) {
      print('❌ خطا در رد مربی: $e');
      throw Exception('خطا در رد مربی: $e');
    }
  }
}
