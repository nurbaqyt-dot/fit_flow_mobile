import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/fit_button.dart';
import '../widgets/fit_card.dart';
import 'screen_helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, dynamic> _settings = const {};
  bool _hydrated = false;
  bool _saving = false;

  void _hydrate(Map<String, dynamic> settings) {
    if (_hydrated) return;
    _settings = {
      'pushNotifications': settings['pushNotifications'] ?? true,
      'workoutReminders': settings['workoutReminders'] ?? true,
      'weeklySummary': settings['weeklySummary'] ?? true,
      'useKg': settings['useKg'] ?? true,
    };
    _hydrated = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateSettings(_settings);
      if (mounted) showFitSnack(context, 'Settings saved.');
    } catch (error) {
      if (mounted) showFitSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete account?'),
        content: const Text(
          'This removes your profile document and asks Firebase Auth to delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      if (mounted) context.go('/login');
    } catch (error) {
      if (mounted) showFitSnack(context, '$error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ScreenPadding(
        child: profile.when(
          data: (user) {
            _hydrate(user?.settings ?? const {});
            return ListView(
              children: [
                FitCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SwitchRow(
                        title: 'Push notifications',
                        value: _settings['pushNotifications'] == true,
                        onChanged: (value) => setState(
                          () => _settings['pushNotifications'] = value,
                        ),
                      ),
                      _SwitchRow(
                        title: 'Workout reminders',
                        value: _settings['workoutReminders'] == true,
                        onChanged: (value) => setState(
                          () => _settings['workoutReminders'] = value,
                        ),
                      ),
                      _SwitchRow(
                        title: 'Weekly summary',
                        value: _settings['weeklySummary'] == true,
                        onChanged: (value) =>
                            setState(() => _settings['weeklySummary'] = value),
                      ),
                      SwitchListTile(
                        title: Text(
                          _settings['useKg'] == true
                              ? 'Units: kg'
                              : 'Units: lbs',
                        ),
                        value: _settings['useKg'] == true,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) =>
                            setState(() => _settings['useKg'] = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FitButton(
                  label: 'Save Settings',
                  icon: Icons.save,
                  onPressed: _save,
                  isLoading: _saving,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Danger zone',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                FitButton(
                  label: 'Delete Account',
                  icon: Icons.delete,
                  onPressed: _deleteAccount,
                  secondary: true,
                ),
                const SizedBox(height: 12),
                FitButton(
                  label: 'Sign Out',
                  icon: Icons.logout,
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  secondary: true,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(
            'Settings could not load. $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
