import 'package:flutter/material.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:provider/provider.dart';

class EditExerciseScreen extends StatefulWidget {
  final ExerciseModel exercise;

  const EditExerciseScreen({super.key, required this.exercise});

  @override
  _EditExerciseScreenState createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends State<EditExerciseScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  String? selectedCountingType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.exercise.name);
    descriptionController = TextEditingController(
      text: widget.exercise.description ?? '',
    );
    selectedCountingType = widget.exercise.countingType;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش تمرین')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم تمرین'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات (اختیاری)',
                hintMaxLines: 3,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedCountingType,
              decoration: const InputDecoration(labelText: 'نوع شمارش'),
              items: const [
                DropdownMenuItem(value: 'وزن (kg)', child: Text('وزن (kg)')),
                DropdownMenuItem(value: 'تایم', child: Text('تایم')),
                DropdownMenuItem(value: 'تعداد', child: Text('تعداد')),
              ],
              onChanged: (value) {
                setState(() => selectedCountingType = value);
                exerciseProvider.setCountingType(value);
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final updates = {
                  'name': nameController.text,
                  'category': widget.exercise.category,
                  'target_muscle': widget.exercise.targetMuscle,
                  'counting_type': selectedCountingType,
                };
                await exerciseProvider.updateExercise(
                  widget.exercise.id,
                  updates,
                );
                Navigator.pop(context);
              },
              child: const Text('ذخیره تغییرات'),
            ),
          ],
        ),
      ),
    );
  }
}
