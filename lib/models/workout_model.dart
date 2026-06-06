import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_model.dart';

class WorkoutCategory {
  const WorkoutCategory({
    required this.type,
    required this.name,
    required this.description,
    required this.exercises,
    required this.estimatedCalories,
  });

  final String type;
  final String name;
  final String description;
  final List<ExerciseModel> exercises;
  final int estimatedCalories;
}

class WorkoutModel {
  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.exercises,
    required this.xpEarned,
    required this.completedAt,
  });

  factory WorkoutModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawExercises = data['exercises'] as List<dynamic>? ?? <dynamic>[];
    return WorkoutModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? 'Strength',
      name: data['name'] as String? ?? 'Completed workout',
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      caloriesBurned: data['caloriesBurned'] as int? ?? 0,
      exercises: rawExercises
          .whereType<Map<String, dynamic>>()
          .map(ExerciseModel.fromMap)
          .toList(),
      xpEarned: data['xpEarned'] as int? ?? 0,
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String type;
  final String name;
  final int durationSeconds;
  final int caloriesBurned;
  final List<ExerciseModel> exercises;
  final int xpEarned;
  final DateTime completedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'name': name,
      'durationSeconds': durationSeconds,
      'caloriesBurned': caloriesBurned,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'xpEarned': xpEarned,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}

class WorkoutResult {
  const WorkoutResult({
    required this.category,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.xpEarned,
    required this.exercisesDone,
  });

  final WorkoutCategory category;
  final int durationSeconds;
  final int caloriesBurned;
  final int xpEarned;
  final int exercisesDone;
}
