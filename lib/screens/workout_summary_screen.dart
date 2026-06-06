import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../models/workout_model.dart';
import '../providers/feed_provider.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.result});

  final WorkoutResult result;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ref
          .read(feedRepositoryProvider)
          .createPost(
            text:
                'Finished ${widget.result.category.name} and earned ${widget.result.xpEarned} XP.',
            workoutType: widget.result.category.type,
          );
      if (mounted) {
        showFitSnack(context, 'Workout shared to your feed.');
        context.go('/feed');
      }
    } catch (error) {
      if (mounted) showFitSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (widget.result.durationSeconds / 60).round();
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(painter: _ConfettiPainter(), size: Size.infinite),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.black,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Workout complete',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '+${widget.result.xpEarned} XP',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 28),
                  FitCard(
                    child: Row(
                      children: [
                        _SummaryStat(label: 'Time', value: '$minutes min'),
                        _SummaryStat(
                          label: 'Calories',
                          value: '${widget.result.caloriesBurned}',
                        ),
                        _SummaryStat(
                          label: 'Exercises',
                          value: '${widget.result.exercisesDone}',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FitButton(
                    label: 'Share to Feed',
                    icon: Icons.ios_share,
                    onPressed: _share,
                    isLoading: _sharing,
                  ),
                  const SizedBox(height: 12),
                  FitButton(
                    label: 'Done',
                    onPressed: () => context.go('/home'),
                    secondary: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(12);
    for (var i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      paint.color = i.isEven ? AppColors.primary : AppColors.success;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 9, 4),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
