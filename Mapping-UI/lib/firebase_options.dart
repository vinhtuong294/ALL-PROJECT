// File này được tạo tự động từ cấu hình Firebase Console
// Chứa thông tin kết nối Firebase cho từng nền tảng

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return web;
    }
  }

  // Cấu hình Web (dùng khi chạy trên Chrome)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnC2p389G8qMbre7j8FBmyafKM5GIonwo',
    authDomain: 'dngo-app.firebaseapp.com',
    databaseURL:
        'https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'dngo-app',
    storageBucket: 'dngo-app.firebasestorage.app',
    messagingSenderId: '1030737312270',
    appId: '1:1030737312270:web:5e3128fcf439133ec99a5f',
  );

  // Cấu hình Android (dùng khi chạy trên điện thoại/emulator Android)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnC2p389G8qMbre7j8FBmyafKM5GIonwo',
    authDomain: 'dngo-app.firebaseapp.com',
    databaseURL:
        'https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'dngo-app',
    storageBucket: 'dngo-app.firebasestorage.app',
    messagingSenderId: '1030737312270',
    appId: '1:1030737312270:web:5e3128fcf439133ec99a5f',
  );

  // Cấu hình iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAnC2p389G8qMbre7j8FBmyafKM5GIonwo',
    authDomain: 'dngo-app.firebaseapp.com',
    databaseURL:
        'https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app',
    projectId: 'dngo-app',
    storageBucket: 'dngo-app.firebasestorage.app',
    messagingSenderId: '1030737312270',
    appId: '1:1030737312270:web:5e3128fcf439133ec99a5f',
  );
}
