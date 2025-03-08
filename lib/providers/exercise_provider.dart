import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymf/core/services/exercise_service.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ExerciseProvider with ChangeNotifier {
  String? _selectedCategory;
  String? _selectedTargetMuscle;
  String? _selectedCountingType;
  File? _selectedImage;
  File? _selectedVideo;
  bool _isLoading = false;
  List<ExerciseModel> _coachExercises = [];
  List<ExerciseModel> get coachExercises => _coachExercises;

  final ExerciseService _exerciseService = ExerciseService();
  final Uuid _uuid = const Uuid();
  late AuthProvider _authProvider;

  final bool _isSearching = false;
  List<ExerciseModel> _searchResults = [];
  final String _searchQuery = '';

  String? get selectedCategory => _selectedCategory;
  String? get selectedTargetMuscle => _selectedTargetMuscle;
  String? get selectedCountingType => _selectedCountingType;
  bool get isLoading => _isLoading;

  ExerciseProvider(BuildContext context) {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _selectedTargetMuscle = null;
      _selectedCountingType = null;
      notifyListeners();
    }
  }

  void setTargetMuscle(String muscle) {
    if (_selectedTargetMuscle != muscle) {
      _selectedTargetMuscle = muscle;
      notifyListeners();
    }
  }

  void setCountingType(String? countingType) {
    if (_selectedCountingType != countingType) {
      _selectedCountingType = countingType;
      notifyListeners();
    }
  }

  void setImage(File image) {
    if (_selectedImage != image) {
      _selectedImage = image;
      notifyListeners();
    }
  }

  void setVideo(File video) {
    if (_selectedVideo != video) {
      _selectedVideo = video;
      notifyListeners();
    }
  }

  void resetForm() {
    bool changed = false;
    if (_selectedCategory != null) {
      _selectedCategory = null;
      changed = true;
    }
    if (_selectedTargetMuscle != null) {
      _selectedTargetMuscle = null;
      changed = true;
    }
    if (_selectedCountingType != null) {
      _selectedCountingType = null;
      changed = true;
    }
    if (_selectedImage != null) {
      _selectedImage = null;
      changed = true;
    }
    if (_selectedVideo != null) {
      _selectedVideo = null;
      changed = true;
    }
    if (changed) notifyListeners();
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
    String? description,
    required VoidCallback onSuccess,
    required Function(String) onFailure,
  }) async {
    if (_authProvider.currentUser == null) {
      onFailure('کاربر وارد نشده است.');
      return;
    }

    if (name.isEmpty || category.isEmpty || _selectedCountingType == null) {
      onFailure(
        'لطفاً همه فیلدهای ضروری (اسم، دسته‌بندی، و نوع شمارش) را پر کنید',
      );
      return;
    }

    _isLoading = true;
    // notifyListeners(); // فقط توی پایان فراخوانی می‌کنیم

    try {
      final existingExercise = await _checkDuplicateExercise(
        name,
        category,
        targetMuscle,
      );
      if (existingExercise != null && existingExercise.id.isNotEmpty) {
        if (existingExercise.createdBy == _authProvider.userId) {
          onFailure('این تمرین قبلاً توسط شما ثبت شده. به صفحه ویرایش بروید.');
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          onFailure('این تمرین قبلاً توسط کاربر دیگری ثبت شده است.');
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      String? imageUrl;
      String? videoUrl;
      final exerciseId = _uuid.v4();

      if (_selectedImage != null) {
        imageUrl = await _uploadFile(
          _selectedImage!,
          '${_authProvider.currentUser!.username}/$exerciseId/image.jpg',
        );
      }

      if (_selectedVideo != null) {
        videoUrl = await _uploadFile(
          _selectedVideo!,
          '${_authProvider.currentUser!.username}/$exerciseId/video.mp4',
        );
      }

      ExerciseModel exercise = ExerciseModel(
        id: exerciseId,
        category: category,
        targetMuscle: category == 'قدرتی' ? targetMuscle : null,
        name: name,
        createdBy: _authProvider.userId ?? '',
        description: description,
        imageUrl: imageUrl ?? '',
        videoUrl: videoUrl ?? '',
        countingType: _selectedCountingType,
      );

      await _exerciseService.addExercise(exercise);

      onSuccess();
      resetForm();
      await fetchCoachExercises(_authProvider.userId ?? '');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      onFailure('خطا در ثبت تمرین: $e');
      notifyListeners();
    }
  }

  Future<ExerciseModel?> _checkDuplicateExercise(
    String name,
    String category,
    String? targetMuscle,
  ) async {
    try {
      final exercises = await _exerciseService.getExercises();
      return exercises.firstWhere(
        (exercise) =>
            exercise.name.toLowerCase() == name.toLowerCase() &&
            exercise.category == category &&
            (targetMuscle != null && category == 'قدرتی'
                ? exercise.targetMuscle == targetMuscle
                : true),
        orElse:
            () => ExerciseModel(
              id: '',
              name: '',
              category: '',
              createdBy: '',
              description: '',
              imageUrl: '',
              videoUrl: '',
              countingType: '',
            ),
      );
    } catch (e) {
      debugPrint('❌ خطا در چک کردن تمرین تکراری: $e');
      return null;
    }
  }

  Future<List<ExerciseModel>> fetchCoachExercises(String userId) async {
    print('🔄 بارگذاری تمرینات برای userId: $userId');
    if (!_isValidUUID(userId)) {
      print('⚠️ userId نامعتبر است: $userId');
      return [];
    }
    try {
      final exercises = await _exerciseService.getExercises().timeout(
        const Duration(seconds: 10),
      );
      _coachExercises =
          exercises.where((exercise) => exercise.createdBy == userId).toList();
      print('✅ تعداد تمرینات بارگذاری‌شده: ${_coachExercises.length}');
      notifyListeners();
      return _coachExercises;
    } catch (e) {
      debugPrint('❌ خطا در دریافت تمرینات: $e');
      return [];
    }
  }

  Future<List<ExerciseModel>> searchExercises({
    required String? category,
    String? targetMuscle,
    required String searchQuery,
    required String userId,
  }) async {
    print(
      '🔍 جستجو با پارامترها: category=$category, targetMuscle=$targetMuscle, searchQuery=$searchQuery, userId=$userId',
    );
    if (category == null || searchQuery.isEmpty) {
      print('⚠️ دسته‌بندی یا جستجو خالی است.');
      return [];
    }
    try {
      final exercises = await _exerciseService.getExercises().timeout(
        const Duration(seconds: 10),
      );
      print('📊 تعداد کل تمرینات دریافت‌شده: ${exercises.length}');
      _searchResults =
          exercises.where((exercise) {
            final matchesCategory = exercise.category == category;
            final matchesMuscle =
                targetMuscle != null && category == 'قدرتی'
                    ? exercise.targetMuscle == targetMuscle
                    : true;
            final matchesName = exercise.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            print(
              '📌 بررسی تمرین: ${exercise.name}, matchesCategory=$matchesCategory, matchesMuscle=$matchesMuscle, matchesName=$matchesName',
            );
            return matchesCategory && matchesMuscle && matchesName;
          }).toList();
      print('✅ تعداد نتایج جستجو: ${_searchResults.length}');
      return _searchResults;
    } catch (e) {
      debugPrint('❌ خطا در جستجوی تمرینات: $e');
      return [];
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    if (!_isValidUUID(exerciseId)) return;

    try {
      await _exerciseService.deleteExercise(exerciseId);
      _coachExercises.removeWhere((exercise) => exercise.id == exerciseId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطا در حذف تمرین: $e');
    }
  }

  Future<void> updateExercise(String id, Map<String, dynamic> updates) async {
    if (!_isValidUUID(id)) return;

    try {
      await _exerciseService.updateExercise(id, {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await fetchCoachExercises(_authProvider.userId ?? '');
    } catch (e) {
      debugPrint('❌ خطا در بروزرسانی تمرین: $e');
    }
  }

  bool _isValidUUID(String? value) {
    return value != null &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(value);
  }
}
