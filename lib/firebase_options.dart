// File generated manually from GoogleService-Info.plist
// This file contains Firebase configuration for different platforms

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCAl0_-vQ815i_OaxybN27euuamI_TZXQo',
    appId: '1:1053858925589:web:placeholder',
    messagingSenderId: '1053858925589',
    projectId: 'mind-rush-15036',
    authDomain: 'mind-rush-15036.firebaseapp.com',
    storageBucket: 'mind-rush-15036.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAl0_-vQ815i_OaxybN27euuamI_TZXQo',
    appId: '1:1053858925589:android:placeholder',
    messagingSenderId: '1053858925589',
    projectId: 'mind-rush-15036',
    storageBucket: 'mind-rush-15036.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAl0_-vQ815i_OaxybN27euuamI_TZXQo',
    appId: '1:1053858925589:ios:3837305642038dcf83521c',
    messagingSenderId: '1053858925589',
    projectId: 'mind-rush-15036',
    storageBucket: 'mind-rush-15036.firebasestorage.app',
    iosBundleId: 'com.dvtechventures.mindrush',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCAl0_-vQ815i_OaxybN27euuamI_TZXQo',
    appId: '1:1053858925589:ios:3837305642038dcf83521c',
    messagingSenderId: '1053858925589',
    projectId: 'mind-rush-15036',
    storageBucket: 'mind-rush-15036.firebasestorage.app',
    iosBundleId: 'com.dvtechventures.mindrush',
  );
}

