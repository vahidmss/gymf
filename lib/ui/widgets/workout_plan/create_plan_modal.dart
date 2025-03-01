import 'package:flutter/material.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';

class CreatePlanModal extends StatefulWidget {
  final AuthProvider authProvider;
  final WorkoutPlanProvider workoutPlanProvider;
  final Function(String) onPlanCreated;

  const CreatePlanModal({
    super.key,
    required this.authProvider,
    required this.workoutPlanProvider,
    required this.onPlanCreated,
  });

  @override
  _CreatePlanModalState createState() => _CreatePlanModalState();
}

class _CreatePlanModalState extends State<CreatePlanModal> {
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  String? selectedFor;

  @override
  void dispose() {
    planNameController.dispose();
    studentUsernameController.dispose();
    super.dispose();
  }

  void _submitPlan() async {
    if (planNameController.text.trim().isEmpty ||
        (selectedFor == 'شاگرد' &&
            studentUsernameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً همه فیلدهای ضروری را پر کنید!')),
      );
      return;
    }

    try {
      await widget.workoutPlanProvider.createPlan(
        userId: widget.authProvider.currentUser!.userId,
        planName: planNameController.text.trim(),
        day: 'روز ۱',
        assignedToUsername:
            selectedFor == 'شاگرد'
                ? studentUsernameController.text.trim()
                : null,
        username: widget.authProvider.currentUser!.username,
        role: widget.authProvider.currentUser!.role,
        exercises: [],
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('برنامه با موفقیت ثبت شد!')));

      widget.onPlanCreated(widget.workoutPlanProvider.plans.last.id);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
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
            CustomTextField(
              controller: planNameController,
              label: 'اسم برنامه',
              validator:
                  (value) =>
                      value == null || value.trim().isEmpty
                          ? 'اسم برنامه نمی‌تواند خالی باشد!'
                          : null,
            ),
            const SizedBox(height: 20),
            if (widget.authProvider.currentUser!.role == 'coach')
              DropdownButtonFormField<String>(
                value: selectedFor,
                decoration: InputDecoration(
                  labelText: 'برنامه برای',
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
                  DropdownMenuItem(value: 'خودم', child: Text('خودم')),
                  DropdownMenuItem(value: 'شاگرد', child: Text('شاگرد')),
                ],
                onChanged:
                    (value) => setState(() {
                      selectedFor = value;
                      studentUsernameController.clear();
                    }),
              ),
            const SizedBox(height: 20),
            if (selectedFor == 'شاگرد')
              CustomTextField(
                controller: studentUsernameController,
                label: 'یوزرنیم شاگرد',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'یوزرنیم شاگرد نمی‌تواند خالی باشد!'
                            : null,
              ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'ثبت برنامه',
              onPressed: _submitPlan,
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
