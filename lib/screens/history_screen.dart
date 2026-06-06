import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme/app_colors.dart';
import '../models/workout_model.dart';
import '../providers/workout_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedHistoryDateProvider);
    final allWorkouts = ref.watch(userWorkoutsProvider);
    final dayWorkouts = ref.watch(workoutsForDayProvider(selectedDate));
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      body: ScreenPadding(
        child: ListView(
          children: [
            Text('History', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 18),
            allWorkouts.when(
              data: (items) => _Calendar(
                workouts: items,
                selectedDate: selectedDate,
                onSelected: (date) {
                  ref.read(selectedHistoryDateProvider.notifier).state =
                      DateTime(date.year, date.month, date.day);
                },
              ),
              loading: () => const FitCard(
                child: SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) => Text(
                'Calendar could not load. $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Strength', 'Cardio', 'HIIT'].map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(type),
                      selected: filter == type,
                      onSelected: (_) {
                        ref.read(historyFilterProvider.notifier).state = type;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: DateFormat.yMMMMd().format(selectedDate)),
            const SizedBox(height: 12),
            dayWorkouts.when(
              data: (items) {
                final filtered = filter == 'All'
                    ? items
                    : items.where((workout) => workout.type == filter).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.calendar_month,
                    title: 'No workouts on this day',
                    message: 'Pick another date or start a workout today.',
                  );
                }
                return Column(
                  children: filtered
                      .map(
                        (workout) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HistoryCard(workout: workout),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Daily workouts could not load. $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.workouts,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<WorkoutModel> workouts;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      child: TableCalendar<WorkoutModel>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, selectedDate),
        eventLoader: (day) => workouts.where((workout) {
          final completed = DateTime(
            workout.completedAt.year,
            workout.completedAt.month,
            workout.completedAt.day,
          );
          return completed == DateTime(day.year, day.month, day.day);
        }).toList(),
        onDaySelected: (selected, focused) => onSelected(selected),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.textSecondary),
          weekendStyle: TextStyle(color: AppColors.textSecondary),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
          todayDecoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.workout});

  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.done, color: AppColors.primary),
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
                const SizedBox(height: 5),
                Text(
                  '${workout.type} • ${(workout.durationSeconds / 60).round()} min',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            DateFormat.Hm().format(workout.completedAt),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
