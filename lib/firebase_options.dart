// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAo2Tu23-RjHRoxfwHPgK1GDkg091PyHR4',
    appId: '1:1027847769078:web:e526159827d0d124a0d5d7',
    messagingSenderId: '1027847769078',
    projectId: 'my-calculator-876c4',
    authDomain: 'my-calculator-876c4.firebaseapp.com',
    storageBucket: 'my-calculator-876c4.firebasestorage.app',
    measurementId: 'G-PK129H3665',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUjcHziAn9nXXxh1BH0Lqo-bEO1NEpsW4',
    appId: '1:1027847769078:android:1ae93c29712bf753a0d5d7',
    messagingSenderId: '1027847769078',
    projectId: 'my-calculator-876c4',
    storageBucket: 'my-calculator-876c4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBOjcksx0VpFN8WS0v9ul-DJ1k0pa8c5Gg',
    appId: '1:1027847769078:ios:ccbfeb0a055c64b9a0d5d7',
    messagingSenderId: '1027847769078',
    projectId: 'my-calculator-876c4',
    storageBucket: 'my-calculator-876c4.firebasestorage.app',
    iosBundleId: 'com.example.myCalculator',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBOjcksx0VpFN8WS0v9ul-DJ1k0pa8c5Gg',
    appId: '1:1027847769078:ios:ccbfeb0a055c64b9a0d5d7',
    messagingSenderId: '1027847769078',
    projectId: 'my-calculator-876c4',
    storageBucket: 'my-calculator-876c4.firebasestorage.app',
    iosBundleId: 'com.example.myCalculator',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAo2Tu23-RjHRoxfwHPgK1GDkg091PyHR4',
    appId: '1:1027847769078:web:5edc674e8a56d5b0a0d5d7',
    messagingSenderId: '1027847769078',
    projectId: 'my-calculator-876c4',
    authDomain: 'my-calculator-876c4.firebaseapp.com',
    storageBucket: 'my-calculator-876c4.firebasestorage.app',
    measurementId: 'G-FR8Z6FDK8B',
  );

}