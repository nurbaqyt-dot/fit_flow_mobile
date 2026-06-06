import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ScreenPadding(
        child: notifications.when(
          data: (items) => items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                  message:
                      'Likes, streaks, and challenge updates will land here.',
                )
              : ListView(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificationCard(item: item),
                        ),
                      )
                      .toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Notifications could not load. $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FitCard(
      onTap: () =>
          ref.read(profileRepositoryProvider).markNotificationRead(item.id),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.read ? AppColors.secondary : AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconFor(item.type),
              color: item.read ? AppColors.textSecondary : Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.text, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  DateFormat.MMMd().add_Hm().format(item.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'social':
        return Icons.favorite;
      case 'streak':
        return Icons.local_fire_department;
      case 'challenge':
        return Icons.flag;
      default:
        return Icons.notifications;
    }
  }
}
