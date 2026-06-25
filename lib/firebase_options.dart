import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with [Firebase.initializeApp].
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDAiiHH9-LEPlVI630_1gT6nA2wSJBPc9I',
    appId: '1:773443742576:android:99bfbdb852815621a43db5',
    messagingSenderId: '773443742576',
    projectId: 'vidyaverse-2026',
    storageBucket: 'vidyaverse-2026.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAcygJSxpwOuuH3-o3Vl0pVUZD92sssZPY',
    appId: '1:773443742576:web:74316015155f75b4a43db5',
    messagingSenderId: '773443742576',
    projectId: 'vidyaverse-2026',
    authDomain: 'vidyaverse-2026.firebaseapp.com',
    storageBucket: 'vidyaverse-2026.firebasestorage.app',
    measurementId: 'G-K5XKY6JQDW',
  );
}
