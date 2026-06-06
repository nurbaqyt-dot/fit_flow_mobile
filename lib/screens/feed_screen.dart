import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fit_card.dart';
import '../widgets/user_avatar.dart';
import 'screen_helpers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);
    final authUser = ref.watch(authStateProvider).value;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/feed/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: ScreenPadding(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(feedPostsProvider),
          child: posts.when(
            data: (items) => items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.groups,
                        title: 'No posts yet',
                        message:
                            'Share your next workout and bring the feed online.',
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      Text(
                        'Feed',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 18),
                      ...items.map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PostCard(
                            post: post,
                            currentUid: authUser?.uid ?? '',
                            onLike: () async {
                              try {
                                await ref
                                    .read(feedRepositoryProvider)
                                    .toggleLike(post);
                              } catch (error) {
                                if (context.mounted) {
                                  showFitSnack(
                                    context,
                                    '$error',
                                    isError: true,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                Text(
                  'Feed could not load. $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.onLike,
  });

  final PostModel post;
  final String currentUid;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final liked = post.likes.contains(currentUid);
    return FitCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatar(photoUrl: post.userPhoto, name: post.userName),
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
                        '${post.workoutType} • ${DateFormat.MMMd().add_Hm().format(post.createdAt)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(post.text, style: const TextStyle(height: 1.35)),
            ),
          if (post.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.15,
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(
                  color: AppColors.secondary,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.secondary,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Liked by ${post.likes.length} people',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
