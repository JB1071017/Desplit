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
      case TargetPlatform.windows:
        return windows;
      default:
        return windows;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCCOdj0_700MAb7oyeGhDh7qS4MyFtLCWQ',
    appId: '1:352737838340:web:counter-7843-app',
    messagingSenderId: '352737838340',
    projectId: 'counter-7843-app',
    authDomain: 'counter-7843-app.firebaseapp.com',
    storageBucket: 'counter-7843-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCCOdj0_700MAb7oyeGhDh7qS4MyFtLCWQ',
    appId: '1:352737838340:android:c5e838ed9aec3a1f903c51',
    messagingSenderId: '352737838340',
    projectId: 'counter-7843-app',
    storageBucket: 'counter-7843-app.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCCOdj0_700MAb7oyeGhDh7qS4MyFtLCWQ',
    appId: '1:352737838340:web:counter-7843-app',
    messagingSenderId: '352737838340',
    projectId: 'counter-7843-app',
    authDomain: 'counter-7843-app.firebaseapp.com',
    storageBucket: 'counter-7843-app.firebasestorage.app',
  );
}
