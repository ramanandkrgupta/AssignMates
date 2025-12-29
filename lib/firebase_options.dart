// File generated manually based on google-services.json and GoogleService-Info.plist
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnNHHUdaZ1kPoqDf-ScjHhrSpARovdnpI',
    appId: '1:784246474278:android:77b43fe833738a221548e7',
    messagingSenderId: '784246474278',
    projectId: 'assignmates-app',
    storageBucket: 'assignmates-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIZUoStRs1Ub-AwGlODX1LRWL6RPZx-sQ',
    appId: '1:784246474278:ios:a9825cf8a48c73f01548e7',
    messagingSenderId: '784246474278',
    projectId: 'assignmates-app',
    storageBucket: 'assignmates-app.firebasestorage.app',
    iosBundleId: 'in.notesmates.assignmates',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDL-qh4aJU-iYesQjDiESBS2GRCmBBLtmw',
    appId: '1:784246474278:web:06057b101cde650d1548e7',
    messagingSenderId: '784246474278',
    projectId: 'assignmates-app',
    authDomain: 'assignmates-app.firebaseapp.com',
    storageBucket: 'assignmates-app.firebasestorage.app',
    measurementId: 'G-72L3KN5F6X',
  );
}
