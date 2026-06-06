import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class FirebaseConfigException implements Exception {
  const FirebaseConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseOptionsResolution {
  const FirebaseOptionsResolution({
    required this.options,
    required this.source,
  });

  final FirebaseOptions options;
  final String source;

  List<String> get configKeys => DefaultFirebaseOptions.configKeysFor(options);
}

class DefaultFirebaseOptions {
  static const requiredConfigKeys = <String>[
    'apiKey',
    'authDomain',
    'projectId',
    'storageBucket',
    'messagingSenderId',
    'appId',
  ];

  static FirebaseOptionsResolution resolve() {
    final dartDefineOptions = _optionsFromDartDefines();
    if (dartDefineOptions != null) {
      return FirebaseOptionsResolution(
        options: dartDefineOptions,
        source: 'Dart defines',
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptionsResolution(
        options: ios,
        source: 'ios/Runner/GoogleService-Info.plist',
      );
    }

    return const FirebaseOptionsResolution(
      options: bundledProjectOptions,
      source:
          'bundled project options from ios/Runner/GoogleService-Info.plist',
    );
  }

  static List<String> configKeysFor(FirebaseOptions options) {
    final values = <String, String>{
      'apiKey': options.apiKey,
      'authDomain': options.authDomain ?? '',
      'projectId': options.projectId,
      'storageBucket': options.storageBucket ?? '',
      'messagingSenderId': options.messagingSenderId,
      'appId': options.appId,
    };

    return values.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  static FirebaseOptions? _optionsFromDartDefines() {
    const values = <String, String>{
      'apiKey': String.fromEnvironment('FIREBASE_API_KEY'),
      'authDomain': String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      'projectId': String.fromEnvironment('FIREBASE_PROJECT_ID'),
      'storageBucket': String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      'messagingSenderId': String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      'appId': String.fromEnvironment('FIREBASE_APP_ID'),
    };

    final providedKeys = values.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toSet();
    if (providedKeys.isEmpty) return null;

    final missingKeys = requiredConfigKeys
        .where((key) => !providedKeys.contains(key))
        .toList(growable: false);
    if (missingKeys.isNotEmpty) {
      throw FirebaseConfigException(
        'Incomplete Firebase Dart defines. Missing: ${missingKeys.join(', ')}. '
        'Required keys: ${requiredConfigKeys.join(', ')}.',
      );
    }

    return FirebaseOptions(
      apiKey: values['apiKey']!,
      authDomain: values['authDomain'],
      projectId: values['projectId']!,
      storageBucket: values['storageBucket'],
      messagingSenderId: values['messagingSenderId']!,
      appId: values['appId']!,
    );
  }

  static const bundledProjectOptions = FirebaseOptions(
    apiKey: 'AIzaSyAs_LLrHtjiIK7xz5Gp5x6usdH92uPUTHI',
    authDomain: 'fit-flow-project.firebaseapp.com',
    projectId: 'fit-flow-project',
    storageBucket: 'fit-flow-project.firebasestorage.app',
    messagingSenderId: '696435009061',
    appId: '1:696435009061:ios:c16d681197dfa8eb1fc1cc',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyAs_LLrHtjiIK7xz5Gp5x6usdH92uPUTHI',
    authDomain: 'fit-flow-project.firebaseapp.com',
    projectId: 'fit-flow-project',
    storageBucket: 'fit-flow-project.firebasestorage.app',
    messagingSenderId: '696435009061',
    appId: '1:696435009061:ios:c16d681197dfa8eb1fc1cc',
    iosBundleId: 'com.example.fitFlow',
  );
}
