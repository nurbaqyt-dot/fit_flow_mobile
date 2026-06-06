import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

void showFitSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.surface,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class ScreenPadding extends StatelessWidget {
  const ScreenPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StreamStateView<T> extends StatelessWidget {
  const StreamStateView({super.key, required this.value, required this.data});

  final AsyncSnapshot<T> value;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    if (value.hasError) {
      return Text(
        'Could not load this section. ${value.error}',
        style: const TextStyle(color: AppColors.error),
      );
    }
    if (!value.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return data(value.data as T);
  }
}
