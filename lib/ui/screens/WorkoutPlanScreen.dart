import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:animate_do/animate_do.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final TextEditingController _planNameController = TextEditingController();
  List<WorkoutDay> _days = [];
  bool _isDarkTheme = true;
  WorkoutPlanModel? _selectedPlan;
  double? _weight;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );

    await exerciseProvider.fetchAllExercises();
    await workoutPlanProvider.fetchCoachPlans(authProvider.userId ?? '');
    setState(() {
      _days = [WorkoutDay(dayName: 'روز ۱', exercises: [])];
    });
  }

  void _addDay() {
    setState(() {
      final newDayNumber = _days.length + 1;
      _days.add(WorkoutDay(dayName: 'روز $newDayNumber', exercises: []));
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index);
      for (int i = 0; i < _days.length; i++) {
        _days[i] = WorkoutDay(
          dayName: 'روز ${i + 1}',
          exercises: _days[i].exercises,
        );
      }
    });
  }

  void _addExercise(int dayIndex) {
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController exerciseNameController =
            TextEditingController();
        int sets = 3;
        int? reps = 10;
        int? duration;
        double? weight;
        String countingType = 'وزن (kg)';
        String? notes;
        ExerciseModel? selectedExercise;
        List<WorkoutExercise> tempExercises = List.from(
          _days[dayIndex].exercises,
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor:
                  _isDarkTheme
                      ? Colors.blueGrey.shade900.withOpacity(0.9)
                      : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'اضافه کردن تمرین',
                style: GoogleFonts.vazirmatn(
                  color: _isDarkTheme ? Colors.yellow : Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<ExerciseModel>(
                            optionsBuilder: (
                              TextEditingValue textEditingValue,
                            ) {
                              if (textEditingValue.text.length < 3) {
                                return const Iterable<ExerciseModel>.empty();
                              }
                              return exerciseProvider.exercises.where((
                                exercise,
                              ) {
                                return exercise.name.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                );
                              });
                            },
                            displayStringForOption:
                                (ExerciseModel option) => option.name,
                            onSelected: (ExerciseModel selection) {
                              setState(() {
                                selectedExercise = selection;
                                exerciseNameController.text = selection.name;
                                countingType =
                                    selection.countingType ?? 'وزن (kg)';
                                if (![
                                  'وزن (kg)',
                                  'تایم',
                                  'تعداد',
                                ].contains(countingType)) {
                                  countingType = 'وزن (kg)';
                                }
                              });
                            },
                            fieldViewBuilder: (
                              context,
                              controller,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              exerciseNameController.addListener(() {
                                if (exerciseNameController.text.length >= 3) {
                                  setState(() {});
                                }
                              });
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'نام تمرین',
                                  labelStyle: GoogleFonts.vazirmatn(
                                    color:
                                        _isDarkTheme
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor:
                                      _isDarkTheme
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.yellow,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/submit-exercise',
                            ).then((newExercise) {
                              if (newExercise != null &&
                                  newExercise is ExerciseModel) {
                                setState(() {
                                  exerciseProvider.exercises.add(newExercise);
                                  selectedExercise = newExercise;
                                  exerciseNameController.text =
                                      newExercise.name;
                                  countingType =
                                      newExercise.countingType ?? 'وزن (kg)';
                                  if (![
                                    'وزن (kg)',
                                    'تایم',
                                    'تعداد',
                                  ].contains(countingType)) {
                                    countingType = 'وزن (kg)';
                                  }
                                });
                              }
                            });
                          },
                          tooltip: 'اضافه کردن تمرین جدید',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (exerciseNameController.text.isNotEmpty &&
                        selectedExercise == null &&
                        !exerciseProvider.exercises.any(
                          (exercise) =>
                              exercise.name.toLowerCase() ==
                              exerciseNameController.text.toLowerCase(),
                        ))
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/submit-exercise',
                          ).then((newExercise) {
                            if (newExercise != null &&
                                newExercise is ExerciseModel) {
                              setState(() {
                                exerciseProvider.exercises.add(newExercise);
                                selectedExercise = newExercise;
                                exerciseNameController.text = newExercise.name;
                                countingType =
                                    newExercise.countingType ?? 'وزن (kg)';
                                if (![
                                  'وزن (kg)',
                                  'تایم',
                                  'تعداد',
                                ].contains(countingType)) {
                                  countingType = 'وزن (kg)';
                                }
                              });
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'تمرین پیدا نشد، ثبت کنید',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    // پیش‌نمایش اطلاعات تمرین
                    if (selectedExercise != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              _isDarkTheme
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                _isDarkTheme
                                    ? Colors.yellow.withOpacity(0.2)
                                    : Colors.black12,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'پیش‌نمایش تمرین:',
                              style: GoogleFonts.vazirmatn(
                                color:
                                    _isDarkTheme
                                        ? Colors.yellow
                                        : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'دسته‌بندی: ${selectedExercise!.category}',
                              style: GoogleFonts.vazirmatn(
                                color:
                                    _isDarkTheme
                                        ? Colors.white70
                                        : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            if (selectedExercise!.targetMuscle != null)
                              Text(
                                'عضله هدف: ${selectedExercise!.targetMuscle}',
                                style: GoogleFonts.vazirmatn(
                                  color:
                                      _isDarkTheme
                                          ? Colors.white70
                                          : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'نوع شمارش: ${selectedExercise!.countingType ?? 'نامشخص'}',
                              style: GoogleFonts.vazirmatn(
                                color:
                                    _isDarkTheme
                                        ? Colors.white70
                                        : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تعداد ست‌ها:',
                          style: GoogleFonts.vazirmatn(
                            color:
                                _isDarkTheme ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed:
                                  sets > 1
                                      ? () {
                                        setState(() {
                                          sets--;
                                        });
                                      }
                                      : null,
                            ),
                            Text(
                              '$sets',
                              style: GoogleFonts.vazirmatn(
                                color:
                                    _isDarkTheme
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  sets++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'شمارش بر اساس:',
                          style: GoogleFonts.vazirmatn(
                            color:
                                _isDarkTheme ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        DropdownButton<String>(
                          value: countingType,
                          items:
                              ['وزن (kg)', 'تایم', 'تعداد'].map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                countingType = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (countingType == 'تعداد')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تعداد تکرارها:',
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed:
                                    reps != null && reps! > 1
                                        ? () {
                                          setState(() {
                                            reps = reps! - 1;
                                          });
                                        }
                                        : null,
                              ),
                              Text(
                                '${reps ?? 0}',
                                style: GoogleFonts.vazirmatn(
                                  color:
                                      _isDarkTheme
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    reps = (reps ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (countingType == 'تایم')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مدت زمان (ثانیه):',
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed:
                                    duration != null && duration! > 0
                                        ? () {
                                          setState(() {
                                            duration = duration! - 1;
                                          });
                                        }
                                        : null,
                              ),
                              Text(
                                '${duration ?? 0}',
                                style: GoogleFonts.vazirmatn(
                                  color:
                                      _isDarkTheme
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    duration = (duration ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (countingType == 'وزن (kg)')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'وزن (کیلوگرم):',
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed:
                                    weight != null && weight! > 0
                                        ? () {
                                          setState(() {
                                            weight = weight! - 1;
                                          });
                                        }
                                        : null,
                              ),
                              Text(
                                '${weight ?? 0}',
                                style: GoogleFonts.vazirmatn(
                                  color:
                                      _isDarkTheme
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    weight = (weight ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => notes = value,
                      decoration: InputDecoration(
                        labelText: 'یادداشت (اختیاری)',
                        labelStyle: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor:
                            _isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade100,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'لغو',
                    style: GoogleFonts.vazirmatn(
                      color: _isDarkTheme ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (exerciseNameController.text.isEmpty ||
                        selectedExercise == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لطفاً یک تمرین معتبر انتخاب کنید!'),
                        ),
                      );
                      return;
                    }
                    final exercise = WorkoutExercise(
                      exerciseId: selectedExercise!.id,
                      name: selectedExercise!.name,
                      category:
                          selectedExercise!.category, // مستقیم از ExerciseModel
                      sets: sets,
                      reps: countingType == 'تعداد' ? reps : null,
                      duration: countingType == 'تایم' ? duration : null,
                      weight: countingType == 'وزن (kg)' ? weight : null,
                      countingType: countingType,
                      notes: notes,
                    );
                    tempExercises.add(exercise);

                    this.setState(() {
                      _days[dayIndex] = WorkoutDay(
                        dayName: _days[dayIndex].dayName,
                        exercises: tempExercises,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'اضافه',
                    style: GoogleFonts.vazirmatn(
                      color: _isDarkTheme ? Colors.yellow : Colors.black87,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int index,
    WorkoutDay day,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            _isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDarkTheme ? Colors.yellow.withOpacity(0.2) : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'دسته: ${exercise.category} | ست‌ها: ${exercise.sets}',
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (exercise.reps != null)
                  Text(
                    'تکرارها: ${exercise.reps}',
                    style: GoogleFonts.vazirmatn(
                      color: _isDarkTheme ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                if (exercise.duration != null)
                  Text(
                    'مدت زمان: ${exercise.duration} ثانیه',
                    style: GoogleFonts.vazirmatn(
                      color: _isDarkTheme ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                if (exercise.weight != null)
                  Text(
                    'وزن: ${exercise.weight} کیلوگرم',
                    style: GoogleFonts.vazirmatn(
                      color: _isDarkTheme ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.redAccent,
            onPressed: () {
              setState(() {
                day.exercises.removeAt(index);
              });
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX();
  }

  void _savePlan() {
    if (_planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً نام برنامه را وارد کنید!')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );

    final newPlan = WorkoutPlanModel(
      createdBy: authProvider.userId ?? '',
      planName: _planNameController.text,
      days: _days,
    );

    workoutPlanProvider.addPlan(
      newPlan,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برنامه با موفقیت ذخیره شد!')),
        );
        setState(() {
          _planNameController.clear();
          _days = [WorkoutDay(dayName: 'روز ۱', exercises: [])];
          _selectedPlan = null;
        });
      },
      onFailure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  void _updatePlan() {
    if (_planNameController.text.isEmpty || _selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً برنامه را انتخاب و نام را وارد کنید!'),
        ),
      );
      return;
    }

    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );

    final updatedPlan = _selectedPlan!.copyWith(
      planName: _planNameController.text,
      days: _days,
      updatedAt: DateTime.now(),
    );

    workoutPlanProvider.updatePlan(
      _selectedPlan!.id,
      updatedPlan.toJson(),
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برنامه با موفقیت آپدیت شد!')),
        );
        setState(() {
          _planNameController.clear();
          _days = [WorkoutDay(dayName: 'روز ۱', exercises: [])];
          _selectedPlan = null;
        });
      },
      onFailure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  void _deletePlan(String id) {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );

    workoutPlanProvider.deletePlan(
      id,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برنامه با موفقیت حذف شد!')),
        );
        setState(() {
          _planNameController.clear();
          _days = [WorkoutDay(dayName: 'روز ۱', exercises: [])];
          _selectedPlan = null;
        });
      },
      onFailure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(context);
    final savedPlans = workoutPlanProvider.coachPlans;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkTheme ? Colors.blueGrey.shade900 : Colors.white,
        elevation: 0,
        title: Text(
          'برنامه تمرینی',
          style: GoogleFonts.vazirmatn(
            color: _isDarkTheme ? Colors.yellow : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkTheme ? Icons.brightness_7 : Icons.brightness_4),
            onPressed: () {
              setState(() {
                _isDarkTheme = !_isDarkTheme;
              });
            },
          ),
        ],
      ),
      body:
          workoutPlanProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _planNameController,
                      decoration: InputDecoration(
                        labelText: 'نام برنامه',
                        labelStyle: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor:
                            _isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade100,
                      ),
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'روزهای برنامه',
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._days.asMap().entries.map((entry) {
                      final index = entry.key;
                      final day = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              _isDarkTheme
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                _isDarkTheme
                                    ? Colors.yellow.withOpacity(0.2)
                                    : Colors.black12,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  day.dayName,
                                  style: GoogleFonts.vazirmatn(
                                    color:
                                        _isDarkTheme
                                            ? Colors.white
                                            : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_days.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removeDay(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (day.exercises.isEmpty)
                              Text(
                                'تمرینی اضافه نشده است',
                                style: GoogleFonts.vazirmatn(
                                  color:
                                      _isDarkTheme
                                          ? Colors.white70
                                          : Colors.black54,
                                  fontSize: 14,
                                ),
                              )
                            else
                              ...day.exercises.asMap().entries.map((entry) {
                                final exerciseIndex = entry.key;
                                final exercise = entry.value;
                                return _buildExerciseCard(
                                  exercise,
                                  exerciseIndex,
                                  day,
                                );
                              }),
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () => _addExercise(index),
                                icon: const Icon(Icons.add),
                                label: Text(
                                  'اضافه کردن تمرین',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _addDay,
                        icon: const Icon(Icons.add),
                        label: Text(
                          'اضافه کردن روز',
                          style: GoogleFonts.vazirmatn(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'برنامه‌های ذخیره‌شده',
                      style: GoogleFonts.vazirmatn(
                        color: _isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (savedPlans.isEmpty)
                      Text(
                        'هیچ برنامه‌ای ذخیره نشده است',
                        style: GoogleFonts.vazirmatn(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      )
                    else
                      ...savedPlans.map((plan) {
                        return ListTile(
                          title: Text(
                            plan.planName,
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'روزها: ${plan.days.length}',
                            style: GoogleFonts.vazirmatn(
                              color:
                                  _isDarkTheme
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedPlan = plan;
                                    _planNameController.text = plan.planName;
                                    _days = List.from(plan.days);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deletePlan(plan.id),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed:
                              _selectedPlan == null ? _savePlan : _updatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _selectedPlan == null
                                    ? Colors.blue
                                    : Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            _selectedPlan == null
                                ? 'ذخیره برنامه'
                                : 'آپدیت برنامه',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_selectedPlan != null)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _planNameController.clear();
                                _days = [
                                  WorkoutDay(dayName: 'روز ۱', exercises: []),
                                ];
                                _selectedPlan = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'لغو ویرایش',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}
