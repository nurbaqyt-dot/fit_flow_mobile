import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/workout_provider.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class WorkoutPickerScreen extends ConsumerWidget {
  const WorkoutPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(workoutCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a workout')),
      body: ScreenPadding(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return FitCard(
              onTap: () => context.go('/workouts/${category.type}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      AppConstants.workoutIcon(category.type),
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.type,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${category.exercises.length} exercises',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
