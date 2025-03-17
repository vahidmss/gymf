import 'package:gymf/data/models/UserProfileModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfileModel> fetchUserProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('*, coaches!left(*, student_count:coach_students(count))')
              .eq('id', userId)
              .single();

      bool isCoach = response['coaches'] != null;

      // استفاده از متغیر موقت برای حل مشکل
      int studentCount;
      if (isCoach && response['coaches']['student_count'] != null) {
        studentCount = response['coaches']['student_count']['count'] ?? 0;
      } else {
        studentCount = 0;
      }

      return UserProfileModel.fromJson({
        'id': response['id'],
        'username': response['username'] ?? 'نامشخص',
        'email': response['email'],
        'profile_image_url': response['profile_image_url'],
        'bio': response['bio'],
        'is_coach': isCoach,
        'certifications':
            isCoach
                ? List<String>.from(response['coaches']['certifications'] ?? [])
                : [],
        'achievements':
            isCoach
                ? List<String>.from(response['coaches']['achievements'] ?? [])
                : [],
        'experience_years':
            isCoach ? response['coaches']['experience_years'] : null,
        'student_count': studentCount, // استفاده از متغیر موقت
        'rating':
            isCoach
                ? (response['coaches']['rating'] as num?)?.toDouble() ?? 0.0
                : 0.0,
      });
    } catch (e) {
      print('❌ خطا در گرفتن پروفایل: $e');
      throw Exception('خطا در گرفتن پروفایل: $e');
    }
  }

  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      print('❌ خطا در آپدیت پروفایل: $e');
      throw Exception('خطا در آپدیت پروفایل: $e');
    }
  }
}
