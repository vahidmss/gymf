import 'package:flutter/material.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:gymf/logic/workout_plan_logic.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';
import 'package:gymf/ui/widgets/exercise_row.dart';
import 'package:flutter/scheduler.dart'; // اضافه کردن برای addPostFrameCallback
import 'package:provider/provider.dart';

class DayExercisesModal extends StatefulWidget {
  final String planId;
  final String day;
  final AuthProvider authProvider;
  final WorkoutPlanProvider workoutPlanProvider;
  final List<WorkoutExerciseModel> exercises;
  final Function(List<WorkoutExerciseModel>) onExercisesUpdated;

  const DayExercisesModal({
    super.key,
    required this.planId,
    required this.day,
    required this.authProvider,
    required this.workoutPlanProvider,
    required this.exercises,
    required this.onExercisesUpdated,
  });

  @override
  _DayExercisesModalState createState() => _DayExercisesModalState();
}

class _DayExercisesModalState extends State<DayExercisesModal> {
  List<WorkoutExerciseModel> exercises = [];
  String? selectedExerciseId;
  int? sets;
  String? countingType;
  int? repsOrDuration;
  String? notes;
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsOrDurationController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  late ExerciseProvider exerciseProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
    if (exercises.isEmpty) {
      _addNewExercise();
    }
  }

  @override
  void initState() {
    super.initState();
    exercises = List.from(widget.exercises);
  }

  void _addNewExercise() {
    final exercise =
        exerciseProvider.coachExercises.firstWhere(
              (e) => e['id'] == selectedExerciseId,
              orElse: () => {},
            )
            as Map<String, dynamic>?;
    if (exercise != null && selectedExerciseId != null && sets != null) {
      setState(() {
        exercises.add(
          WorkoutExerciseModel(
            planId: widget.planId,
            exerciseId: selectedExerciseId!,
            sets: sets!,
            countingType: exercise['counting_type'] ?? 'تعداد',
            reps: countingType == 'تعداد' ? repsOrDuration : null,
            duration: countingType == 'تایم' ? repsOrDuration : null,
            notes: notes,
            createdAt: DateTime.now(),
          ),
        );
        selectedExerciseId = null;
        sets = null;
        countingType = null;
        repsOrDuration = null;
        notes = null;
        setsController.clear();
        repsOrDurationController.clear();
        notesController.clear();
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً تمرین و تعداد ست را انتخاب/وارد کنید'),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تمرینات روز ${widget.day}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...exercises.map((exercise) {
              final selected = exerciseProvider.coachExercises.firstWhere(
                (e) => e['id'] == exercise.exerciseId,
                orElse: () => {},
              );
              return ExerciseRow(
                exercise: exercise,
                countingType: selected['counting_type'] ?? 'تعداد',
                onDelete: () {
                  setState(() {
                    exercises.remove(exercise);
                  });
                },
                onUpdate: (updatedExercise) {
                  setState(() {
                    final index = exercises.indexOf(exercise);
                    if (index != -1) {
                      exercises[index] = updatedExercise;
                    }
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 20),
            CustomButton(
              text: 'ثبت روز',
              onPressed: () {
                if (exercises.isEmpty) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('حداقل یک تمرین اضافه کن')),
                    );
                  });
                  return;
                }
                widget.workoutPlanProvider
                    .updatePlan(
                      widget.workoutPlanProvider.plans
                          .firstWhere((p) => p.id == widget.planId)
                          .copyWith(day: widget.day),
                      exercises,
                    )
                    .then((_) {
                      Navigator.pop(context);
                      widget.onExercisesUpdated(exercises);
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('روز با موفقیت ثبت شد!'),
                          ),
                        );
                      });
                    })
                    .catchError((e) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('خطا: $e')));
                      });
                    });
              },
              backgroundColor: Colors.yellowAccent,
              textColor: Colors.black,
              borderRadius: 15,
              elevation: 5,
            ),
          ],
        ),
      ),
    );
  }
}
