import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymf/core/services/exercise_service.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseProvider with ChangeNotifier {
  String? selectedCategory;
  String? selectedTargetMuscle;
  String? selectedCountingType; // نوع شمارش
  File? selectedImage;
  File? selectedVideo;
  bool isLoading = false;
  List<Map<String, dynamic>> _coachExercises = [];
  List<Map<String, dynamic>> get coachExercises => _coachExercises;

  final ExerciseService _exerciseService = ExerciseService();

  void setCategory(String category) {
    selectedCategory = category;
    selectedTargetMuscle = null;
    selectedCountingType = null; // ریست نوع شمارش وقتی دسته عوض می‌شه
    notifyListeners();
  }

  void setTargetMuscle(String muscle) {
    selectedTargetMuscle = muscle;
    notifyListeners();
  }

  void setCountingType(String? countingType) {
    // تغییر به nullable
    selectedCountingType = countingType;
    notifyListeners();
  }

  void setImage(File image) {
    selectedImage = image;
    notifyListeners();
  }

  void setVideo(File video) {
    selectedVideo = video;
    notifyListeners();
  }

  void resetForm() {
    selectedCategory = null;
    selectedTargetMuscle = null;
    selectedCountingType = null; // ریست نوع شمارش
    selectedImage = null;
    selectedVideo = null;
    notifyListeners();
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      await Supabase.instance.client.storage
          .from('exercise_media')
          .upload(path, file);
      return Supabase.instance.client.storage
          .from('exercise_media')
          .getPublicUrl(path);
    } catch (e) {
      throw Exception('خطا در آپلود فایل: $e');
    }
  }

  Future<void> submitExercise({
    required String name,
    required String category,
    String? targetMuscle,
    required String coachUsername,
    String? description,
    required VoidCallback onSuccess,
    required Function(String) onFailure,
  }) async {
    if (name.isEmpty ||
        category.isEmpty ||
        coachUsername.isEmpty ||
        selectedCountingType == null) {
      onFailure(
        'لطفاً همه فیلدهای ضروری (اسم، دسته‌بندی، و نوع شمارش) را پر کنید',
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      String? imageUrl;
      String? videoUrl;
      final exerciseId = DateTime.now().millisecondsSinceEpoch.toString();

      if (selectedImage != null) {
        imageUrl = await _uploadFile(
          selectedImage!,
          '$coachUsername/$exerciseId/image.jpg',
        );
      }

      if (selectedVideo != null) {
        videoUrl = await _uploadFile(
          selectedVideo!,
          '$coachUsername/$exerciseId/video.mp4',
        );
      }

      ExerciseModel exercise = ExerciseModel(
        category: category,
        targetMuscle: category == 'قدرتی' ? targetMuscle : null,
        name: name,
        coachUsername: coachUsername,
        description: description,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        countingType: selectedCountingType,
      );

      await _exerciseService.addExercise(exercise);

      onSuccess();
      resetForm();
      await fetchCoachExercises(coachUsername);
    } catch (e) {
      onFailure('خطا در ثبت تمرین: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteExercise(String exerciseId, String coachUsername) async {
    try {
      await _exerciseService.deleteExercise(exerciseId);
      _coachExercises.removeWhere((exercise) => exercise['id'] == exerciseId);
      notifyListeners();
    } catch (e) {
      throw Exception('خطا در حذف تمرین: $e');
    }
  }

  Future<void> fetchCoachExercises(String coachUsername) async {
    try {
      final exercises = await _exerciseService.getExercises();
      _coachExercises =
          exercises
              .where((exercise) => exercise.coachUsername == coachUsername)
              .map((e) => e.toJson())
              .toList()
              .cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      throw Exception('خطا در دریافت تمرینات: $e');
    }
  }

  // متد برای آپدیت تمرین (برای ادیت)
  Future<void> updateExercise(String id, Map<String, dynamic> updates) async {
    try {
      await _exerciseService.updateExercise(id, updates);
      await fetchCoachExercises(updates['coach_username'] ?? ''); // ریفرش لیست
    } catch (e) {
      throw Exception('خطا در بروزرسانی تمرین: $e');
    }
  }
}
