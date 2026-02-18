// File generated manually based on provided google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCA7_NDPJPd4iSBIHYBAnhn5c3jzdKPibQ',
    appId: '1:1060561916082:web:placeholder', // Placeholder - User may need to update this from Firebase Console (Project Settings > General > Web Apps)
    messagingSenderId: '1060561916082',
    projectId: 'kowopay',
    authDomain: 'kowopay.firebaseapp.com',
    storageBucket: 'kowopay.firebasestorage.app',
    databaseURL: 'https://kowopay-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCA7_NDPJPd4iSBIHYBAnhn5c3jzdKPibQ',
    appId: '1:1060561916082:android:7c6dff06730d9bf53cb9ab',
    messagingSenderId: '1060561916082',
    projectId: 'kowopay',
    storageBucket: 'kowopay.firebasestorage.app',
    databaseURL: 'https://kowopay-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAxoWf22LL7OqagK5RGdCS914YzcZ_gzNg',
    appId: '1:1060561916082:ios:e160b9e94e9890d83cb9ab',
    messagingSenderId: '1060561916082',
    projectId: 'kowopay',
    storageBucket: 'kowopay.firebasestorage.app',
    iosBundleId: 'com.example.kowopay',
    databaseURL: 'https://kowopay-default-rtdb.firebaseio.com',
  );
}
