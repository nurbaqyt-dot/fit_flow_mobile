import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/workout_model.dart';
import '../providers/auth_provider.dart';
import '../screens/active_workout_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../screens/workout_picker_screen.dart';
import '../screens/workout_summary_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authUser = ref.watch(authStateProvider).value;

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: authUser == null ? '/onboarding' : '/home',
    redirect: (context, state) {
      final loggedIn = authUser != null;
      final path = state.uri.path;
      if (path == '/splash') return loggedIn ? '/home' : '/onboarding';

      final publicRoutes = {
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      };
      final isPublic = publicRoutes.contains(path);
      if (!loggedIn && !isPublic) return '/login';
      final authRoute =
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/onboarding';
      if (loggedIn && authRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreatePostScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/workouts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WorkoutPickerScreen(),
      ),
      GoRoute(
        path: '/workouts/:type',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return WorkoutDetailScreen(type: state.pathParameters['type']!);
        },
      ),
      GoRoute(
        path: '/workouts/:type/active',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return ActiveWorkoutScreen(type: state.pathParameters['type']!);
        },
      ),
      GoRoute(
        path: '/workout-summary',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final result = state.extra;
          if (result is! WorkoutResult) return const HomeScreen();
          return WorkoutSummaryScreen(result: result);
        },
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});
