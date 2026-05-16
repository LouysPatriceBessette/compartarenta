// ignore_for_file: lines_longer_than_80_chars
//
// **Replace this file** by running `dart pub global activate flutterfire_cli`
// then `flutterfire configure` from the `mobile/` directory so FCM can reach
// a real Firebase project. Placeholder values keep the project compiling until
// then; push delivery will not work until configuration is complete.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'compartarenta-placeholder',
    authDomain: 'compartarenta-placeholder.firebaseapp.com',
    storageBucket: 'compartarenta-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'compartarenta-placeholder',
    storageBucket: 'compartarenta-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'compartarenta-placeholder',
    storageBucket: 'compartarenta-placeholder.appspot.com',
    iosBundleId: 'com.compartarenta.compartarenta',
  );

  static const FirebaseOptions macos = ios;
}
