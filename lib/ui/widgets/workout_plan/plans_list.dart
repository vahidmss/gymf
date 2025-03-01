import 'package:flutter/material.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/ui/widgets/workout_plan/plan_card.dart';

class PlansList extends StatelessWidget {
  final WorkoutPlanProvider workoutPlanProvider;
  final AuthProvider authProvider;

  const PlansList({
    super.key,
    required this.workoutPlanProvider,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: workoutPlanProvider.plans.length,
      itemBuilder: (context, index) {
        final plan = workoutPlanProvider.plans[index];
        return PlanCard(
          plan: plan,
          workoutPlanProvider: workoutPlanProvider,
          authProvider: authProvider,
        );
      },
    );
  }
}
