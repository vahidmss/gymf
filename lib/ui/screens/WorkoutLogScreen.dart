import 'package:flutter/material.dart';
import 'package:gymf/core/services/WorkoutLogService.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:provider/provider.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  _WorkoutLogScreenState createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  WorkoutPlanModel? _selectedPlan;
  String? _selectedDay;
  final Map<String, Map<String, dynamic>> _exerciseLogs =
      {}; // برای ذخیره لاگ‌های موقت تمرین‌ها
  final WorkoutLogService _workoutLogService =
      WorkoutLogService(); // تعریف نمونه
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // بارگذاری برنامه‌های اولیه از Provider
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
      context,
      listen: false,
    );
    if (workoutPlanProvider.plans.isNotEmpty) {
      _selectedPlan = workoutPlanProvider.plans.first;
      _selectedDay =
          _selectedPlan
              ?.days
              .first
              .dayName; // انتخاب اولین روز به‌عنوان پیش‌فرض
    }
  }

  void _saveExerciseLog(
    String exerciseId,
    String value,
    String countingType,
    String? notes,
  ) {
    if (_selectedPlan == null || _selectedDay == null) return;

    final logKey = _uuid.v4(); // یه شناسه منحصربه‌فرد برای هر لاگ
    _exerciseLogs[logKey] = {
      'id': logKey,
      'exerciseId': exerciseId,
      'value': value,
      'countingType': countingType,
      'notes': notes, // نکات (اختیاری)
      'planId': _selectedPlan!.id,
      'day': _selectedDay!,
    };
    setState(() {});
  }

  Future<void> _saveAllLogs() async {
    if (_selectedPlan == null ||
        _selectedDay == null ||
        _exerciseLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هیچ لاگی برای ذخیره وجود ندارد!')),
      );
      return;
    }

    try {
      await _workoutLogService.saveWorkoutLogs(
        _selectedPlan!.id,
        _selectedDay!,
        _exerciseLogs.values.toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمرینات با موفقیت ثبت شدند!')),
      );
      _exerciseLogs.clear(); // پاک کردن لاگ‌های موقت بعد از ذخیره
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ثبت تمرینات: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(context);

    // اگر برنامه‌ای وجود نداشته باشه، پیام خطا نشون بده
    if (workoutPlanProvider.plans.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'هیچ برنامه تمرینی وجود ندارد!',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'ثبت تمرینات روزانه',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // منوی کشویی برای انتخاب برنامه
            DropdownButtonFormField<WorkoutPlanModel>(
              decoration: InputDecoration(
                labelText: 'انتخاب برنامه',
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              value: _selectedPlan,
              items:
                  workoutPlanProvider.plans.map((plan) {
                    return DropdownMenuItem<WorkoutPlanModel>(
                      value: plan,
                      child: Text(
                        plan.planName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlan = value;
                  _selectedDay =
                      value?.days.first.dayName; // انتخاب اولین روز برنامه
                  _exerciseLogs.clear(); // پاک کردن لاگ‌های قبلی
                });
              },
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // منوی کشویی برای انتخاب روز
            if (_selectedPlan != null)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'انتخاب روز',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                value: _selectedDay,
                items:
                    _selectedPlan!.days.map((day) {
                      return DropdownMenuItem<String>(
                        value: day.dayName,
                        child: Text(
                          day.dayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value;
                    _exerciseLogs
                        .clear(); // پاک کردن لاگ‌های قبلی وقتی روز عوض می‌شه
                  });
                },
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 16),
            // لیست تمرینات
            if (_selectedPlan != null && _selectedDay != null)
              Expanded(child: _buildExerciseList(workoutPlanProvider))
            else
              const Center(
                child: Text(
                  'لطفاً برنامه و روز را انتخاب کنید!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            // دکمه ذخیره کل تمرینات
            if (_selectedPlan != null && _selectedDay != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _saveAllLogs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'ذخیره کل تمرینات',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ).animate().scale(duration: 200.ms), // انیمیشن شیک برای دکمه
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(WorkoutPlanProvider workoutPlanProvider) {
    if (_selectedPlan == null || _selectedDay == null) {
      return const Center(
        child: Text(
          'لطفاً برنامه و روز را انتخاب کنید!',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final exercises =
        _selectedPlan!.days
            .firstWhere((day) => day.dayName == _selectedDay)
            .exercises;

    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    final log = _exerciseLogs.values.firstWhere(
      (log) => log['exerciseId'] == exercise.exerciseId,
      orElse: () => {},
    );
    final TextEditingController valueController = TextEditingController(
      text: log['value']?.toString() ?? '',
    );
    final TextEditingController notesController = TextEditingController(
      text: log['notes']?.toString() ?? '',
    );

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نوع: ${exercise.countingType}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'ست‌ها: ${exercise.sets}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      if (exercise.reps != null)
                        Text(
                          'تکرارها: ${exercise.reps}',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      if (exercise.duration != null)
                        Text(
                          'مدت زمان: ${exercise.duration} ثانیه',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      hintText: _getHintText(exercise.countingType),
                      hintStyle: TextStyle(color: Colors.white70),
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
                      if (value.isNotEmpty) {
                        _saveExerciseLog(
                          exercise.exerciseId,
                          value,
                          exercise.countingType,
                          notesController.text.isEmpty
                              ? null
                              : notesController.text,
                        );
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _exerciseLogs.removeWhere(
                        (key, log) => log['exerciseId'] == exercise.exerciseId,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'یادداشت‌ها (اختیاری)',
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                _saveExerciseLog(
                  exercise.exerciseId,
                  valueController.text,
                  exercise.countingType,
                  value.isEmpty ? null : value,
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  String _getHintText(String countingType) {
    switch (countingType) {
      case 'وزن (kg)':
        return 'وزن (kg)';
      case 'تعداد':
        return 'تکرار';
      case 'تایم':
        return 'زمان (ثانیه)';
      default:
        return 'مقدار';
    }
  }
}
