import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for platforms that cannot read a config file.
///
/// Android reads `google-services.json` and iOS reads `GoogleService-Info.plist`
/// at runtime, so they need nothing here. The web has no such file, so its
/// options have to be compiled into the bundle.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// These values are public by design — they ship inside every web bundle and
  /// identify the project, they do not authorise anything on their own.
  ///
  /// They are duplicated in `web/firebase-messaging-sw.js`, which the browser
  /// loads outside the Dart bundle and so cannot read this file. Change one,
  /// change the other — nothing enforces it.
  // TODO(vikas): replace the API key placeholder once the senior sends it.
  //  The build succeeds without it; Firebase only fails at runtime.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PASTE_FULL_API_KEY',
    appId: '1:15198833110:web:a4192fa474e8f235aac3a7',
    messagingSenderId: '15198833110',
    projectId: 'client-website-test-prod',
    authDomain: 'client-website-test-prod.firebaseapp.com',
    storageBucket: 'client-website-test-prod.firebasestorage.app',
    measurementId: 'G-T2KFXGLD90',
  );
}
