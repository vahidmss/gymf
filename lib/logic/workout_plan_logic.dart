import 'package:flutter/widgets.dart';
import 'package:gymf/providers/exercise_provider.dart';

List<Map<String, dynamic>> getExercises(
  ExerciseProvider provider,
  String? selectedCategory,
  String? selectedMuscle,
  TextEditingController searchController,
) {
  if (selectedCategory == null) return [];
  final filtered =
      provider.coachExercises.where((exercise) {
        if (selectedMuscle != null && selectedCategory == 'قدرتی') {
          return exercise['category'] == selectedCategory &&
              exercise['target_muscle'] == selectedMuscle;
        }
        return exercise['category'] == selectedCategory;
      }).toList();
  return filtered.where((exercise) {
    final name = exercise['name'].toString().toLowerCase();
    final search = searchController.text.toLowerCase();
    return search.isEmpty || name.contains(search);
  }).toList();
}
