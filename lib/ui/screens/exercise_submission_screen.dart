import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';

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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedCountingType;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ).drive(Tween<double>(begin: 0, end: 1));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ).drive(Tween<double>(begin: 0.8, end: 1.0));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset('images/Vteem1.png', height: 60),
              ),
              const SizedBox(width: 10),
              const Text(
                'ثبت تمرین جدید',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
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
          authProvider.currentUser?.username ?? 'test_coach',
        ),
        body: Container(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildCategoryDropdown(exerciseProvider),
                      ),
                      const SizedBox(height: 20),
                      if (exerciseProvider.selectedCategory == 'قدرتی')
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildTargetMuscleDropdown(exerciseProvider),
                        ),
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: CustomTextField(
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
                        child: CustomTextField(
                          controller: descriptionController,
                          label: 'توضیحات (اختیاری)',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: DropdownButtonFormField<String>(
                          value:
                              selectedCountingType ??
                              exerciseProvider
                                  .selectedCountingType, // مقدار پیش‌فرض از پرووایدر
                          decoration: InputDecoration(
                            labelText: 'نوع شمارش',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.yellowAccent,
                            ),
                          ),
                          dropdownColor: Colors.black87,
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.yellowAccent,
                          items: const [
                            DropdownMenuItem(
                              value: 'وزن (kg)',
                              child: Text('وزن (kg)'),
                            ),
                            DropdownMenuItem(
                              value: 'تایم',
                              child: Text('تایم'),
                            ),
                            DropdownMenuItem(
                              value: 'تعداد',
                              child: Text('تعداد'),
                            ),
                          ],
                          onChanged:
                              (value) => setState(() {
                                selectedCountingType = value;
                                exerciseProvider.setCountingType(value);
                              }),
                          validator: (value) {
                            if (value == null) {
                              return 'لطفاً نوع شمارش رو انتخاب کن!';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildMediaButtons(context, exerciseProvider),
                      ),
                      const SizedBox(height: 30),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: CustomButton(
                          text: 'ثبت تمرین',
                          onPressed: () {
                            if (exerciseProvider.selectedCategory == null ||
                                selectedCountingType == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لطفاً دسته‌بندی و نوع شمارش رو انتخاب کن',
                                  ),
                                ),
                              );
                              return;
                            }
                            exerciseProvider.submitExercise(
                              name: nameController.text,
                              category: exerciseProvider.selectedCategory!,
                              targetMuscle:
                                  exerciseProvider.selectedCategory == 'قدرتی'
                                      ? exerciseProvider.selectedTargetMuscle
                                      : null,
                              coachUsername:
                                  authProvider.currentUser?.username ??
                                  'unknown',
                              description:
                                  descriptionController.text.isEmpty
                                      ? null
                                      : descriptionController.text,
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تمرین با موفقیت ثبت شد!'),
                                  ),
                                );
                                nameController.clear();
                                descriptionController.clear();
                                setState(() {
                                  selectedCountingType = null; // ریست نوع شمارش
                                });
                                exerciseProvider.resetForm();
                              },
                              onFailure: (error) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                                print('خطای دقیق: $error');
                              },
                            );
                          },
                          backgroundColor: Colors.yellowAccent,
                          textColor: Colors.black,
                          borderRadius: 15,
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ExerciseProvider provider) {
    return DropdownButtonFormField<String>(
      value: provider.selectedCategory,
      decoration: InputDecoration(
        labelText: 'دسته‌بندی',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.yellowAccent),
      ),
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.yellowAccent,
      items: const [
        DropdownMenuItem(value: 'قدرتی', child: Text('قدرتی')),
        DropdownMenuItem(value: 'هوازی', child: Text('هوازی')),
        DropdownMenuItem(value: 'تعادلی', child: Text('تعادلی')),
      ],
      onChanged: (value) => provider.setCategory(value!),
    );
  }

  Widget _buildTargetMuscleDropdown(ExerciseProvider provider) {
    return DropdownButtonFormField<String>(
      value: provider.selectedTargetMuscle,
      decoration: InputDecoration(
        labelText: 'عضله هدف',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.yellowAccent),
      ),
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.yellowAccent,
      items: const [
        DropdownMenuItem(value: 'پا', child: Text('پا')),
        DropdownMenuItem(value: 'شکم', child: Text('شکم')),
        DropdownMenuItem(value: 'سینه', child: Text('سینه')),
        DropdownMenuItem(value: 'بازو', child: Text('بازو')),
        DropdownMenuItem(value: 'زیربغل', child: Text('زیربغل')),
        DropdownMenuItem(value: 'سرشانه', child: Text('سرشانه')),
      ],
      onChanged: (value) => provider.setTargetMuscle(value!),
    );
  }

  Widget _buildMediaButtons(BuildContext context, ExerciseProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: ElevatedButton.icon(
            onPressed: () async {
              final pickedFile = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                provider.setImage(File(pickedFile.path));
              }
            },
            icon: const Icon(Icons.image, color: Colors.white),
            label: const Text(
              'انتخاب عکس',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
          ),
        ),
        ScaleTransition(
          scale: _scaleAnimation,
          child: ElevatedButton.icon(
            onPressed: () async {
              final pickedFile = await ImagePicker().pickVideo(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                provider.setVideo(File(pickedFile.path));
              }
            },
            icon: const Icon(Icons.videocam, color: Colors.white),
            label: const Text(
              'انتخاب ویدیو',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseDrawer(BuildContext context, String coachUsername) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Drawer(
      backgroundColor: Colors.black87,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.yellowAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'تمرینات من',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exerciseProvider.coachExercises.length,
              itemBuilder: (context, index) {
                final exercise = exerciseProvider.coachExercises[index];
                return Card(
                  color: Colors.grey.shade900,
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
                      exercise['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${exercise['category']} ${exercise['target_muscle'] != null ? '- ${exercise['target_muscle']}' : ''} (${exercise['counting_type'] ?? 'نامشخص'})',
                      style: const TextStyle(color: Colors.grey),
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
                                coachUsername,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            exerciseProvider.deleteExercise(
                              exercise['id'],
                              coachUsername,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editExercise(
    BuildContext context,
    Map<String, dynamic> exercise,
    String coachUsername,
  ) {
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    final TextEditingController nameController = TextEditingController(
      text: exercise['name'],
    );
    final TextEditingController descriptionController = TextEditingController(
      text: exercise['description'] ?? '',
    );
    String? selectedCountingType = exercise['counting_type']; // نوع شمارش

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'ویرایش تمرین',
            style: TextStyle(color: Colors.yellowAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: CustomTextField(
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
                child: CustomTextField(
                  controller: descriptionController,
                  label: 'توضیحات (اختیاری)',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: _scaleAnimation,
                child: DropdownButtonFormField<String>(
                  value: selectedCountingType,
                  decoration: InputDecoration(
                    labelText: 'نوع شمارش',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.yellowAccent),
                  ),
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.yellowAccent,
                  items: const [
                    DropdownMenuItem(
                      value: 'وزن (kg)',
                      child: Text('وزن (kg)'),
                    ),
                    DropdownMenuItem(value: 'تایم', child: Text('تایم')),
                    DropdownMenuItem(value: 'تعداد', child: Text('تعداد')),
                  ],
                  onChanged:
                      (value) => setState(() {
                        selectedCountingType = value;
                        exerciseProvider.setCountingType(
                          value,
                        ); // آپدیت پرووایدر
                      }),
                  validator: (value) {
                    if (value == null) {
                      return 'لطفاً نوع شمارش رو انتخاب کن!';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final updates = {
                    'name': nameController.text,
                    'category': exercise['category'],
                    'target_muscle':
                        exercise['category'] == 'قدرتی'
                            ? exercise['target_muscle']
                            : null,
                    'coach_username': coachUsername,
                    'description':
                        descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                    'counting_type': selectedCountingType, // آپدیت نوع شمارش
                  };
                  await exerciseProvider.updateExercise(
                    exercise['id'],
                    updates,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمرین با موفقیت ویرایش شد!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطا در ویرایش: $e')));
                }
              },
              child: const Text(
                'ذخیره',
                style: TextStyle(color: Colors.yellowAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
