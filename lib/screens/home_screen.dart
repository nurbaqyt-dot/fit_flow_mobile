import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../providers/feed_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import '../widgets/user_avatar.dart';
import 'screen_helpers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider);
    final recent = ref.watch(recentWorkoutsProvider);
    final workouts = ref.watch(userWorkoutsProvider);
    final feed = ref.watch(latestFeedPostsProvider);
    final today = DateTime.now();
    final todayWorkouts = ref.watch(
      workoutsForDayProvider(DateTime(today.year, today.month, today.day)),
    );

    return Scaffold(
      body: ScreenPadding(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(recentWorkoutsProvider);
            ref.invalidate(userWorkoutsProvider);
            ref.invalidate(latestFeedPostsProvider);
          },
          child: ListView(
            children: [
              profile.when(
                data: (user) => _Greeting(user: user),
                loading: () => const SizedBox(
                  height: 72,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  'Profile could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 22),
              todayWorkouts.when(
                data: (items) => _TodayStats(workouts: items),
                loading: () => const FitCard(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(
                  'Today stats could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 18),
              FitButton(
                label: 'Start Workout',
                icon: Icons.play_arrow,
                onPressed: () => context.go('/workouts'),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Recent workouts'),
              const SizedBox(height: 12),
              recent.when(
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        icon: Icons.fitness_center,
                        title: 'No workouts yet',
                        message:
                            'Start a workout to build your first training log.',
                      )
                    : Column(
                        children: items
                            .map(
                              (workout) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _WorkoutRow(workout: workout),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  'Recent workouts could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Weekly activity'),
              const SizedBox(height: 12),
              workouts.when(
                data: (items) => _WeeklyChart(workouts: items),
                loading: () => const FitCard(
                  child: SizedBox(
                    height: 210,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Text(
                  'Weekly activity could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Community',
                trailing: TextButton(
                  onPressed: () => context.go('/feed'),
                  child: const Text('View all'),
                ),
              ),
              const SizedBox(height: 12),
              feed.when(
                data: (posts) => posts.isEmpty
                    ? const EmptyState(
                        icon: Icons.groups,
                        title: 'Community is warming up',
                        message: 'Share your next workout and start the feed.',
                      )
                    : Column(
                        children: posts
                            .map(
                              (post) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MiniPost(post: post),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  'Community posts could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final FitUser? user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final name = (user?.name.isNotEmpty ?? false)
        ? user!.name.split(' ').first
        : 'Athlete';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name 💪',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Your next session is ready when you are.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        UserAvatar(photoUrl: user?.photoUrl ?? '', name: name, size: 54),
      ],
    );
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats({required this.workouts});

  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    final calories = workouts.fold<int>(
      0,
      (total, workout) => total + workout.caloriesBurned,
    );
    final minutes = workouts.fold<int>(
      0,
      (total, workout) => total + (workout.durationSeconds / 60).round(),
    );
    final steps = minutes * 110;
    return FitCard(
      child: Row(
        children: [
          _Stat(label: 'Steps', value: NumberFormat.compact().format(steps)),
          _Divider(),
          _Stat(label: 'Calories', value: '$calories'),
          _Divider(),
          _Stat(label: 'Active min', value: '$minutes'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 42,
      child: VerticalDivider(color: AppColors.secondary),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout});

  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.check_circle, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${workout.type} • ${(workout.durationSeconds / 60).round()} min • ${DateFormat.MMMd().format(workout.completedAt)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+${workout.xpEarned} XP',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.workouts});

  final List<WorkoutModel> workouts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = DateTime(
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
      final index = day.difference(weekStart).inDays;
      if (index >= 0 && index < 7) {
        values[index] += workout.durationSeconds / 60;
      }
    }
    final maxValue = values.fold<double>(
      30,
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
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
            ),
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

class _MiniPost extends StatelessWidget {
  const _MiniPost({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          UserAvatar(photoUrl: post.userPhoto, name: post.userName, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.workoutType} • ${post.likes.length} likes',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (post.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(post.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
