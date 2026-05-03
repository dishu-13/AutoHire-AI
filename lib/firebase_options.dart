import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const bool _forceConfigured = bool.fromEnvironment(
    'FIREBASE_CONFIGURED',
    defaultValue: false,
  );

  static bool get isConfigured {
    return _forceConfigured ||
        (android.apiKey != 'replace-me' &&
            android.appId != 'replace-me' &&
            android.messagingSenderId != 'replace-me' &&
            android.projectId == 'autohire-ai-8f5f6');
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Only Android is configured for this app.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: 'AIzaSyBfao47v1YnwLSAazeR6z_WcVfW_wiYhQA',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '1:556007849704:android:3f47af55e98439efdc135d',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '556007849704',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'autohire-ai-8f5f6',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'autohire-ai-8f5f6.firebasestorage.app',
    ),
  );
}
