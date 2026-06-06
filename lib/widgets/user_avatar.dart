import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 48,
  });

  final String photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'F'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: photoUrl.isEmpty
            ? DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.secondary),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: AppColors.secondary),
                errorWidget: (_, __, ___) => DecoratedBox(
                  decoration: const BoxDecoration(color: AppColors.secondary),
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: size * 0.44,
                  ),
                ),
              ),
      ),
    );
  }
}
