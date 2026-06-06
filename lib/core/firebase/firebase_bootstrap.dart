import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

const _firebaseInitializationTimeout = Duration(seconds: 12);
const authStateInitializationTimeout = Duration(seconds: 12);

final firebaseInitializationProvider = FutureProvider<FirebaseApp>((ref) {
  return initializeFirebaseApp();
});

Future<FirebaseApp> initializeFirebaseApp() async {
  debugPrint('Firebase initialization started');

  try {
    if (Firebase.apps.isNotEmpty) {
      final app = Firebase.app();
      debugPrint(
        'Firebase config loaded: ${DefaultFirebaseOptions.configKeysFor(app.options)} '
        'from existing Firebase app',
      );
      return app;
    }

    final resolution = DefaultFirebaseOptions.resolve();
    debugPrint(
      'Firebase config loaded: ${resolution.configKeys} from ${resolution.source}',
    );

    return await Firebase.initializeApp(
      options: resolution.options,
    ).timeout(_firebaseInitializationTimeout);
  } catch (error, stackTrace) {
    logFirebaseError('Firebase initialization failed', error, stackTrace);
    Error.throwWithStackTrace(error, stackTrace);
  }
}

String describeFirebaseUser(User? user) {
  if (user == null) return 'null';

  final providerIds = user.providerData
      .map((provider) => provider.providerId)
      .toList(growable: false);

  return '{uid: ${user.uid}, isAnonymous: ${user.isAnonymous}, '
      'emailVerified: ${user.emailVerified}, providers: $providerIds}';
}

void logFirebaseError(String description, Object error, StackTrace stackTrace) {
  debugPrint('$description: $error\n$stackTrace');
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'Firebase bootstrap',
      context: ErrorDescription(description),
    ),
  );
}
