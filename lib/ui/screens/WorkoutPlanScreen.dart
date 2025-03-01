import 'package:flutter/material.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:gymf/providers/exercise_provider.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  _WorkoutPlanScreenState createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  String? selectedPlan; // برنامه انتخاب‌شده
  bool isForMe = true; // برای خودم یا شaرد
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  List<Map<String, dynamic>> days = [
    {'day': 'روز 1', 'exercises': []}, // تغییر به "روز 1" (فارسی)
  ];
  List<WorkoutExerciseModel> exercisesForDay = []; // لیست تمرینات هر روز

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser(); // مطمئن شدن که کاربر لود شده
    if (authProvider.currentUser != null) {
      final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
        context,
        listen: false,
      );
      await workoutPlanProvider.fetchPlans(
        authProvider.currentUser!.userId,
      ); // استفاده ایمن از !
      if (workoutPlanProvider.plans.isEmpty) {
        setState(() {
          selectedPlan = null;
        });
      } else {
        setState(() {
          selectedPlan = workoutPlanProvider.plans.first.id;
        });
        _loadExercisesForDay('روز 1'); // تغییر به "روز 1" (فارسی)
      }
    }
  }

  @override
  void dispose() {
    planNameController.dispose();
    studentUsernameController.dispose();
    super.dispose();
  }

  void _addExercise(int dayIndex) {
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    setState(() {
      days[dayIndex]['exercises'].add({
        'exerciseId': null, // پیش‌فرض null برای انتخاب تمرین
        'sets': '',
        'reps': '',
        'countingType': '', // نوع شمارش (بعداً با انتخاب تمرین تنظیم می‌شه)
      });
    });
  }

  void _addNewDay() {
    setState(() {
      days.add({
        'day': 'روز ${days.length + 1}',
        'exercises': [],
      }); // تغییر به "روز" (فارسی)
    });
  }

  Future<void> _savePlan() async {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String? assignedToUsername =
        !isForMe ? studentUsernameController.text : null;
    String? assignedToId = null;
    if (assignedToUsername != null && assignedToUsername.isNotEmpty) {
      assignedToId = await workoutPlanProvider.getUserIdByUsername(
        assignedToUsername,
      );
      if (assignedToId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('یوزرنیم شaرد پیدا نشد!')));
        return;
      }
    }

    final plan = WorkoutPlanModel(
      userId: authProvider.currentUser!.userId,
      planName: planNameController.text,
      username: authProvider.currentUser!.username,
      role: authProvider.currentUser!.role,
      assignedTo: assignedToId,
      day: days.first['day'], // روز پیش‌فرض "روز 1"
    );

    await workoutPlanProvider.createPlan(
      userId: authProvider.currentUser!.userId,
      planName: planNameController.text,
      day: days.first['day'], // روز پیش‌فرض "روز 1"
      assignedToUsername: assignedToUsername,
      username: authProvider.currentUser!.username,
      role: authProvider.currentUser!.role,
      exercises: exercisesForDay,
    );

    setState(() {
      selectedPlan = workoutPlanProvider.plans.last.id;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('برنامه با موفقیت ثبت شد!')));
  }

  Future<void> _saveDay(int dayIndex) async {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );
    if (selectedPlan != null) {
      final plan = workoutPlanProvider.plans.firstWhere(
        (p) => p.id == selectedPlan,
      );
      final day = days[dayIndex]['day'];
      final exercises =
          days[dayIndex]['exercises']
              .map((exercise) {
                if (exercise['exerciseId'] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لطفاً یک تمرین انتخاب کنید!'),
                    ),
                  );
                  throw Exception('تمرین انتخاب نشده است.');
                }
                // تبدیل مقادیر به String و چک کردن null با اطمینان بیشتر
                final exerciseId = (exercise['exerciseId'] as String?) ?? '';
                final sets = (exercise['sets'] as String?) ?? '0';
                final reps = (exercise['reps'] as String?) ?? '0';
                final countingType =
                    (exercise['countingType'] as String?) ?? 'تعداد';

                if (exerciseId.isEmpty || sets.isEmpty || reps.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لطفاً همه فیلدها را پر کنید!'),
                    ),
                  );
                  throw Exception('فیلدها خالی هستند.');
                }

                return WorkoutExerciseModel(
                  planId: selectedPlan!,
                  exerciseId: exerciseId, // حالا همیشه String هست
                  sets: int.tryParse(sets) ?? 0,
                  countingType: countingType,
                  reps: int.tryParse(reps) ?? 0,
                  duration: null, // برای تایم، اگر نیاز باشه
                  notes: '', // باید از TextField گرفته بشه
                  createdAt: DateTime.now(),
                );
              })
              .toList()
              .cast<
                WorkoutExerciseModel
              >(); // اضافه کردن cast برای تبدیل به List<WorkoutExerciseModel>

      await workoutPlanProvider.updatePlan(plan.copyWith(day: day), exercises);
      setState(() {
        exercisesForDay = exercises;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('روز با موفقیت ثبت شد!')));
    }
  }

  void _loadExercisesForDay(String day) async {
    if (selectedPlan != null) {
      final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
        context,
        listen: false,
      );
      final exercises = await workoutPlanProvider.fetchPlanExercises(
        selectedPlan!,
      );
      setState(() {
        exercisesForDay =
            exercises
                .where((e) => e.planId == selectedPlan && e.countingType == day)
                .toList();
        // به‌روزرسانی لیست exercises برای هر روز
        final dayIndex = days.indexWhere((d) => d['day'] == day);
        if (dayIndex != -1) {
          days[dayIndex]['exercises'] =
              exercisesForDay
                  .map(
                    (e) => {
                      'exerciseId': e.exerciseId,
                      'sets': e.sets.toString(),
                      'reps': e.reps?.toString() ?? '',
                      'countingType': e.countingType,
                    },
                  )
                  .toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(context);
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    if (authProvider.currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellowAccent),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Planner',
          style: TextStyle(color: Colors.yellowAccent),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlan,
                decoration: InputDecoration(
                  labelText: 'Programs',
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
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  ...workoutPlanProvider.plans.map(
                    (plan) => DropdownMenuItem<String>(
                      value: plan.id,
                      child: Text(
                        plan.planName,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPlan = value;
                    if (value == null) {
                      planNameController.clear();
                      isForMe = true;
                      studentUsernameController.clear();
                      days = [
                        {'day': 'روز 1', 'exercises': []},
                      ]; // ریست کردن روزها
                      exercisesForDay.clear();
                    } else {
                      final plan = workoutPlanProvider.plans.firstWhere(
                        (p) => p.id == value,
                      );
                      planNameController.text = plan.planName;
                      isForMe = plan.assignedTo == null;
                      studentUsernameController.text = plan.assignedTo ?? '';
                      _loadExercisesForDay(plan.day); // لود تمرینات روز برنامه
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('For Me', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: !isForMe,
                    onChanged: (value) {
                      setState(() {
                        isForMe = !value;
                        if (isForMe) studentUsernameController.clear();
                      });
                    },
                    activeColor: Colors.yellowAccent,
                  ),
                ],
              ),
              if (!isForMe)
                TextFormField(
                  controller: studentUsernameController,
                  decoration: InputDecoration(
                    labelText: 'Student Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.yellowAccent),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              const SizedBox(height: 20),
              if (selectedPlan == null)
                ElevatedButton(
                  onPressed: _savePlan,
                  child: const Text(
                    'Save Program',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ...days.asMap().entries.map((entry) {
                int index = entry.key;
                var day = entry.value;
                return Card(
                  color: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day['day'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...day['exercises'].asMap().entries.map((
                          exerciseEntry,
                        ) {
                          int exIndex = exerciseEntry.key;
                          var exercise = exerciseEntry.value;
                          return Column(
                            children: [
                              // دراپ‌داون با سرچ برای انتخاب تمرین از دیتابیس
                              DropdownButtonFormField<String>(
                                value: exercise['exerciseId'],
                                decoration: InputDecoration(
                                  labelText: 'Exercise',
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
                                items:
                                    Provider.of<ExerciseProvider>(
                                      context,
                                      listen: false,
                                    ).coachExercises.map((exercise) {
                                      return DropdownMenuItem<String>(
                                        value: exercise['id'],
                                        child: Text(
                                          '${exercise['name']} (${exercise['counting_type'] ?? 'تعداد'})',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    days[index]['exercises'][exIndex]['exerciseId'] =
                                        value;
                                    final selectedExercise =
                                        Provider.of<ExerciseProvider>(
                                          context,
                                          listen: false,
                                        ).coachExercises.firstWhere(
                                          (e) => e['id'] == value,
                                        );
                                    days[index]['exercises'][exIndex]['countingType'] =
                                        selectedExercise['counting_type'] ??
                                        'تعداد';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: exercise['sets'],
                                      decoration: InputDecoration(
                                        labelText: 'Sets',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          days[index]['exercises'][exIndex]['sets'] =
                                              value ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: exercise['reps'],
                                      decoration: InputDecoration(
                                        labelText: 'Reps',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          days[index]['exercises'][exIndex]['reps'] =
                                              value ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _addExercise(index),
                          child: const Text(
                            '+ Add Exercise',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _saveDay(index),
                          child: const Text(
                            'Save Day',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addNewDay,
                child: const Text(
                  '+ Add Day',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
