import 'package:flutter/material.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const WorkoutPlanScreen(),
      theme: ThemeData(
        primaryColor: Colors.yellow,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  _WorkoutPlanScreenState createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  String? selectedPlan;
  bool isForStudent = false;
  String? studentUsername;
  String planName = '';
  List<WorkoutDay> workoutDays = [];
  final TextEditingController _planNameController = TextEditingController();
  bool isLoading = false; // اضافه شد

  @override
  void initState() {
    super.initState();
    workoutDays.add(WorkoutDay(dayName: 'روز ۱'));
    _fetchExercises(); // اضافه شد
  }

  Future<void> _fetchExercises() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    await exerciseProvider.fetchCoachExercises(
      authProvider.currentUser?.username ?? 'test_coach',
    );
  }

  void addNewPlan() {
    setState(() {
      selectedPlan = null;
      workoutDays.clear();
      workoutDays.add(WorkoutDay(dayName: 'روز ۱'));
      _planNameController.clear();
      isForStudent = false;
      studentUsername = null;
    });
  }

  void addWorkoutDay() {
    setState(() {
      workoutDays.add(WorkoutDay(dayName: 'روز ${workoutDays.length + 1}'));
    });
  }

  void savePlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );

    if (_planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً اسم برنامه رو وارد کن!')),
      );
      return;
    }

    setState(() => isLoading = true); // شروع لودینگ

    for (var day in workoutDays) {
      final plan = WorkoutPlanModel(
        userId: authProvider.userId ?? '',
        planName: _planNameController.text,
        username: authProvider.currentUser?.username ?? '',
        role: authProvider.currentUser?.role ?? 'athlete',
        assignedTo: isForStudent ? studentUsername : null,
        day: day.dayName,
      );

      final exercises =
          day.exercises
              .map(
                (e) => WorkoutExerciseModel(
                  planId: '', // بعد از ثبت plan پر می‌شه
                  exerciseId: e.exerciseId,
                  sets: e.sets,
                  reps: e.reps,
                  duration: e.duration,
                  countingType: e.countingType,
                  notes: e.notes,
                ),
              )
              .toList();

      await workoutPlanProvider.createPlan(
        userId: authProvider.userId ?? '',
        planName: _planNameController.text,
        day: day.dayName,
        assignedToUsername: isForStudent ? studentUsername : null,
        username: authProvider.currentUser?.username ?? '',
        role: authProvider.currentUser?.role ?? 'athlete',
        exercises: exercises,
      );
    }

    setState(() => isLoading = false); // پایان لودینگ

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('برنامه با موفقیت ثبت شد!')));
    addNewPlan(); // ریست فرم
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت برنامه تمرینی'),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : savePlan, // غیرفعال موقع لودینگ
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          // اضافه کردن Stack برای لودینگ
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _planNameController,
                  label: 'اسم برنامه',
                  validator:
                      (value) =>
                          value!.isEmpty ? 'اسم برنامه رو وارد کن!' : null,
                ),
                const SizedBox(height: 16),
                if (authProvider.currentUser?.role == 'coach') ...[
                  Row(
                    children: [
                      const Text(
                        'نقش: ',
                        style: TextStyle(color: Colors.white),
                      ),
                      ChoiceChip(
                        label: const Text('برای خودم'),
                        selected: !isForStudent,
                        onSelected: (_) => setState(() => isForStudent = false),
                        selectedColor: Colors.yellow,
                        backgroundColor: Colors.grey[800],
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('برای شاگرد'),
                        selected: isForStudent,
                        onSelected: (_) => setState(() => isForStudent = true),
                        selectedColor: Colors.yellow,
                        backgroundColor: Colors.grey[800],
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  if (isForStudent)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: CustomTextField(
                        label: 'نام کاربری شاگرد',
                        onChanged: (value) => studentUsername = value,
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: workoutDays.length,
                    itemBuilder: (context, index) {
                      return WorkoutDayCard(
                        workoutDay: workoutDays[index],
                        onDelete:
                            () => setState(() => workoutDays.removeAt(index)),
                        availableExercises: exerciseProvider.coachExercises,
                      );
                    },
                  ),
                ),
              ],
            ),
            if (isLoading)
              const Center(
                child: CustomButton(
                  text: 'در حال ثبت...', // دکمه غیرفعال موقع لودینگ
                  onPressed: null,
                  isLoading: true,
                  backgroundColor: Colors.yellow,
                  textColor: Colors.black,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : addWorkoutDay, // غیرفعال موقع لودینگ
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class WorkoutDay {
  String dayName;
  List<WorkoutExercise> exercises;

  WorkoutDay({
    required this.dayName,
    List<WorkoutExercise> exercises = const [],
  }) : exercises = List<WorkoutExercise>.from(
         exercises,
       ); // تبدیل به لیست قابل تغییر
}

class WorkoutExercise {
  String exerciseId;
  String name;
  int sets;
  int? reps;
  int? duration;
  String countingType;
  String? notes;

  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.reps,
    this.duration,
    required this.countingType,
    this.notes,
  });
}

class WorkoutDayCard extends StatefulWidget {
  final WorkoutDay workoutDay;
  final VoidCallback onDelete;
  final List<Map<String, dynamic>> availableExercises;

  const WorkoutDayCard({
    super.key,
    required this.workoutDay,
    required this.onDelete,
    required this.availableExercises,
  });

  @override
  _WorkoutDayCardState createState() => _WorkoutDayCardState();
}

class _WorkoutDayCardState extends State<WorkoutDayCard> {
  void addExercise(Map<String, dynamic>? exercise) {
    if (exercise != null) {
      _showAddExerciseDialog(exercise);
    }
  }

  void _showAddExerciseDialog(Map<String, dynamic> exercise) {
    final TextEditingController setsController = TextEditingController(
      text: '3',
    );
    final TextEditingController valueController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'اضافه کردن تمرین',
            style: TextStyle(color: Colors.yellow),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: setsController,
                label: 'تعداد ست',
                keyboardType: TextInputType.number,
                validator:
                    (value) => value!.isEmpty ? 'تعداد ست رو وارد کن!' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: valueController,
                label:
                    exercise['counting_type'] == 'وزن (kg)'
                        ? 'وزن (kg)'
                        : exercise['counting_type'] == 'تعداد'
                        ? 'تعداد (حرکات)'
                        : 'مدت زمان (ثانیه)',
                keyboardType: TextInputType.number,
                validator:
                    (value) => value!.isEmpty ? 'مقدار رو وارد کن!' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: notesController,
                label: 'یادداشت (اختیاری)',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (setsController.text.isEmpty ||
                    valueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لطفاً همه فیلدها رو پر کن!')),
                  );
                  return;
                }

                setState(() {
                  widget.workoutDay.exercises.add(
                    WorkoutExercise(
                      exerciseId: exercise['id'],
                      name: exercise['name'],
                      sets: int.parse(setsController.text),
                      reps:
                          exercise['counting_type'] == 'تعداد'
                              ? int.parse(valueController.text)
                              : null,
                      duration:
                          exercise['counting_type'] == 'تایم'
                              ? int.parse(valueController.text)
                              : null,
                      countingType: exercise['counting_type'],
                      notes:
                          notesController.text.isEmpty
                              ? null
                              : notesController.text,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text(
                'ذخیره',
                style: TextStyle(color: Colors.yellow),
              ),
            ),
          ],
        );
      },
    );
  }

  void updateExercise(WorkoutExercise updatedExercise, int index) {
    setState(() {
      widget.workoutDay.exercises[index] = updatedExercise;
    });
  }

  void deleteExercise(int index) {
    setState(() {
      widget.workoutDay.exercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.workoutDay.dayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            ...widget.workoutDay.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return ExerciseRow(
                exercise: exercise,
                countingType: exercise.countingType,
                onDelete: () => deleteExercise(index),
                onUpdate: (updated) => updateExercise(updated, index),
              );
            }).toList(),
            if (widget.availableExercises.isNotEmpty) // چک کردن لیست خالی
              DropdownButton<Map<String, dynamic>>(
                hint: const Text(
                  'انتخاب تمرین',
                  style: TextStyle(color: Colors.white),
                ),
                items:
                    widget.availableExercises.map((exercise) {
                      return DropdownMenuItem(
                        value: exercise,
                        child: Text(exercise['name']),
                      );
                    }).toList(),
                onChanged: (value) => addExercise(value),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.yellow, // رنگ آیکون Dropdown
                isExpanded: true, // گسترش Dropdown برای نمایش بهتر
              )
            else
              const Text(
                'هیچ تمرینی یافت نشد',
                style: TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class ExerciseRow extends StatelessWidget {
  final WorkoutExercise exercise;
  final String countingType;
  final VoidCallback onDelete;
  final Function(WorkoutExercise) onUpdate;

  const ExerciseRow({
    super.key,
    required this.exercise,
    required this.countingType,
    required this.onDelete,
    required this.onUpdate,
  });

  void _showEditDialog(BuildContext context) {
    final setsController = TextEditingController(
      text: exercise.sets.toString(),
    );
    final valueController = TextEditingController(
      text: (exercise.reps ?? exercise.duration ?? '').toString(),
    );
    final notesController = TextEditingController(text: exercise.notes ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'ویرایش تمرین',
            style: TextStyle(color: Colors.yellow),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: setsController,
                label: 'تعداد ست',
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                controller: valueController,
                label:
                    countingType == 'وزن (kg)'
                        ? 'وزن (kg)'
                        : countingType == 'تایم'
                        ? 'زمان (ثانیه)'
                        : 'تکرار',
                keyboardType: TextInputType.number,
              ),
              CustomTextField(
                controller: notesController,
                label: 'یادداشت (اختیاری)',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                final updated = WorkoutExercise(
                  exerciseId: exercise.exerciseId,
                  name: exercise.name,
                  sets: int.parse(setsController.text),
                  reps:
                      countingType == 'تعداد'
                          ? int.parse(valueController.text)
                          : null,
                  duration:
                      countingType == 'تایم'
                          ? int.parse(valueController.text)
                          : null,
                  countingType: countingType,
                  notes:
                      notesController.text.isEmpty
                          ? null
                          : notesController.text,
                );
                onUpdate(updated);
                Navigator.pop(context);
              },
              child: const Text(
                'ذخیره',
                style: TextStyle(color: Colors.yellow),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(exercise.name)),
          Text('$countingType: ${exercise.reps ?? exercise.duration ?? 0}'),
          const SizedBox(width: 8),
          Text('${exercise.sets} ست'),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.yellow),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
