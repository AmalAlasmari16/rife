import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

/// Bootstraps Firebase for both iOS and Android.
///
/// The platform-specific config files live outside of source control:
///   - Android: `android/app/google-services.json`
///   - iOS:    `ios/Runner/GoogleService-Info.plist`
///
/// They are pulled in at build-time by the Google Services Gradle plugin
/// (Android) and CocoaPods (iOS). Place the files there before the first
/// build — see `mobile/README.md` for the full setup checklist.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Offline persistence powers the "works on poor connections" promise for
    // attendance + daily logs.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
