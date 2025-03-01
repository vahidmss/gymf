import 'package:flutter/material.dart';
import 'package:gymf/data/models/workout_exercise_model.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class ExerciseRow extends StatefulWidget {
  final WorkoutExerciseModel exercise;
  final String? countingType;
  final VoidCallback onDelete;
  final Function(WorkoutExerciseModel) onUpdate;

  const ExerciseRow({
    super.key,
    required this.exercise,
    required this.countingType,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  _ExerciseRowState createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<ExerciseRow> {
  late int sets;
  late int? repsOrDuration;
  late String? notes;
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsOrDurationController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sets = widget.exercise.sets;
    repsOrDuration = widget.exercise.reps ?? widget.exercise.duration;
    notes = widget.exercise.notes;
    setsController.text = sets.toString();
    repsOrDurationController.text = (repsOrDuration?.toString() ?? '');
    notesController.text = notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(
      context,
      listen: false,
    );
    final exercise = exerciseProvider.coachExercises.firstWhere(
      (e) => e['id'] == widget.exercise.exerciseId,
      orElse: () => {},
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${exercise['name']} (${widget.countingType})',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              'ست: $sets',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              widget.countingType == 'وزن (kg)'
                  ? 'وزن: ${repsOrDuration ?? 0}kg'
                  : widget.countingType == 'تعداد'
                  ? 'تعداد: ${repsOrDuration ?? 0}'
                  : 'زمان: ${repsOrDuration ?? 0}s',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.yellowAccent),
            onPressed: () => _showEditExerciseModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  void _showEditExerciseModal(BuildContext context) {
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
              CustomTextField(
                controller: setsController,
                label: 'تعداد ست',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'تعداد ست رو وارد کن!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: repsOrDurationController,
                label:
                    widget.countingType == 'وزن (kg)'
                        ? 'وزن (kg)'
                        : widget.countingType == 'تعداد'
                        ? 'تعداد (حرکات)'
                        : 'مدت زمان (ثانیه)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: notesController,
                label: 'توضیحات (اختیاری)',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final updatedExercise = widget.exercise.copyWith(
                  sets: int.parse(setsController.text),
                  reps:
                      widget.countingType == 'تعداد'
                          ? int.tryParse(repsOrDurationController.text)
                          : null,
                  duration:
                      widget.countingType == 'تایم'
                          ? int.tryParse(repsOrDurationController.text)
                          : null,
                  notes:
                      notesController.text.isEmpty
                          ? null
                          : notesController.text,
                );
                widget.onUpdate(updatedExercise);
                Navigator.pop(context);
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
