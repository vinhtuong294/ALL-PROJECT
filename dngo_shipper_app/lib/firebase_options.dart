// File generated based on google-services.json configuration
// Project: dngo-app

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhLrmHuA0WP2hCHhCO3BpcbLKe1B3S6uM',
    appId: '1:1030737312270:web:f5a94900a789af34c99a5f',
    messagingSenderId: '1030737312270',
    projectId: 'dngo-app',
    databaseURL: 'https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dngo-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhLrmHuA0WP2hCHhCO3BpcbLKe1B3S6uM',
    appId: '1:1030737312270:android:f5a94900a789af34c99a5f',
    messagingSenderId: '1030737312270',
    projectId: 'dngo-app',
    databaseURL: 'https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'dngo-app.firebasestorage.app',
  );
}
