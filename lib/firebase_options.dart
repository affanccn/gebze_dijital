// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyD4CqNJxmmKPTTnFqjzHbFvvH3FZN8VIRM',
    appId: '1:417554808986:web:aea3daf07f5b6534301f23',
    messagingSenderId: '417554808986',
    projectId: 'gebze-dijital',
    authDomain: 'gebze-dijital.firebaseapp.com',
    storageBucket: 'gebze-dijital.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgnE2rK551zELva0KBG9jgQ9wn-gn_VNE',
    appId: '1:417554808986:android:161f1a7b16613c6b301f23',
    messagingSenderId: '417554808986',
    projectId: 'gebze-dijital',
    storageBucket: 'gebze-dijital.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCKcXtpVxUkZoLqqka7RmiL5jqJtMa0pvw',
    appId: '1:417554808986:ios:6244bbe5fee8d02b301f23',
    messagingSenderId: '417554808986',
    projectId: 'gebze-dijital',
    storageBucket: 'gebze-dijital.firebasestorage.app',
    iosBundleId: 'com.example.gebzeDijital',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCKcXtpVxUkZoLqqka7RmiL5jqJtMa0pvw',
    appId: '1:417554808986:ios:6244bbe5fee8d02b301f23',
    messagingSenderId: '417554808986',
    projectId: 'gebze-dijital',
    storageBucket: 'gebze-dijital.firebasestorage.app',
    iosBundleId: 'com.example.gebzeDijital',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD4CqNJxmmKPTTnFqjzHbFvvH3FZN8VIRM',
    appId: '1:417554808986:web:3a9b4ab2b7c75056301f23',
    messagingSenderId: '417554808986',
    projectId: 'gebze-dijital',
    authDomain: 'gebze-dijital.firebaseapp.com',
    storageBucket: 'gebze-dijital.firebasestorage.app',
  );
}
