import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Placeholder Firebase options. Regenerate with the FlutterFire CLI once the
/// real Firebase project is provisioned:
///
///   dart pub global activate flutterfire_cli
///   flutterfire configure --project=rifq-prod
///
/// That command will rewrite this file with real keys for each platform and
/// also drop `google-services.json` / `GoogleService-Info.plist` into place.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'رِفق هو تطبيق جوال فقط (iOS/Android) في الوقت الحالي.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        throw UnsupportedError(
          'منصة غير مدعومة: $defaultTargetPlatform',
        );
    }
  }

  // TODO(rifq): replace with values from `flutterfire configure`.
  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'REPLACE_ME_ANDROID_API_KEY',
    appId: 'REPLACE_ME_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'rifq-prod',
    storageBucket: 'rifq-prod.appspot.com',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'REPLACE_ME_IOS_API_KEY',
    appId: 'REPLACE_ME_IOS_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'rifq-prod',
    storageBucket: 'rifq-prod.appspot.com',
    iosBundleId: 'sa.rifq.app',
  );
}
