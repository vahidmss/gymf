import 'package:flutter/material.dart';
import 'package:gymf/data/models/workout_plan_model.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';

class PlanCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final WorkoutPlanProvider workoutPlanProvider;
  final AuthProvider authProvider;

  const PlanCard({
    super.key,
    required this.plan,
    required this.workoutPlanProvider,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        title: Text(
          plan.planName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(plan.day, style: const TextStyle(color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (authProvider.currentUser!.role == 'coach')
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.yellowAccent),
                onPressed:
                    () => _showEditPlanModal(
                      context,
                      plan,
                      authProvider,
                      workoutPlanProvider,
                    ),
              ),
            if (authProvider.currentUser!.role == 'coach')
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed:
                    () => _deletePlan(context, plan.id, workoutPlanProvider),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanModal(
    BuildContext context,
    WorkoutPlanModel plan,
    AuthProvider authProvider,
    WorkoutPlanProvider provider,
  ) {
    final TextEditingController planNameController = TextEditingController(
      text: plan.planName,
    );
    final TextEditingController studentUsernameController =
        TextEditingController(text: plan.assignedTo ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: planNameController,
                  label: 'اسم برنامه',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم برنامه نمی‌تونه خالی باشه!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (authProvider.currentUser!.role == 'coach')
                  CustomTextField(
                    controller: studentUsernameController,
                    label: 'یوزرنیم شaگرد (اختیاری)',
                  ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'ذخیره تغییرات',
                  onPressed: () {
                    final updatedPlan = plan.copyWith(
                      planName: planNameController.text,
                      assignedTo:
                          studentUsernameController.text.isEmpty
                              ? null
                              : studentUsernameController.text,
                    );
                    provider
                        .updatePlan(updatedPlan, [])
                        .then((_) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('برنامه با موفقیت ویرایش شد!'),
                            ),
                          );
                        })
                        .catchError((e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('خطا: $e')));
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
      },
    );
  }

  void _deletePlan(
    BuildContext context,
    String planId,
    WorkoutPlanProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'حذف برنامه',
            style: TextStyle(color: Colors.yellowAccent),
          ),
          content: const Text(
            'مطمئنی می‌خوای این برنامه رو حذف کنی؟',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await provider.deletePlan(planId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برنامه حذف شد!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('خطا: $e')));
                }
              },
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
