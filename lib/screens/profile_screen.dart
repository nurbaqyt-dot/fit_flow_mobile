import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fit_card.dart';
import '../widgets/user_avatar.dart';
import '../widgets/xp_bar.dart';
import 'screen_helpers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider);
    final myPosts = ref.watch(myPostsProvider);

    return Scaffold(
      body: ScreenPadding(
        child: profile.when(
          data: (user) => ListView(
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 18),
              _StatsRow(user: user),
              const SizedBox(height: 18),
              FitCard(child: XpBar(totalXp: user?.totalXp ?? 0)),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Achievements'),
              const SizedBox(height: 12),
              _Achievements(user: user),
              const SizedBox(height: 24),
              const SectionHeader(title: 'My posts'),
              const SizedBox(height: 12),
              myPosts.when(
                data: (posts) => _MyPosts(posts: posts),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  'Posts could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 24),
              _Menu(
                onSignOut: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Profile could not load. $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final FitUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'FitFlow Athlete';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(photoUrl: user?.photoUrl ?? '', name: name, size: 84),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '@${user?.username ?? 'athlete'}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Level ${user?.level ?? 1} ${AppConstants.levelName(user?.totalXp ?? 0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if ((user?.bio ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            user!.bio,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final FitUser? user;

  @override
  Widget build(BuildContext context) {
    return FitCard(
      child: Row(
        children: [
          _ProfileStat(label: 'Workouts', value: '${user?.totalWorkouts ?? 0}'),
          _ProfileStat(label: 'Streak', value: '${user?.currentStreak ?? 0}'),
          _ProfileStat(label: 'Following', value: '${user?.following ?? 0}'),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

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

class _Achievements extends StatelessWidget {
  const _Achievements({required this.user});

  final FitUser? user;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: AppConstants.achievements.length,
      itemBuilder: (context, index) {
        final achievement = AppConstants.achievements[index];
        final unlocked = user?.achievements[achievement] == true;
        return FitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                unlocked ? Icons.verified : Icons.lock_outline,
                color: unlocked ? AppColors.primary : AppColors.textSecondary,
              ),
              const Spacer(),
              Text(
                achievement,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: unlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MyPosts extends StatelessWidget {
  const _MyPosts({required this.posts});

  final List<PostModel> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const EmptyState(
        icon: Icons.grid_view,
        title: 'No posts shared',
        message: 'Your workout photos and feed posts will appear here.',
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: post.imageUrl.isEmpty
              ? ColoredBox(
                  color: AppColors.surface,
                  child: Center(
                    child: Text(
                      post.workoutType,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              : CachedNetworkImage(imageUrl: post.imageUrl, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Edit Profile', Icons.edit, '/profile/edit'),
      ('Settings', Icons.settings, '/profile/settings'),
      ('Notifications', Icons.notifications, '/profile/notifications'),
    ];
    return FitCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.$2, color: AppColors.primary),
              title: Text(item.$1),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () => context.go(item.$3),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out'),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}
