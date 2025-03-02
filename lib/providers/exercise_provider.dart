import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymf/core/services/exercise_service.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseProvider with ChangeNotifier {
  String? selectedCategory;
  String? selectedTargetMuscle;
  String? selectedCountingType;
  File? selectedImage;
  File? selectedVideo;
  bool isLoading = false;
  List<Map<String, dynamic>> _coachExercises = [];
  List<Map<String, dynamic>> get coachExercises => _coachExercises;

  final ExerciseService _exerciseService = ExerciseService();

  void setCategory(String category) {
    selectedCategory = category;
    selectedTargetMuscle = null;
    selectedCountingType = null;
    notifyListeners();
  }

  void setTargetMuscle(String muscle) {
    selectedTargetMuscle = muscle;
    notifyListeners();
  }

  void setCountingType(String? countingType) {
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
    selectedCountingType = null;
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
      debugPrint('❌ خطا در آپلود فایل: $e');
      return null;
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
        imageUrl: imageUrl ?? '',
        videoUrl: videoUrl ?? '',
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
    if (exerciseId.isEmpty) return;

    try {
      await _exerciseService.deleteExercise(exerciseId);
      _coachExercises.removeWhere((exercise) => exercise['id'] == exerciseId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطا در حذف تمرین: $e');
    }
  }

  Future<void> fetchCoachExercises(String coachUsername) async {
    if (coachUsername.isEmpty) return;

    try {
      final exercises = await _exerciseService.getExercises();
      if (exercises.isNotEmpty) {
        _coachExercises =
            exercises
                .where((exercise) => exercise.coachUsername == coachUsername)
                .map((e) => e.toJson())
                .toList()
                .cast<Map<String, dynamic>>();
      } else {
        _coachExercises = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطا در دریافت تمرینات: $e');
    }
  }

  Future<void> updateExercise(String id, Map<String, dynamic> updates) async {
    try {
      await _exerciseService.updateExercise(id, updates);
      final String coachUsername = updates['coach_username'] ?? '';
      if (coachUsername.isNotEmpty) {
        await fetchCoachExercises(coachUsername);
      }
    } catch (e) {
      debugPrint('❌ خطا در بروزرسانی تمرین: $e');
    }
  }
}
