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
  File? selectedImage;
  File? selectedVideo;
  bool _shouldNotify = true; // پرچم برای کنترل notifyListeners
  bool _isLoading = false;
  List<ExerciseModel> _coachExercises = [];
  List<ExerciseModel> get coachExercises => _coachExercises;

  final ExerciseService _exerciseService = ExerciseService();
  final Uuid _uuid = const Uuid();
  final ValueNotifier<double> uploadProgress = ValueNotifier<double>(
    0.0,
  ); // برای پیشرفت
  late AuthProvider authProvider;
  List<ExerciseModel> _exercises = [];
  List<ExerciseModel> get exercises => _exercises;

  List<ExerciseModel> _searchResults = [];

  String? get selectedCategory => _selectedCategory;
  String? get selectedTargetMuscle => _selectedTargetMuscle;
  String? get selectedCountingType => _selectedCountingType;
  bool get isLoading => _isLoading;

  ExerciseProvider(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  Future<void> fetchAllExercises() async {
    try {
      print('🔄 گرفتن همه تمرین‌ها...');
      final response = await Supabase.instance.client
          .from('exercises')
          .select('''
            *,
            profiles:created_by (username)
          ''')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      _exercises =
          data.map((json) {
            final username =
                json['profiles'] != null
                    ? json['profiles']['username'] as String? ?? 'ناشناس'
                    : 'ناشناس';
            return ExerciseModel.fromJson(
              json,
            ).copyWith(creatorUsername: username);
          }).toList();

      print('✅ تعداد تمرین‌های گرفته‌شده: ${_exercises.length}');
      notifyListeners();
    } catch (e, stacktrace) {
      print('❌ خطا در گرفتن همه تمرین‌ها: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      _exercises = []; // پیش‌فرض خالی برای جلوگیری از کرش
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> getUserName(String userId) async {
    if (!_isValidUUID(userId)) {
      print('⚠️ userId نامعتبر است: $userId');
      return null;
    }
    try {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('username')
              .eq('id', userId)
              .maybeSingle();

      if (response == null) {
        print('❌ کاربر با ID $userId پیدا نشد');
        return null;
      }

      final username = response['username'] as String?;
      print('✅ نام کاربر برای $userId: $username');
      return username;
    } catch (e) {
      print('❌ خطا در گرفتن نام کاربر: $e');
      return null;
    }
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
    if (countingType != null &&
        !['وزن (kg)', 'تایم', 'تعداد'].contains(countingType)) {
      print('⚠️ نوع شمارش نامعتبر: $countingType');
      return;
    }
    if (_selectedCountingType != countingType) {
      _selectedCountingType = countingType;
      notifyListeners();
    }
  }

  void setImage(File image) {
    if (selectedImage != image) {
      selectedImage = image;
      if (_shouldNotify) notifyListeners();
      print('📸 تصویر جدید انتخاب شد: ${image.path}');
    }
  }

  void setVideo(File video) {
    if (selectedVideo != video) {
      selectedVideo = video;
      if (_shouldNotify) notifyListeners();
      print('🎥 ویدیو جدید انتخاب شد: ${video.path}');
    }
  }

  void clearImage() {
    if (selectedImage != null) {
      selectedImage = null;
      if (_shouldNotify) notifyListeners();
      print('🗑️ تصویر حذف شد');
    }
  }

  void clearVideo() {
    if (selectedVideo != null) {
      selectedVideo = null;
      if (_shouldNotify) notifyListeners();
      print('🗑️ ویدیو حذف شد');
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
    if (selectedImage != null) {
      selectedImage = null;
      changed = true;
    }
    if (selectedVideo != null) {
      selectedVideo = null;
      changed = true;
    }
    if (changed && _shouldNotify) notifyListeners();
  }

  Future<String> uploadFile(File file, String path) async {
    try {
      if (!await file.exists()) {
        throw Exception('فایل وجود ندارد: ${file.path}');
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('کاربر وارد نشده است');
      }
      print('👤 کاربر فعلی: ${user.id}');
      print('⬆️ شروع آپلود فایل: $path');
      print('📂 مسیر فایل محلی: ${file.path}');
      await Supabase.instance.client.storage
          .from('exercise-media')
          .upload(
            path,
            file,
            fileOptions: FileOptions(
              contentType:
                  file.path.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg',
            ),
          );
      final url = Supabase.instance.client.storage
          .from('exercise-media')
          .getPublicUrl(path);
      final uri = Uri.tryParse(url);
      if (uri == null ||
          (!uri.scheme.contains('http') && !uri.scheme.contains('https'))) {
        throw Exception('URL عمومی نامعتبر است: $url');
      }
      print('✅ URL عمومی تولید شد: $url');
      return url;
    } catch (e, stacktrace) {
      print('❌ خطا در آپلود فایل: $e');
      print('🔍 جزئیات بیشتر: $stacktrace');
      throw Exception('خطا در آپلود فایل: $e');
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
    if (authProvider.currentUser == null) {
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
    _shouldNotify = false; // موقع آپلود آپدیت نکن
    notifyListeners();

    try {
      final existingExercise = await _checkDuplicateExercise(
        name,
        category,
        targetMuscle,
      );
      if (existingExercise != null && existingExercise.id.isNotEmpty) {
        if (existingExercise.createdBy == authProvider.userId) {
          onFailure('این تمرین قبلاً توسط شما ثبت شده. به صفحه ویرایش بروید.');
          return;
        } else {
          onFailure('این تمرین قبلاً توسط کاربر دیگری ثبت شده است.');
          return;
        }
      }

      String? imageUrl;
      String? videoUrl;
      final exerciseId = _uuid.v4();

      print(
        '📸 وضعیت تصویر: ${selectedImage != null ? "انتخاب شده (${selectedImage!.path})" : "خالی"}',
      );
      print(
        '🎥 وضعیت ویدیو: ${selectedVideo != null ? "انتخاب شده (${selectedVideo!.path})" : "خالی"}',
      );

      // شروع پروگرس بار
      uploadProgress.value = 0.0;

      if (selectedImage != null) {
        uploadProgress.value = 25.0; // 25% برای آپلود تصویر
        imageUrl = await uploadFile(
          selectedImage!,
          '${authProvider.currentUser!.username}/$exerciseId/image.jpg',
        );
        print('🌄 URL تصویر: $imageUrl');
      }

      if (selectedVideo != null) {
        uploadProgress.value =
            selectedImage != null ? 50.0 : 25.0; // 25% یا 50% برای آپلود ویدیو
        videoUrl = await uploadFile(
          selectedVideo!,
          '${authProvider.currentUser!.username}/$exerciseId/video.mp4',
        );
        print('🎬 URL ویدیو: $videoUrl');
      }

      // اتمام آپلود و ذخیره
      uploadProgress.value = 75.0; // 75% برای پردازش
      ExerciseModel exercise = ExerciseModel(
        id: exerciseId,
        category: category,
        targetMuscle: category == 'قدرتی' ? targetMuscle : null,
        name: name,
        createdBy: authProvider.userId ?? '',
        creatorUsername: authProvider.currentUser?.username ?? 'ناشناس',
        description: description,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        countingType: _selectedCountingType!,
      );

      print('💾 مدل تمرین قبل از ذخیره: ${exercise.toJson()}');
      await _exerciseService.addExercise(exercise);
      uploadProgress.value = 100.0; // 100% بعد از ذخیره

      onSuccess();
      resetForm();
      await fetchCoachExercises(authProvider.userId ?? '');
    } catch (e) {
      onFailure('خطا در ثبت تمرین: $e');
    } finally {
      _isLoading = false;
      _shouldNotify = true; // بعد ثبت دوباره فعال کن
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
        orElse: () => ExerciseModel.empty(),
      );
    } catch (e) {
      print('❌ خطا در چک کردن تمرین تکراری: $e');
      return null;
    }
  }

  Future<List<ExerciseModel>> fetchCoachExercises(String userId) async {
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
      notifyListeners();
      return _coachExercises;
    } catch (e) {
      print('❌ خطا در دریافت تمرینات: $e');
      _coachExercises = []; // پیش‌فرض خالی
      notifyListeners();
      return [];
    }
  }

  Future<List<ExerciseModel>> searchExercises({
    required String? category,
    String? targetMuscle,
    required String searchQuery,
    required String userId,
  }) async {
    if (category == null || searchQuery.isEmpty) {
      print('🔍 سرچ رد شد: دسته‌بندی یا کوئری خالیه');
      return [];
    }
    try {
      print('🔍 شروع سرچ: $searchQuery');
      final exercises = await _exerciseService.getExercises().timeout(
        const Duration(seconds: 10),
      );
      _searchResults =
          exercises.where((exercise) {
            final matchesCategory =
                category == 'همه' || exercise.category == category;
            final matchesMuscle =
                targetMuscle == null || targetMuscle == 'همه'
                    ? true
                    : exercise.targetMuscle == targetMuscle;
            final matchesName = exercise.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final matchesUser = userId.isEmpty || exercise.createdBy == userId;
            return matchesCategory &&
                matchesMuscle &&
                matchesName &&
                matchesUser;
          }).toList();
      print('✅ سرچ تموم شد: ${_searchResults.length} نتیجه');
      notifyListeners();
      return _searchResults;
    } catch (e) {
      print('❌ خطا در جستجوی تمرینات: $e');
      _searchResults = []; // پیش‌فرض خالی
      notifyListeners();
      return [];
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    if (!_isValidUUID(exerciseId)) return;
    try {
      final exercise = _exercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => ExerciseModel.empty(),
      );
      if (exercise.createdBy != authProvider.userId) {
        throw Exception('شما اجازه حذف این تمرین را ندارید');
      }
      await _exerciseService.deleteExercise(exerciseId);
      _exercises.removeWhere((exercise) => exercise.id == exerciseId);
      _coachExercises.removeWhere((exercise) => exercise.id == exerciseId);
      notifyListeners();
    } catch (e) {
      print('❌ خطا در حذف تمرین: $e');
    }
  }

  Future<void> updateExercise(String id, Map<String, dynamic> updates) async {
    if (!_isValidUUID(id)) return;
    try {
      final exercise = _exercises.firstWhere(
        (e) => e.id == id,
        orElse: () => ExerciseModel.empty(),
      );
      if (exercise.createdBy != authProvider.userId) {
        throw Exception('شما اجازه ویرایش این تمرین را ندارید');
      }
      await _exerciseService.updateExercise(id, {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await fetchAllExercises(); // به‌روزرسانی لیست
    } catch (e) {
      print('❌ خطا در بروزرسانی تمرین: $e');
    }
  }

  bool _isValidUUID(String? value) {
    return value != null &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(value);
  }
}
