import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.totalXp});

  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final next = AppConstants.nextLevelXp(totalXp);
    final previous = totalXp < 200
        ? 0
        : totalXp < 500
        ? 200
        : totalXp < 1000
        ? 500
        : 1000;
    final progress = next == totalXp
        ? 1.0
        : ((totalXp - previous) / (next - previous)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppConstants.levelName(totalXp)} level',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              next == totalXp ? '$totalXp XP' : '$totalXp / $next XP',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            backgroundColor: AppColors.secondary,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
