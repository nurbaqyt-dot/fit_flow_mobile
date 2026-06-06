import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../core/firebase/firebase_bootstrap.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final controller = StreamController<User?>();
  StreamSubscription<User?>? authSubscription;
  Timer? authTimeout;
  var disposed = false;
  var initialAuthStateReceived = false;

  Future<void> startAuthListener() async {
    try {
      await ref.watch(firebaseInitializationProvider.future);
      if (disposed) return;

      debugPrint('Auth listener initialized');
      authTimeout = Timer(authStateInitializationTimeout, () {
        if (initialAuthStateReceived || controller.isClosed) return;

        final error = TimeoutException(
          'Firebase Auth did not return an initial auth state.',
          authStateInitializationTimeout,
        );
        final stackTrace = StackTrace.current;
        logFirebaseError('Firebase auth state timed out', error, stackTrace);
        controller.addError(error, stackTrace);
        authSubscription?.cancel();
        authSubscription = null;
      });

      authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (user) {
          if (controller.isClosed) return;

          initialAuthStateReceived = true;
          authTimeout?.cancel();
          debugPrint('Auth state received: ${describeFirebaseUser(user)}');
          controller.add(user);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (controller.isClosed) return;

          authTimeout?.cancel();
          logFirebaseError(
            'Firebase auth state listener failed',
            error,
            stackTrace,
          );
          controller.addError(error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      if (controller.isClosed) return;

      authTimeout?.cancel();
      logFirebaseError(
        'Firebase auth listener setup failed',
        error,
        stackTrace,
      );
      controller.addError(error, stackTrace);
    }
  }

  unawaited(startAuthListener());

  ref.onDispose(() {
    disposed = true;
    authTimeout?.cancel();
    authSubscription?.cancel();
    controller.close();
    debugPrint('Auth listener disposed');
  });

  return controller.stream;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

class AuthRepository {
  AuthRepository({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  Future<void>? _googleInit;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await _ensureUserDoc(
        user: user,
        name: name.trim(),
        photoUrl: user.photoURL ?? '',
      );
    }
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token for Firebase Auth.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await _ensureUserDoc(
        user: user,
        name: googleUser.displayName ?? googleUser.email.split('@').first,
        photoUrl: googleUser.photoUrl ?? '',
      );
    }
    return userCredential;
  }

  Future<void> sendPasswordReset(String email) {
    return auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Firebase sign-out still completes even when Google is not configured.
    }
    await auth.signOut();
  }

  Future<void> _ensureGoogleInitialized() {
    _googleInit ??= GoogleSignIn.instance.initialize();
    return _googleInit!;
  }

  Future<void> _ensureUserDoc({
    required User user,
    required String name,
    required String photoUrl,
  }) async {
    final userRef = firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (snapshot.exists) return;

    final usernameBase = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .trim();
    final username = usernameBase.isEmpty
        ? 'athlete${user.uid.substring(0, 5)}'
        : '$usernameBase${user.uid.substring(0, 3)}';
    final achievements = {
      for (final achievement in AppConstants.achievements) achievement: false,
    };

    final batch = firestore.batch();
    batch.set(userRef, {
      'name': name.isEmpty ? 'FitFlow Athlete' : name,
      'username': username,
      'bio': 'Building momentum one session at a time.',
      'photoUrl': photoUrl,
      'level': 1,
      'totalXp': 0,
      'currentStreak': 0,
      'bestStreak': 0,
      'totalWorkouts': 0,
      'following': 0,
      'achievements': achievements,
      'settings': {
        'pushNotifications': true,
        'workoutReminders': true,
        'weeklySummary': true,
        'useKg': true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final notifications = firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('items');
    final now = FieldValue.serverTimestamp();
    batch.set(notifications.doc(), {
      'text': 'Alex liked your post',
      'type': 'social',
      'read': false,
      'createdAt': now,
    });
    batch.set(notifications.doc(), {
      'text': 'You have a 7-day streak! 🔥',
      'type': 'streak',
      'read': false,
      'createdAt': now,
    });
    batch.set(notifications.doc(), {
      'text': 'New challenge available: 30 active minutes today',
      'type': 'challenge',
      'read': false,
      'createdAt': now,
    });
    await batch.commit();
  }
}
