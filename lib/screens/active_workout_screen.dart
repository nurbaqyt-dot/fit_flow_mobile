import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/exercise_model.dart';
import '../providers/workout_provider.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.type});

  final String type;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final _startedAt = DateTime.now();
  Timer? _timer;
  int _exerciseIndex = 0;
  int _set = 1;
  int _reps = 0;
  int _restRemaining = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.9,
      upperBound: 1.08,
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining > 0) {
        setState(() => _restRemaining--);
      } else if (_restRemaining == 0 && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _nextSet(ExerciseModel exercise) {
    setState(() {
      if (_set < exercise.sets) {
        _set++;
        _reps = 0;
        _restRemaining = exercise.restSeconds;
      } else {
        _set = 1;
        _reps = 0;
        _restRemaining = 0;
        if (_exerciseIndex <
            ref
                    .read(workoutCategoriesProvider)
                    .firstWhere((item) => item.type == widget.type)
                    .exercises
                    .length -
                1) {
          _exerciseIndex++;
        }
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final category = ref
        .read(workoutCategoriesProvider)
        .firstWhere((item) => item.type == widget.type);
    final duration = DateTime.now()
        .difference(_startedAt)
        .inSeconds
        .clamp(60, 7200);
    try {
      final result = await ref
          .read(workoutRepositoryProvider)
          .completeWorkout(category: category, durationSeconds: duration);
      if (mounted) context.go('/workout-summary', extra: result);
    } catch (error) {
      if (mounted) showFitSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = ref
        .watch(workoutCategoriesProvider)
        .firstWhere((item) => item.type == widget.type);
    final exercise = category.exercises[_exerciseIndex];
    final progress =
        (_exerciseIndex + (_set - 1) / exercise.sets) /
        category.exercises.length;

    return Scaffold(
      appBar: AppBar(title: Text(category.type)),
      body: ScreenPadding(
        child: ListView(
          children: [
            FitCard(
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(34),
                      ),
                      child: Icon(
                        AppConstants.workoutIcon(category.type),
                        color: Colors.black,
                        size: 58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    exercise.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Set $_set of ${exercise.sets}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppColors.secondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FitCard(
              child: Column(
                children: [
                  const Text(
                    'Reps completed',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => setState(() {
                          if (_reps > 0) _reps--;
                        }),
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 104,
                        child: Text(
                          '$_reps',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => setState(() => _reps++),
                        icon: const Icon(Icons.add, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Target: ${exercise.reps} reps',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FitCard(
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.primary, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _restRemaining > 0 ? 'Rest timer' : 'Ready for work',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _restRemaining > 0
                              ? '$_restRemaining seconds remaining'
                              : 'Complete the set when your reps are done.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _restRemaining > 0 ? '$_restRemaining' : 'Go',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FitButton(
              label:
                  _set == exercise.sets &&
                      _exerciseIndex == category.exercises.length - 1
                  ? 'Complete Last Set'
                  : 'Complete Set',
              icon: Icons.check,
              onPressed: _restRemaining > 0 ? null : () => _nextSet(exercise),
            ),
            const SizedBox(height: 12),
            FitButton(
              label: 'Finish Workout',
              icon: Icons.flag,
              onPressed: _finish,
              isLoading: _saving,
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }
}
