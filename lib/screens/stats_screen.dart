import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../providers/profile_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(userWorkoutsProvider);
    final profile = ref.watch(currentUserProvider);
    return Scaffold(
      body: ScreenPadding(
        child: workouts.when(
          data: (items) => ListView(
            children: [
              Text('Stats', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Weekly volume'),
              const SizedBox(height: 12),
              _VolumeChart(workouts: items),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Monthly progress'),
              const SizedBox(height: 12),
              _LineProgressChart(workouts: items),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Personal records'),
              const SizedBox(height: 12),
              _Records(workouts: items),
              const SizedBox(height: 24),
              profile.when(
                data: (user) => _Streaks(user: user, workouts: items),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  'Streaks could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Stats could not load. $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.workouts});

  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final values = List<double>.filled(7, 0);
    for (final workout in workouts) {
      final day = DateTime(
        workout.completedAt.year,
        workout.completedAt.month,
        workout.completedAt.day,
      );
      final index = day.difference(start).inDays;
      if (index >= 0 && index < 7) {
        values[index] += workout.exercises.fold<double>(
          0,
          (sum, exercise) => sum + exercise.sets * exercise.reps,
        );
      }
    }
    final maxValue = values.fold<double>(
      40,
      (max, value) => value > max ? value : max,
    );
    return FitCard(
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxValue,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: _bottomTitles(const [
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
              'S',
            ]),
            barGroups: List.generate(
              7,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    width: 18,
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineProgressChart extends StatelessWidget {
  const _LineProgressChart({required this.workouts});

  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 27);
    final values = List<double>.filled(4, 0);
    for (final workout in workouts) {
      if (workout.completedAt.isBefore(start)) continue;
      final index = (workout.completedAt.difference(start).inDays / 7).floor();
      if (index >= 0 && index < values.length) {
        values[index] += workout.caloriesBurned;
      }
    }
    final maxValue = values.fold<double>(
      200,
      (max, value) => value > max ? value : max,
    );
    return FitCard(
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxValue,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: _bottomTitles(const ['W1', 'W2', 'W3', 'W4']),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  4,
                  (index) => FlSpot(index.toDouble(), values[index]),
                ),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Records extends StatelessWidget {
  const _Records({required this.workouts});

  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    double? maxFor(String name) {
      double? maxWeight;
      for (final workout in workouts) {
        for (final exercise in workout.exercises) {
          final matches = exercise.name.toLowerCase().contains(
            name.toLowerCase(),
          );
          final weight = exercise.maxWeightKg;
          if (matches &&
              weight != null &&
              (maxWeight == null || weight > maxWeight)) {
            maxWeight = weight;
          }
        }
      }
      return maxWeight;
    }

    final records = [
      ('Bench Press', maxFor('bench')),
      ('Squat', maxFor('squat')),
      ('Deadlift', maxFor('deadlift')),
    ];
    return Column(
      children: records
          .map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FitCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record.$1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      record.$2 == null
                          ? 'No max yet'
                          : '${record.$2!.toStringAsFixed(1)} kg',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Streaks extends StatelessWidget {
  const _Streaks({required this.user, required this.workouts});

  final FitUser? user;
  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    final totalTime = workouts.fold<int>(
      0,
      (total, workout) => total + workout.durationSeconds,
    );
    final hours = (totalTime / 3600).toStringAsFixed(1);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Current streak',
                value: '${user?.currentStreak ?? 0} days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Best streak',
                value: '${user?.bestStreak ?? 0} days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total workouts',
                value: '${workouts.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(label: 'Total time', value: '$hours h'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

FlTitlesData _bottomTitles(List<String> labels) {
  return FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= labels.length) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              labels[index],
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        },
      ),
    ),
  );
}
