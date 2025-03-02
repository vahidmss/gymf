import 'package:flutter/material.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:google_fonts/google_fonts.dart'; // برای فونت‌ها

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  _WorkoutPlanScreenState createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen>
    with SingleTickerProviderStateMixin {
  String? selectedPlan; // برنامه انتخاب‌شده
  bool isForMe = true; // برای خودم یا شریک
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  List<Map<String, dynamic>> days = [
    {'day': 'روز 1', 'exercises': []}, // تغییر به "روز 1" (فارسی)
  ];
  List<dynamic> exercisesForDay = []; // لیست تمرینات هر روز
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    planNameController.dispose();
    studentUsernameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser(); // مطمئن شدن که کاربر لود شده
    if (authProvider.currentUser != null) {
      final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
        context,
        listen: false,
      );
      final exerciseProvider = Provider.of<ExerciseProvider>(
        context,
        listen: false,
      );
      await workoutPlanProvider.fetchPlans(authProvider.currentUser!.userId);
      final coachUsername =
          authProvider.currentUser!.username ?? 'default_coach';
      await exerciseProvider.fetchCoachExercises(coachUsername);

      if (workoutPlanProvider.plans.isEmpty) {
        setState(() {
          selectedPlan = null;
        });
      } else {
        setState(() {
          selectedPlan = workoutPlanProvider.plans.first.id;
        });
        _loadExercisesForDay('روز 1'); // تغییر به "روز 1" (فارسی)
        _animationController.forward();
      }
    }
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
      _animationController.forward(from: 0);
    });
  }

  void _addNewDay() {
    setState(() {
      days.add({
        'day': 'روز ${days.length + 1}',
        'exercises': [],
      }); // تغییر به "روز" (فارسی)
      _animationController.forward(from: 0);
    });
  }

  Future<void> _savePlan() async {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (planNameController.text.trim().isEmpty) {
      _showSnackBar('لطفاً اسم برنامه را وارد کنید!');
      return;
    }

    String? assignedToUsername =
        !isForMe ? studentUsernameController.text : null;
    String? assignedToId = null;

    if (assignedToUsername != null && assignedToUsername.isNotEmpty) {
      assignedToId = await workoutPlanProvider.getUserIdByUsername(
        assignedToUsername,
      );
      if (assignedToId == null) {
        _showSnackBar('یوزرنیم شریک پیدا نشد!');
        return;
      }
    }

    final plan = WorkoutPlanModel(
      userId: authProvider.currentUser!.userId,
      planName: planNameController.text.trim(),
      username: authProvider.currentUser!.username,
      role: authProvider.currentUser!.role,
      assignedTo: assignedToId,
      day: days.first['day'], // روز پیش‌فرض "روز 1"
    );

    // Ensure exercisesForDay is cast to List<WorkoutExerciseModel>
    await workoutPlanProvider.createPlan(
      userId: authProvider.currentUser!.userId,
      planName: planNameController.text.trim(),
      day: days.first['day'], // روز پیش‌فرض "روز 1"
      assignedToUsername: assignedToUsername,
      username: authProvider.currentUser!.username,
      role: authProvider.currentUser!.role,
      exercises: exercisesForDay.cast<WorkoutExerciseModel>(), // Explicit cast
    );

    setState(() {
      selectedPlan = workoutPlanProvider.plans.last.id;
    });

    _showSnackBar('برنامه با موفقیت ثبت شد!');
  }

  Future<void> _saveDay(int dayIndex) async {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );

    if (selectedPlan != null) {
      try {
        final plan = workoutPlanProvider.plans.firstWhere(
          (p) => p.id == selectedPlan,
        );
        final day = days[dayIndex]['day'];

        // Convert exercises to WorkoutExerciseModel
        final exercises =
            days[dayIndex]['exercises']
                .map((exercise) {
                  if (exercise['exerciseId'] == null ||
                      exercise['sets'].toString().isEmpty ||
                      exercise['reps'].toString().isEmpty) {
                    throw Exception('فیلدها خالی هستند.');
                  }

                  return WorkoutExerciseModel(
                    planId: selectedPlan!,
                    exerciseId: exercise['exerciseId'].toString(),
                    sets: int.tryParse(exercise['sets']) ?? 0,
                    reps: int.tryParse(exercise['reps']) ?? 0,
                    countingType: exercise['countingType'] ?? 'تعداد',
                    duration: null,
                    notes: '',
                    createdAt: DateTime.now(),
                  );
                })
                .toList()
                .cast<
                  WorkoutExerciseModel
                >(); // Explicitly cast to List<WorkoutExerciseModel>

        // Update the plan with the new exercises
        await workoutPlanProvider.updatePlan(
          plan.copyWith(day: day),
          exercises,
        );

        setState(() {
          exercisesForDay = exercises; // Ensure exercisesForDay is also updated
        });

        _showSnackBar('روز با موفقیت ثبت شد!');
      } catch (e) {
        _showSnackBar(e.toString());
      }
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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
        title: Text(
          'Workout Planner',
          style: GoogleFonts.poppins(
            color: Colors.yellowAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.yellowAccent),
            onPressed: () {
              // منطق تنظیمات (اختیاری)
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.deepPurple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.8],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _animation,
                      child: DropdownButtonFormField<String?>(
                        value: selectedPlan,
                        decoration: InputDecoration(
                          labelText: 'Programs',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.yellowAccent),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.yellowAccent,
                            fontSize: 16,
                          ),
                        ),
                        dropdownColor: Colors.black87,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        iconEnabledColor: Colors.yellowAccent,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...workoutPlanProvider.plans.map(
                            (plan) => DropdownMenuItem<String?>(
                              value: plan.id,
                              child: Text(
                                plan.planName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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
                              ];
                              exercisesForDay.clear();
                            } else {
                              final plan = workoutPlanProvider.plans.firstWhere(
                                (p) => p.id == value,
                              );
                              planNameController.text = plan.planName;
                              isForMe = plan.assignedTo == null;
                              studentUsernameController.text =
                                  plan.assignedTo ?? '';
                              _loadExercisesForDay(plan.day);
                              _animationController.forward(from: 0);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _animation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'For Me',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: !isForMe,
                            onChanged: (value) {
                              setState(() {
                                isForMe = !value;
                                if (isForMe) studentUsernameController.clear();
                                _animationController.forward(from: 0);
                              });
                            },
                            activeColor: Colors.yellowAccent,
                            activeTrackColor: Colors.yellowAccent.withOpacity(
                              0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isForMe)
                      FadeTransition(
                        opacity: _animation,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: TextFormField(
                            controller: studentUsernameController,
                            decoration: InputDecoration(
                              labelText: 'Student Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.yellowAccent,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.yellowAccent,
                                fontSize: 16,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (selectedPlan == null)
                      FadeTransition(
                        opacity: _animation,
                        child: ElevatedButton(
                          onPressed: _savePlan,
                          child: Text(
                            'Save Program',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            elevation: 8,
                            shadowColor: Colors.yellowAccent.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ...days.asMap().entries.map((entry) {
                      int index = entry.key;
                      var day = entry.value;
                      return FadeTransition(
                        opacity: _animation,
                        child: Card(
                          color: Colors.grey.shade900.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.yellowAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      day['day'],
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.expand_more,
                                        color: Colors.yellowAccent,
                                      ),
                                      onPressed: () {
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                ...day['exercises'].asMap().entries.map((
                                  exerciseEntry,
                                ) {
                                  int exIndex = exerciseEntry.key;
                                  var exercise = exerciseEntry.value;
                                  return FadeTransition(
                                    opacity: _animation,
                                    child: Column(
                                      children: [
                                        DropdownButtonFormField<String?>(
                                          value: exercise['exerciseId'],
                                          decoration: InputDecoration(
                                            labelText: 'Exercise',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.yellowAccent,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            labelStyle: GoogleFonts.poppins(
                                              color: Colors.yellowAccent,
                                              fontSize: 16,
                                            ),
                                          ),
                                          dropdownColor: Colors.black87,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          iconEnabledColor: Colors.yellowAccent,
                                          items:
                                              exerciseProvider.coachExercises.map((
                                                exercise,
                                              ) {
                                                return DropdownMenuItem<
                                                  String?
                                                >(
                                                  value: exercise['id'],
                                                  child: Text(
                                                    '${exercise['name']} (${exercise['counting_type'] ?? 'تعداد'})',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              days[index]['exercises'][exIndex]['exerciseId'] =
                                                  value;
                                              final selectedExercise =
                                                  exerciseProvider
                                                      .coachExercises
                                                      .firstWhere(
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
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.yellowAccent,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white
                                                      .withOpacity(0.1),
                                                  labelStyle:
                                                      GoogleFonts.poppins(
                                                        color:
                                                            Colors.yellowAccent,
                                                        fontSize: 16,
                                                      ),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
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
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Colors.yellowAccent,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white
                                                      .withOpacity(0.1),
                                                  labelStyle:
                                                      GoogleFonts.poppins(
                                                        color:
                                                            Colors.yellowAccent,
                                                        fontSize: 16,
                                                      ),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
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
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                                FadeTransition(
                                  opacity: _animation,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _addExercise(index),
                                        child: Text(
                                          '+ Add Exercise',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.yellowAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 20,
                                          ),
                                          elevation: 8,
                                          shadowColor: Colors.yellowAccent
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _saveDay(index),
                                        child: Text(
                                          'Save Day',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.yellowAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 20,
                                          ),
                                          elevation: 8,
                                          shadowColor: Colors.yellowAccent
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _animation,
                      child: ElevatedButton(
                        onPressed: _addNewDay,
                        child: Text(
                          '+ Add Day',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          elevation: 8,
                          shadowColor: Colors.yellowAccent.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
