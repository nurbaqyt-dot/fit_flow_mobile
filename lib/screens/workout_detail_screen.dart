import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/workout_model.dart';
import '../providers/workout_provider.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref
        .watch(workoutCategoriesProvider)
        .firstWhere((item) => item.type == type);
    return Scaffold(
      appBar: AppBar(title: Text(category.type)),
      body: ScreenPadding(
        child: ListView(
          children: [
            FitCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppConstants.workoutIcon(category.type),
                    color: AppColors.primary,
                    size: 42,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Exercises'),
            const SizedBox(height: 12),
            ...category.exercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FitCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${exercise.sets} sets x ${exercise.reps} reps',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${exercise.restSeconds}s rest',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            FitButton(
              label: 'Start',
              icon: Icons.play_arrow,
              onPressed: () => context.go('/workouts/${category.type}/active'),
            ),
          ],
        ),
      ),
    );
  }
}

WorkoutCategory categoryForType(List<WorkoutCategory> categories, String type) {
  return categories.firstWhere((item) => item.type == type);
}
