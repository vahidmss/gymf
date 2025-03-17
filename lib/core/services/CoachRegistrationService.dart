import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class CoachRegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitCoachApplication({
    required String userId,
    required List<String> certifications,
    required List<String> achievements,
    required int experienceYears,
    required String identityDocumentPath,
    required String certificatesPath,
  }) async {
    try {
      // آپلود مدارک هویتی
      final identityUrl = await _uploadFile(
        userId,
        'identity',
        identityDocumentPath,
      );
      // آپلود مدارک مربی‌گری
      final certificatesUrl = await _uploadFile(
        userId,
        'certificates',
        certificatesPath,
      );

      await _supabase.from('pending_coaches').insert({
        'user_id': userId,
        'certifications': certifications,
        'achievements': achievements,
        'experience_years': experienceYears,
        'identity_document_url': identityUrl,
        'certificates_url': certificatesUrl,
      });
    } catch (e) {
      print('❌ خطا در ثبت درخواست مربی: $e');
      throw Exception('خطا در ثبت درخواست مربی: $e');
    }
  }

  Future<String> _uploadFile(
    String userId,
    String type,
    String filePath,
  ) async {
    final file = File(filePath);
    final fileName =
        '${userId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final response = await _supabase.storage
        .from('coach-documents')
        .upload('documents/$fileName', file);
    return _supabase.storage
        .from('coach-documents')
        .getPublicUrl('documents/$fileName');
  }
}
