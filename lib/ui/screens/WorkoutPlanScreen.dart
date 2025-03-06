import 'package:flutter/material.dart';
import 'package:gymf/core/services/WorkoutPlanService.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:provider/provider.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  _WorkoutPlanScreenState createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final WorkoutPlanService _workoutPlanService = WorkoutPlanService();
  final Uuid _uuid = const Uuid();

  List<WorkoutDay> _days = [
    WorkoutDay(dayName: 'روز 1', exercises: []),
  ]; // لیست اولیه روزها
  String? _selectedAssignedToUsername; // یوزرنیم گیرنده (اختیاری)
  String? _currentUserId; // شناسه کاربر فعلی
  String? _currentUsername; // یوزرنیم کاربر فعلی
  String? _currentRole; // نقش کاربر (coach یا athlete)

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.userId;
    _currentUsername = authProvider.currentUser?.username;
    _currentRole = authProvider.currentUser?.role;
  }

  void _addDay() {
    setState(() {
      _days.add(WorkoutDay(dayName: 'روز ${_days.length + 1}', exercises: []));
    });
  }

  void _removeDay(int index) {
    if (_days.length > 1) {
      setState(() {
        _days.removeAt(index);
      });
    }
  }

  void _addExercise(int dayIndex) {
    setState(() {
      _days[dayIndex].exercises.add(
        WorkoutExercise(
          exerciseId: _uuid.v4(),
          name: 'تمرین جدید',
          sets: 3, // پیش‌فرض 3 ست
          countingType: 'وزن (kg)', // پیش‌فرض وزن
          supersetGroupId: null, // پیش‌فرض بدون سوپرست
        ),
      );
    });
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      _days[dayIndex].exercises.removeAt(exerciseIndex);
    });
  }

  void _updateExerciseSuperset(
    int dayIndex,
    int exerciseIndex,
    String? supersetGroupId,
  ) {
    setState(() {
      _days[dayIndex].exercises[exerciseIndex] = _days[dayIndex]
          .exercises[exerciseIndex]
          .copyWith(supersetGroupId: supersetGroupId);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await workoutPlanProvider.createPlan(
        userId: _currentUserId ?? '',
        planName: _planNameController.text,
        days: _days,
        assignedToUsername: _selectedAssignedToUsername,
        username: _currentUsername ?? '',
        role: _currentRole ?? 'athlete',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برنامه با موفقیت ایجاد شد!')),
      );
      _planNameController.clear();
      _notesController.clear();
      setState(() {
        _days = [WorkoutDay(dayName: 'روز 1', exercises: [])];
        _selectedAssignedToUsername = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ایجاد برنامه: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'ایجاد برنامه تمرینی',
          style: TextStyle(color: Colors.yellow, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _planNameController,
                  decoration: InputDecoration(
                    labelText: 'نام برنامه',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'نام برنامه الزامی است';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_currentRole == 'coach') // فقط برای مربی‌ها
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'یوزرنیم ورزشکار (اختیاری)',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    value: _selectedAssignedToUsername,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'هیچ‌کدام',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      // اینجا باید لیستی از یوزرنیم‌های ورزشکارها بگیری (مثلاً از AuthProvider)
                      // برای سادگی، فعلاً خالی نگه می‌دارم
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAssignedToUsername = value;
                      });
                    },
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'یادداشت‌ها (اختیاری)',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ..._days.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  return _buildDaySection(index, day);
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _addDay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'اضافه کردن روز',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _savePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'ذخیره برنامه',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(int dayIndex, WorkoutDay day) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.dayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeDay(dayIndex),
                ),
              ],
            ),
            ...day.exercises.asMap().entries.map((entry) {
              final exerciseIndex = entry.key;
              final exercise = entry.value;
              return _buildExerciseSection(dayIndex, exerciseIndex, exercise);
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _addExercise(dayIndex),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'اضافه کردن تمرین',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ).animate().scale(duration: 200.ms),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildExerciseSection(
    int dayIndex,
    int exerciseIndex,
    WorkoutExercise exercise,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: exercise.name,
                  decoration: InputDecoration(
                    labelText: 'نام تمرین',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _days[dayIndex].exercises[exerciseIndex] = exercise
                          .copyWith(name: value);
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'نوع شمارش',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  value: exercise.countingType,
                  items:
                      ['وزن (kg)', 'تعداد', 'تایم'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _days[dayIndex].exercises[exerciseIndex] = exercise
                          .copyWith(countingType: value);
                    });
                  },
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: exercise.sets.toString(),
                        decoration: InputDecoration(
                          labelText: 'تعداد ست‌ها',
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _days[dayIndex].exercises[exerciseIndex] = exercise
                                .copyWith(
                                  sets: int.tryParse(value) ?? exercise.sets,
                                );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: exercise.reps?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: 'تکرارها (اختیاری)',
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _days[dayIndex]
                                .exercises[exerciseIndex] = exercise.copyWith(
                              reps: value.isEmpty ? null : int.tryParse(value),
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: exercise.duration?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: 'مدت زمان (ثانیه، اختیاری)',
                          labelStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _days[dayIndex]
                                .exercises[exerciseIndex] = exercise.copyWith(
                              duration:
                                  value.isEmpty ? null : int.tryParse(value),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: 'گروه سوپرست (اختیاری)',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  value: exercise.supersetGroupId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'بدون سوپرست',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ...Provider.of<WorkoutPlanProvider>(
                      context,
                      listen: false,
                    ).supersetGroups.keys.map(
                      (groupId) => DropdownMenuItem<String>(
                        value: groupId,
                        child: Text(
                          'سوپرست $groupId',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _updateExerciseSuperset(dayIndex, exerciseIndex, value);
                  },
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: exercise.notes ?? '',
                  decoration: InputDecoration(
                    labelText: 'یادداشت‌ها (اختیاری)',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _days[dayIndex].exercises[exerciseIndex] = exercise
                          .copyWith(notes: value.isEmpty ? null : value);
                    });
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeExercise(dayIndex, exerciseIndex),
          ),
        ],
      ),
    );
  }
}
