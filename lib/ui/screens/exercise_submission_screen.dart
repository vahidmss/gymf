import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart'; // برای فونت Vazirmatn

class ExerciseSubmissionScreen extends StatefulWidget {
  const ExerciseSubmissionScreen({super.key});

  @override
  _ExerciseSubmissionScreenState createState() =>
      _ExerciseSubmissionScreenState();
}

class _ExerciseSubmissionScreenState extends State<ExerciseSubmissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCountingType;

  late ValueNotifier<String> _searchQueryNotifier;
  late Debouncer<String> _searchDebouncer;
  late StreamSubscription<String> _searchSubscription;
  Future<List<ExerciseModel>>? _coachExercisesFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // زمان کمتر برای روان‌تر شدن
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    ).drive(Tween<double>(begin: 0, end: 1));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    ).drive(Tween<double>(begin: 0.8, end: 1.0));
    _controller.forward();

    _searchQueryNotifier = ValueNotifier<String>('');
    _searchDebouncer = Debouncer<String>(
      const Duration(milliseconds: 500),
      initialValue: '',
    );

    _searchSubscription = _searchDebouncer.values.listen((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchQueryNotifier.value = value;
      });
    });

    _nameController.addListener(() {
      _searchDebouncer.value = _nameController.text;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    _loadCoachExercises(authProvider.userId ?? '', exerciseProvider);
  }

  void _loadCoachExercises(String userId, ExerciseProvider exerciseProvider) {
    setState(() {
      _coachExercisesFuture = exerciseProvider.fetchCoachExercises(userId);
    });
  }

  @override
  void dispose() {
    _searchSubscription.cancel();
    _controller.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  void _navigateToEditExercise(ExerciseModel exercise) {
    Navigator.pushNamed(context, '/edit-exercise', arguments: exercise);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A72), Color(0xFF009FFD)], // بنفش تیره به آبی
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Image(
                  image: AssetImage('images/Vteem1.png'),
                  height: 60,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ثبت تمرین جدید',
                style: GoogleFonts.vazirmatn(
                  textStyle: const TextStyle(
                    color: Colors.yellowAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.yellowAccent),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
            ),
          ],
        ),
        endDrawer: _buildExerciseDrawer(
          context,
          authProvider.userId ?? 'unknown',
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<ExerciseProvider>(
                      builder: (context, provider, child) {
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildCategoryDropdown(provider),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder: (context, provider, child) {
                        if (provider.selectedCategory == 'قدرتی') {
                          return ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildTargetMuscleDropdown(provider),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder: (context, provider, child) {
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildCustomTextField(
                            controller: _nameController,
                            label: 'اسم تمرین',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'اسم تمرین نمی‌تونه خالی باشه!';
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<String>(
                      valueListenable: _searchQueryNotifier,
                      builder: (context, searchQuery, child) {
                        final provider = Provider.of<ExerciseProvider>(
                          context,
                          listen: false,
                        );
                        if (searchQuery.isNotEmpty &&
                            provider.selectedCategory != null) {
                          return _buildSearchResults(
                            provider,
                            authProvider.userId,
                            searchQuery,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder: (context, provider, child) {
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildCustomTextField(
                            controller: _descriptionController,
                            label: 'توضیحات (اختیاری)',
                            maxLines: 3,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<ExerciseProvider>(
                      builder: (context, provider, child) {
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildCountingTypeDropdown(provider),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildMediaButtons(
                        context,
                        Provider.of<ExerciseProvider>(context, listen: false),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Consumer<ExerciseProvider>(
                      builder: (context, provider, child) {
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildCustomButton(
                            text: 'ثبت تمرین',
                            onPressed: () => _submitExercise(provider),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitExercise(ExerciseProvider provider) {
    if (provider.selectedCategory == null || _selectedCountingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً دسته‌بندی و نوع شمارش رو انتخاب کن'),
        ),
      );
      return;
    }

    provider.submitExercise(
      name: _nameController.text,
      category: provider.selectedCategory!,
      targetMuscle:
          provider.selectedCategory == 'قدرتی'
              ? provider.selectedTargetMuscle
              : null,
      description:
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمرین با موفقیت ثبت شد!')),
        );
        _nameController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCountingType = null;
        });
        provider.resetForm();
      },
      onFailure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ثبت تمرین: $error')));
      },
    );
  }

  Widget _buildCategoryDropdown(ExerciseProvider provider) {
    return DropdownButtonFormField<String>(
      value: provider.selectedCategory,
      decoration: InputDecoration(
        labelText: 'دسته‌بندی',
        labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      dropdownColor: const Color(0xFF2A2A72),
      style: GoogleFonts.vazirmatn(color: Colors.white),
      iconEnabledColor: Colors.yellowAccent,
      items: const [
        DropdownMenuItem(value: 'قدرتی', child: Text('قدرتی')),
        DropdownMenuItem(value: 'هوازی', child: Text('هوازی')),
        DropdownMenuItem(value: 'تعادلی', child: Text('تعادلی')),
      ],
      onChanged: (value) => provider.setCategory(value!),
      validator:
          (value) => value == null ? 'لطفاً دسته‌بندی رو انتخاب کن!' : null,
    );
  }

  Widget _buildTargetMuscleDropdown(ExerciseProvider provider) {
    return DropdownButtonFormField<String>(
      value:
          provider.selectedCategory == 'قدرتی'
              ? provider.selectedTargetMuscle
              : null,
      decoration: InputDecoration(
        labelText: 'عضله هدف',
        labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      dropdownColor: const Color(0xFF2A2A72),
      style: GoogleFonts.vazirmatn(color: Colors.white),
      iconEnabledColor: Colors.yellowAccent,
      items: const [
        DropdownMenuItem(value: 'پا', child: Text('پا')),
        DropdownMenuItem(value: 'شکم', child: Text('شکم')),
        DropdownMenuItem(value: 'سینه', child: Text('سینه')),
        DropdownMenuItem(value: 'بازو', child: Text('بازو')),
        DropdownMenuItem(value: 'زیربغل', child: Text('زیربغل')),
        DropdownMenuItem(value: 'سرشانه', child: Text('سرشانه')),
      ],
      onChanged:
          provider.selectedCategory == 'قدرتی'
              ? (value) => provider.setTargetMuscle(value!)
              : null,
    );
  }

  Widget _buildCountingTypeDropdown(ExerciseProvider provider) {
    return DropdownButtonFormField<String>(
      value: _selectedCountingType ?? provider.selectedCountingType,
      decoration: InputDecoration(
        labelText: 'نوع شمارش',
        labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      dropdownColor: const Color(0xFF2A2A72),
      style: GoogleFonts.vazirmatn(color: Colors.white),
      iconEnabledColor: Colors.yellowAccent,
      items: const [
        DropdownMenuItem(value: 'وزن (kg)', child: Text('وزن (kg)')),
        DropdownMenuItem(value: 'تایم', child: Text('تایم')),
        DropdownMenuItem(value: 'تعداد', child: Text('تعداد')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCountingType = value;
          provider.setCountingType(value);
        });
      },
      validator:
          (value) => value == null ? 'لطفاً نوع شمارش رو انتخاب کن!' : null,
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: GoogleFonts.vazirmatn(color: Colors.white),
        validator: validator,
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.yellowAccent, const Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.yellowAccent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.vazirmatn(
            textStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButtons(BuildContext context, ExerciseProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: _buildGlassButton(
            icon: Icons.image,
            label: 'انتخاب عکس',
            onPressed: () async {
              final pickedFile = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                provider.setImage(File(pickedFile.path));
              }
            },
          ),
        ),
        ScaleTransition(
          scale: _scaleAnimation,
          child: _buildGlassButton(
            icon: Icons.videocam,
            label: 'انتخاب ویدیو',
            onPressed: () async {
              final pickedFile = await ImagePicker().pickVideo(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                provider.setVideo(File(pickedFile.path));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: GoogleFonts.vazirmatn(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseDrawer(BuildContext context, String userId) {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            canvasColor: const Color(0xFF2A2A72), // رنگ دراور
          ),
          child: Drawer(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFFF00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تمرینات من',
                        style: GoogleFonts.vazirmatn(
                          textStyle: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<ExerciseModel>>(
                    future: _coachExercisesFuture,
                    builder: (context, snapshot) {
                      if (_coachExercisesFuture == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Center(
                          child: Text(
                            'خطا در بارگذاری تمرینات',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      final exercises = snapshot.data!;
                      if (exercises.isEmpty) {
                        return const Center(
                          child: Text(
                            'هنوز تمرینی ثبت نشده است!',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return Card(
                            color: Colors.white.withOpacity(0.1),
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              title: Text(
                                exercise.name,
                                style: GoogleFonts.vazirmatn(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                '${exercise.category} ${exercise.targetMuscle != null ? '- ${exercise.targetMuscle}' : ''} (${exercise.countingType ?? 'نامشخص'})',
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.yellowAccent,
                                    ),
                                    onPressed:
                                        () => _editExercise(
                                          context,
                                          exercise,
                                          userId,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      provider.deleteExercise(exercise.id);
                                      _loadCoachExercises(userId, provider);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(
    ExerciseProvider provider,
    String? userId,
    String searchQuery,
  ) {
    return FutureBuilder<List<ExerciseModel>>(
      future: provider.searchExercises(
        category: provider.selectedCategory,
        targetMuscle:
            provider.selectedCategory == 'قدرتی'
                ? provider.selectedTargetMuscle
                : null,
        searchQuery: searchQuery,
        userId: userId ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'خطا در جستجوی تمرینات: ${snapshot.error ?? "داده‌ای دریافت نشد"}',
                  style: GoogleFonts.vazirmatn(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          );
        }

        final filteredExercises = snapshot.data!;
        if (filteredExercises.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'تمرینی یافت نشد!',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredExercises.length,
          itemBuilder: (context, index) {
            final exercise = filteredExercises[index];
            return ListTile(
              title: Text(
                exercise.name,
                style: GoogleFonts.vazirmatn(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              subtitle: Text(
                '${exercise.category} (${exercise.countingType ?? 'نامشخص'})',
                style: GoogleFonts.vazirmatn(color: Colors.grey),
              ),
              onTap: () {
                if (exercise.createdBy == userId) {
                  _navigateToEditExercise(exercise);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'شما فقط به تمرین‌های ثبت‌شده توسط خودتان دسترسی دارید.',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  void _editExercise(
    BuildContext context,
    ExerciseModel exercise,
    String userId,
  ) {
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    final nameController = TextEditingController(text: exercise.name);
    final descriptionController = TextEditingController(
      text: exercise.description ?? '',
    );
    String? selectedCountingType = exercise.countingType;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'ویرایش تمرین',
            style: GoogleFonts.vazirmatn(
              textStyle: const TextStyle(color: Colors.yellowAccent),
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCustomTextField(
                      controller: nameController,
                      label: 'اسم تمرین',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اسم تمرین نمی‌تونه خالی باشه!';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCustomTextField(
                      controller: descriptionController,
                      label: 'توضیحات (اختیاری)',
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCountingTypeDropdown(exerciseProvider),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'لغو',
                style: GoogleFonts.vazirmatn(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final updates = {
                    'name': nameController.text,
                    'category': exercise.category,
                    'target_muscle':
                        exercise.category == 'قدرتی'
                            ? exercise.targetMuscle
                            : null,
                    'created_by': userId,
                    'description':
                        descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                    'counting_type': selectedCountingType,
                  };
                  await exerciseProvider.updateExercise(exercise.id, updates);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمرین با موفقیت ویرایش شد!')),
                  );
                  _loadCoachExercises(userId, exerciseProvider);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطا در ویرایش: $e')));
                }
              },
              child: Text(
                'ذخیره',
                style: GoogleFonts.vazirmatn(
                  textStyle: const TextStyle(color: Colors.yellowAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
