import 'package:flutter/material.dart';
import 'package:gymf/data/models/workout_plan_model.dart';

class PlanSelector extends StatelessWidget {
  final String? selectedPlan;
  final List<WorkoutPlanModel> plans;
  final ValueChanged<String?> onPlanChanged;

  const PlanSelector({
    super.key,
    required this.selectedPlan,
    required this.plans,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedPlan,
      isDense: true, // ظاهری جمع‌وجورتر
      menuMaxHeight: 250, // جلوگیری از بیش‌ازحد بلند شدن منو
      decoration: InputDecoration(
        labelText: 'انتخاب برنامه',
        hintText: 'یک برنامه انتخاب کنید',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.yellowAccent),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.yellowAccent,
      items:
          plans.map((plan) {
            return DropdownMenuItem<String>(
              value: plan.id,
              child: Text(
                plan.planName,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
      onChanged: onPlanChanged,
    );
  }
}
