import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FitFlowApp()));
}

class FitFlowApp extends ConsumerStatefulWidget {
  const FitFlowApp({super.key});

  @override
  ConsumerState<FitFlowApp> createState() => _FitFlowAppState();
}

class _FitFlowAppState extends ConsumerState<FitFlowApp> {
  var _appReadyLogged = false;

  @override
  Widget build(BuildContext context) {
    final firebaseInitialization = ref.watch(firebaseInitializationProvider);

    final app = firebaseInitialization.when(
      skipLoadingOnRefresh: false,
      loading: () {
        _appReadyLogged = false;
        return _buildMaterialHome(
          const SplashScreen(),
          key: const ValueKey('firebase-loading'),
        );
      },
      error: (error, stackTrace) {
        _appReadyLogged = false;
        return _buildMaterialHome(
          FirebaseSetupScreen(
            error: error,
            stackTrace: stackTrace,
            onRetry: _retryFirebaseInitialization,
          ),
          key: const ValueKey('firebase-error'),
        );
      },
      data: (_) {
        final authState = ref.watch(authStateProvider);

        return authState.when(
          skipLoadingOnRefresh: false,
          loading: () {
            _appReadyLogged = false;
            return _buildMaterialHome(
              const SplashScreen(),
              key: const ValueKey('auth-loading'),
            );
          },
          error: (error, stackTrace) {
            _appReadyLogged = false;
            return _buildMaterialHome(
              FirebaseSetupScreen(
                error: error,
                stackTrace: stackTrace,
                onRetry: _retryFirebaseInitialization,
              ),
              key: const ValueKey('auth-error'),
            );
          },
          data: (_) {
            if (!_appReadyLogged) {
              debugPrint('App ready to display');
              _appReadyLogged = true;
            }

            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              key: const ValueKey('ready-app'),
              debugShowCheckedModeBanner: false,
              title: 'FitFlow',
              theme: AppTheme.dark,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              routerConfig: router,
            );
          },
        );
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: app,
    );
  }

  MaterialApp _buildMaterialHome(Widget home, {required Key key}) {
    return MaterialApp(
      key: key,
      debugShowCheckedModeBanner: false,
      title: 'FitFlow',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: home,
    );
  }

  void _retryFirebaseInitialization() {
    _appReadyLogged = false;
    ref.invalidate(authStateProvider);
    ref.invalidate(firebaseInitializationProvider);
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    super.key,
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  final Object error;
  final StackTrace stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase is not ready',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'FitFlow could not finish connecting to Firebase. Check your configuration or network connection, then try again.',
                ),
                const SizedBox(height: 16),
                Text('$error', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
