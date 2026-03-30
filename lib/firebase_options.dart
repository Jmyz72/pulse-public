// Public repository placeholder.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase options for the public repository copy.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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
    apiKey: 'REMOVED_FOR_PUBLIC_REPO',
    appId: 'REMOVED_FOR_PUBLIC_REPO',
    messagingSenderId: 'REMOVED_FOR_PUBLIC_REPO',
    projectId: 'removed-for-public-repo',
    storageBucket: 'removed-for-public-repo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMOVED_FOR_PUBLIC_REPO',
    appId: 'REMOVED_FOR_PUBLIC_REPO',
    messagingSenderId: 'REMOVED_FOR_PUBLIC_REPO',
    projectId: 'removed-for-public-repo',
    storageBucket: 'removed-for-public-repo.appspot.com',
    iosBundleId: 'com.example.pulse',
  );
}
