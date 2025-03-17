import 'package:gymf/data/models/PendingCoachModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachRegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PendingCoachModel>> getPendingCoachRequests() async {
    try {
      print('🔄 دریافت لیست درخواست‌های مربی شدن...');
      final response = await _supabase
          .from('pending_coaches')
          .select()
          .timeout(const Duration(seconds: 10));

      if (response.isEmpty) {
        print('⚠️ هیچ درخواستی یافت نشد.');
        return [];
      }

      final requests =
          (response as List<dynamic>)
              .map((json) => PendingCoachModel.fromJson(json))
              .toList();
      print('✅ ${requests.length} درخواست یافت شد.');
      return requests;
    } catch (e) {
      print('❌ خطا در دریافت درخواست‌ها: $e');
      throw Exception('خطا در دریافت درخواست‌ها: $e');
    }
  }

  Future<void> approveCoach(String userId) async {
    try {
      print('🔄 تأیید مربی با ID: $userId');
      await _supabase
          .from('profiles')
          .update({'is_coach': true})
          .eq('id', userId)
          .timeout(const Duration(seconds: 10));

      await _supabase
          .from('pending_coaches')
          .delete()
          .eq('id', userId)
          .timeout(const Duration(seconds: 10));

      print('✅ مربی با موفقیت تأیید شد.');
    } catch (e) {
      print('❌ خطا در تأیید مربی: $e');
      throw Exception('خطا در تأیید مربی: $e');
    }
  }

  Future<void> rejectCoach(String userId) async {
    try {
      print('🔄 رد درخواست مربی با ID: $userId');
      await _supabase
          .from('pending_coaches')
          .delete()
          .eq('id', userId)
          .timeout(const Duration(seconds: 10));

      print('✅ درخواست با موفقیت رد شد.');
    } catch (e) {
      print('❌ خطا در رد درخواست: $e');
      throw Exception('خطا در رد درخواست: $e');
    }
  }

  Future<void> submitCoachRequest(PendingCoachModel request) async {
    try {
      print('🔄 ثبت درخواست مربی شدن برای ID: ${request.id}');
      await _supabase
          .from('pending_coaches')
          .upsert(request.toJson())
          .timeout(const Duration(seconds: 10));
      print('✅ درخواست با موفقیت ثبت شد.');
    } catch (e) {
      print('❌ خطا در ثبت درخواست: $e');
      throw Exception('خطا در ثبت درخواست: $e');
    }
  }
}
